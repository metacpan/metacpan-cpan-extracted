package LittleORM::Tutorial;

use 5.006;
use strict;
use warnings FATAL => 'all';

=head1 NAME

LittleORM::Tutorial - what is and how to use LittleORM

=cut

=head1 INTRODUCTION

LittleORM is an ORM. It uses Moose. It is tested to work with
PostgreSQL 8.x and 9.x. It is also tested to work in persistent
environment, such as mod_perl 2.x.

I used it in my projects for abt a year and it probably does all you
need it to.

The main drawback I am aware of is that it is heavy if you need to
process tenths of thousands of records, as every record gets created
as an object.

=head1 IMPORTANT


Important: There are at least 2 things LittleORM does not do, which
means that you have to do yourself:

- Create your tables, actually writing SQL yourself. You do it only
  once.

- Write Moose class representing your model. Although you could use
  inheritance mechanisms to simplify that some. You do it only once,
  you write your model.

- Connect to your DB with DBI. You connect to database, then
  initialize ORM with valid connected $dbh. (Not actually correct
  anymore: you can provide your model with function which will be used
  to connect to DB).

Did I say 2 things? OK, I meant 3.

Continuing with this tutorial I assume that you're more or less
familiar with Moose. If not, then get acquainted before moving
on. Moving on.

=head1 INITIALIZATION


Most standard way, one database:


    LittleORM::Db -> init( $dbh );


Where $dbh is a connected database handle you received from L<DBI> .

Starting with version 0.13 you can use separate $dbh handles for
reading and writing operations. NOTE: reading operation is assumed to
be C<SELECT> . This is useful for heavy-duty projects where you may
have several separate read-only DB servers and one read-write master
DB server.

In such cases you can use:


    LittleORM::Db -> init( { read => $dbh1,
                             write => $dbh2 } );

Or


    LittleORM::Db -> init( { read => [ $dbh1, $dbh2, ... ],
                             write => $dbh3 } );


Or


    LittleORM::Db -> init( { read => [ $dbh1, $dbh2, ... ],
                             write => [ $dbh3, $dbh4, ... ] } );



Etc.

=head1 MORE CONVENIENT WAY TO DECLARE MODEL ATTRS


As of version 0.10 (at least) LittleORM supports more convenient
attribute declaration, like:


    package Models::Book;
    use LittleORM;
    extends 'LittleORM::Model';
    
    sub _db_table { 'book' }
    
    has_field 'id' => ( isa => 'Int',
                        description => { primary_key => 1 } );
    
    has_field 'title' => ( isa => 'Str' );
    
    has_field 'author' => ( isa => 'Models::AuthorHF',
    			    description => { foreign_key => 'yes' } );


However, the rest of this tutorial was written earlier, and hence uses
standard Moose attributes syntax with "has". Didn't have time to
rewrite it yet. Now read on.


=head1 WRITING YOUR MODEL


A model is your table description in terms of LittleORM. You create a
model by subclassing from LittleORM::Model class. Or other class,
which in turn, is a subclass of LittleORM::Model.

=head1 EXAMPLE

Suppose we have following table:


    $ \d author
                                   Table "public.author"
     Column |         Type          |                      Modifiers                      
    --------+-----------------------+-----------------------------------------------------
     id     | integer               | not null default nextval('some_seq')
     name   | character varying     | 
     email  | character varying     | 
     login  | character varying     | 
     pwdsum | character varying(32) | 
     active | boolean               | 
     rctype | smallint              | 
    
    $

We'll call it MyModel::Author. So, let's write:


    package MyModel::Author;
    use LittleORM;
    extends 'LittleORM::Model';
    
    # the first column, is PK, id:
    
    has_field 'id' => ( isa => 'Int',
                        description => { primary_key => 1 } );

Note C<< description => { ... } >> attribute. It is how you tell
LittleORM things about your columns. C<< metaclass =>
'LittleORM::Meta::Attribute' >> should be included along and is
required for Moose to process our extra description.

Now, as id column PK is pretty common, I ship base class for it with
LittleORM. So we re-write our model:


    package MyModel::Author;
    use LittleORM;
    extends 'LittleORM::GenericID';
    

OK, now we need to tell our model which table in database we work
with. Redefine C<< sub _db_table >> for that:


    package MyModel::Author;
    use LittleORM;
    extends 'LittleORM::GenericID';

    sub _db_table { 'author' }

    # Now other columns:

    has_field 'name' => ( isa => 'Str' );
    
    has_field 'email' => ( isa => 'Str' );
    
    has_field 'login' => ( isa => 'Str' );
    
    has_field 'pwdsum' => ( isa => 'Str' );
    
    has_field 'active' => ( isa => 'Bool' );
    
    has_field 'rctype' => ( isa => 'Int' );
    

NOTE: You would want to write C<< Maybe[Str], Maybe[Int] >> if your
columns can have NULL values in them.

Moving on.

As it is a Moose class you're writing, you're not limited to
attributes which only are present in your table. You can add more
attributes and methods. A bit artificial example is C<< valid_email >>
attribute:


    has_field 'valid_email' => ( isa => 'Bool',
                                 lazy => 1,
                                 builder    => '_is_valid_email', # your sub
                                 description => { ignore => 1 } );

Note C<< description => { ignore => 1 } >> attribute. It's not present
in the table, so LittleORM must ignore it. This descriptions tells it
to.

=head1 WORKING WITH DB - READING

Before we were describing our model, now, it's time to manipulate it,
actually working with database.

As was said before, LittleORM does not connect to DB for you. You have
to connect and initialize it before. Now, in my web project I have
$dbh available to me with C<&dbconnect()> function. It connects once and
then returns C<$dbh> to any client script require it.

NOTE: C<$dbh> is supposed to be db handle returned by C<< DBI -> connect() >>

So we write:

    use strict;
    use MyModel::Author;
    
    # ...
    
    LittleORM::Db -> init( $dbh );
    
    # selecting a single record is done with get():
    
    my $author = MyModel::Author -> get( id => 100500 );
    print $author -> name();
    

    # selecting multiple records is done with get_many():

    my @active = MyModel::Author -> get_many( active => 1 );
    # now, @active is an ARRAY of MyModel::Author objects

    # selecting count is donte with count() and returns integer
    my $active_cnt = MyModel::Author -> count( active => 1 );

I<Every MyModel::Author object you get is MyModel::Author you described
in your model, with all the properties and methods you wrote.>

NOTE: Always remember to do C<< LittleORM::Db -> init() >>! Well,
assert will remind you to, but still.


If you're afraid that someone might be tinkering with your record from
the time you selected it, you can reload:

    my $author = MyModel::Author -> get( id => 100500 );

    # ...

    $author -> reload();



=head1 WORKING WITH DB - INSERTING AND UPDATING

Update simple. You set new value, then call C<< update() >>:

    use strict;
    use MyModel::Author;
    
    # ...
    
    LittleORM::Db -> init( $dbh );

    my $author = MyModel::Author -> get( id => 100500 );
    $author -> name( "New Name For This Author" );
    $author -> update();


Insert is actually simple too:

    # This will throw assert on error:
    
    my $new_author = MyModel::Author -> create( name => 'Mad Squirrel',
                                                # other attrs );
    
    print $new_author -> id();
    

Now, you might want to create new record only if it does not yet exists:


    my $author = MyModel::Author -> get_or_create( name => 'Mad Squirrel',
                                                   # other attrs );
    
    print $new_author -> id();



And you might want to create a copy:

    my $author = MyModel::Author -> get( id => 100500 );
    
    my $new_one = $author -> copy();
    





=head1 WORKING WITH DB - DELETING

Delete can be dangerous. Remeber that.


    my $author = MyModel::Author -> get( id => 100500 );
    $author -> delete();

# same as:

    MyModel::Author -> delete( id => 100500 );


# deletes all authors (!):

    MyModel::Author -> delete();

It's safer to call delete() from an instance, not from package.

=head1 DEBUG SQL

All mentioned LittleORM calls are translated to SQL language at some
(close to final) point. And you might want to see what it looks like.

Every LittleORM method which works with DB - get(), get_many(),
count(), delete(), update() support C<< _debug => 1 >> argument. If
C<< _debug => 1 >> is passed, ORM does not do anything, but builds SQL
it's about to execute and returns it in one plain string scalar.


    my $author = MyModel::Author -> get( id => 100500,
                                         _debug => 1 );

    print $author;

    # Might produce something resembling:

    SELECT author.id,author.name,... FROM author WHERE id='100500'





=head1 MORE ON SELECTION CLAUSES

To this point, we only used simple exact selection filters. Like exact
C<< id >> or exact C<< active >> field. Life is usually more
complicated than that.

Note that filtring clauses syntax is the same in get(), get_many(),
count(), delete(), clause(), filter() methods. There will be more
about former two later.



    use strict;
    use MyModel::Author;

    # Dont forget:

    LittleORM::Db -> init( $dbh );

    # Several IDs:

    my @ids_i_want = ( 123, 456, 789 );
    my @authors = MyModel::Author -> get_many( id => \@ids_i_want );


    # ID more than:

    my @authors = MyModel::Author -> get_many( id => { '>', 100500 } );


    # Name like:

    my @authors = MyModel::Author -> get_many( name => { 'LIKE', 'Mad%' } );


    # Combined with AND:

    my @authors = MyModel::Author -> get_many( name => { 'LIKE', 'Mad%' },
                                               active => 0,
                                               id => { '>', 100500 } );


    # Combined with OR:

    my @authors = MyModel::Author -> get_many( name => { 'LIKE', 'Mad%' },
                                               active => 0,
                                               id => { '>', 100500 },
                                               _logic => 'OR' );


=head1 SORTING

We still want active ones:

    my @authors = MyModel::Author -> get_many( active => 1,
                                               _sortby => [ id      => 'ASC',
                                                            created => 'DESC' ] );

    # ... ORDER BY author.id ASC,author.created DESC ...


Oops, C<< author >> does not contain C<< created >> column in our
example. Anyway, you got the idea.

=head1 SELECTION METHODS SYSTEM PROPERTIES

Both get() and get_many() support following system arguments:

( _limit => Int ) - How much records we want to get with get_many() an
once (translates to SQL LIMIT)

( _offset => Int ) - Starting from offset (translates to SQL OFFSET)


    my @authors = MyModel::Author -> get_many( active => 1,
                                               _limit => 50,
                                               _offset => 0,
                                               _sortby => [ id      => 'ASC',
                                                            created => 'DESC' ] );


( _distinct => 1/0  ) - Select only distinct records. (SQL DISTINCT)

( _clause => $c ) - Pass a clause. If $c if an ARRAYREF it assumed to
be args for clause() method.

( _logic => 'AND'/'OR' ) - Join all clauses with this logic. Default is 'AND'.


    ( _sortby => 'attr' )
    or
    ( _sortby => { 'attr' => 'ASC' / 'DESC', ... } )
    or
    ( _sortby => [ 'attr', 'ASC', ... ] )
    
 - Sort.



( _dbh => $dbh ) - Pass another $dbh. Will be used as default if no
other was seen before.


( _where => 'RAW SQL' ) - Be cautios.


=head1 LittleORM::Clause OBJECT

LittleORM::Clause is a way to create and store selection clauses in an
object. This object may then be used in get(), get_many(), and
filter().

It can simplify get() methods arguments. Also it can help you separate
selection arguments building from records selecting and processing. Be
sure to look at B<< LittleORM::Filter >> too.

They (Clause objects) can also be combined flexibly.


    my $c1 = MyModel::Author -> clause( cond => [ id => { '>', 91 },
                                                  # anything that can be passed
                                                  # to get() funcs
                                                  # see "MORE ON SELECTION CLAUSES"
                                                  id => { '<', 100 } ] );



    my $c2 = MyModel::Author -> clause( cond => [ id => { '>', 100 },
                                                  id => { '<', 110 } ] );


Or simpler:


    my $c1 = MyModel::Author -> clause( id => { '>', 91 },
                                        id => { '<', 100 } );

    my $c2 = MyModel::Author -> clause( id => { '>', 100 },
                                        id => { '<', 110 } );

    my $c3 = MyModel::Author -> clause( cond => [ $c1, $c2 ],
                                        logic => 'OR' );
    
    my $debug = MyModel::Author -> get( _clause => $c3,
                                        _debug => 1 );
    
    
    # same as:
    
    my $debug = MyModel::Author -> get( _clause => [ cond => [ $c1, $c2 ],
                                                     logic => 'OR' ],
                                        _debug => 1 );
    
    # produces: 
    # ... WHERE  (  ( id > '91' AND id < '100' )  OR  ( id > '100' AND id < '110' )  )


Can use clause inside clause:

    my $c1 = MyModel::Author -> clause( id => { '>', 91 },
                                        id => { '<', 100 } );

    my $c2 = MyModel::Author -> clause( id => { '>', 100 },
                                        id => { '<', 110 },
                                        _clause => $c1 );





=head1 FOREIGN KEYS

LittleORM works with foreign keys nicely. You just have to specify FK
in your Model description.

Suppose we have one more table, in addition to C<<authors>>:


    $ \d book
                                         Table "public.book"
      Column   |            Type             |                     Modifiers                      
    -----------+-----------------------------+----------------------------------------------
     id        | integer                     | not null default nextval('book_id_seq')
     title     | character varying           | 
     published | timestamp without time zone | 
     author    | integer                     | 
    
    $

Now, the C<< author >> column of table C<< book >> refers to C<<
author.id >>. That's our FK. OK, now let's write the model for books :


    package MyModel::Book;
    use LittleORM;
    extends 'LittleORM::GenericID';

    has_field 'title' => ( isa => 'Str' );
    
    # we'll convert this to DateTime later:
    has_field 'published' => ( isa => 'Str' ); 

    # and finally:

    has_field 'author' => ( isa => 'MyModel::Author',
                            description => { foreign_key => 'MyModel::Author' } );
    
    # or

    has_field 'author' => ( isa => 'MyModel::Author',
                            description => { foreign_key => 'yes' } );


    # "yes" keyword tells LittleORM to load model specified in "isa",
    # so you don't have to write it's name again.



And that is all. Now we can do something like:


    use strict;
    use MyModel::Book;
    
    # ...
    
    LittleORM::Db -> init( $dbh );

    my $book = MyModel::Book -> get( id => 100500 );

    printf( "The author of %s is %s",
            $book -> title(),
            $book -> author() -> name() );



=head1 REVERSE FK

Now this is possible only if relation 1-to-1. Although C<< author >>
table does not contain C<< book >> column we could write:


    has_field 'book' => ( isa         => 'MyModel::Book',
                          description => { foreign_key  => 'yes',
    				           ignore_write => 1, # cant write it
    				           db_field     => 'id', 
    				           foreign_key_attr_name => 'author' } );



=head1 MORE ON ATTRIBUTES DESCRIPTIONS

As you could see, there are many keywords you can use in attribute
description. These all proved to be useful in a long time work in real
world.


Let's list them all:

I<coerce_from>

Subroutine, which is called to convert DB field value into your class
attribute value. Remember when we wrote:

    has_field 'published' => ( isa => 'Str' ); 

That's not very cool. Here is how to have DateTime there:

    has_field 'published' => ( isa => 'DateTime',
                               description => { coerce_from => sub { &ts2dt( $_[ 0 ] ) } } );


With ts2dt() being something like:

    sub ts2dt
    {
    	my $ts = shift;
    	return DateTime::Format::Strptime -> new() -> parse_datetime( $ts );
    }
    

I<coerce_to>

Reverse for I<coerce_from>. Previous example will fail on
updating/writing, because there is no way LittleORM knows how to
convert DateTime back to DB format. We should either put C<<
ignore_write >> there, or provide I<coerce_to>:


    has_field 'published' => ( isa => 'DateTime',
                               description => { coerce_from => sub { &ts2dt( $_[ 0 ] ) },
                                                coerce_to => sub { &dt2ts( $_[ 0 ] ) } } );



With dt2ts() :

    sub ts2dt
    {
    	my $dt = shift;
        return DateTime::Format::Strptime -> new() -> format_datetime( $dt );
    }


You can have a text or XML field and with C<< coerce_from >> / C<<
coerce_to >> you can appear it to be something else, like. Like
anything.


I<db_field>

It happens that DB colunm names are not always precise or
appropriate. You can have attribute in your model with a name
different from db column name:


    has_field 'product' => ( isa => 'ExampleModel',
		             description => { db_field => 'pid' } );


I<db_field_type>

Well, that is a mechanism to determine a correct SQL operation for
underlying DB column depending on it's type.


    has_field 'attrs' => ( isa => 'Str',
                           description => { db_field_type => 'xml' } );


'xml' is the only known field type currently.

I<do_not_clear_on_reload>

There is a reload() method, remember? This causes LittleORM to skip
attribute from being cleared when reload() is called.

I<foreign_key>

This is how FKs are defined. See B<< FOREIGN KEYS >> section.

I<foreign_key_attr_name>

Normally, you dont need this. FK thought to be connected to other
model's PK. But if it's not true, you can manually specify the
corresponding attribute name from other model.


I<ignore>

Causes LittleORM to ignore this attribute. Let's you have arbitrary
attributes in your class along with DB-related ones.


I<ignore_write>

Then LittleORM ignores attribute only on writing. It does not get updated,
etc. Only read from DB. If you have something you present with C<<
coerce_from >>, you might want it.


I<primary_key>

Tells LittleORM that this column is a PK. Most models should have a
PK.

I<sequence>

Normally, you don't need this. Just make sure your PKs are of type
serial and have sequences attached to them inside DB.

But you may also specify sequence which will be used to obtain a value
for column on creating new record (if no value passed of course).


=head1 LittleORM::Filter OBJECT

LittleORM::Filter is advanced version of LittleORM::Clause. Filter is
a set of clauses, associated with a model. Filter is also a main tool
to join tables on query.


=head1 JOINING TABLES

Suppose we need to select all books from all active authors:

    my $authors = MyModel::Author -> filter( active => 1 );
    my @books = MyModel::Book -> filter( $authors ) -> get_many();


OK, what about all authors with books published before 2000?

    my $books = MyModel::Book -> f( published => { '<', '2000-01-01' } );
    my @authors = MyModel::Author -> f( $books ) -> get_many();

Yeah, you can write f(), not filter(). Shorter that way.

The latter example has one flaw. If there are one-to-many
correspondence between authors and books, we might get duplicates in
authors. To avoid that:

    my @authors = MyModel::Author -> f( $books ) -> get_many( _distinct => 1 );

Note how you dont need to specify corresponding columns between
models. It's because you declared FK between them earlier.

But there can be no FK.

=head1 MORE JOINING TABLES

You can specify a column which filter corresponds to, and which column
is returned from filter. The code from previous section:


    my $authors = MyModel::Author -> filter( active => 1 );
    my @books = MyModel::Book -> filter( $authors ) -> get_many();


Without FK must be written as:

    my $authors = MyModel::Author -> filter( active => 1,
                                             _return => 'id' );

    my @books = MyModel::Book -> filter( author => $authors ) -> get_many();


And you can join a table on itself. Sorry for totally artificial
example:

    my $f = Metatable -> f( rgroup => 100500,
                            _clause => $c1, # passing additional clause
                            f01 => Metatable -> f( rgroup => 500100,
                                                   _return => 'f02' ) );
    
    my @recs = $f -> get_many();



You can connect filters after they have been created with I<connect_filter()>. Same as above:


    my $f = Metatable -> f( rgroup => 100500,
                            _clause => $c1 );

    my $f1 = Metatable -> f( rgroup => 500100,
                             _return => 'f02' )
    
    $f -> connect_filter( f01 => $f1 );


=head1 LEFT AND OUTER JOINS

... are supported:

    $f1 -> connect_filter_left_join( $f2 );

Instead of "_left_join" you can use _join, _inner_join, _right_join,
_left_outer_join, _right_outer_join to get the appropriate join in SQL
query.

Connection clause is optional (otherwise LittleORM will try to find FK
between models):

    $f1 -> connect_filter_left_join( $f2,
                                     _clause => $c1 );


=head1 Fieldsets, datasets, and LittleORM::Model::Field object.

TODO: describe.


=head1 API REFERENCE

Public mehods you inherit from C<< LittleORM::Model >> or C<< LittleORM::GenericID >>:


I<_db_table()>

Specify database table name your model works with.


I<reload()>

Reload object instance from DB.


I<clone()>

Create object copy. DB record is not copied. see C<< copy() >> below.


I<< get() >>

Select and return one object.


I<< values_list() >>

    @values = Class -> values_list( [ 'id', 'name' ], [ something => { '>', 100 } ] );
    # will return ( [ id, name ], [ id1, name1 ], ... )


I<< get_or_create() >>

Try to get record with passed arguments. If none found, calls
C<<create()>> and tries to create it.


I<< get_many() >>

Get many records/objects.


I<< count() >>
Get matching records count (integer).

I<< create() >>

Create new record in DB. Returns newly created object.

I<< update() >>

Write changes you made to object actually to DB.


I<< copy() >>

Actually copy record. New object corresponding to new record is returned.


I<< delete() >>

Delete records from DB.

I<< With LittleORM::Clause: >>

I<< clause() >>

Create new clause object. See B<< LittleORM::Clause OBJECT >> section.

I<< With LittleORM::Filter: >>

I<< filter() >>

Create new filter object. See B<< LittleORM::Filter OBJECT >>
, B<< JOINING TABLES >> , B<< MORE JOINING TABLES >> sections.


I<< f() >>

Shortcut to filter() .



=head1 TO REMEMBER

1. Remember to init C<< LittleORM::Db -> init( $dbh ); >>

2. You can pass C<< _debug => 1 >> and see what is going on.


=head1 MOAR EXAMPLES

Could be a bit outdated, but still.

Look here: https://github.com/gnudist/littleorm/tree/master/examples

=head1 AUTHOR

Eugene Kuzin, C<< <eugenek at 45-98.org> >>, JID: C<< <gnudist at jabber.ru> >>
with significant contributions by
Kain Winterheart, C<< <kain.winterheart at gmail.com> >>

=head1 BUGS

The main drawback I am aware of is that it is heavy if you need to
process tenths of thousands of records, as every record gets created
as an object.

Please report any bugs or feature requests to C<bug-littleorm at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=LittleORM>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.




=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc LittleORM


You can also look for information at:

=over 4


=item * Project home:

L<https://github.com/gnudist/littleorm>

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=LittleORM>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/LittleORM>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/LittleORM>

=item * Search CPAN

L<http://search.cpan.org/dist/LittleORM/>

=back


=head1 ACKNOWLEDGEMENTS


=head1 LICENSE AND COPYRIGHT

Copyright 2013 Eugene Kuzin.

This program is free software; you can redistribute it and/or modify it
under the terms of the the Artistic License (2.0). You may obtain a
copy of the full license at:

L<http://www.perlfoundation.org/artistic_license_2_0>

Any use, modification, and distribution of the Standard or Modified
Versions is governed by this Artistic License. By using, modifying or
distributing the Package, you accept this license. Do not use, modify,
or distribute the Package, if you do not accept this license.

If your Modified Version has been derived from a Modified Version made
by someone other than you, you are nevertheless required to ensure that
your Modified Version complies with the requirements of this license.

This license does not grant you the right to use any trademark, service
mark, tradename, or logo of the Copyright Holder.

This license includes the non-exclusive, worldwide, free-of-charge
patent license to make, have made, use, offer to sell, sell, import and
otherwise transfer the Package with respect to any patent claims
licensable by the Copyright Holder that are necessarily infringed by the
Package. If you institute patent litigation (including a cross-claim or
counterclaim) against any party alleging that the Package constitutes
direct or contributory patent infringement, then this Artistic License
to you shall terminate on the date that such litigation is filed.

Disclaimer of Warranty: THE PACKAGE IS PROVIDED BY THE COPYRIGHT HOLDER
AND CONTRIBUTORS "AS IS' AND WITHOUT ANY EXPRESS OR IMPLIED WARRANTIES.
THE IMPLIED WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR
PURPOSE, OR NON-INFRINGEMENT ARE DISCLAIMED TO THE EXTENT PERMITTED BY
YOUR LOCAL LAW. UNLESS REQUIRED BY LAW, NO COPYRIGHT HOLDER OR
CONTRIBUTOR WILL BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, OR
CONSEQUENTIAL DAMAGES ARISING IN ANY WAY OUT OF THE USE OF THE PACKAGE,
EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.


=cut

42; # End of LittleORM
