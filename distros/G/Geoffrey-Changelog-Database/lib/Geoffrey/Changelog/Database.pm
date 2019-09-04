package Geoffrey::Changelog::Database;

use utf8;
use 5.024;
use strict;
use warnings;
use Geoffrey::Exception::Database;

$Geoffrey::Changelog::Database::VERSION = '0.000202';

use parent 'Geoffrey::Role::Changelog';

sub new {
    my $class = shift;
    my $self  = $class->SUPER::new(@_);
    $self->{needs_converter} = 1;
    $self->{needs_dbh}       = 1;
    $self->{generated_sql}   = [];
    $self = bless $self, $class;
    $self->_prepare_tables if ($self->converter && $self->dbh);
    return $self;
}

sub _action_entry {
    my ($self, $o_action_entry) = @_;
    $self->{action_entry} = $o_action_entry if $o_action_entry;
    require Geoffrey::Action::Entry;
    $self->{action_entry} //= Geoffrey::Action::Entry->new(dbh => $self->dbh, converter => $self->converter);
    return $self->{action_entry};
}

sub _sql_abstract {
    my ($self) = @_;
    require SQL::Abstract;
    $self->{sql_abstract} //= SQL::Abstract->new;
    return $self->{sql_abstract};
}

sub _changlog_entries_table_name {
    $_[0]->{changlog_entries_table} //= 'geoffrey_changlog_entries';
    return $_[0]->{changlog_entries_table};
}

sub _changlog_entries_table {
    my ($self) = @_;
    return [
        {name => 'id',        type => 'integer', primarykey => 1, notnull => 1, default => 'autoincrement',},
        {name => 'action',    type => 'varchar', lenght     => 64,},
        {name => 'name',      type => 'varchar', lenght     => 64,},
        {name => 'template',  type => 'varchar', lenght     => 64,},
        {name => 'type',      type => 'varchar', lenght     => 64,},
        {name => 'plain_sql', type => 'text'},
        {name => 'refcolumn', type => 'varchar', lenght     => 64,},
        {name => 'reftable',  type => 'varchar', lenght     => 64,},
        {name => 'columns',   type => 'varchar', lenght     => 64,},
        {
            name       => 'geoffrey_changelog',
            type       => 'varchar',
            lenght     => 64,
            notnull    => 1,
            foreignkey => {reftable => $self->geoffrey_changelogs, refcolumn => 'id'},
        },
    ];
}

sub _get_changesets {
    my ($self, $hr_params) = @_;
    $self->_prepare_tables;
    my $s_changeset_sql = $self->_sql_abstract->select(
        ($self->schema ? $self->schema . q/./ : q//) . $self->geoffrey_changelogs,
        qw/*/,
        {
            ($hr_params->{changeset_id} ? (id => $hr_params->{changeset_id}) : ()),
            ($hr_params->{not_executed} ? (md5sum => undef) : ()),
        });
    return $self->dbh->selectall_arrayref(
        $s_changeset_sql,
        {Slice => {}},
        ($hr_params->{changeset_id} ? ($hr_params->{changeset_id}) : ())
    ) || Geoffrey::Exception::Database::throw_sql_handle($!, $s_changeset_sql);
}

sub _prepare_tables {
    my ($self) = @_;
    require Geoffrey::Action::Table;
    my $o_action_able = Geoffrey::Action::Table->new(dbh => $self->dbh, converter => $self->converter);
    my $hr_params = $self->converter->get_changelog_table_hashref($self->dbh, $self->schema);
    if ($hr_params) {
        $hr_params->{schema} = $self->schema;
        Geoffrey::Action::Table->new(dbh => $self->dbh, converter => $self->converter)->add($hr_params);
    }

    my $o_statement_handle = $self->dbh->prepare($self->converter->select_get_table);
    if ($self->schema) {
        $o_statement_handle->execute($self->schema, $self->_changlog_entries_table_name) or Carp::confess $!;
    }
    else {
        $o_statement_handle->execute($self->_changlog_entries_table_name) or Carp::confess $!;
    }
    $hr_params = $o_statement_handle->fetchrow_hashref;
    return $hr_params ? undef : $o_action_able->add({
        name    => $self->_changlog_entries_table_name,
        columns => $self->_changlog_entries_table,
        schema  => $self->schema,
    });
}

sub file_extension { return $_[0]->{file_extension}; }

sub _get_changeset_entries {
    my ($self, $hr_unhandeled_changelog) = @_;
    my $s_table_name = ($self->schema ? $self->schema . q/./ : q//) . $self->_changlog_entries_table_name;
    my $s_entries_sql = $self->_sql_abstract->select($s_table_name, qw/*/, {geoffrey_changelog => {'=', '?'}});

    my $ar_entries = $self->dbh->selectall_arrayref($s_entries_sql, {Slice => {}}, ($hr_unhandeled_changelog->{ID}))
        || Geoffrey::Exception::Database::throw_sql_handle($!, $s_entries_sql);
    return $ar_entries;
}

sub load {
    my ($self, $s_changeset_id) = @_;
    my $ar_changesets = $self->_get_changesets($s_changeset_id ? ({changeset_id => $s_changeset_id}) : ());
    $_->{entries} = $self->_get_changeset_entries($_) for @{$ar_changesets};
    require Geoffrey::Utils;
    Geoffrey::Utils::to_lowercase($_) for @{$ar_changesets};
    return ($s_changeset_id && scalar @{$ar_changesets} == 1) ? $ar_changesets->[0] : $ar_changesets;
}


sub load_changeset {
    my ($self, $s_changeset_id) = @_;
    my $ar_changesets = $self->_get_changesets({changeset_id => $s_changeset_id});
    $_->{entries} = $self->_get_changeset_entries($_) for @{$ar_changesets};
    require Geoffrey::Utils;
    Geoffrey::Utils::to_lowercase($_) for @{$ar_changesets};
    return ($s_changeset_id && scalar @{$ar_changesets} == 1) ? $ar_changesets->[0] : $ar_changesets;
}

sub write {
    my ($self, $s_file, $ur_data) = @_;
    return shift->insert(@_);
}

sub delete {
    my ($self, $s_changeset_id) = @_;
    my $ar_changesets = $self->_get_changesets({changeset_id => $s_changeset_id, not_executed => 1});
    return unless scalar @{$ar_changesets};
    my @a_statements = ();
    push @a_statements,
        $self->_action_entry->drop({
            schema     => $self->schema,
            table      => $self->_changlog_entries_table_name,
            conditions => {geoffrey_changelog => $s_changeset_id,}});
    push @a_statements,
        $self->_action_entry->drop(
        {schema => $self->schema, table => $self->geoffrey_changelogs, conditions => {id => $s_changeset_id,}});
    return \@a_statements;
}

sub insert {
    my ($self, $s_file, $ur_data) = @_;
    $self->_prepare_tables;
    require Ref::Util;
    return $self->{generated_sql} if Ref::Util::is_hashref($ur_data);
    for my $hr_changeset (@{$ur_data}) {
        next unless (exists $hr_changeset->{id});
        next unless scalar @{$hr_changeset->{entries}};

        push(
            @{$self->{generated_sql}},
            $self->_action_entry->add({
                    schema => $self->schema,
                    table  => $self->geoffrey_changelogs,
                    values => [{
                            id         => $hr_changeset->{id},
                            filename   => __PACKAGE__ . '::' . __LINE__,
                            created_by => $hr_changeset->{created_by} ? $hr_changeset->{created_by}
                            : $hr_changeset->{author} ? $hr_changeset->{author}
                            : undef,
                            geoffrey_version => $Geoffrey::Changelog::Database::VERSION,
                            ($hr_changeset->{comment} ? (comment => $hr_changeset->{comment}) : ()),
                        }]}));

        for my $hr_entry (@{$hr_changeset->{entries}}) {
            push(
                @{$self->{generated_sql}},
                $self->_action_entry->add({
                        schema => $self->schema,
                        table  => $self->_changlog_entries_table_name,
                        values => [{
                                geoffrey_changelog => $hr_changeset->{id},
                                action             => $hr_entry->{action},
                                name               => $hr_entry->{entry_name},
                                (exists $hr_entry->{as} ? (plain_sql => $hr_entry->{as}) : ()),
                            }]}));
        }
    }
    return $self->{generated_sql};
}

## GETTER / SETTER

sub schema {
    my ($self, $s_schema) = @_;
    $self->{schema} = $s_schema if $s_schema;
    return $self->{schema};
}

sub converter {
    my ($self, $o_converter) = @_;
    $self->{converter} = $o_converter if $o_converter;
    return $self->{converter};
}

sub dbh {
    my ($self, $o_dbh) = @_;
    $self->{dbh} = $o_dbh if $o_dbh;
    return $self->{dbh};
}

sub geoffrey_changelogs {
    my ($self, $s_geoffrey_changelogs) = @_;
    $self->{geoffrey_changelogs} = $s_geoffrey_changelogs if $s_geoffrey_changelogs;
    $self->{geoffrey_changelogs} //= 'geoffrey_changelogs';
    return $self->{geoffrey_changelogs};
}

## END GETTER / SETTER

1;    # End of Geoffrey::Changelog

__END__

=pod

=encoding UTF-8

=head1 NAME

Geoffrey::Changelog::Database - module for Geoffrey::Changelog to load changeset from database tables.

=head1 VERSION

Version 0.000202

=head1 DESCRIPTION

=head1 SYNOPSIS

    my $o_geoffrey = Geoffrey->new(
        dbh            => $o_handle,
        converter_name => 'Pg',
        io_name        => 'Database'
    );

    # the dot is to fake the root directory, which is not needed becaues of database
    my $s_user = 'Mario Zieschang';
    my $s_sql = 'SELECT 1;';
    my $s_changeset_id = time . '-' . $s_user
    $o_geoffrey->insert( q~.~, {
        author  => $s_user,
        id      => $s_changeset_id,
        name    => 'Some createative name',
        entries => [{action => 'sql.add', as => $s_sql}],
    });

    my $hr_changeset = $o_geoffrey->changelog_io->load($s_changeset_id);
    
    # changesets are stored in the geoffrey table but without md5sum. 
    # run the changeset will set it
    $o_geoffrey->reader->run_changeset($hr_get_changeset, delete $hr_get_changeset->{filename});

    # changesets without md5sum can be deleted without effect
    $o_geoffrey->delete($s_changeset_id);

=head1 SUBROUTINES/METHODS

=head2 new

=head2 file_extension

=head2 load

Called to load changesets from database

=head2 write

A wrapper for insert

=head2 converter

Instantiates Geoffrey::Converter::... object if none is the in the internal key 'converter'
and returns it. converter SQLite is default if no changeset_converter is given in the constructor.

=head2 dbh

Contains the given dbi session

=head2 geoffrey_changelogs

Returns the geoffrey_changelogs table name because it's needed for feference

=head2 schema

Some Databases are using different schemas e.g. to categorize.
If you need to store your datas in a special schema you can set it here

=head2 delete

Geoffrey::Changelog::Database is able to delete a changeset by id as long it's not executed

=head2 insert

Called to write changesets to database

=head2 load_changeset

Get the value of a changeset by given changeset id.

=head1 DIAGNOSTICS

=head1 CONFIGURATION AND ENVIRONMENT

=head1 DEPENDENCIES

=over 4

=item * Inherits

L<Geoffrey::Role::Changelog|Geoffrey::Role::Changelog>

=item * Internal usage

L<SQL::Abstract|SQL::Abstract>, L<Geoffrey::Exception::Database|Geoffrey::Exception::Database>

=back

=head1 INCOMPATIBILITIES

=head1 BUGS AND LIMITATIONS

Please report any bugs or feature requests to C<bug-Geoffrey at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Geoffrey>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

You can find documentation for this module with the perldoc command.

    perldoc Geoffrey::Changelog::Database

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
