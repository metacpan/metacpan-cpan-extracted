package GitDDL::Migrator;
use 5.008001;
use strict;
use warnings;

our $VERSION = "0.08";

use Carp qw/croak/;
use SQL::Translator;
use SQL::Translator::Diff;
use Time::HiRes qw/gettimeofday/;

use Mouse;
extends 'GitDDL';

has ignore_tables => (
    is      => 'ro',
    isa     => 'ArrayRef',
    default => sub { [] },
);

has _db => (
    is => 'ro',
    default => sub {
        my $self = shift;
        my $dsn0 = $self->dsn->[0];
        my $db
            = $dsn0 =~ /:mysql:/ ? 'MySQL'
            : $dsn0 =~ /:Pg:/    ? 'PostgreSQL'
            :                      do { my ($d) = $dsn0 =~ /dbi:(.*?):/; $d };
    },
);

has real_translator => (
    is      => 'ro',
    lazy    => 1,
    default => sub {
        my $self = shift;
        my $translator = SQL::Translator->new(
            parser      => 'DBI',
            parser_args => +{ dbh => $self->_dbh },
        );
        $translator->translate;
        $translator->producer($self->_db);

        if ($self->_db eq 'MySQL') {
            # cut off AUTO_INCREMENT. see. http://bugs.mysql.com/bug.php?id=20786
            my $schema = $translator->schema;
            for my $table ($schema->get_tables) {
                my @options = $table->options;
                if (my ($idx) = grep { $options[$_]->{AUTO_INCREMENT} } 0..$#options) {
                    splice @{$table->options}, $idx, 1;
                }
            }
        }
        $translator;
    },
);

no Mouse;

sub database_version {
    my ($self, %args) = @_;

    my $back = defined $args{back} ? $args{back} : 0;

    croak sprintf 'invalid version_table: %s', $self->version_table
        unless $self->version_table =~ /^[a-zA-Z_]+$/;

    local $@;
    my @versions = eval {
        open my $fh, '>', \my $stderr;
        local *STDERR = $fh;
        $self->_dbh->selectrow_array('SELECT version FROM ' . $self->version_table . ' ORDER BY upgraded_at DESC');
    };

    return $versions[$back];
}

sub deploy {
    my $self = shift;

    if (@_) {
        croak q[GitDDL::Migrator#deploy doesn't accepts any arguments]
    }
    if ($self->database_version) {
        croak "database already deployed, use upgrade_database instead";
    }

    my $sql = $self->_slurp(File::Spec->catfile($self->work_tree, $self->ddl_file));
    $self->_do_sql($sql);

    $self->create_version_table($sql);
}

sub create_version_table {
    my ($self, $sql) = @_;

    $self->_do_sql(sprintf
"CREATE TABLE @{[ $self->version_table ]} (
    version     VARCHAR(40) NOT NULL,
    upgraded_at VARCHAR(20) NOT NULL UNIQUE,
    sql_text    %s
);", $self->_db eq 'MySQL' ? 'LONGTEXT' : 'TEXT'
    );

    $self->_insert_version(undef, $sql || '');
}

sub _new_translator {
    my $self = shift;

    my $translator = SQL::Translator->new;
    $translator->parser($self->_db) or croak $translator->error;

    $translator;
}

sub _new_translator_of_version {
    my ($self, $version) = @_;

    my $tmp_fh = File::Temp->new;
    $self->_dump_sql_for_specified_commit($version, $tmp_fh->filename);

    my $translator = $self->_new_translator;
    $translator->translate($tmp_fh->filename) or croak $translator->error;

    $translator;
}

sub _diff {
    my ($self, $source, $target) = @_;

    my $diff = SQL::Translator::Diff->new({
        output_db     => $self->_db,
        source_schema => $source->schema,
        target_schema => $target->schema,
    })->compute_differences->produce_diff_sql;

    # ignore first line
    $diff =~ s/.*?\n//;

    $diff
}

sub diff {
    my ($self, %args) = @_;

    my $version = $args{version};
    my $reverse = $args{reverse};

    if (!$version && $self->check_version) {
        return '';
    }
    my $source = $self->_new_translator_of_version($self->database_version);

    my $target;
    if (!$version) {
        $target = $self->_new_translator;
        $target->translate(File::Spec->catfile($self->work_tree, $self->ddl_file))
            or croak $target->error;
    }
    else {
        $target = $self->_new_translator_of_version($version);
    }

    my ($from, $to) = !$reverse ? ($source, $target) : ($target, $source);
    $self->_diff($from, $to);
}

sub real_diff { goto \&diff_to_real_database }
sub diff_to_real_database {
    my $self = shift;

    my $source = $self->_new_translator_of_version($self->database_version);
    my $real   = $self->real_translator;

    my $diff = SQL::Translator::Diff->new({
        output_db     => $self->_db,
        source_schema => $source->schema,
        target_schema => $real->schema,
    })->compute_differences;

    my @tabls_to_create = @{ $diff->tables_to_create };
    @tabls_to_create = grep {sub {
        my $table_name = shift;
        return () if $table_name eq $self->version_table;
        ! grep { $table_name eq $_ } @{ $self->ignore_tables };
    }->($_->name) } @tabls_to_create;
    $diff->tables_to_create(\@tabls_to_create);

    my $diff_str = $diff->produce_diff_sql;
    # ignore first line
    $diff_str =~ s/.*?\n//;

    $diff_str;
}

sub diff_from_real_database {
    my $self = shift;

    my $target = $self->_new_translator_of_version($self->database_version);
    my $real   = $self->real_translator;

    my $diff = SQL::Translator::Diff->new({
        output_db     => $self->_db,
        source_schema => $real->schema,
        target_schema => $target->schema,
    })->compute_differences;

    my @tabls_to_drop = @{ $diff->tables_to_drop };
    @tabls_to_drop = grep {sub {
        my $table_name = shift;
        return () if $table_name eq $self->version_table;
        ! grep { $table_name eq $_ } @{ $self->ignore_tables };
    }->($_->name) } @tabls_to_drop;
    $diff->tables_to_drop(\@tabls_to_drop);

    my $diff_str = $diff->produce_diff_sql;
    # ignore first line
    $diff_str =~ s/.*?\n//;

    $diff_str;
}

sub check_ddl_mismatch {
    my $self = shift;

    my $real_diff = $self->real_diff;
    croak "Mismatch between ddl version and real database is found. Diff is:\n $real_diff"
        unless $real_diff =~ /\A\s*-- No differences found;\s*\z/ms;
}

sub get_rollback_version {
    my $self = shift;

    my $sth = $self->_dbh->prepare('SELECT version FROM ' . $self->version_table . ' ORDER BY upgraded_at DESC');
    $sth->execute;

    my ($current_version) = $sth->fetchrow_array;
    my ($prev_version)    = $sth->fetchrow_array;
    croak 'No rollback target is found' unless $prev_version;

    $prev_version;
}

sub rollback_diff {
    my $self = shift;

    $self->diff(version => $self->get_rollback_version);
}

sub upgrade_database {
    my ($self, %args) = @_;
    croak 'Failed to get database version, please deploy first' unless $self->database_version;

    my $version = $args{version};
    my $sql     = $args{sql} || $self->diff(version => $version);

    return if $sql =~ /\A\s*\z/ms;

    $self->_do_sql($sql);
    $self->_insert_version($version, $sql);
}

sub migrate {
    my $self = shift;

    if (!$self->database_version) {
        $self->deploy(@_);
    }
    else {
        $self->upgrade_database(@_);
    }
}

sub _insert_version {
    my ($self, $version, $sql) = @_;

    $version ||= $self->ddl_version;
    unless (length($version) == 40) {
        $version = $self->_restore_full_hash($version);
    }

    # steal from DBIx::Schema::Versioned
    my @tm = gettimeofday();
    my @dt = gmtime ($tm[0]);
    my $upgraded_at = sprintf("v%04d%02d%02d_%02d%02d%02d.%03.0f",
        $dt[5] + 1900,
        $dt[4] + 1,
        $dt[3],
        $dt[2],
        $dt[1],
        $dt[0],
        int($tm[1] / 1000), # convert to millisecs
    );

    $self->_dbh->do(
        "INSERT INTO @{[ $self->version_table ]} (version, upgraded_at, sql_text) VALUES (?, ?, ?)", {}, $version, $upgraded_at, $sql
    ) or croak $self->_dbh->errstr;
}

sub _restore_full_hash {
    my ($self, $version) = @_;
    $self->_git->run('rev-parse', $version);
}

sub vacuum {
    die 'to be implemented';
    # remove old verison hitosry.
}

1;
__END__

=for stopwords versioned

=encoding utf-8

=head1 NAME

GitDDL::Migrator - database migration utility for git managed SQL extended L<GitDDL>

=head1 SYNOPSIS

    use GitDDL::Migrator;
    my $gd = GitDDL::Migrator->new(
        work_tree => '/path/to/project', # git working directory
        ddl_file  => 'sql/schema_ddl.sql',
        dsn       => ['dbi:mysql:my_project', 'root', ''],
    );

=head1 DESCRIPTION

GitDDL::Migrator is database migration utility extended L<GitDDL>.

L<GitDDL> is very cool module. It's very simple and developer friendly.
I use it in development, but features of it are not enough in operation phase.

Features needed at operation phases are: e.g.

=over

=item save migration history

=item rollback to previous version

=item specify version

=item specify SQL (sometimes L<SQL::Translator>'s output is wrong)

=item check differences from versioned SQL and real database

=back

Then for solving them, I wrote GitDDL::Migrator.

=head1 METHODS

=head2 C<< GitDDL::Migrator->new(%options) >>

Create GitDDL::Migrator object. Available options are:

=over

=item C<work_tree> => 'Str' (Required)

Git working tree path includes target DDL file.

=item C<ddl_file>  => 'Str' (Required)

DDL file ( .sql file) path in repository.

If DDL file located at /repos/project/sql/schema.sql and work_tree root is /repos/project, then this option should be sql/schema.sql

=item C<dsn> => 'ArrayRef' (Required)

DSN parameter that pass to L<DBI> module.

=item C<version_table> => 'Str' (optional)

database table name that contains its git commit version. (default: git_ddl_version)

=item C<ignore_tables> => 'ArrayRef' (optional)

tables for ignoring when calling C<check_ddl_mismatch()>. (default: empty)

=back

=head2 C<< $gd->migrate(%opt) >>

migrate database

=head2 C<< $gd->real_diff >>

display differences from versioned DDL and real database setting.

=head2 C<< $gd->diff_to_real_database >>

alias of C<real_diff>

=head2 C<< $gd->diff_from_real_database >>

display differences from real database setting and versioned DDL.

=head2 C<< $gd->check_ddl_mismatch >>

check differences from versioned DDL and real database setting.

=head2 C<< $gd->get_rollback_version >>

get previous database version.

=head2 C<< $gd->rollback_diff >>

display differences SQL from current version and previous version.

=head2 C<< $gd->create_version_table >>

Only create version table, don't deploy any other SQLs. It is useful to apply C<GitDDL::Migrator> to existing databases.

=head1 LICENSE

Copyright (C) Masayuki Matsuki.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHOR

Masayuki Matsuki E<lt>y.songmu@gmail.comE<gt>

=cut

