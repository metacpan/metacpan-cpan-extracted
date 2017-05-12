#!/usr/bin/perl

eval 'exec /usr/bin/perl  -S $0 ${1+"$@"}'
    if 0; # not running under some shell

use warnings;
use strict;

use Migraine;
use YAML;
use Getopt::Std;
use IO::Handle;
use File::Basename;

sub HELP_MESSAGE {
    print STDERR "Syntax: migraine [options] <db-conn.yml>\n";
    print STDERR "-c db-conn.yml      reads configuration from db-conn.yml (compatibility)\n";
    print STDERR "-f                  force (don't stop on missing migrations)\n";
    print STDERR "-m migrations       sets the migrations directory to migrations\n";
    print STDERR "-n                  doesn't execute anything on the database\n";
    print STDERR "-o mid              only apply the given migration\n";
    print STDERR "-u                  upgrades the migraine metadata format if needed\n";
    print STDERR "-v mid              applies migrations up to mid, instead of all\n";
    print STDERR "-V                  verbose mode\n";
    exit 1;
}

sub VERSION_MESSAGE {
    print STDERR "migraine version $Migraine::VERSION\n";
}


$Getopt::Std::STANDARD_HELP_VERSION = 1;

# Command-line options =======================================================
my %opts;
getopts('nc:m:v:Vuo:f', \%opts) || HELP_MESSAGE;

my $config_file          = $opts{c} || shift @ARGV;
if (!$config_file) {
    HELP_MESSAGE;
}
my $force                   = $opts{f};
my $migrations_directory    = $opts{m} || dirname($config_file)."/migrations";
my $no_act                  = $opts{n} || 0;
my $only_apply_migration    = $opts{o};
my $upgrade_database_format = $opts{u};
my $migrate_to_version      = $opts{v};
my $verbose                 = $opts{V};

if (exists $opts{o} && exists $opts{v}) {
    print STDERR "ERROR: You can't specify both a single migration to apply\n\n";
    print STDERR "       and a version to migrate to\n\n";
    HELP_MESSAGE;
}

if (scalar @ARGV > 0) {
    HELP_MESSAGE;
}

# Load config and initial checks =============================================
if (! -r $config_file) {
    print STDERR "ERROR: Can't read configuration file $config_file\n\n";
    HELP_MESSAGE;
}
open F, $config_file;
my $config_data = join("", <F>);
close F;
my $config = YAML::Load($config_data);

# The dbname and dbmasterhost is here for compatibility with some old stuff.
# Explicitly undocumented, please don't use it :-)
my $dsn = $config->{dsn} || "db:mysql:dbname=$config->{dbname};host=$config->{dbmasterhost}";
my $migrator = Migraine->new($config->{dsn},
                             user           => $config->{user},
                             password       => $config->{password},
                             migrations_dir => $migrations_directory);

print "Operating in $config->{dsn}\n";
print "=========================================\n";

if (!$migrator->migraine_metadata_present) {
    print "It seems you haven't run migrations in this DB.\n";
    unless ($no_act) {
        print "Creating migraine metadata...";
        $migrator->create_migraine_metadata;
        print " done.\n";
    }
    print "=========================================\n";
}
else {
    my $db_format = $migrator->migraine_metadata_version;
    if ($db_format < $Migraine::SUPPORTED_METADATA_FORMAT) {
        if ($upgrade_database_format) {
            print "Upgrading database format...";
            my $r = 1;
            unless ($no_act) {
                $r = $migrator->upgrade_migraine_metadata;
            }

            if ($r) {
                print " done.\n";
            }
            else {
                print "\n";
                print STDERR "ERROR: Couldn't upgrade database format";
                exit 1;
            }
        }
        else {
            print STDERR "ERROR: Old migraine metadata format $db_format.\n";
            print STDERR "To upgrade (won't be compatible with older migraine versions!), use -u\n";
            exit 1;
        }
    }
    elsif ($db_format > $Migraine::SUPPORTED_METADATA_FORMAT) {
        print STDERR "ERROR: This version of migraine is too old for your database\n";
        print STDERR "This migraine supports metadata format: $Migraine::SUPPORTED_METADATA_FORMAT\n";
        print STDERR "Your database has metadata format:      $db_format\n";
        exit 1;
    }
}

my %migration_options = (no_act                  => $no_act,
                         skip_missing_migrations => $force,
                         before_migrate          => sub {
                             my ($id, $path) = @_;
                             STDOUT->autoflush(1);
                             print "Applying migration $id ($path)... ";
                             if ($verbose) {
                                 print "\n";
                                 print "Migration contents:\n";
                                 open F, $path;
                                 print join("", <F>), "\n";
                                 close F;
                             }
                         },
                         after_migrate           => sub {
                             my ($id) = @_;
                             print "done\n";
                             if ($verbose) {
                                 print "-" x 50, "\n";
                             }
                         });

# Prepare which migrations to apply ==========================================
my $latest_version = $migrator->latest_version;
print "Currently applied migrations: ",
      join(", ", $migrator->applied_migration_ranges), "\n";
print "Latest available:             $latest_version\n";
print "=========================================\n";

# We either apply a single migration, or all migrations up to a given version
if (defined $only_apply_migration) {
    print "Attempting to apply SINGLE migration $only_apply_migration\n";
    print "-----------------------------------------\n";
    if ($migrator->migration_applied($only_apply_migration)) {
        print STDERR "ERROR: Migration $only_apply_migration is already applied\n";
        exit 1;
    }
    else {
        $migrator->apply_migration($only_apply_migration,
                                   %migration_options);
    }
}
else {
    $migration_options{version} = $migrate_to_version || $latest_version;
    if ($migration_options{version} > $latest_version) {
        print STDERR "Can't migrate to version $migration_options{version}. Latest is $latest_version\n";
        exit 1;
    }
    else {
        # Calculate if there are any migrations pending to apply
        my @pending_migrations = ();
        foreach my $migration (1 .. $migration_options{version}) {
            if (!$migrator->migration_applied($migration)) {
                push @pending_migrations, $migration;
            }
        }
        if (!@pending_migrations) {
            print "No migrations left to apply to reach version $migration_options{version}.\n";
        }
        else {
            print "Attempting migration to VERSION: ", $migration_options{version}, "\n";
            print "-----------------------------------------\n";
            $migrator->migrate(%migration_options);
        }
    }
}

__END__

=head1 NAME

migraine - DB schema MIGRAtor that takes headache out of the game

=head1 SYNOPSIS

 $ migraine db-conn-live.yml
 $ migraine -n db-conn-test.yml         # No act (a la Makefile)
 $ migraine -m alternative-migrations-dir db-conn-devel.yml
 $ migraine -V -v 5 db-conn-live.yml    # Verbose, migrate up to 5
 $ migraine -o 8 db-conn-devel.yml      # Apply ONLY migration 8
 $ migraine -f db-conn-test.yml         # Don't stop on missing migrations

=head1 DESCRIPTION

DB schema migrator inspired by Rails migrations. Allows developers to store
changes to a DB schema in "migration" files, then run the migrator to get all
the pending migrations for some DB executed. That allows for easy and automated
upgrading of any database used for a given project. Executing migrations just
up to a point (as opposed to "up to the latest version"), or applying single
migrations (say, applying 4, even if 3 is still unapplied) is also supported.

There are two things migraine has to know to be able to update your database:
first, which database should it connect to (given by the YAML configuration
file in the C<migraine> call); second, the list of available migrations (the
files in a directory, by default C<migrations> in the same directory as the
YAML).

=head1 OPTIONS

=over 4

=item -c db-conn.yml

Reads the configuration from C<db-conn.yml>. This option is deprecated, and
it's maintained just temporarily for compatibility with older versions of
migraine. You should pass your configuration file as an argument, without the
C<-c> switch.

=item -f

"Force": don't stop executing migrations if there's one that doesn't exist or
has a duplicated id.

=item -m /some/migrations/dir

Looks for migrations in the given C</some/migrations/dir> directory. The
default is a directory called C<migrations> at the same level as the given YAML
file.

=item -n

Doesn't execute anything on the database ("no act", like Makefile)

=item -o mid

It applies B<only> the given migration with id C<mid>, regardless of which
other migrations may be pending. It returns an error if the migration was
B<already> applied.

=item -u

Upgrades the migraine metadata in the target database, if needed. It will
return an error if the migraine metadata is newer than migraine supports.

=item -v mid

Instead of trying to apply all available migrations, it only applies pending
migrations up to the given migration id ("migration version") C<mid>.

=item -V

Verbose mode. Give more information about what's going on, including showing
the complete text of the migrations being applied.

=back

=head1 DATABASE CONNECTION INFORMATION

It's stored in a YAML file (mandatory argument in C<migraine> calls) which
looks like this:

 dsn: dbi:mysql:dbname=mydb;host=mydbserver;port=3307
 user: dbuser
 # password: s3kr3t

=head1 MIGRATIONS

The migration filenames B<must> have the form
I<number>C<->I<some_name>C<.>I<extension>. Numbers should start at B<1>, and
none of them should be skipped or repeated. You can use leading zeros to get
nice ASCII-betical order in directory listings.

In the only format currently supported, SQL, the extension must be C<sql>, so
the files will be named something like C<8-add_some_table.sql> or
C<008-update_obsolete_field.sql>. The contents will be executed as-is, without
any processing, so they should be valid SQL for the DB server you're using.

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
