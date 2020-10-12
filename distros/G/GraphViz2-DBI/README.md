# NAME

[GraphViz2::DBI](https://metacpan.org/pod/GraphViz2::DBI) - Visualize a database schema as a graph

# Synopsis

        #!/usr/bin/env perl

        use strict;
        use warnings;

        use DBI;

        use GraphViz2;
        use GraphViz2::DBI;

        use Log::Handler;

        # ---------------

        exit 0 if (! $ENV{DBI_DSN});

        my($logger) = Log::Handler -> new;

        $logger -> add
                (
                 screen =>
                 {
                         maxlevel       => 'debug',
                         message_layout => '%m',
                         minlevel       => 'error',
                 }
                );

        my($graph) = GraphViz2 -> new
                (
                 edge   => {color => 'grey'},
                 global => {directed => 1},
                 graph  => {rankdir => 'TB'},
                 logger => $logger,
                 node   => {color => 'blue', shape => 'oval'},
                );
        my($attr)              = {};
        $$attr{sqlite_unicode} = 1 if ($ENV{DBI_DSN} =~ /SQLite/i);
        my($dbh)               = DBI -> connect($ENV{DBI_DSN}, $ENV{DBI_USER}, $ENV{DBI_PASS}, $attr);

        $dbh -> do('PRAGMA foreign_keys = ON') if ($ENV{DBI_DSN} =~ /SQLite/i);

        my($g) = GraphViz2::DBI -> new(dbh => $dbh, graph => $graph);

        $g -> create(name => '');

        my($format)      = shift || 'svg';
        my($output_file) = shift || File::Spec -> catfile('html', "dbi.schema.$format");

        $graph -> run(format => $format, output_file => $output_file);

See scripts/dbi.schema.pl (["Scripts Shipped with this Module" in GraphViz2](https://metacpan.org/pod/GraphViz2#Scripts-Shipped-with-this-Module)).

The image html/dbi.schema.svg was generated from the database tables of my module
[App::Office::Contacts](https://metacpan.org/pod/App::Office::Contacts).

# Description

Takes a database handle, and graphs the schema.

You can write the result in any format supported by [Graphviz](http://www.graphviz.org/).

Here is the list of [output formats](http://www.graphviz.org/content/output-formats).

# Constructor and Initialization

## Calling new()

`new()` is called as `my($obj) = GraphViz2::DBI -> new(k1 => v1, k2 => v2, ...)`.

It returns a new object of type `GraphViz2::DBI`.

Key-value pairs accepted in the parameter list:

- o dbh => $dbh

    This options specifies the database handle to use.

    This key is mandatory.

- o graph => $graphviz\_object

    This option specifies the GraphViz2 object to use. This allows you to configure it as desired.

    The default is GraphViz2 -> new. The default attributes are the same as in the synopsis, above,
    except for the graph label of course.

    This key is optional.

# Methods

## create(exclude => \[\], include => \[\], name => $name)

Creates the graph, which is accessible via the graph() method, or via the graph object you passed to
new().

Returns $self to allow method chaining.

Parameters:

- o exclude

    An optional arrayref of table names to exclude.

    If none are listed for exclusion, _all_ tables are included.

- o include

    An optional arrayref of table names to include.

    If none are listed for inclusion, _all_ tables are included.

- o name

    $name is the string which will be placed in the root node of the tree.
    It may be omitted, in which case the root node is omitted.

## graph()

Returns the graph object, either the one supplied to new() or the one created during the call to
new().

# FAQ

## Why did I get an error about 'Unable to find primary key'?

For plotting foreign keys, the code has an algorithm to find the primary table/key pair which the
foreign table/key pair point to.

The steps are listed here, in the order they are tested. The first match stops the search.

- o Check a hash for special cases

    Currently, the only special case is a foreign key of `spouse_id`. It is assumed to point to a
    primary key called `person_id`.

    There is no option available, at the moment, to override this check.

- o Ask the database for foreign key information

    [DBIx::Admin::TableInfo](https://metacpan.org/pod/DBIx::Admin::TableInfo) is used for this.

- o Take a guess

    Assume the foreign key points to a table with a column called `id`, and use that as the primary
    key.

- o Die with a detailed error message

## Which versions of the servers did you test?

See ["FAQ" in DBIx::Admin::TableInfo](https://metacpan.org/pod/DBIx::Admin::TableInfo#FAQ).

## Does GraphViz2::DBI work with SQLite databases?

Yes. See ["FAQ" in DBIx::Admin::TableInfo](https://metacpan.org/pod/DBIx::Admin::TableInfo#FAQ).

## What is returned by SQLite's "pragma foreign\_key\_list($table\_name)"?

See ["FAQ" in DBIx::Admin::TableInfo](https://metacpan.org/pod/DBIx::Admin::TableInfo#FAQ).

## How does GraphViz2::DBI draw edges from foreign keys to primary keys?

It assumes that the primary table's name is a plural word, and that the foreign key's name is
prefixed by the singular
of the primary table's name, separated by '\_'.

Thus a (primary) table 'people' with a primary key 'id' will be pointed to by a table
'phone\_numbers' using a column 'person\_id'.

Table 'phone\_numbers' will probably have a primary key 'id' but that is not used (unless some other
table has a foreign key pointing to the 'phone\_numbers' table).

The conversion of plural to singular is done with [Lingua::EN::PluralToSingular](https://metacpan.org/pod/Lingua::EN::PluralToSingular).

If this naming convention does not hold, then both the source and destination ports default to '1',
which is the port of the 1st column (in alphabetical order) in each table. The table name itself is
port '0'.

# Scripts Shipped with this Module

## scripts/dbi.schema.pl

If the environment vaiables DBI\_DSN, DBI\_USER and DBI\_PASS are set (the latter 2 are optional \[e.g. for SQLite\]),
then this demonstrates building a graph from a database schema.

Also, for Postgres, you can set $ENV{DBI\_SCHEMA} to a comma-separated list of schemas, e.g. when processing the
MusicBrainz database. See scripts/dbi.schema.pl.

For details, see [http://blogs.perl.org/users/ron\_savage/2013/03/graphviz2-and-the-dread-musicbrainz-db.html](http://blogs.perl.org/users/ron_savage/2013/03/graphviz2-and-the-dread-musicbrainz-db.html).

Outputs to ./html/dbi.schema.svg by default.

## scripts/sqlite.foreign.keys.pl

Demonstrates how to find foreign key info by calling SQLite's pragma foreign\_key\_list.

Outputs to STDOUT.

# Thanks

Many thanks to the people who chose to make [Graphviz](http://www.graphviz.org/) Open Source.

And thanks to [Leon Brocard](http://search.cpan.org/~lbrocard/), who wrote [GraphViz](https://metacpan.org/pod/GraphViz), and kindly
gave me co-maint of the module.

# Author

[GraphViz2](https://metacpan.org/pod/GraphViz2) was written by Ron Savage _<ron@savage.net.au>_ in 2011.

Home page: [http://savage.net.au/index.html](http://savage.net.au/index.html).

# Copyright

Australian copyright (c) 2011, Ron Savage.

        All Programs of mine are 'OSI Certified Open Source Software';
        you can redistribute them and/or modify them under the terms of
        The Perl License, a copy of which is available at:
        http://dev.perl.org/licenses/
