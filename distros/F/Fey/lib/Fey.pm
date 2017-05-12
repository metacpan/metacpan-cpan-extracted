package Fey;

use strict;
use warnings;

our $VERSION = '0.43';

1;

# ABSTRACT: Better SQL Generation Through Perl

__END__

=pod

=head1 NAME

Fey - Better SQL Generation Through Perl

=head1 VERSION

version 0.43

=head1 SYNOPSIS

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

=head1 DESCRIPTION

The C<Fey> distribution contains a set of modules for representing the
components of a DBMS schema, and for dynamically generating SQL
queries based on that schema.

=head1 USAGE

Loading this module does nothing. It's just here to provide docs and a
version number for the distro.

You'll want to take a look at L<Fey::Schema>, L<Fey::Table>, and other
modules in the distro for more details.

=head1 WHAT IS Fey?

The goal of the core C<Fey> distro is to provide a simple, flexible
way of I<dynamically> generating complex SQL queries in Perl. Other
packages build on top of this functionality to create a complete ORM
(C<Fey::ORM>).

=head1 GETTING STARTED

If you're interested in an ORM, take a look at the C<Fey::ORM> distro.

To generate SQL with Fey, you first need to create a set of objects
representing the tables and foreign keys in your schema. The simplest
way to do this is to use the C<Fey-Loader> distro, which will connect
to an existing schema and generate a set of objects for you.

Alternatively, you can create these objects via Fey's API. You would
first create a L<Fey::Schema> object. This object will hold all of
your tables and foreign keys. If you want to create your schema this
way, you should start with the L<Fey::Schema>, L<Fey::Table>, and
L<Fey::FK> APIs. You'll also want to use the L<Fey::Column> API.

Once you have a schema, you can generate SQL using L<Fey::SQL>, or a
DBMS-specific subclass of L<Fey::SQL>.

=head1 THE CORE Fey DISTRO

The emphasis in the core Fey distro is on dynamic queries,
particularly on the tables/columns/etc involved in the query, not just
the bound parameters.

This is I<not> what I mean by a dynamic query ...

 SELECT user_id FROM User where username = ?

While this is dynamic in the sense that the username is parameterized
and may change on each invocation, it is still easily handled by a
phrasebook class. If that is all you need, I suggest checking out any
of C<Class::Phrasebook::SQL>, C<Data::Phrasebook>, or C<SQL::Library>
on CPAN.

Imagine that we have a database with a User table and a Message table,
where each message has a user who is that message's creator. We might
want to grab all the users in the database, in which case we would do
a simple C<SELECT> against the User table ...

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

=head1 RATIONALE

You probably don't need to read this if you just wanted to know how to
use Fey.

=head2 Why Not Use a Phrasebook?

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

=head2 Why Not String Manipulation?

The next idea that might come to mind is to dump the phrasebook in
favor of string manipulation. This is simple enough at first, but
quickly gets ugly. Handling all of the possible options correctly
requires lots of fiddly code that has to concatenate bits of SQL in
the correct order, taking into account where to put in commas,
C<WHERE> vs C<AND>, and so on and so forth. I've been there, and trust
me, it's madness.

=head2 The Solution

The core Fey modules provide a solution to the dynamic SQL
problem. Using Fey, you can specify queries in the form of I<Perl
methods and objects>. Fey provides a set of objects to represent the
parts of a schema, specifically tables, columns, and foreign
keys. Using these objects along with L<Fey::SQL>, you can easily
generate very complex queries.

This core distro is also intended to be the foundation for building
higher-level tools like an ORM. See C<Fey::ORM> for just such a thing.

=head1 HISTORY AND GOALS

This module comes from my experience writing and using Alzabo. Alzabo
does everything this module does, and a lot more. The fact that Alzabo
does so many things has become a fairly problematic in its
maintenance, and Alzabo was over 6 years old at the time this project
was begun (August of 2006).

=head2 Goals

Rather than coming up with a very smart solution that allows us to use
80% of a DBMS's functionality, I'd rather come up with a solution
that's dumber but supports all (or at least 99%) of the DBMS's
features. It's easy to add smarts on top of a dumb layer, but it can
be terribly hard to add that last 20% once you've got something really
smart.

The goals for Fey, based on my experience with Alzabo, are the
following:

=over 4

=item *

Provide a simple way to generate queries dynamically. I really like
how this works with Alzabo conceptually, but Alzabo is not as flexible
as I'd like and it's "build a data structure" approach to query
building can become very cumbersome.

Rather than complex data structures, with Fey you call methods on a
C<Fey::SQL> object to build up a query. This turns out to be simpler
to work with.

Fey, unlike Alzabo, can be used to generate multi-row updates and
deletes, and it supports sub-selects, unions, etc. and all that other
good stuff.

=item *

Fey supports complex query creation with less fiddliness than
Alzabo. This means that the class to represent queries is a little
smarter and more flexible about the order in which bits are added.

For example, in using Alzabo I often came across cases where I wanted
to add a table to a query's join I<if it hasn't already been
added>. With Alzabo, there's no nice clean way to do this. Simply
adding the table to the join parameter twice will cause an error. It
would be nice to simply be able to do this

  $select->join( $foo_table => $bar_table );

and have it do the right thing if that join already exists (where the
right thing is just do nothing). C<Fey::SQL> does exactly that.

=item *

Provide the core for an RDBMS-OO mapper similar to a combination of
C<Alzabo::Runtime::Row> and C<Class::AlzaboWrapper>.

At the same time, query generation and the ORM are decoupled. You can
use L<Fey::SQL> to generate queries without having to every use the
C<Fey::ORM> ORM.

=item *

Be declarative like Moose. In particular, the C<Fey::ORM> ORM is as
declarative as possible, and aims to emulate Moose's declarative sugar
style where possible.

=item *

Leverage the API user's SQL knowledge. Building up queries with Fey
looks enough like SQL that you shouldn't have to think I<too> hard
about it. This means join support is baked in at a core level, as are
subselects and ideally anything else you can do in SQL.

=back

=head2 Problems with Alzabo

Here are some of the problems I've had with Alzabo over the years
which inspired me to create Fey ...

=over 4

=item *

Adding support for a new DBMS to Alzabo is a lot of work, so it only
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

=item *

Alzabo has too much DBMS-specific knowledge. If you want to use a SQL
function in a query, you have to import a corresponding Perl function
from the appropriate C<Alzabo::SQLMaker>, which limits you to what's
already defined, or forces you to go through a cumbersome API to
define a new SQL function for use in your Perl code.

By contrast, Fey has simple generic support for arbitrary functions
via the C<Fey::Literal::Function> class. If you need more flexibility
you can use the C<Fey::Literal::Term> subclass to generate an
arbitrary snippet to insert into your SQL.

A related problem is that Alzabo doesn't support multiple versions of
a DBMS very well. Either it doesn't work with an older version at all,
or it doesn't support some enhanced capability of a newer version. It
mostly supports whatever version I happened to be using when I wrote a
specific piece of functionality.

=item *

There are now free GUI design tools for specific databases that do a
better job of supporting the database in question than Alzabo ever
has.

=item *

Alzabo separates its classes into Create (for generation of DDL) and
Runtime (for DML) subclasses, which might have been worth the memory
savings six years ago, but just makes for an extra hassle now.

=item *

When I originally developed Alzabo, I included a feature for
generating high-level application object classes which subclass the
Alzabo classes and add "business logic" methods. This is what is
provided by C<Alzabo::MethodMaker>.

Nowadays, I prefer to have my business logic classes simply use the
Alzabo classes. In other words, I now prefer "has-a" and "uses-a"
versus "is-a" object design for this case.

Method auto-generation based on a specific schema can be quite handy,
but it should be done in the domain-specific application classes, not
as a subclass of the core functionality.

=item *

Storing schemas in an Alzabo-specific format is problematic for many
reasons. It's simpler to simply get the schema definition from an
existing schema, or to allow users to define it in code.

=item *

Alzabo's referential integrity checking code was really cool back when
I mostly used MySQL with MYISAM tables. Now it's just a maintenance
burden and a barrier for new features.

=item *

I didn't catch the testing bug until quite a while after I'd started
working on Alzabo. Alzabo's test suite is nasty. Fey is built with
testability in mind, and high test coverage is part of my ongoing
goals for the project.

=item *

Alzabo does too many things, which makes it hard to explain and
document.

=back

=head1 WHY IS IT NAMED Fey?

When I first started working on Fey, it was named "Q". This was a nice
short name to type, but obviously unsuitable for releasing on CPAN. I
wanted a nice short name that could be used in multiple distributions,
like John Siracusa's "Rose" modules.

I was standing in the shower one day and had the following series of
thoughts leading to Fey. Reading this will may give you an unpleasant
insight into my mind. You have been warned.

=over 4

=item * SQLy

This module is "SQL-y", as in "related to SQL". However, this name is
bad for a number of reasons. First, it's not clear how to pronounce
it. It may make you think of a YACC grammar ("SQL.y"). It's a weird
combo of upper- and lower-case letters.

=item * SQLy => Squall

"SQLy" and "Squall" share a number of letters, obviously.

Squall is a single short word, which is good. However, it's a bit
awkward to type and has a somewhat negative meaning to me, because a
storm can mean trouble.

=item * Squall => Lionheart => Faye

Squall Lionheart is a character in Final Fantasy VIII, which IMO is
the best Final Fantasy game before the PS2.

The inimitable Faye Wong sang the theme song for FF VIII. I love Faye
Wong.

=item * Faye => Fey

And thus we arrive at "Fey". It's nice and short, easy to type, and
easy to say.

Some of its meanings are "otherworldly" or "magical". Attempting to
combine SQL and OO in any way is certainly unnatural, and if done
right, perhaps magical. Fey can also mean "appearing slightly
crazy". This project is certainly that.

=back

Yes, I'm a nerd, I know.

=head1 BUGS

Please report any bugs or feature requests to C<bug-fey@rt.cpan.org>,
or through the web interface at L<http://rt.cpan.org>.  I will be
notified, and then you'll automatically be notified of progress on
your bug as I make changes.

=head1 AUTHOR

Dave Rolsky <autarch@urth.org>

=head1 CONTRIBUTORS

=for stopwords Aristotle Pagaltzis hdp@glaive.weftsoar.net hdp@localhost hdp@rook.opensourcery.com Oliver Charles

=over 4

=item *

Aristotle Pagaltzis <pagaltzis@gmx.de>

=item *

hdp@glaive.weftsoar.net <hdp@glaive.weftsoar.net>

=item *

hdp@localhost <hdp@localhost>

=item *

hdp@rook.opensourcery.com <hdp@rook.opensourcery.com>

=item *

Oliver Charles <oliver@ocharles.org.uk>

=back

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2011 - 2015 by Dave Rolsky.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
