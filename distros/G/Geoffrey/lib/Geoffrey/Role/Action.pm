package Geoffrey::Role::Action;

use utf8;
use strict;
use warnings FATAL => 'all';

$Geoffrey::Role::Action::VERSION = '0.000101';

sub new {
    my $class = shift;
    my $self  = {@_};
    # make converter required
    if ( !$self->{converter} ) {
        require Geoffrey::Exception::RequiredValue;
        Geoffrey::Exception::RequiredValue::throw_converter( __PACKAGE__ . '::new' );
    }
    return bless $self, $class;
}

sub dbh { return $_[0]->{dbh} }

sub converter { return $_[0]->{converter} }

sub add {
    require Geoffrey::Exception::NotSupportedException;
    return Geoffrey::Exception::NotSupportedException::throw_action( 'add', shift );
}

sub alter {
    require Geoffrey::Exception::NotSupportedException;
    return Geoffrey::Exception::NotSupportedException::throw_action( 'alter', shift );
}

sub drop {
    require Geoffrey::Exception::NotSupportedException;
    return Geoffrey::Exception::NotSupportedException::throw_action( 'drop', shift );
}

sub list_from_schema {
    require Geoffrey::Exception::NotSupportedException;
    return Geoffrey::Exception::NotSupportedException::throw_action( 'list_from_schema',
        shift );
}

sub dryrun {
    my ( $self, $dryrun ) = @_;
    return $self->{dryrun} if !defined $dryrun;
    $self->{dryrun} = $dryrun;
    return $self;
}

sub for_table {
    my ( $self, $for_table ) = @_;
    return $self->{for_table} if !defined $for_table;
    $self->{for_table} = $for_table;
    return $self;
}

sub do {
    my ( $self, $s_sql ) = @_;
    return $s_sql if $self->dryrun;
    require Geoffrey::Exception::Database;
    Geoffrey::Exception::Database::throw_no_dbh() if !$self->dbh;
    $self->dbh->do($s_sql) or Geoffrey::Exception::Database::throw_sql_handle( $!, $s_sql );
    return $s_sql;
}

sub do_arrayref {
    my ( $self, $s_sql, $options ) = @_;
    return unless $s_sql;
    return [] if $self->dryrun;
    require Geoffrey::Exception::Database;
    Geoffrey::Exception::Database::throw_no_dbh() if !$self->dbh;
    return $self->dbh->selectall_arrayref( $s_sql, { Slice => {} }, @{$options} )
      || Geoffrey::Exception::Database::throw_sql_handle( $!, $s_sql );
}

sub do_prepared {
    my ( $self, $s_sql, $ar_values ) = @_;
    return $s_sql if $self->dryrun;
    require Carp;
    my $obj_prepared_statement = $self->dbh->prepare($s_sql) or Carp::croak $!;
    $obj_prepared_statement->execute( @{$_} ) or Carp::croak $! for @{$ar_values};
    return $s_sql;
}

1;# End of Geoffrey::Role::Action

__END__

=pod

=encoding UTF-8

=head1 NAME

Geoffrey::Role::Action - Abstract action class.

=head1 VERSION

Version 0.000101

=head1 DESCRIPTION

=head1 SYNOPSIS

=head1 SUBROUTINES/METHODS

=head2 new

=head2 dbh

=head2 converter

=head2 add

Required sub to run add for specific action type.

=head2 alter

Required sub to run alter for specific action type.

=head2 drop

Required sub to run drop for specific action type.

=head2 list_from_schema

Required sub to run drop for specific action type.

=head2 do

Running generated sql statements.

=head2 do_arrayref

Running generated sql statements.

=head2 dryrun

Boolean if action should only do in dryrun

=head2 for_table

Boolean if action is to generate a complete create table statement

=head2 do_prepared

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
