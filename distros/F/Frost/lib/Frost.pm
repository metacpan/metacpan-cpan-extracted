package Frost;

use strict;
use warnings;

#	LIBS
#
use Moose ();
use Moose::Exporter;

use Frost::Types;
use Frost::Util ();

use Frost::Meta::Class;
use Frost::Meta::Instance;
use Frost::Meta::Constructor;

use Frost::Locum;

#	CLASS VARS
#
our $VERSION	= '0.70';
$VERSION			= eval $VERSION;

our $AUTHORITY	= 'cpan:ERNESTO';

#	CLASS INIT
#
Moose::Exporter->setup_import_methods ( also => 'Moose' );

#	CLASS METHODS
#

#sub init_meta
#{
#	shift;				#	just your package name
#	my %options	= @_;
#
#	my $meta		= Moose->init_meta
#	(
#		%options,
#		base_class	=> 'Frost::Locum',
#	);
#
#	Moose::Util::MetaRole::apply_metaclass_roles
#	(
#		for_class						=> $options{for_class},
#		metaclass_roles				=> [ 'Frost::Meta::Class'			],
#		attribute_metaclass_roles	=> [ 'Frost::Meta::Attribute'		],
#		instance_metaclass_roles	=> [ 'Frost::Meta::Instance'		],
#		constructor_class_roles		=> [ 'Frost::Meta::Constructor'	],
#	);
#
#	return $meta;
#}

sub init_meta
{
	shift;				#	just your package name
	my %options	= @_;

	my $meta		= Moose->init_meta
	(
		%options,
		base_class	=> 'Frost::Locum',
	);

	Moose::Util::MetaRole::apply_metaroles
	(
		for						=> $options{for_class},
		class_metaroles		=>
		{
			class					=> [ 'Frost::Meta::Class' ],
			attribute			=> [ 'Frost::Meta::Attribute' ],
#			method
#			wrapped_method
			instance				=> [ 'Frost::Meta::Instance' ],
			constructor			=> [ 'Frost::Meta::Constructor' ],
#			destructor
#			error
		}
	);

	return $options{for_class}->meta();
}

#	PUBLIC ATTRIBUTES
#

#	PRIVATE ATTRIBUTES
#

#	CONSTRUCTORS
#

#	DESTRUCTORS
#

#	PUBLIC METHODS
#

#	PRIVATE METHODS
#

#	CALLBACKS
#

#	IMMUTABLE
#

1;

__END__

=head1 NAME

Frost - Feasible Referential Object STorage

=head1 SYNOPSIS

   package My::BaseFoo;
   # use Moose;
   use Frost;

   has my_base_attr => ( ... );

   no Frost;
   __PACKAGE__->meta->make_immutable();   #  mutable is VERBOTEN

   ###################

   package My::Foo;
   use Moose;
   extends 'My::BaseFoo';

   use Frost::Util;   # provides true() and false() aka 1 and 0

   has my_attr           => ( ... );
   has my_index_attr     => ( index     => true, ... );
   has my_unique_attr    => ( index     => 'unique', ... );
   has my_transient_attr => ( transient => true, ... );
   has my_virtual_attr   => ( virtual   => true, ... );
   has my_derived_attr   => ( derived   => true, ... );

   sub _build_my_derived_attr { ... }

   no Moose;
   __PACKAGE__->meta->make_immutable();   #  mutable is VERBOTEN

   ###################

   package My::Bar::AutoId;
   use Moose;
   extends 'My::Foo';

   use Frost::Util;   # provides true() and false() aka 1 and 0

   has id => ( auto_id => true );   # UUID

   no Moose;
   __PACKAGE__->meta->make_immutable();

   ###################

   package My::Bar::AutoInc;
   use Moose;
   extends 'My::Foo';

   use Frost::Util;   # provides true() and false() aka 1 and 0

   has id => ( auto_inc => true );  # 1, 2, 3, 4, ....

   no Moose;
   __PACKAGE__->meta->make_immutable();

   ###################

   package My::Loop;
   use Moose;
   extends 'My::BaseFoo';

   has next => ( isa => 'My::Loop', ... )   #  weak ref is VERBOTEN
   has last => ( isa => 'My::Loop', ... )   #  weak ref is VERBOTEN

   no Moose;
   __PACKAGE__->meta->make_immutable();

   ###################

   #  application.cgi
   #
   use Frost::Asylum;
   use My::Foo;
   use My::Bar::AutoId;
   use My::Bar::AutoInc;

   my $asylum   = Frost::Asylum->new ( data_root => '/existing/path/for/my/data' );

   my ( $id_auto_id, $id_auto_inc );

   #   Create
   {
      my $foo      = My::Foo->new          ( id => 42, asylum => $asylum, my_attr => ... );
      my $bar_id   = My::Bar::AutoId->new  (           asylum => $asylum, my_attr => ... );
      my $bar_inc  = My::Bar::AutoInc->new (           asylum => $asylum, my_attr => ... );

      $id_auto_id  = $bar_id->id;    # something like ECDAEFD4-9247-11DE-9343-7794CBAD412D
      $id_auto_inc = $bar_inc->id;   # if empty 1, otherwise last used id + 1
   }

   #   Circular references
   {
      my $loop1 = My::Loop->new ( id => 'L1', asylum => $asylum );
      my $loop2 = My::Loop->new ( id => 'L2', asylum => $asylum, last => $loop1 );
      my $loop3 = My::Loop->new ( id => 'L3', asylum => $asylum, last => $loop2  );

      $loop1->last ( $loop3 );

      $loop1->next ( $loop2 );
      $loop2->next ( $loop3 );
      $loop3->next ( $loop1 );
   }

   $asylum->close;   # and auto-save

   #   Evoke

   {
      my $foo      = My::Foo->new          ( id => 42,           asylum => $asylum );
      my $bar_id   = My::Bar::AutoId->new  ( id => $id_auto_id,  asylum => $asylum );
      my $bar_inc  = My::Bar::AutoInc->new ( id => $id_auto_inc, asylum => $asylum );

      my $loop2    = My::Loop->new ( id => 'L2', asylum => $asylum );

      ( $loop2->last->id eq 'L1' ) or die;
      ( $loop2->next->id eq 'L3' ) or die;

      my $loop1 = $loop2->next->next;
   }

=head1 ABSTRACT

Frost is an extension of Moose providing persistence even to circular structures.

=head1 DESCRIPTION

Once upon a time, when there were still real winters with frosty air,
an old moose named Elly Elk walked through the snow-white forest and
murmured over and over "How can I become persistent?", "I want to live
forever!" and more and more of that agonizing stuff.

Suddenly she ran into Mona Moose, her old friend. Elly noticed, that
Mona was looking younger than ever, fresh and clean, although Mona was
as old as Elly. "How comes, that you're looking so fine?" Elly said
and Mona replied, that she would share her secret with Elly: "Come on,
join me at the Asylum."

Said and done. The Asylum was a warm and cozy place and the warden was
a friendly man, although - with his peaked hat - he looked more like a
wizard. The room was dimly lit. Elly recognized many of her old
friends hanging out in the Twilight.

"Yes, you can live forever as all the other moose, just sign here with
blood." the warden said.

Elly Elk shivered but Mona Moose encouraged her: "This is a mere
formality."

What the warden didn't tell, that he was a Necromancer and that behind
the Asylum was a big Cemetery, where his assistants - the Morticians -
did their clandestine work. But he knew, that - although he was
practicing only white magic - the truth would have frighten his
guests.

"Trust me - I know what I'm doing!" he said and continued: "Look at
Mona and all your friends."

So Elly Elk signed the registration form and the Necromancer blessed
her with an exclusive mantra and said: "With this mantra you'll be
unique in the world. As long as it's a known value, you'll live for
ever. But now take a sleep - you're looking tired."

The Necromancer conducted Elly to his studio, where she was silenced.
And as she passed away, he removed her spirit and put it in the
Twilight zone.

As he came back, Mona wanted to see Elly again. "That's easy!"
answered the Necromancer and with a little hex he evoked Elly and
turns her from a spirit to - no, not to the original Elly - but to a
confusingly similar Locum.

"Welcome back, Elly!" Mona said, "You're looking so good now." And
really, Elly was feeling young and strong. Mona, Elly and all their
friends had much fun all day.

In the evening the warden started to silence everybody  - um, every
Locum - with the magic words "We've done a full day's work and it's
time for bed."

When the Asylum was closed, the Necromancer absolved all spirits in
the Twilight and tasked the Morticians to extract the essence of every
spirit and bury it in the Cemetery while collecting every spirit's
mantra in a huge book called Illuminator.

The next morning, when the Asylum was opened again. the Morticians
were instructed by the Necromancer to grub all essences from the
Cemetery. His secret assistents did as told: After consulting the
Illuminator, they aspirated every mantra to conjure up the spirit from
the essence. Then the Necromancer evoked every spirit and so the
lounge filled up with Locums again.

So it went day in, day out. Elly and Mona and their friends were
persistent now and they all lived happily ever after.

=head1 MOTIVATION

=head2 Persistent storage even for circular structures like trees or loops is feasible

As Matt Sergeant pointed out in his article at
L<http://www.perl.com/pub/a/2002/08/07/proxyobject.html> using
referential structures is problematic, because it leads often to
memory leakage.

Weak references for object relations like Tree->parent and
Tree->children or Loop->next and Loop->last are no solution, because
at time the root object is leaving the scope, all references are lost
also.

Using a proxy object as described in the article is bad too,
because deploying a tree constructed with a weak proxy will fail, if you
I<hold onto a sub-tree while letting the root of the tree go out of
scope. All of a sudden you'll find your data structure has become
untangled, like so much wool from a snagged jumper.> (Matt Sergeant)

An AUTOLOAD solution would foil L<Moose>' fast immutable mode. Moreover
you always have to be sure, which attribute has to be weak or not - an
endless source of bugs.

But we need referential structures - imagine a repertoire management
system for a theatre:

We have productions (plays) bound to events (stage performances),
while any event points to a production and furthermore to a location,
each connected in turn to many productions. Moreover we have authors,
directors, technicians, actors etc. attached to events, locations and
productions and so on.

Loops, loops, loops...

The L<Moose> example in t/020_attributes/028_no_slot_access.t gave us the right direction.

But just backending all attributes of a complete object - as in the
example - wouldn't provide us with a solution for circular references.
So why not deliver always a small proxy object (the
L<Locum|Frost::Locum>), which holds no real attributes in memory except
'id' (the mantra) and 'asylum' (the storage object
L<Asylum|Frost::Asylum>) for speed. Every other attribute is
kept in a cache (the L<Twilight|Frost::Twilight>) as a unique
hash structure (the spirit), which in turn is tied to a L<Berkeley
DB|DB_File> backend (the L<Cemetery|Frost::Cemetery>) managed
by the L<Necromancer|Frost::Necromancer> and his assistants,
the L<Morticians|Frost::Mortician>.

Frost's meta voodoo provides us with a lightweight proxy mechanism
without AUTOLOAD tricks: Any other object is not stored in the owner
object's attribute as a real reference, but only as a special pointer
to the other already cached hash (aka spirit). Every time, the referenced
object is accessed, the factory (Asylum) delivers a new proxy object (Locum).
This way we'll never create hard circular references, which can't be
garbage collected.

=head1 IMPLEMENTATION

=head2 The underlying magic disclosed

The program:

   #   ===>   next
   #   --->   last
   #
   #   +---------+     +---------+
   #   |         |====>|         |
   #   |         |<----|         |
   #   | Loop(1) |     | Loop(2) |
   #   |         |---->|         |
   #   |         |<====|         |
   #   +---------+     +---------+

   {
      package Loop;
      use Frost;
      use Frost::Util;   # provides true() and false() aka 1 and 0

      has content => ( is => 'rw', isa => 'Str' );

      has 'last' =>
      (
         is       => 'rw',
         isa      => 'Loop',
         weak_ref => false,      #   weak refs are VERBOTEN
      );

      has 'next' =>
      (
         is       => 'rw',
         isa      => 'Loop',
         weak_ref => false,      #   weak refs are VERBOTEN
      );

      sub add_next
      {
         my ( $self, $next )  = @_;

         $next->last ( $self );
         $self->next ( $next );
      }

      no Frost;

      __PACKAGE__->meta->make_immutable();
   }

   use Frost::Asylum;

   my $asylum  = Frost::Asylum->new ( data_root => '/existing/path/for/my/data' );

   my $loop1   = Loop->new ( asylum => $asylum, id => 1, content => 'This is Loop 1' );
   my $loop2   = Loop->new ( asylum => $asylum, id => 2, content => 'This is Loop 2' );

   $loop1->add_next ( $loop2 );
   $loop2->add_next ( $loop1 );

gives us the structures (memory addresses simplified):

   Loop=HASH(100)         ( = $loop1 )
   {
      id       => 1,
      asylum   => Asylum=HASH(666),
      _status  => "missing",
   }

   Loop=HASH(200)         ( = $loop2 )
   {
      id       => 2,
      asylum   => Asylum=HASH(666),
      _status  => "missing",
   }

   Asylum=HASH(666)
   {
      twilight => Twilight=HASH(42)
      {
         'Loop|1' => { id => 1, _dirty => false,
                       content => 'This is Loop 1',
                       next => { type => 'Loop', ref => 2 }, last => { type => 'Loop', ref => 2 } },
         'Loop|2' => { id => 2, _dirty => true,
                       content => 'This is Loop 2',
                       next => { type => 'Loop', ref => 1 }, last => { type => 'Loop', ref => 1 } },
      }
   }

Loop 1 in the Twilight is NOT dirty as one may expect, because it was saved
automatically during silencing due to the referential structure.

Somewhere else in the program:

   {
      my $loop1n2 = $loop1->next();
      my $loop1l2 = $loop1->last();

      my $loop2n1 = $loop2->next();
      my $loop2l1 = $loop2->last();
   }

gives us the structures:

   Loop=HASH(300)         ( = $loop1n2 )
   {
      id       => 2,
      asylum   => Asylum=HASH(666),
      _status  => "exists",
   }

   Loop=HASH(400)         ( = $loop1l2 )
   {
      id       => 2,
      asylum   => Asylum=HASH(666),
      _status  => "exists",
   }

   Loop=HASH(500)         ( = $loop2n1 )
   {
      id       => 1,
      asylum   => Asylum=HASH(666),
      _status  => "exists",
   }

   Loop=HASH(600)         ( = $loop2l1 )
   {
      id       => 1,
      asylum   => Asylum=HASH(666),
      _status  => "exists",
   }

The Twilight has not changed:

   Asylum=HASH(666)
   {
      twilight => Twilight=HASH(42)
      {
         'Loop|1' => { id => 1, _dirty => false,
                       content => 'This is Loop 1',
                       next => { type => 'Loop', ref => 2 }, last => { type => 'Loop', ref => 2 } },
         'Loop|2' => { id => 2, _dirty => true,
                       content => 'This is Loop 2',
                       next => { type => 'Loop', ref => 1 }, last => { type => 'Loop', ref => 1 } },
      }
   }

But we got new instances:

   Loop=HASH(300) != Loop=HASH(200)
   Loop=HASH(400) != Loop=HASH(200)
   Loop=HASH(500) != Loop=HASH(100)
   Loop=HASH(600) != Loop=HASH(100)

Continuing the program:

   my $loop3   = Loop->new ( asylum => $asylum, id => 3, content => 'This is Loop 3' );

   $loop1->add_next ( $loop3 );
   $loop3->add_next ( $loop2 );

gives us the structures:

   Loop=HASH(333)         ( = $loop3 )
   {
      id       => 3,
      asylum   => Asylum=HASH(666),
      _status  => "missing",
   }

   Asylum=HASH(666)
   {
      twilight => Twilight=HASH(42)
      {
         'Loop|1' => { id => 1, _dirty => true,
                       content => 'This is Loop 1',
                       next => { type => 'Loop', ref => 3 }, last => { type => 'Loop', ref => 2 } },
         'Loop|2' => { id => 2, _dirty => false,
                       content => 'This is Loop 2',
                       next => { type => 'Loop', ref => 1 }, last => { type => 'Loop', ref => 3 } },
         'Loop|3' => { id => 3, _dirty => true,
                       content => 'This is Loop 3',
                       next => { type => 'Loop', ref => 2 }, last => { type => 'Loop', ref => 1 } },
      }
   }

Now Loop 2 in the Twilight is NOT dirty, but the others. Which Locum
was automatically saved depends on the order of entering the
referential structure - adding to $loop3 first i.e.:

   $loop3->add_next ( $loop2 );
   $loop1->add_next ( $loop3 );

would yield:

   Asylum=HASH(666)
   {
      twilight => Twilight=HASH(42)
      {
         'Loop|1' => { id => 1, _dirty => true,
                       content => 'This is Loop 1',
                       next => { type => 'Loop', ref => 3 }, last => { type => 'Loop', ref => 2 } },
         'Loop|2' => { id => 2, _dirty => false,
                       content => 'This is Loop 2',
                       next => { type => 'Loop', ref => 1 }, last => { type => 'Loop', ref => 3 } },
         'Loop|3' => { id => 3, _dirty => false,
                       content => 'This is Loop 3',
                       next => { type => 'Loop', ref => 2 }, last => { type => 'Loop', ref => 1 } },
      }
   }

But this doesn't matter, as long as you always close the Asylum. This
will auto-save all remaining dirty Loops:

   $asylum->close();

What the user wanted:

   #   ===>   next
   #   --->   last
   #
   #   +---------+     +---------+     +---------+
   #   |         |====>|         |====>|         |
   #   |         |<----|         |<----|         |
   #   | Loop(1) |     | Loop(3) |     | Loop(2) |
   #   |         |     |         |     |         |
   #   |         |     |         |     |         |
   #   |         |     |         |     |         |
   #   |         |     |         |     |         |
   #   |         |     +---------+     |         |
   #   |         |-------------------->|         |
   #   |         |<====================|         |
   #   +---------+                     +---------+

could easily be reloaded - in another script the next day just say:

   my $loop3 = Loop->new ( id => 3, asylum => $asylum );

   print $loop3->content;               #   'This is Loop 3'

   print $loop3->last->content;         #   'This is Loop 1'
   print $loop3->next->content;         #   'This is Loop 2'
   print $loop3->next->next->content;   #   'This is Loop 1'
   print $loop3->last->next->content;   #   'This is Loop 3'


=head2 My friend Jack eats sugar lumps - more fun with attributes

Frost comes with six new features extending L<Moose::Meta::Attribute>.

They provide some sugar to deal with the location of an attribute,
to save some typing and to create indices.

So migrating from a SQL database to an object-oriented storage is
possible without loosing one of the main features of a relational
database: indexing.

=over 4

=item transient

   has foo => ( transient => true, ... );

A C<transient> attribute lives at run-time and is B<"local"> :

It B<becomes undef>, when the Locum object goes B<out of scope>, and it's B<not saved>.

=item virtual

   has bar => ( virtual => true, ... );

A C<virtual> attribute lives at run-time and is B<"global"> :

It's B<still present>, when the Locum object goes B<out of scope>, but it's B<not saved>.

=item derived

   has dat => ( derived => true, ... );

A C<derived> attribute lives at run-time and is B<"global"> :

It's B<still present>, when the Locum object goes B<out of scope>, but it's B<not saved>.

   # The definition:

   has dat => ( derived => true, isa => 'Str' );

   # is a shortcut for:

   has dat => ( virtual => true, isa => 'Str', is => 'ro', init_arg => undef, lazy_build => true );

   # which becomes:

   has dat =>
   (
      virtual   => true,          # from derived
      is        => 'ro',          #
      init_arg  => undef,         #
      isa       => 'Str',
      lazy      => true,          # from lazy_build
      builder   => '_build_dat',  #
      clearer   => 'clear_dat',   #
      predicate => 'has_dat',     #
   );

   # and requires:

   sub _build_dat { ... }

=item index

   package Foo;
   ...
   has foo => ( index => true, ... );
   has bar => ( index => 'unique', ... );

This creates a multiple or unique index
(L<Frost::Illuminator>) of the attribute values. Numeric sorting is automatically
determined from the attribute's C<isa>.

Thus, if you create objects with following attributes:

   { id => 'id1', foo => 'foo1', bar => 'bar1' }
   { id => 'id2', foo => 'foo2', bar => 'bar2' }
   { id => 'id3', foo => 'foo3', bar => 'bar3' }
   { id => 'id4', foo => 'foo3', bar => 'bar2' }
   { id => 'id5', foo => 'foo1', bar => 'bar3' }

you'll get two indices:

   foo1 -> id1
   foo1 -> id5
   foo2 -> id2
   foo3 -> id3
   foo3 -> id4

   bar1 -> id1
           id2 silently eaten...
           id3 silently eaten...
   bar2 -> id4
   bar3 -> id5

Later you can search in the unique index:

   my $id  = $asylum->find ( 'Foo', 'bar3', 'bar' );   # class, key, attribute_name

   #  $id is 'id5'

   my $foo = Foo->new ( id => $id, asylum => $asylum );

or iterate over the multiple index:

   my $id  = $asylum->first ( 'Foo', 'foo1', 'foo' );  # class, key, attribute_name

   while ( $id )
   #  1st loop: $id is 'id1'
   #  2nd loop: $id is 'id5'
   #  3rd loop: $id is ''
   {
      my $foo = Foo->new ( id => $id, asylum => $asylum );

      $id   = $asylum->next ( 'Foo', 'foo1', 'foo' );
   }

and much more - see L<Frost::Asylum>.

=item auto_id

   has id  => ( auto_id => true, ... );
   has +id => ( auto_id => true, ... );

If the basic attribute B<id> is sweetened with C<auto_id>, the instance
is automatically assigned a UUID - see L<Data::UUID>.

The resulting B<id> is something like C<ECDAEFD4-9247-11DE-9343-7794CBAD412D>.

=item auto_inc

   has id  => ( auto_inc => true, ... );
   has +id => ( auto_inc => true, ... );

If the basic attribute B<id> is sweetened with C<auto_inc>, the
instance is automatically assigned a sequential number: I<highest used
id> + 1, where I<highest used id> = 0 in an empty cemetery.

=back

See L<Frost::Meta::Attribute>

=head1 The Four Commandments of Frost

=head2 Thou shalt absolve no other Moose before Locum

Frost can only store L<Moose> objects, more precisely: objects inheriting
from L<Frost::Locum>.

This does not mean, that each of your old classes must now use
Frost instead of L<Moose>. Migrating is easily possible by
creating or changing a base class from C<use Moose> to C<use
Frost> - i.e.

   package My::BaseFoo;
   # use Moose;
   use Frost;

   no Frost;
   __PACKAGE__->meta->make_immutable();   #  mutable is VERBOTEN

   package My::Foo;
   use Moose;
   extends 'My::BaseFoo';

   has my_attr      => ( ... );

   no Moose;
   __PACKAGE__->meta->make_immutable();   #  mutable is VERBOTEN

Thus My::Foo and all inheriting classes can be defined the usual L<Moose>
way. The class My::BaseFoo inherits from Frost::Locum, pulling
in all its persistence stuff.

=head2 Thou shalt honor immutability

While applying L<Moose>' tests for Frost it appeared, that reblessing an
object - i.e. because of applying a role at run-time - creates mutable
objects blessed in an anonymous class. This destroys the silence/evoke
mechanism, which depends on the real classname.

So reblessing as well as make_mutable is VERBOTEN.

=head2 Thou shalt not weaken thy reference

Due to Frost's proxy algorithm there is no need for weak references.
See L</MOTIVATION>.

=head2 Thou shalt not create or load objects without an id and thy asylum

To create a new frostable object you must always say:

   my $foo = Foo->new ( id => 'a_unique_id', asylum => $asylum, an_attr => ..., another_attr => ... );

   $remembered_id   = $foo->id;

And to reload a frosted object just say:

   my $foo = Foo->new ( id => $remembered_id, asylum => $asylum );   #   other params ignored

Or use the Asylum API - a matter of taste:

   my $remembered_id   = 'a_unique_id';

   my $foo = $asylum->silence ( 'Foo', $remembered_id, an_attr => ..., another_attr => ... );

   # later...

   my $foo = $asylum->evoke ( 'Foo', $remembered_id );   #   other params ignored

If the C<id> is defined with C<auto_id> or C<auto_inc>, Asylum is creating a mantra for you - i.e.:

   package Bar;
   ...
   has id ( auto_id => 1 );
   ...

   # Create and silence without id:
   #
   my $bar    = Bar->new ( asylum => $asylum, an_attr => ..., another_attr => ... );

   my $bar_id = $bar->id;   # something like ECDAEFD4-9247-11DE-9343-7794CBAD412D

   # Evoke with id:
   #
   my $bar    = Bar->new ( id => $bar_id, asylum => $asylum );

=head1 TODO

Docs, docs, docs...

=head1 GETTING HELP

I'm reading the L<Moose> mailing list frequently, so please ask your
questions there.

The mailing list is L<moose@perl.org>. You must be subscribed to send
a message. To subscribe, send an empty message to
L<moose-subscribe@perl.org>

=head1 DEPENDENCIES

This module requires these other modules and libraries:

	BerkeleyDB
	Carp
	Class::MOP
	Data::Dumper
	Data::UUID
	Exporter
	Fcntl
	File::Path
	IO::File
	Log::Log4perl
	Moose
	Scalar::Util
	Storable
	Tie::Cache::LRU
	Time::HiRes

For testing these modules are needed:

	DateTime::Format::MySQL
	List::Util
	List::MoreUtils
	Test::Deep
	Test::Differences
	Test::Exception
	Test::More
	Test::Requires

Optional modules to run some tests:

	Devel::Size
	Sys::MemInfo
	Declare::Constraints::Simple
	Regexp::Common
	Locale::US

Please see Makefile.PL for required versions.

=head1 BUGS

All complex software has bugs lurking in it, and this module is no
exception.

Please report any bugs to me or the mailing list.

=head1 AUTHOR

Ernesto L<ernesto@dienstleistung-kultur.de>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2010 by Dienstleistung Kultur Ltd. & Co. KG

L<http://dienstleistung-kultur.de/frost/>

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut


