# NAME

GitHubDDL - GitDDL compatibility database migration utility when  hosted on GitHub

# SYNOPSIS

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

# DESCRIPTION

GitHubDDL is a tool module of the migration for RDBMS uses SQL::Translator::Diff.

This is database migration helper module for users who manage database schema version by single .sql file in git repository.

By using this module, you can deploy .sql to database, check sql version between database and .sql file, make diff between them, and apply alter table to database.

# METHODS

## GitHubDDL->new(%options)

    my $gd = GitHubDDL->new(
        ddl_file     => 'sql/schema_ddl.sql',
        dsn          => ['dbi:mysql:my_project', 'root', ''],
        ddl_version  => '...',
        github_user  => '<your GitHub user/org name>',
        github_repo  => '<your GitHub repository name>',
        github_token => '<your GitHub token>',
    );

Create GitHubDDL object. Available options are:

- ddl\_file  => 'Str' (Required)

    ddl file (.sql file) path in repository.

    If ddl file located at /repos/project/sql/schema.sql and work\_dir root is /repos/project, then this option should be sql/schema.sql

- dsn => 'ArrayRef' (Required)

    DSN parameter that pass to [DBI](https://metacpan.org/pod/DBI) module.

- ddl\_version => 'Str' (Required)

    DDL file's commit hash of local. If you need to apply schema to database by working dir's schema, you specify current commit hash of this file. **THIS IS NOT OLDER COMMIT HASH**.

- github\_user => 'Str' (Required)

    GitHub's user or organization name of repository.

- github\_repo => 'Str' (Required)

    GitHub's repository name.

- github\_token => 'Str' (Required)

    GitHub's Personal Access Token. This is used to retrieve DDL that is applied to the database from GitHub.

    NOTE: If you need to use the authority of GitHub Apps, you can use [GitHub::Apps::Auth](https://metacpan.org/pod/GitHub%3A%3AApps%3A%3AAuth) in it.

- work\_dir => 'Str' (Optional)

    Working directory of path includes target ddl file. Default is current working directory.

- version\_table => 'Str' (Optional)

    database table name that contains its git commit version. (default: git\_ddl\_version)

- sql\_filter => 'CodeRef' (Optional)

    CodeRef for filtering sql content. It is invoked only in `diff()` method. (default: do nothing)

- dump\_sql\_specified\_commit\_method => 'CodeRef' (Optional)

    CodeRef for a bypass for dump SQL from GitHub. If you need to use your project-specific retrieve SQL method, you should set this option. This option is used as an alternative to the original method. (default: do nothing)

    This CodeRef takes a commit hash as the only argument.

## check\_version()

Compare versions latest ddl sql and database, and return true when both version is same.

Otherwise return false, which means database is not latest. To upgrade database to latest, see upgrade\_database method described below.

## database\_version()

Return git commit hash indicates database's schema.

## ddl\_version()

Return git commit hash indicates ddl file.

## deploy()

Just deploy ddl\_file schema to database. This method is designed for initial database setup.
But database should be created previously.

## diff()

Show sql differences between ddl file and database.
This method is useful for dry-run checking before upgrade\_database.

## upgrade\_database()

Upgrade database schema to latest ddl schema.

# SEE ALSO

- [GitDDL](https://metacpan.org/pod/GitDDL)

    GitDDL is to compare local a DDL file and an older DDL from history in git.
    GitHubDDL is almost the same as GitDDL, but the only difference is that it retrieves the old DDL from GitHub.

# LICENSE

Copyright (C) mackee.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

# AUTHOR

mackee <macopy123@gmail.com>
