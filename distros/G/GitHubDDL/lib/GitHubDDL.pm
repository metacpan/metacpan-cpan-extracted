package GitHubDDL;
use 5.008001;
use strict;
use warnings;

use Carp;
use File::Spec;
use File::Temp;
use SQL::Translator;
use SQL::Translator::Diff;
use DBI;
use Furl;
use Cwd;
use Types::Standard qw/Str ArrayRef CodeRef Maybe/;
use Try::Tiny;

our $VERSION = "0.01";

use Moo;

has ddl_file => (
    is       => 'ro',
    isa      => Str,
    required => 1,
);

has dsn => (
    is       => 'ro',
    isa      => ArrayRef,
    required => 1,
);

has ddl_version => (
    is       => 'ro',
    isa      => Str,
    required => 1,
);

has version_table => (
    is      => 'ro',
    isa     => Str,
    default => 'git_ddl_version',
);

has sql_filter => (
    is      => 'ro',
    isa     => CodeRef,
    default => sub {
        return sub { shift },
    },
);

has work_dir => (
    is      => 'ro',
    isa     => Str,
    lazy    => 1,
    default => sub { return Cwd::getcwd; },
);

has dump_sql_specified_commit_method => (
    is      => 'ro',
    isa     => Maybe[CodeRef],
    default => sub { return undef },
);

has _dbh => (
    is      => 'rw',
    lazy    => 1,
    builder => '_build_dbh',
);

has github_user => (
    is       => 'ro',
    isa      => Str,
    required => 1,
);

has github_repo => (
    is       => 'ro',
    isa      => Str,
    required => 1,
);

has github_token => (
    is       => 'ro',
    required => 1,
);

sub check_version {
    my $self = shift;
    $self->database_version eq $self->ddl_version;
}

sub database_version {
    my $self = shift;

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

sub deploy {
    my $self = shift;

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

    $self->_do_sql($self->_slurp(File::Spec->catfile($self->work_dir, $self->ddl_file)));

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
    my $self = shift;

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
        $self->_slurp(File::Spec->catfile($self->work_dir, $self->ddl_file))
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
    my $self = shift;

    $self->_do_sql($self->diff);

    $self->_dbh->do(
        "UPDATE @{[ $self->version_table ]} SET version = ?", {}, $self->ddl_version
    ) or croak $self->_dbh->errstr;
}

sub _build_dbh {
    my $self = shift;

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

    open my $fh, '>', $outfile or croak $!;
    if (my $method = $self->dump_sql_specified_commit_method) {
        my $sql = $method->($commit_hash);
        print $fh $sql;
        close $fh;
        return;
    }

    my $url = sprintf "https://raw.githubusercontent.com/%s/%s/%s/%s",
        $self->github_user,
        $self->github_repo,
        $commit_hash,
        $self->ddl_file;

    my $furl = Furl->new;
    my $res = $furl->request(
        method          => "GET",
        url             => $url,
        headers         => [
            Authorization => "token " . $self->github_token,
            Accept        => "application/vnd.github.v3+raw",
        ],
        write_code      => sub {
            my ( $status, $msg, $headers, $buf ) = @_;
            if ($status != 200) {
                die "status is not success when dump sql from GitHub: " . $self->ddl_file . ", status=" . $status;
            }
            print $fh $buf;
        }
    );
    close $fh;
}

1;
__END__

=encoding utf-8

=head1 NAME

GitHubDDL - GitDDL compatibility database migration utility when  hosted on GitHub

=head1 SYNOPSIS

    use GitHubDDL;
    my $gd = GitHubDDL->new(
        ddl_file     => 'sql/schema_ddl.sql',
        dsn          => ['dbi:mysql:my_project', 'root', ''],
        ddl_version  => '...',
        github_user  => '<your GitHub user/org name>',
        github_repo  => '<your GitHub repository name>',
        github_token => '<your GitHub token>',
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

GitHubDDL is a tool module of the migration for RDBMS uses SQL::Translator::Diff.

This is database migration helper module for users who manage database schema version by single .sql file in git repository.

By using this module, you can deploy .sql to database, check sql version between database and .sql file, make diff between them, and apply alter table to database.

=head1 METHODS

=head2 GitHubDDL->new(%options)

    my $gd = GitHubDDL->new(
        ddl_file     => 'sql/schema_ddl.sql',
        dsn          => ['dbi:mysql:my_project', 'root', ''],
        ddl_version  => '...',
        github_user  => '<your GitHub user/org name>',
        github_repo  => '<your GitHub repository name>',
        github_token => '<your GitHub token>',
    );

Create GitHubDDL object. Available options are:

=over 4

=item * ddl_file  => 'Str' (Required)

ddl file (.sql file) path in repository.

If ddl file located at /repos/project/sql/schema.sql and work_dir root is /repos/project, then this option should be sql/schema.sql

=item * dsn => 'ArrayRef' (Required)

DSN parameter that pass to L<DBI> module.

=item * ddl_version => 'Str' (Required)

DDL file's commit hash of local. If you need to apply schema to database by working dir's schema, you specify current commit hash of this file. B<THIS IS NOT OLDER COMMIT HASH>.

=item * github_user => 'Str' (Required)

GitHub's user or organization name of repository.

=item * github_repo => 'Str' (Required)

GitHub's repository name.

=item * github_token => 'Str' (Required)

GitHub's Personal Access Token. This is used to retrieve DDL that is applied to the database from GitHub.

NOTE: If you need to use the authority of GitHub Apps, you can use L<GitHub::Apps::Auth> in it.

=item * work_dir => 'Str' (Optional)

Working directory of path includes target ddl file. Default is current working directory.

=item * version_table => 'Str' (Optional)

database table name that contains its git commit version. (default: git_ddl_version)

=item * sql_filter => 'CodeRef' (Optional)

CodeRef for filtering sql content. It is invoked only in C<< diff() >> method. (default: do nothing)

=item * dump_sql_specified_commit_method => 'CodeRef' (Optional)

CodeRef for a bypass for dump SQL from GitHub. If you need to use your project-specific retrieve SQL method, you should set this option. This option is used as an alternative to the original method. (default: do nothing)

This CodeRef takes a commit hash as the only argument.

=back

=head2 check_version()

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

=head1 SEE ALSO

=over 4

=item * L<GitDDL>

GitDDL is to compare local a DDL file and an older DDL from history in git.
GitHubDDL is almost the same as GitDDL, but the only difference is that it retrieves the old DDL from GitHub.

=back

=head1 LICENSE

Copyright (C) mackee.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHOR

mackee E<lt>macopy123@gmail.comE<gt>

=cut
