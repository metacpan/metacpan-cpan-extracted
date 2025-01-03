# NAME

Fey - Better SQL Generation Through Perl

# VERSION

version 0.44

# SYNOPSIS

    use Fey::Literal::Function;
    use Fey::Placeholder;
    use Fey::Schema;
    use Fey::SQL;


    my $schema = hand_waving();

    my $user  = $schema->table('User');
    my $group = $schema->table('Group')

    my $select = Fey::SQL->new_select();

    my $func = Fey::Literal::Function->new( 'LCASE', $user->column('username') );

    $select->select( $user->columns( 'user_id', 'username' ) )
           ->from( $user, $group )
           ->where( $group->group_id, 'IN', 1, 2, 3 )
           ->and  ( $func, 'LIKE', 'smith%' );

    print $select->sql($dbh);

# DESCRIPTION

The `Fey` distribution contains a set of modules for representing the
components of a DBMS schema, and for dynamically generating SQL
queries based on that schema.

# USAGE

Loading this module does nothing. It's just here to provide docs and a
version number for the distro.

You'll want to take a look at [Fey::Schema](https://metacpan.org/pod/Fey%3A%3ASchema), [Fey::Table](https://metacpan.org/pod/Fey%3A%3ATable), and other
modules in the distro for more details.

# WHAT IS Fey?

The goal of the core `Fey` distro is to provide a simple, flexible
way of _dynamically_ generating complex SQL queries in Perl. Other
packages build on top of this functionality to create a complete ORM
(`Fey::ORM`).

# GETTING STARTED

If you're interested in an ORM, take a look at the `Fey::ORM` distro.

To generate SQL with Fey, you first need to create a set of objects
representing the tables and foreign keys in your schema. The simplest
way to do this is to use the `Fey-Loader` distro, which will connect
to an existing schema and generate a set of objects for you.

Alternatively, you can create these objects via Fey's API. You would
first create a [Fey::Schema](https://metacpan.org/pod/Fey%3A%3ASchema) object. This object will hold all of
your tables and foreign keys. If you want to create your schema this
way, you should start with the [Fey::Schema](https://metacpan.org/pod/Fey%3A%3ASchema), [Fey::Table](https://metacpan.org/pod/Fey%3A%3ATable), and
[Fey::FK](https://metacpan.org/pod/Fey%3A%3AFK) APIs. You'll also want to use the [Fey::Column](https://metacpan.org/pod/Fey%3A%3AColumn) API.

Once you have a schema, you can generate SQL using [Fey::SQL](https://metacpan.org/pod/Fey%3A%3ASQL), or a
DBMS-specific subclass of [Fey::SQL](https://metacpan.org/pod/Fey%3A%3ASQL).

# THE CORE Fey DISTRO

The emphasis in the core Fey distro is on dynamic queries,
particularly on the tables/columns/etc involved in the query, not just
the bound parameters.

This is _not_ what I mean by a dynamic query ...

    SELECT user_id FROM User where username = ?

While this is dynamic in the sense that the username is parameterized
and may change on each invocation, it is still easily handled by a
phrasebook class. If that is all you need, I suggest checking out any
of `Class::Phrasebook::SQL`, `Data::Phrasebook`, or `SQL::Library`
on CPAN.

Imagine that we have a database with a User table and a Message table,
where each message has a user who is that message's creator. We might
want to grab all the users in the database, in which case we would do
a simple `SELECT` against the User table ...

    SELECT * FROM User

But maybe we want to get all the users who have created a message in
the last week:

    SELECT User.*
      FROM User JOIN Message
           USING (user_id)
     WHERE Message.creation_date >= ?

The resultset for our query is still the same (0+ users) but the
constraints of the query are more complex. Now imagine another dozen
or so permutations on how we search for users. This is what I mean by
"dynamically" generating queries.

# RATIONALE

You probably don't need to read this if you just wanted to know how to
use Fey.

## Why Not Use a Phrasebook?

Let's assume we have a simple User table with the following columns:

    username
    state
    first_name
    last_name
    access_level

Limiting ourselves to queries of equality ("username = ?", "state =
?"), we would still need 32 (1 + 5 + 10 + 10 + 5 + 1) entries to
handle all the possible combinations of columns. Now imagine adding in
variants like allowing for wildcard searches using LIKE or regexes, or
more complex variants involving an "OR" in a subclause.

This gets even more complicated if you start adding in joins, outer
joins, and so on. It's plain to see that a phrasebook gets too large
to be usable at this point. You'd probably have to write a program
just to generate the phrasebook and keep it up to date!

## Why Not String Manipulation?

The next idea that might come to mind is to dump the phrasebook in
favor of string manipulation. This is simple enough at first, but
quickly gets ugly. Handling all of the possible options correctly
requires lots of fiddly code that has to concatenate bits of SQL in
the correct order, taking into account where to put in commas,
`WHERE` vs `AND`, and so on and so forth. I've been there, and trust
me, it's madness.

## The Solution

The core Fey modules provide a solution to the dynamic SQL
problem. Using Fey, you can specify queries in the form of _Perl
methods and objects_. Fey provides a set of objects to represent the
parts of a schema, specifically tables, columns, and foreign
keys. Using these objects along with [Fey::SQL](https://metacpan.org/pod/Fey%3A%3ASQL), you can easily
generate very complex queries.

This core distro is also intended to be the foundation for building
higher-level tools like an ORM. See `Fey::ORM` for just such a thing.

# HISTORY AND GOALS

This module comes from my experience writing and using Alzabo. Alzabo
does everything this module does, and a lot more. The fact that Alzabo
does so many things has become a fairly problematic in its
maintenance, and Alzabo was over 6 years old at the time this project
was begun (August of 2006).

## Goals

Rather than coming up with a very smart solution that allows us to use
80% of a DBMS's functionality, I'd rather come up with a solution
that's dumber but supports all (or at least 99%) of the DBMS's
features. It's easy to add smarts on top of a dumb layer, but it can
be terribly hard to add that last 20% once you've got something really
smart.

The goals for Fey, based on my experience with Alzabo, are the
following:

- Provide a simple way to generate queries dynamically. I really like
how this works with Alzabo conceptually, but Alzabo is not as flexible
as I'd like and it's "build a data structure" approach to query
building can become very cumbersome.

    Rather than complex data structures, with Fey you call methods on a
    `Fey::SQL` object to build up a query. This turns out to be simpler
    to work with.

    Fey, unlike Alzabo, can be used to generate multi-row updates and
    deletes, and it supports sub-selects, unions, etc. and all that other
    good stuff.

- Fey supports complex query creation with less fiddliness than
Alzabo. This means that the class to represent queries is a little
smarter and more flexible about the order in which bits are added.

    For example, in using Alzabo I often came across cases where I wanted
    to add a table to a query's join _if it hasn't already been
    added_. With Alzabo, there's no nice clean way to do this. Simply
    adding the table to the join parameter twice will cause an error. It
    would be nice to simply be able to do this

        $select->join( $foo_table => $bar_table );

    and have it do the right thing if that join already exists (where the
    right thing is just do nothing). `Fey::SQL` does exactly that.

- Provide the core for an RDBMS-OO mapper similar to a combination of
`Alzabo::Runtime::Row` and `Class::AlzaboWrapper`.

    At the same time, query generation and the ORM are decoupled. You can
    use [Fey::SQL](https://metacpan.org/pod/Fey%3A%3ASQL) to generate queries without having to every use the
    `Fey::ORM` ORM.

- Be declarative like Moose. In particular, the `Fey::ORM` ORM is as
declarative as possible, and aims to emulate Moose's declarative sugar
style where possible.
- Leverage the API user's SQL knowledge. Building up queries with Fey
looks enough like SQL that you shouldn't have to think _too_ hard
about it. This means join support is baked in at a core level, as are
subselects and ideally anything else you can do in SQL.

## Problems with Alzabo

Here are some of the problems I've had with Alzabo over the years
which inspired me to create Fey ...

- Adding support for a new DBMS to Alzabo is a lot of work, so it only
supports MySQL and Postgres. Alzabo tries to be really smart about
preventing users from shooting themselves in the foot, and requires a
lot of DBMS-specific code to achieve this.

    In retrospect, being a lot dumber and allowing for foot-shooting makes
    supporting a new DBMS much easier. People generally know how their
    DBMS works, and if they generate an invalid query or table name, it
    will throw an error.

    For example, while Fey can accommodate per-DBMS query (sub)classes, it does
    not include any by default, and is capable of supporting many DBMS-specific
    features without per-DBMS classes.

- Alzabo has too much DBMS-specific knowledge. If you want to use a SQL
function in a query, you have to import a corresponding Perl function
from the appropriate `Alzabo::SQLMaker`, which limits you to what's
already defined, or forces you to go through a cumbersome API to
define a new SQL function for use in your Perl code.

    By contrast, Fey has simple generic support for arbitrary functions
    via the `Fey::Literal::Function` class. If you need more flexibility
    you can use the `Fey::Literal::Term` subclass to generate an
    arbitrary snippet to insert into your SQL.

    A related problem is that Alzabo doesn't support multiple versions of
    a DBMS very well. Either it doesn't work with an older version at all,
    or it doesn't support some enhanced capability of a newer version. It
    mostly supports whatever version I happened to be using when I wrote a
    specific piece of functionality.

- There are now free GUI design tools for specific databases that do a
better job of supporting the database in question than Alzabo ever
has.
- Alzabo separates its classes into Create (for generation of DDL) and
Runtime (for DML) subclasses, which might have been worth the memory
savings six years ago, but just makes for an extra hassle now.
- When I originally developed Alzabo, I included a feature for
generating high-level application object classes which subclass the
Alzabo classes and add "business logic" methods. This is what is
provided by `Alzabo::MethodMaker`.

    Nowadays, I prefer to have my business logic classes simply use the
    Alzabo classes. In other words, I now prefer "has-a" and "uses-a"
    versus "is-a" object design for this case.

    Method auto-generation based on a specific schema can be quite handy,
    but it should be done in the domain-specific application classes, not
    as a subclass of the core functionality.

- Storing schemas in an Alzabo-specific format is problematic for many
reasons. It's simpler to simply get the schema definition from an
existing schema, or to allow users to define it in code.
- Alzabo's referential integrity checking code was really cool back when
I mostly used MySQL with MYISAM tables. Now it's just a maintenance
burden and a barrier for new features.
- I didn't catch the testing bug until quite a while after I'd started
working on Alzabo. Alzabo's test suite is nasty. Fey is built with
testability in mind, and high test coverage is part of my ongoing
goals for the project.
- Alzabo does too many things, which makes it hard to explain and
document.

# WHY IS IT NAMED Fey?

When I first started working on Fey, it was named "Q". This was a nice
short name to type, but obviously unsuitable for releasing on CPAN. I
wanted a nice short name that could be used in multiple distributions,
like John Siracusa's "Rose" modules.

I was standing in the shower one day and had the following series of
thoughts leading to Fey. Reading this will may give you an unpleasant
insight into my mind. You have been warned.

- SQLy

    This module is "SQL-y", as in "related to SQL". However, this name is
    bad for a number of reasons. First, it's not clear how to pronounce
    it. It may make you think of a YACC grammar ("SQL.y"). It's a weird
    combo of upper- and lower-case letters.

- SQLy => Squall

    "SQLy" and "Squall" share a number of letters, obviously.

    Squall is a single short word, which is good. However, it's a bit
    awkward to type and has a somewhat negative meaning to me, because a
    storm can mean trouble.

- Squall => Lionheart => Faye

    Squall Lionheart is a character in Final Fantasy VIII, which IMO is
    the best Final Fantasy game before the PS2.

    The inimitable Faye Wong sang the theme song for FF VIII. I love Faye
    Wong.

- Faye => Fey

    And thus we arrive at "Fey". It's nice and short, easy to type, and
    easy to say.

    Some of its meanings are "otherworldly" or "magical". Attempting to
    combine SQL and OO in any way is certainly unnatural, and if done
    right, perhaps magical. Fey can also mean "appearing slightly
    crazy". This project is certainly that.

Yes, I'm a nerd, I know.

# BUGS

Please report any bugs or feature requests to `bug-fey@rt.cpan.org`,
or through the web interface at [http://rt.cpan.org](http://rt.cpan.org).  I will be
notified, and then you'll automatically be notified of progress on
your bug as I make changes.

Bugs may be submitted at [https://github.com/ap/Fey/issues](https://github.com/ap/Fey/issues).

# SOURCE

The source code repository for Fey can be found at [https://github.com/ap/Fey](https://github.com/ap/Fey).

# DONATIONS

If you'd like to thank me for the work I've done on this module, please
consider making a "donation" to me via PayPal. I spend a lot of free time
creating free software, and would appreciate any support you'd care to offer.

Please note that **I am not suggesting that you must do this** in order for me
to continue working on this particular software. I will continue to do so,
inasmuch as I have in the past, for as long as it interests me.

Similarly, a donation made in this way will probably not make me work on this
software much more, unless I get so many donations that I can consider working
on free software full time (let's all have a chuckle at that together).

To donate, log into PayPal and send money to autarch@urth.org, or use the
button at [https://houseabsolute.com/foss-donations/](https://houseabsolute.com/foss-donations/).

# AUTHOR

Dave Rolsky <autarch@urth.org>

# CONTRIBUTORS

- Aristotle Pagaltzis <pagaltzis@gmx.de>
- hdp@glaive.weftsoar.net <hdp@glaive.weftsoar.net>
- hdp@localhost &lt;hdp@localhost>
- hdp@rook.opensourcery.com <hdp@rook.opensourcery.com>
- Oliver Charles <oliver@ocharles.org.uk>

# COPYRIGHT AND LICENSE

This software is Copyright (c) 2011 - 2025 by Dave Rolsky.

This is free software, licensed under:

    The Artistic License 2.0 (GPL Compatible)

The full text of the license can be found in the
`LICENSE` file included with this distribution.
