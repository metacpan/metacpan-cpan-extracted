# NAME

GitDDL::Migrator - database migration utility for git managed SQL extended [GitDDL](https://metacpan.org/pod/GitDDL)

# SYNOPSIS

    use GitDDL::Migrator;
    my $gd = GitDDL::Migrator->new(
        work_tree => '/path/to/project', # git working directory
        ddl_file  => 'sql/schema_ddl.sql',
        dsn       => ['dbi:mysql:my_project', 'root', ''],
    );

# DESCRIPTION

GitDDL::Migrator is database migration utility extended [GitDDL](https://metacpan.org/pod/GitDDL).

[GitDDL](https://metacpan.org/pod/GitDDL) is very cool module. It's very simple and developer friendly.
I use it in development, but features of it are not enough in operation phase.

Features needed at operation phases are: e.g.

- save migration history
- rollback to previous version
- specify version
- specify SQL (sometimes [SQL::Translator](https://metacpan.org/pod/SQL::Translator)'s output is wrong)
- check differences from versioned SQL and real database

Then for solving them, I wrote GitDDL::Migrator.

# METHODS

## `GitDDL::Migrator->new(%options)`

Create GitDDL::Migrator object. Available options are:

- `work_tree` => 'Str' (Required)

    Git working tree path includes target DDL file.

- `ddl_file`  => 'Str' (Required)

    DDL file ( .sql file) path in repository.

    If DDL file located at /repos/project/sql/schema.sql and work\_tree root is /repos/project, then this option should be sql/schema.sql

- `dsn` => 'ArrayRef' (Required)

    DSN parameter that pass to [DBI](https://metacpan.org/pod/DBI) module.

- `version_table` => 'Str' (optional)

    database table name that contains its git commit version. (default: git\_ddl\_version)

- `ignore_tables` => 'ArrayRef' (optional)

    tables for ignoring when calling `check_ddl_mismatch()`. (default: empty)

## `$gd->migrate(%opt)`

migrate database

## `$gd->real_diff`

display differences from versioned DDL and real database setting.

## `$gd->diff_to_real_database`

alias of `real_diff`

## `$gd->diff_from_real_database`

display differences from real database setting and versioned DDL.

## `$gd->check_ddl_mismatch`

check differences from versioned DDL and real database setting.

## `$gd->get_rollback_version`

get previous database version.

## `$gd->rollback_diff`

display differences SQL from current version and previous version.

## `$gd->create_version_table`

Only create version table, don't deploy any other SQLs. It is useful to apply `GitDDL::Migrator` to existing databases.

# LICENSE

Copyright (C) Masayuki Matsuki.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

# AUTHOR

Masayuki Matsuki <y.songmu@gmail.com>
