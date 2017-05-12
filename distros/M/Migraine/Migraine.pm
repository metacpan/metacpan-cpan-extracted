package Migraine;

use strict;

our $VERSION = "0.54"; # ==> ALSO update the version in the pod text below!

use Carp;
use DBI;
use English qw(-no_match_vars);

use constant MIGRATION_REGEX           => qr/^(\d+)-.+\..+/;
use constant MIGRAINE_META_CREATION_SQL =>
                "CREATE TABLE migraine_meta (name  varchar(20),
                                             value varchar(200))";
use constant MIGRAINE_META_UPGRADE_SQL =>
                "ALTER TABLE migraine_meta ADD (name  varchar(20),
                                                value varchar(200))";
use constant MIGRAINE_META_REMOVE_OBSOLETE_SQL =>
                "ALTER TABLE migraine_meta DROP version";
use constant MIGRAINE_MIGRATIONS_CREATION_SQL =>
                "CREATE TABLE migraine_migrations (id integer,
                                                   PRIMARY KEY (id))";

our $SUPPORTED_METADATA_FORMAT = 2;

sub new {
    my ($class, $dsn, %params) = @_;
    my $dbh = DBI->connect($dsn, $params{user},
                                 $params{password},
                                 $params{dbi_options});
    my $attrs = { migrations_dir => "migrations",
                  %params,
                  dbh => $dbh };
    bless $attrs, $class;
}

sub dbh {
    my ($self) = @_;
    $self->{dbh};
}

sub migraine_metadata_present {
    my ($self) = @_;

    return $self->_check_table_exists("migraine_meta");
}

sub migraine_metadata_usable {
    my ($self) = @_;

    return ($self->migraine_metadata_version == $SUPPORTED_METADATA_FORMAT);
}

sub _check_table_exists {
    my ($self, $table_name) = @_;

    my @tables = $self->dbh->tables(undef, undef, $table_name);
    return (scalar grep /$table_name/, @tables);
}

sub migraine_metadata_version {
    my ($self) = @_;

    if ($self->migraine_metadata_present) {
        my ($old_raise, $old_print) = ($self->dbh->{RaiseError},
                                       $self->dbh->{PrintError});
        $self->dbh->{RaiseError} = $self->dbh->{PrintError} = 0;
        my $sth = $self->dbh->prepare("SELECT value
                                         FROM migraine_meta
                                        WHERE name = 'metadata_version'");
        my $r = $sth->execute;
        $self->dbh->{RaiseError} = $old_raise;
        $self->dbh->{PrintError} = $old_print;
        if ($r) {
            my $results = $sth->fetchrow_hashref;
            if (defined $results->{value}) {
                return 0 + $results->{value};     # Force number
            }
            else {
                croak "Inconsistent or unknown migraine_meta";
            }
        }
        else {
            my $old_raise = $self->dbh->{RaiseError};
            $self->dbh->{RaiseError} = 0;
            $sth = $self->dbh->prepare("SELECT version FROM migraine_meta");
            $r = $sth->execute;
            $self->dbh->{RaiseError} = $old_raise;
            if ($r) {
                return 1;
            }
            else {
                croak "Inconsistent or unknown migraine_meta";
            }
        }
    }
    else {
        return 0;
    }
}

sub create_migraine_metadata {
    my ($self) = @_;

    unless ($self->migraine_metadata_present) {
        my $sth = $self->dbh->prepare(MIGRAINE_META_CREATION_SQL);
        $sth->execute ||
            croak "Couldn't create migraine_meta table: $DBI::errstr\n";
        $sth = $self->dbh->prepare(MIGRAINE_MIGRATIONS_CREATION_SQL);
        $sth->execute ||
            croak "Couldn't create migraine_migrations table: $DBI::errstr\n";
        $sth = $self->dbh->prepare("INSERT INTO migraine_meta (name, value)
                                                       VALUES (?, ?)");
        $sth->execute('metadata_version', $SUPPORTED_METADATA_FORMAT) ||
            croak "Couldn't insert migraine_meta information.";
    }
    return 1;
}

sub upgrade_migraine_metadata {
    my ($self) = @_;

    my $df = $self->migraine_metadata_version;
    if ($df == 0) {
        return $self->create_migraine_metadata;
    }
    elsif ($df == 1) {
        my $dbh = $self->dbh;
        $dbh->do(MIGRAINE_META_UPGRADE_SQL) ||
            croak "Couldn't upgrade the migraine_meta table: $DBI::errstr\n";
        # Store how many migrations had been applied and remove obsolete record
        my $res = $dbh->selectall_arrayref("SELECT version FROM migraine_meta");
        my $version = $res->[0]->[0];
        $dbh->do("DELETE FROM migraine_meta");  # Remove obsolete record
        $dbh->do(MIGRAINE_META_REMOVE_OBSOLETE_SQL) ||
            croak "Couldn't remove obsolete fields from migraine_meta table: $DBI::errstr\n";
        $dbh->do("INSERT INTO migraine_meta (name, value)
                                     VALUES ('metadata_version', '2')");
        $dbh->do(MIGRAINE_MIGRATIONS_CREATION_SQL) ||
            croak "Couldn't create migraine_migrations table: $DBI::errstr\n";
        for (my $v = 1; $v <= $version; $v++) {
            $dbh->do("INSERT INTO migraine_migrations (id) VALUES ($v)");
        }
        return 1;
    }
    elsif ($df == 2) {
        return 1;
    }
    else {
        croak "Sorry, I don't know how to upgrade from version $df";
    }
}

sub latest_version {
    my ($self) = @_;

    opendir D, $self->{migrations_dir};
    my ($higher_version) = reverse sort { $a <=> $b }
                                        map { $_ =~ MIGRATION_REGEX;
                                              int($1); }
                                            grep { $_ =~ MIGRATION_REGEX }
                                                 readdir D;
    closedir D;
    $higher_version || 0;
}

sub current_version {
    my ($self) = @_;

    if ($self->migraine_metadata_present) {
        my $sth = $self->dbh->prepare("SELECT id FROM migraine_migrations
                                             ORDER BY id DESC
                                                LIMIT 1");
        if (defined $sth && $sth->execute) {
            $sth->bind_columns(\my $version);
            $sth->fetch;
            return $version || 0;
        }
        else {
            croak "Can't query migraine_meta table?! ".$self->dbh->errstr;
        }
    }
    else {
        return 0;
    }
}

sub migration_applied {
    my ($self, $migration_id) = @_;

    return unless $self->migraine_metadata_usable;
    my $sth = $self->dbh->prepare("SELECT id FROM migraine_migrations
                                            WHERE id = ?");
    if (defined $sth && $sth->execute($migration_id)) {
        $sth->bind_columns(\my $version);
        $sth->fetch;
        if (defined $version && $version == $migration_id) {
            return 1;
        }
    }
    else {
        return 0;
    }
}

sub migrate {
    my ($self, %user_params) = @_;
    my %params = (no_act => 0, %user_params);

    my $up_to_version = $params{version} || $self->latest_version;

    # Create migraine metadata if it's not there
    $self->create_migraine_metadata unless $params{no_act};

    for (my $cnt = 1; $cnt <= $up_to_version; $cnt++) {
        next if $self->migration_applied($cnt);
        $self->apply_migration($cnt, before_migrate => $params{before_migrate},
                                     after_migrate  => $params{after_migrate},
                                     no_act         => $params{no_act},
                                     skip_missing_migrations =>
                                            $params{skip_missing_migrations});
    }
}

sub _mark_migration_as_applied {
    my ($self, $version) = @_;

    my $sth = $self->dbh->prepare("INSERT INTO migraine_migrations (id)
                                                            VALUES (?)");
    $sth->execute($version);
}

sub apply_migration {
    my ($self, $version, %user_options) = @_;
    my %options = (no_act                  => 0,
                   skip_missing_migrations => 0,
                   %user_options);

    if ($self->migration_applied($version)) {
        croak "Migration $version already applied";
    }

    my $contents;
    eval {
        if ($options{before_migrate}) {
            $options{before_migrate}->($version,
                                       $self->get_migration_path($version));
        }
        $contents = $self->get_migration($version);
    };
    if ($EVAL_ERROR) {
        if ($options{skip_missing_migrations}) {
            print STDERR "Skipping migration $version: $EVAL_ERROR";
            return;
        }
        else {
            die $EVAL_ERROR;
        }
    }

    if (defined $contents) {
        unless ($options{no_act}) {
            foreach my $query (split(/;\s*\n/, $contents)) {
                my $sth = $self->dbh->prepare($query);
                if ($sth) {
                    my $r;
                    eval { $r = $sth->execute };
                    $r || croak "Couldn't execute migration $version ($query): ".$self->dbh->errstr;
                }
                else {
                    croak "Can't prepare migration $version: ".$self->dbh->errstr;
                }
            }
            $self->_mark_migration_as_applied($version);
        }

        if ($options{after_migrate}) {
            $options{after_migrate}->($version,
                                      $self->get_migration_path($version));
        }
    }
}

sub applied_migrations {
    my ($self) = @_;

    if ($self->migraine_metadata_usable) {
        my $res = $self->dbh->selectall_arrayref("SELECT id
                                                    FROM migraine_migrations
                                                ORDER BY id");
        return map { $_->[0] } @$res;
    }
    else {
        return;
    }
}

sub applied_migration_ranges {
    my ($self) = @_;

    my @ordered_migrations = $self->applied_migrations;
    return if scalar @ordered_migrations == 0;
    my $range_first_item = $ordered_migrations[0];
    my $last_item        = $range_first_item;
    my @r = ();
    foreach my $id (@ordered_migrations) {
        if ($id > $last_item + 1) {
            push @r,
                 ($last_item != $range_first_item ?
                     "$range_first_item-$last_item" :
                     "$range_first_item");
            $range_first_item = $id;
        }
        $last_item = $id;
    }

    # Take care of the last range/element
    push @r,
         ($last_item != $range_first_item ?
             "$range_first_item-$last_item" :
             "$range_first_item");

    return @r;
}

sub get_migration_path {
    my ($self, $version) = @_;

    opendir D, $self->{migrations_dir};
    my @migrations = map { "$self->{migrations_dir}/$_" }
                         grep /^0*$version-.+\..+$/,
                              readdir D;
    closedir D;

    @migrations || die "Can't find migration $version\n";
    scalar @migrations == 1 || die "More than one migration '$version'?!\n";
    return $migrations[0];
}

sub get_migration {
    my ($self, $version) = @_;

    # This will throw an exception if it's not there, there is more than one or
    # whatever. So we can assume everything was right.
    my $path = $self->get_migration_path($version);

    open F, $path;
    my $contents = join("", <F>);
    close F;
    return $contents;
}

1;

__END__

=head1 NAME

Migraine - DB schema MIGRAtor that takes headache out of the game

=head1 SYNOPSIS

    use Migraine;
    $migrator = Migraine->new($dsn);
    $migrator = Migraine->new($dsn, user => 'dbuser', password => 's3kr3t');
    $migrator = Migraine->new($dsn, migrations_dir => 'migrations');
    $migrator->migrate;                 # Latest version
    $migrator->migrate(version => $v);  # Custom version
    $migrator->migrate(before_migrate => sub {
                                            my ($version, $path) = @_;
                                            # ...
                                         });
    $migrator->migrate(after_migrate => sub {
                                            my ($version, $path) = @_
                                            # ...
                                        });

=head1 DESCRIPTION

DB schema migrator (migraine) implementation module. See migraine for more
details.

To be able to know the current version of the DB schema in a given database,
the C<Migraine> module maintains certain meta information in it, in special
tables called C<migraine_*>. These tables shouldn't be deleted or modified in
any way.

=head1 METHODS

=over 4

=item dbh

Returns a DB handler.

=item migraine_metadata_present

Returns if the migraine metadata is already present in the target database
(needed for migraine to work).

=item migraine_metadata_usable

Returns if the migraine metadata is already present in the target database,
B<and> that it's the correct format/version.

=item migraine_metadata_version

Returns the migraine metadata version for the target database.

=item create_migraine_metadata

Creates the migraine metadata in the target metadata, if it's not already
there.

=item upgrade_migraine_metadata

Upgrades the migraine metadata if it's an older version. If it doesn't exist at
all, it's created. It dies if the metadata has a future version.

=item latest_version

Returns the latest migration version in the specified migrations dir.

=item current_version

B<This method is deprecated>. Now, thinking in terms of the version of the
database is obsolete: now a database has a list of migrations applied to it.
It returns the highest id of the applied migrations. It returns 0 if the
migraine metadata is not in place.

=item migration_applied($id)

Returns if the given migration is already applied.

=item migrate(%options)

Migrates the database. The valid keys for the C<%options> hash are:

=over 4

=item C<version>

Specifies the version to migrate to (instead of just using
the latest one)

=item C<before_migrate>, C<after_migrate>

Subroutines to be executed before and after each migration. When they are
called, they are passed two parameters: the version of the migration to be/just
executed, and the path for the migration file to be/just executed.

=item C<no_act>

Specifies that no migrations should be actually executed in the DB. The hooks
B<will> be executed, though.

=item C<skip_missing_migrations>

Specifies that if a migration doesn't exist (or there is more than one
migration with the same id or something similar) it will just be skipped
instead of producing an error and stopping execution.

=back

=item apply_migration($id, %user_opts)

Applies the given migration (C<$id>). Supports the following options:
C<before_migrate>, C<after_migrate>, C<no_act> and C<skip_missing_migrations>.
See the C<migrate> documentation for details.

=item applied_migrations

Returns the list of migration ids that have been already applied.

=item applied_migration_ranges

Returns a list of B<strings> representing version ranges of applied
migrations. For example, if the applied migration list is (1,2,3,8,10,11), it
will return ("1-3","8","10-11").

=back

=head1 VERSION

    0.54

=head1 LICENSE AND COPYRIGHT

This code is offered under the Open Source BSD license.

Copyright (c) 2009, Opera Software. All rights reserved.

Redistribution and use in source and binary forms, with or without
modification, are permitted provided that the following conditions are met:

=over 4

=item

Redistributions of source code must retain the above copyright notice,
this list of conditions and the following disclaimer.

=item

Redistributions in binary form must reproduce the above copyright notice,
this list of conditions and the following disclaimer in the documentation
and/or other materials provided with the distribution.

=item

Neither the name of Opera Software nor the names of its contributors may
be used to endorse or promote products derived from this software without
specific prior written permission.

=back

=head1 DISCLAIMER OF WARRANTY

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND
ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR
ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
(INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON
ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
(INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
