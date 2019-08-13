package Geoffrey::Role::Converter;

use utf8;
use Carp qw/croak/;
use strict;
use warnings;
use Perl::Version;

$Geoffrey::Role::Converter::VERSION = '0.000101';

sub new {
    my $class = shift;
    my $self  = {@_};
    return bless $self, $class;
}

sub changelog_table {
    $_[0]->{changelog_table} //= 'geoffrey_changelogs';
    return $_[0]->{changelog_table};
}

sub changelog_columns {
    return [
        {name => 'id', type => 'varchar', lenght => 64, primarykey => 1, notnull => 1, default => '\'\''},
        {name => 'author',           type => 'varchar', lenght => 128, notnull => 1, default => '\'\'',},
        {name => 'filename',         type => 'varchar', lenght => 255, notnull => 1, default => '\'\''},
        {name => 'md5sum',           type => 'varchar', lenght => 64,  notnull => 1, default => '\'\''},
        {name => 'description',      type => 'varchar', lenght => 255,},
        {name => 'comment',          type => 'varchar', lenght => 128,},
        {name => 'geoffrey_version', type => 'varchar', lenght => 16,  notnull => 1, default => '\'\''},
        {name => 'created', type => 'timestamp', default => 'current_timestamp', notnull => 1,},
    ];
}

sub origin_types {
    return [
        'abstime', 'aclitem',                                                      #Al
        'bigint', 'bigserial', 'bit', 'varbit', 'blob', 'bool', 'box', 'bytea',    #B
        'char', 'character', 'varchar', 'cid', 'cidr', 'circle',                   #C
        'date', 'daterange', 'double', 'double_precision', 'decimal',              #D
                                                                                   #E
                                                                                   #F
        'gtsvector',                                                               #G
                                                                                   #H
        'inet', 'int2vector', 'int4range', 'int8range', 'integer', 'interval',     #I
        'json',                                                                    #J
                                                                                   #K
        'line',    'lseg',                                                         #L
        'macaddr', 'money',                                                        #M
        'name',    'numeric', 'numrange',                                          #N
        'oid',     'oidvector',                                                    #O
        'path',    'pg_node_tree', 'point', 'polygon',                             #P
                                                                                   #Q
        'real', 'refcursor', 'regclass', 'regconfig', 'regdictionary', 'regoper', 'regoperator', 'regproc',
        'regprocedure', 'regtype', 'reltime',                                      #R
        'serial', 'smallint', 'smallserial', 'smgr',                               #S
        'text', 'tid', 'timestamp', 'timestamp_tz', 'time', 'time_tz', 'tinterval', 'tsquery', 'tsrange',
        'tstzrange', 'tsvector', 'txid_snapshot',                                  #T
        'uuid',                                                                    #U
                                                                                   #V
                                                                                   #W
        'xid',                                                                     #X
                                                                                   #Y
                                                                                   #Z
    ];
}

sub min_version { return shift->{min_version} }

sub max_version { return shift->{max_version} }

sub can_create_empty_table;

sub check_version {
    my ($self, $s_version) = @_;
    $s_version = Perl::Version->new($s_version);
    my ($s_max_version, $s_min_version) = undef;
    eval { $s_min_version = $self->min_version; } or do { };
    eval { $s_max_version = $self->max_version; } or do { };
    $s_min_version = Perl::Version->new($s_min_version);
    if ($s_max_version) {
        $s_max_version = Perl::Version->new($s_max_version);
        return 1 if ($s_min_version <= $s_version && $s_version <= $s_max_version);
        require Geoffrey::Exception::NotSupportedException;
        Geoffrey::Exception::NotSupportedException::throw_version($self, $s_min_version, $s_version,
            $s_max_version);
    }
    elsif ($s_min_version <= $s_version) {
        return 1;
    }
    require Geoffrey::Exception::NotSupportedException;
    return Geoffrey::Exception::NotSupportedException::throw_version($self, $s_min_version, $s_version);
}

sub type {
    my ($self, $hr_column) = @_;
    if (!$hr_column->{type}) {
        require Geoffrey::Exception::RequiredValue;
        Geoffrey::Exception::RequiredValue::throw_column_type($self);
    }

    my $s_column_type
        = (grep {/^$hr_column->{type}$/sxm} @{$self->origin_types()})
        ? $self->types()->{$hr_column->{type}}
        : undef;
    if (!$s_column_type) {
        require Geoffrey::Exception::NotSupportedException;
        Geoffrey::Exception::NotSupportedException::throw_column_type($hr_column->{type}, $self);
    }
    $s_column_type .= $hr_column->{strict} ? '(strict)' : q//;
    $s_column_type .= defined $hr_column->{lenght} ? qq~($hr_column->{lenght})~ : q//;
    return $s_column_type;
}

sub _create_table {
    my ($self, $dbh, $s_name, $ar_columns, $ar_constraints) = @_;
    my $sth = $dbh->prepare($self->select_get_table);
    $sth->execute($s_name) or croak $!;
    my $table = $sth->fetchrow_hashref();
    return if defined $table;
    return {
        name    => $s_name,
        columns => $ar_columns,
        ($ar_constraints ? (constraints => $ar_constraints) : ()),
    };
}

sub create_changelog_table {
    my ($self, $o_dbh) = @_;
    return $self->_create_table($o_dbh, $self->changelog_table(), $self->changelog_columns());
}

sub constraints {
    require Geoffrey::Exception::NotSupportedException;
    return Geoffrey::Exception::NotSupportedException::throw_converter();
}

sub index {
    require Geoffrey::Exception::NotSupportedException;
    return Geoffrey::Exception::NotSupportedException::throw_converter();
}

sub table {
    require Geoffrey::Exception::NotSupportedException;
    return Geoffrey::Exception::NotSupportedException::throw_converter();
}

sub view {
    require Geoffrey::Exception::NotSupportedException;
    return Geoffrey::Exception::NotSupportedException::throw_converter();
}

sub foreign_key {
    require Geoffrey::Exception::NotSupportedException;
    return Geoffrey::Exception::NotSupportedException::throw_converter();
}

sub trigger {
    require Geoffrey::Exception::NotSupportedException;
    return Geoffrey::Exception::NotSupportedException::throw_converter();
}

sub primary_key {
    require Geoffrey::Exception::NotSupportedException;
    return Geoffrey::Exception::NotSupportedException::throw_converter();
}

sub sequence {
    require Geoffrey::Exception::NotSupportedException;
    return Geoffrey::Exception::NotSupportedException::throw_converter();
}

sub function {
    require Geoffrey::Exception::NotSupportedException;
    return Geoffrey::Exception::NotSupportedException::throw_converter();
}

sub unique {
    require Geoffrey::Exception::NotSupportedException;
    return Geoffrey::Exception::NotSupportedException::throw_converter();
}

sub colums_information {
    require Geoffrey::Exception::NotSupportedException;
    return Geoffrey::Exception::NotSupportedException::throw_list_information('colums_information', shift);
}

sub index_information {
    require Geoffrey::Exception::NotSupportedException;
    return Geoffrey::Exception::NotSupportedException::throw_list_information('index_information', shift);
}

sub view_information {
    require Geoffrey::Exception::NotSupportedException;
    return Geoffrey::Exception::NotSupportedException::throw_list_information('view_information', shift);
}

sub sequence_information {
    require Geoffrey::Exception::NotSupportedException;
    return Geoffrey::Exception::NotSupportedException::throw_list_information('sequence_information', shift);
}

sub primary_key_information {
    require Geoffrey::Exception::NotSupportedException;
    return Geoffrey::Exception::NotSupportedException::throw_list_information('primary_key_information',
        shift);
}

sub function_information {
    require Geoffrey::Exception::NotSupportedException;
    return Geoffrey::Exception::NotSupportedException::throw_list_information('function_information', shift);
}

sub unique_information {
    require Geoffrey::Exception::NotSupportedException;
    return Geoffrey::Exception::NotSupportedException::throw_list_information('unique_information', shift);
}

sub trigger_information {
    require Geoffrey::Exception::NotSupportedException;
    return Geoffrey::Exception::NotSupportedException::throw_list_information('trigger_information', shift);
}

1;    # End of Geoffrey::converter

__END__

=pod

=encoding UTF-8

=head1 NAME

Geoffrey::Role::Converter - Abstract converter class.

=head1 VERSION

Version 0.000101

=head1 DESCRIPTION

=head1 SYNOPSIS

=head1 SUBROUTINES/METHODS

=head2 new

=head2 changelog_columns

=head2 origin_types

=head2 min_version

=head2 max_version

=head2 environment_changelog_relation_table

=head2 can_create_empty_table

=head2 check_version

=head2 type

=head2 create_changelog_table

=head2 changelog_table

=head2 constraints

=head2 index

=head2 table

=head2 view

=head2 foreign_key

=head2 trigger

=head2 primary_key

=head2 sequence

=head2 function

=head2 unique

=head2 colums_information

=head2 function_information

=head2 index_information

=head2 primary_key_information

=head2 sequence_information

=head2 trigger_information

=head2 unique_information

=head2 view_information

=head1 DIAGNOSTICS

=head1 CONFIGURATION AND ENVIRONMENT

=head1 DEPENDENCIES

=head1 INCOMPATIBILITIES

=head1 BUGS AND LIMITATIONS

After installing, you can find documentation for this module with the
perldoc command.

    perldoc Geoffrey

You can also look for information at:

    RT, CPAN's request tracker (report bugs here)
        http://rt.cpan.org/NoAuth/Bugs.html?Dist=Geoffrey

    AnnoCPAN, Annotated CPAN documentation
        http://annocpan.org/dist/Geoffrey

    CPAN Ratings
        http://cpanratings.perl.org/d/Geoffrey

    Search CPAN
        http://search.cpan.org/dist/Geoffrey/

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
