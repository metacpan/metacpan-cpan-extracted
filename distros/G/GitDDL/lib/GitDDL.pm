package GitDDL;
use strict;
use warnings;

use Mouse;

our $VERSION = '0.03';

use Carp;
use DBI;
use File::Spec;
use File::Temp;
use Git::Repository;
use SQL::Translator;
use SQL::Translator::Diff;
use Try::Tiny;

has work_tree => (
    is       => 'ro',
    required => 1,
);

has ddl_file => (
    is       => 'ro',
    required => 1,
);

has dsn => (
    is       => 'ro',
    required => 1,
);

has sql_filter => (
    is      => 'rw',
    lazy    => 1,
    builder => '_build_sql_filter',
);

has version_table => (
    is      => 'rw',
    default => 'git_ddl_version',
);

has _dbh => (
    is      => 'rw',
    lazy    => 1,
    builder => '_build_dbh',
);

has _git => (
    is      => 'rw',,
    lazy    => 1,
    builder => '_build_git',
);

no Mouse;

sub check_version {
    my ($self) = @_;
    $self->database_version eq $self->ddl_version;
}

sub database_version {
    my ($self) = @_;

    croak sprintf 'invalid version_table: %s', $self->version_table
        unless $self->version_table =~ /^[a-zA-Z_]+$/;

    my ($version) =
        $self->_dbh->selectrow_array('SELECT version FROM ' . $self->version_table);

    if (defined $version) {
        return $version;
    }
    else {
        croak "Failed to get database version, please deploy first";
    }
}

sub ddl_version {
    my ($self) = @_;
    $self->_git->run('log', '-n', '1', '--pretty=format:%H', '--', $self->ddl_file);
}

sub deploy {
    my ($self) = @_;

    my $version = try {
        open my $fh, '>', \my $stderr;
        local *STDERR = $fh;
        $self->database_version;
        close $fh;
    };

    if ($version) {
        croak "database already deployed, use upgrade_database instead";
    }

    croak sprintf 'invalid version_table: %s', $self->version_table
        unless $self->version_table =~ /^[a-zA-Z_]+$/;

    $self->_do_sql($self->_slurp(File::Spec->catfile($self->work_tree, $self->ddl_file)));

    $self->_do_sql(<<"__SQL__");
CREATE TABLE @{[ $self->version_table ]} (
    version VARCHAR(40) NOT NULL
);
__SQL__

    $self->_dbh->do(
        "INSERT INTO @{[ $self->version_table ]} (version) VALUES (?)", {}, $self->ddl_version
    ) or croak $self->_dbh->errstr;
}

sub diff {
    my ($self) = @_;

    if ($self->check_version) {
        croak 'ddl_version == database_version, should no differences';
    }

    my $dsn0 = $self->dsn->[0];
    my $db
        = $dsn0 =~ /:mysql:/ ? 'MySQL'
        : $dsn0 =~ /:Pg:/    ? 'PostgreSQL'
        :                      do { my ($d) = $dsn0 =~ /dbi:(.*?):/; $d };

    my $tmp_fh = File::Temp->new;
    $self->_dump_sql_for_specified_commit($self->database_version, $tmp_fh->filename);

    my $source_sql = $self->sql_filter->($self->_slurp($tmp_fh->filename));
    my $source = SQL::Translator->new;
    $source->parser($db) or croak $source->error;
    $source->translate(\$source_sql) or croak $source->error;

    my $target_sql = $self->sql_filter->(
        $self->_slurp(File::Spec->catfile($self->work_tree, $self->ddl_file))
    );
    my $target = SQL::Translator->new;
    $target->parser($db) or croak $target->error;
    $target->translate(\$target_sql) or croak $target->error;

    my $diff = SQL::Translator::Diff->new({
        output_db     => $db,
        source_schema => $source->schema,
        target_schema => $target->schema,
    })->compute_differences->produce_diff_sql;

    # ignore first line
    $diff =~ s/.*?\n//;

    $diff
}

sub upgrade_database {
    my ($self) = @_;

    $self->_do_sql($self->diff);

    $self->_dbh->do(
        "UPDATE @{[ $self->version_table ]} SET version = ?", {}, $self->ddl_version
    ) or croak $self->_dbh->errstr;
}

sub _build_dbh {
    my ($self) = @_;

    # support on_connect_do
    my $on_connect_do;
    if (ref $self->dsn->[-1] eq 'HASH') {
        $on_connect_do = delete $self->dsn->[-1]{on_connect_do};
    }

    my $dbh = DBI->connect(@{ $self->dsn })
        or croak $DBI::errstr;

    if ($on_connect_do) {
        if (ref $on_connect_do eq 'ARRAY') {
            $dbh->do($_) || croak $dbh->errstr
                for @$on_connect_do;
        }
        else {
            $dbh->do($on_connect_do) or croak $dbh->errstr;
        }
    }

    $dbh;
}

sub _build_git {
    my ($self) = @_;
    Git::Repository->new( work_tree => $self->work_tree );
}

sub _build_sql_filter {
    my ($self) = @_;
    sub { shift };
}

sub _do_sql {
    my ($self, $sql) = @_;

    my @statements = map { "$_;" } grep { /\S+/ } split ';', $sql;
    for my $statement (@statements) {
        $self->_dbh->do($statement)
            or croak $self->_dbh->errstr;
    }
}

sub _slurp {
    my ($self, $file) = @_;

    open my $fh, '<', $file or croak sprintf 'Cannot open file: %s, %s', $file, $!;
    my $data = do { local $/; <$fh> };
    close $fh;

    $data;
}

sub _dump_sql_for_specified_commit {
    my ($self, $commit_hash, $outfile) = @_;

    my ($mode, $type, $blob_hash) = split /\s+/, scalar $self->_git->run(
        'ls-tree', $commit_hash, '--', $self->ddl_file,
    );

    my $sql = $self->_git->run('cat-file', 'blob', $blob_hash);

    open my $fh, '>', $outfile or croak $!;
    print $fh $sql;
    close $fh;
}

__PACKAGE__->meta->make_immutable;

__END__

=head1 NAME

GitDDL - database migration utility for git managed sql

=head1 SYNOPSIS

    my $gd = GitDDL->new(
        work_tree => '/path/to/project', # git working directory
        ddl_file  => 'sql/schema_ddl.sql',
        dsn       => ['dbi:mysql:my_project', 'root', ''],
    );
    
    # checking whether the database version matchs ddl_file version or not.
    $gd->check_version;
    
    # getting database version
    my $db_version = $gd->database_version;
    
    # getting ddl version
    my $ddl_version = $gd->ddl_version;
    
    # upgrade database
    $gd->upgrade_database;
    
    # deploy ddl
    $gd->deploy;

=head1 DESCRIPTION

This is database migration helper module for users who manage database schema version by single .sql file in git repository.

By using this module, you can deploy .sql to database, check sql version between database and .sql file, make diff between them, and apply alter table to database.

=head1 METHODS

=head2 GitDDL->new(%options)

    my $gd = GitDDL->new(
        work_tree => '/path/to/project', # git working directory
        ddl_file  => 'sql/schema_ddl.sql',
        dsn       => ['dbi:mysql:my_project', 'root', ''],
    );

Create GitDDL object. Available options are:

=over 4

=item * work_tree => 'Str' (Required)

Git working tree path includes target ddl file.

=item * ddl_file  => 'Str' (Required)

ddl file (.sql file) path in repository.

If ddl file located at /repos/project/sql/schema.sql and work_tree root is /repos/project, then this option should be sql/schema.sql

=item * dsn => 'ArrayRef' (Required)

DSN parameter that pass to L<DBI> module.

=item * version_table => 'Str' (optional)

database table name that contains its git commit version. (default: git_ddl_version)

=item * sql_filter => 'CodeRef' (optional)

CodeRef for filtering sql content. It is invoked only in C<< diff() >> method. (default: do nothing)

=back

=head2 check_version()

    $gd->check_version();

Compare versions latest ddl sql and database, and return true when both version is same.

Otherwise return false, which means database is not latest. To upgrade database to latest, see upgrade_database method described below.

=head2 database_version()

Return git commit hash indicates database's schema.

=head2 ddl_version()

Return git commit hash indicates ddl file.

=head2 deploy()

Just deploy ddl_file schema to database. This method is designed for initial database setup.
But database should be created previously.

=head2 diff()

Show sql differences between ddl file and database.
This method is useful for dry-run checking before upgrade_database.

=head2 upgrade_database()

Upgrade database schema to latest ddl schema. 

=head1 AUTHOR

Daisuke Murase <typester@cpan.org>

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2012 Daisuke Murase. All rights reserved.

This program is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

The full text of the license can be found in the LICENSE file included with this module.

=cut
