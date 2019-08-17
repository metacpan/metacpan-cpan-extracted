package Geoffrey::Converter::SQLite;

use utf8;
use 5.016;
use strict;
use Readonly;
use warnings;

$Geoffrey::Converter::SQLite::VERSION = '0.000201';

use parent 'Geoffrey::Role::Converter';

Readonly::Scalar my $I_CONST_LENGTH_VALUE      => 2;
Readonly::Scalar my $I_CONST_NOT_NULL_VALUE    => 3;
Readonly::Scalar my $I_CONST_PRIMARY_KEY_VALUE => 4;
Readonly::Scalar my $I_CONST_DEFAULT_VALUE     => 5;

{

    package Geoffrey::Converter::SQLite::Constraints;

    use parent 'Geoffrey::Role::ConverterType';

    sub new {
        my $class = shift;
        return bless $class->SUPER::new(
            not_null    => q~NOT NULL~,
            unique      => q~UNIQUE~,
            primary_key => q~PRIMARY KEY~,
            foreign_key => q~FOREIGN KEY~,
            check       => q~CHECK~,
          ),
          $class;
    }
}
{

    package Geoffrey::Converter::SQLite::View;

    use parent 'Geoffrey::Role::ConverterType';

    sub add { return 'CREATE VIEW {0} AS {1}'; }

    sub drop { return 'DROP VIEW {0}'; }

    sub list {
        my ( $self, $schema ) = @_;
        require Geoffrey::Utils;
        return
            q~SELECT * FROM  ~
          . Geoffrey::Utils::add_schema($schema)
          . q~sqlite_master WHERE type='view'~;
    }
}
{

    package Geoffrey::Converter::SQLite::ForeignKey;
    use parent 'Geoffrey::Role::ConverterType';
    sub add { return 'FOREIGN KEY ({0}) REFERENCES {1}({2})' }
}
{
    package Geoffrey::Converter::SQLite::PrimaryKey;
    use parent 'Geoffrey::Role::ConverterType';
    sub add    { return 'CONSTRAINT {0} PRIMARY KEY ( {1} )'; }
}
{

    package Geoffrey::Converter::SQLite::UniqueIndex;
    use parent 'Geoffrey::Role::ConverterType';
    sub append { return 'CREATE UNIQUE INDEX IF NOT EXISTS {0} ON {1} ( {2} )'; }
    sub add    { return 'CONSTRAINT {0} UNIQUE ( {1} )'; }
    sub drop   { return 'DROP INDEX IF EXISTS {1}'; }
}
{

    package Geoffrey::Converter::SQLite::Trigger;
    use parent 'Geoffrey::Role::ConverterType';

    sub add {
        my ( $self, $options ) = @_;
        my $s_sql_standard = <<'EOF';
CREATE TRIGGER {0} UPDATE OF {1} ON {2}
BEGIN
    {4}
END
EOF
        my $s_sql_view = <<'EOF';
CREATE TRIGGER {0} INSTEAD OF UPDATE OF {1} ON {2}
BEGIN
    {4}
END
EOF
        return $options->{for_view} ? $s_sql_view : $s_sql_standard;
    }

    sub drop { return 'DROP TRIGGER IF EXISTS {1}'; }
}

sub new {
    my $class = shift;
    my $self  = $class->SUPER::new(@_);
    $self->{min_version} = '3.7';
    return bless $self, $class;
}

sub defaults {
    return {
        current_timestamp => 'CURRENT_TIMESTAMP',
        autoincrement     => 'AUTOINCREMENT',
    };
}

sub types {
    return {
        blob      => 'BLOB',
        integer   => 'INTEGER',
        numeric   => 'NUMERIC',
        real      => 'REAL',
        text      => 'TEXT',
        bool      => 'BOOL',
        double    => 'DOUBLE',
        float     => 'FLOAT',
        char      => 'CHAR',
        varchar   => 'VARCHAR',
        timestamp => 'DATETIME',
    };
}

sub select_get_table {
    return
      q~SELECT t.name AS table_name FROM sqlite_master t WHERE type='table' AND t.name = ?~;
}

sub convert_defaults {
    my ( $self, $params ) = @_;
    return $params->{default};
}
sub can_create_empty_table { return 0 }

sub colums_information {
    my ( $self, $ar_raw_data ) = @_;
    return [] if scalar @{$ar_raw_data} == 0;
    my $table_row = shift @{$ar_raw_data};
    $table_row->{sql} =~ s/^.*(CREATE|create) (.*)\(/$2/g;
    my $columns = [];
    for ( split m/,/, $table_row->{sql} ) {
        s/^TABLE\s+\S+\s+\((.*)/$1/g;
        s/^\s*(.*)\s*$/$1/g;
        my $rx_not_null      = 'NOT NULL';
        my $rx_primary_key   = 'PRIMARY KEY';
        my $rx_default       = 'AUTOINCREMENT|DEFAULT';
        my $rx_column_values = qr/($rx_not_null)*\s($rx_primary_key)*.*($rx_default \w{1,})*/;
        my @column           = m/^(\w+)\s([[:upper:]]+)(\(\d*\))*\s$rx_column_values$/;
        next if scalar @column == 0;
        $column[$I_CONST_LENGTH_VALUE] =~ s/([\(\)])//g if $column[$I_CONST_LENGTH_VALUE];
        push @{$columns},
          {
            name => $column[0],
            type => $column[1],
            (
                $column[$I_CONST_LENGTH_VALUE] ? ( length => $column[$I_CONST_LENGTH_VALUE] )
                : ()
            ),
            (
                $column[$I_CONST_NOT_NULL_VALUE]
                ? ( not_null => $column[$I_CONST_NOT_NULL_VALUE] )
                : ()
            ),
            (
                $column[$I_CONST_PRIMARY_KEY_VALUE]
                ? ( primary_key => $column[$I_CONST_PRIMARY_KEY_VALUE] )
                : ()
            ),
            (
                $column[$I_CONST_DEFAULT_VALUE]
                ? ( default => $column[$I_CONST_DEFAULT_VALUE] )
                : ()
            ),
          };
    }
    return $columns;
}

sub index_information {
    my ( $self, $ar_raw_data ) = @_;
    my @mapped = ();
    for ( @{$ar_raw_data} ) {
        next if !$_->{sql};
        my ($s_columns) = $_->{sql} =~ m/\((.*)\)$/;
        my @columns = split m/,/, $s_columns;
        s/^\s+|\s+$//g for @columns;
        push @mapped,
          {
            name    => $_->{name},
            table   => $_->{tbl_name},
            columns => \@columns
          };
    }
    return \@mapped;
}

sub view_information {
    my ( $self, $ar_raw_data ) = @_;
    return [] unless $ar_raw_data;
    return [ map { { name => $_->{name}, sql => $_->{sql} } } @{$ar_raw_data} ];
}

sub constraints {
    my ($self) = @_;
    $self->{constraints} //= Geoffrey::Converter::SQLite::Constraints->new;
    return $self->{constraints};
}

sub index {
    my ( $self, $new_value ) = @_;
    require Geoffrey::Converter::SQLite::Index;
    $self->{index} = $new_value if defined $new_value;
    $self->{index} //= Geoffrey::Converter::SQLite::Index->new;
    return $self->{index};
}

sub table {
    my ($self) = @_;
    require Geoffrey::Converter::SQLite::Tables;
    $self->{table} //= Geoffrey::Converter::SQLite::Tables->new;
    return $self->{table};
}

sub view {
    my ($self) = @_;
    $self->{view} //= Geoffrey::Converter::SQLite::View->new;
    return $self->{view};
}

sub foreign_key {
    my ( $self, $new_value ) = @_;
    $self->{foreign_key} = $new_value if defined $new_value;
    $self->{foreign_key} //= Geoffrey::Converter::SQLite::ForeignKey->new;
    return $self->{foreign_key};
}

sub trigger {
    my ( $self, $o_trigger ) = @_;
    $self->{trigger} = $o_trigger if defined $o_trigger;
    $self->{trigger} //= Geoffrey::Converter::SQLite::Trigger->new;
    return $self->{trigger};
}

sub primary_key {
    my ($self) = @_;
    $self->{primary_key} //= Geoffrey::Converter::SQLite::PrimaryKey->new;
    return $self->{primary_key};
}

sub unique {
    my ($self) = @_;
    $self->{unique} //= Geoffrey::Converter::SQLite::UniqueIndex->new;
    return $self->{unique};
}

1;    # End of Geoffrey::Converter::SQLite

__END__

=pod

=head1 NAME

Geoffrey::Converter::SQLite - SQLite converter for Geoffrey

=head1 VERSION

Version 0.000201

=head1 DESCRIPTION

=head1 SYNOPSIS

=head1 SUBROUTINES/METHODS

=head2 new

=head2 colums_information

=head2 convert_defaults

=head2 defaults

=head2 index_information

=head2 select_get_table

=head2 types

=head1 DIAGNOSTICS

=head1 CONFIGURATION AND ENVIRONMENT

=head1 DEPENDENCIES

=head1 INCOMPATIBILITIES

=head1 BUGS AND LIMITATIONS

Please report any bugs or feature requests to C<bug-Geoffrey at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Geoffrey>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

You can find documentation for this module with the perldoc command.

    perldoc Geoffrey::Converter::SQLite

You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Geoffrey>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Geoffrey>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Geoffrey>

=item * Search CPAN

L<http://search.cpan.org/dist/Geoffrey/>

=back

=head1 AUTHOR

Mario Zieschang, C<< <mziescha at cpan.org> >>

=head1 LICENSE AND COPYRIGHT

Copyright 2015 Mario Zieschang.

This program is free software; you can redistribute it and/or modify it
under the terms of the the Artistic License (2.0). You may obtain a
copy of the full license at:

L<http://www.perlfoundation.org/artistic_license_2_0>

Any use, modification, and distribution of the Standard or Modified
Versions is governed by this Artistic License. By using, modifying or
distributing the Package, you accept this license. Do not use, modify,
or distribute the Package, if you do not accept this license.

If your Modified Version has been derived from a Modified Version made
by someone other than you, you are nevertheless required to ensure that
your Modified Version complies with the requirements of this license.

This license does not grant you the right to use any trademark, service
mark, trade name, or logo of the Copyright Holder.

This license includes the non-exclusive, worldwide, free-of-charge
patent license to make, have made, use, offer to sell, sell, import and
otherwise transfer the Package with respect to any patent claims
licensable by the Copyright Holder that are necessarily infringed by the
Package. If you institute patent litigation (including a cross-claim or
counterclaim) against any party alleging that the Package constitutes
direct or contributory patent infringement, then this Artistic License
to you shall terminate on the date that such litigation is filed.

Disclaimer of Warranty: THE PACKAGE IS PROVIDED BY THE COPYRIGHT HOLDER
AND CONTRIBUTORS "AS IS' AND WITHOUT ANY EXPRESS OR IMPLIED WARRANTIES.
THE IMPLIED WARRANTIES OF MERCHANT ABILITY, FITNESS FOR A PARTICULAR
PURPOSE, OR NON-INFRINGEMENT ARE DISCLAIMED TO THE EXTENT PERMITTED BY
YOUR LOCAL LAW. UNLESS REQUIRED BY LAW, NO COPYRIGHT HOLDER OR
CONTRIBUTOR WILL BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, OR
CONSEQUENTIAL DAMAGES ARISING IN ANY WAY OUT OF THE USE OF THE PACKAGE,
EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

=cut
