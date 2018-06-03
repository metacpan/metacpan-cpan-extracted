#   Dot - The beginning of a Perl universe
#   Copyright © 2018 Yang Bo
#
#   This program is free software: you can redistribute it and/or modify
#   it under the terms of the GNU General Public License as published by
#   the Free Software Foundation, either version 3 of the License, or
#   (at your option) any later version.
#
#   This program is distributed in the hope that it will be useful,
#   but WITHOUT ANY WARRANTY; without even the implied warranty of
#   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#   GNU General Public License for more details.
#
#   You should have received a copy of the GNU General Public License
#   along with this program.  If not, see <https://www.gnu.org/licenses/>.

package Dot;

our $VERSION = 'v1.0.1';

use strict;
use warnings qw/all FATAL uninitialized/;
use feature qw/state say/;

BEGIN {
	no strict 'refs';
	my @H = ($^H, ${^WARNING_BITS}, %^H);
	sub import {
		my $ns = caller . '::';
		shift;
		while (@_) {
			my $q = shift;
			if ($q eq 'iautoload') {
				my (@pkg, %map, @l);
				for (@{+shift}) {
					my ($p, @f) = ref() ? @$_ : $_;
					push @pkg, $p;
					for (@f) {
						push @l, $ns . $_ if s/^0//;
						$map{$_} = $p;
					}
				}
				my $i = 1;
				*{$ns . 'AUTOLOAD'} = sub {
					# "fully qualified name of the original subroutine".
					my $q = our $AUTOLOAD;
					# to avoid possibly overwrite @_ by successful regular expression match.
					my ($f) = do { $q =~ /.*::(.*)/ };
					for my $p ($map{$f} || @pkg) {
						#   calculate the actual file to be loaded thus avoid eval and
						# checking $@ mannually.
						my $r = do { $p =~ s|::|/|gr . '.pm' };
						require $r if not $INC{$r};
						if (my $r = *{"${p}::$f"}{CODE}) {
							no warnings 'prototype';
							*$q = $r;
							# TODO: understand why using goto will lost context.
							#goto &$r;
							return $i ? undef : &$r;
						}
					}
					confess("unable to autoload $q.");
				};
				$_->() for @l;
				$i = 0;
			} elsif ($q eq 'oautoload') {
				for my $p (@{+shift}) {
					my $r = $p =~ s|::|/|gr . '.pm';
					# ignore already loaded module.
					my $f = "${p}::AUTOLOAD";
					next if $INC{$r} or *$f{CODE};
					*$f = sub {
						my ($f) = do { our $AUTOLOAD =~ /.*::(.*)/ };
						my $symtab = *{"${p}::"}{HASH};
						delete $symtab->{AUTOLOAD};
						require $r;
						&{$symtab->{$f}};
					};
				}
			} elsif ($q eq 'sane') {
				($^H, ${^WARNING_BITS}, %^H) = @H;
			} else {
				confess("unknown request $q");
			}
		}
	}
}
Dot->import(iautoload => [[qw/Scalar::Util weaken/],
			  [qw/Carp confess/]]);
sub add {
	my $o = shift;
	while (@_) {
		my ($k, $v) = splice @_, 0, 2;
		$o->{$k} = $v;
	}
}
sub mod {
	my $o = shift;
	weaken($o);
	add($o,
	    weaken => \&weaken,
	    add => sub {
		    unshift @_, $o;
		    goto &add;
	    },
	    del => sub {
		    map { $_ => delete $o->{$_} } @_;
	    });
	$o;
}
1;
__END__

=head1 NAME

Dot - The beginning of a Perl universe

=head1 SYNOPSIS

There's no synopsis since while there is indeed some code in C<Dot>, it's
for convenience only and not mandatory at all, you don't even have to install
this module and then say C<use Dot;> to use C<Dot>, you could just use it
(after reading this documentation). So providing a synopsis here would change
the focus on the wrong subject, so I decided not to.

=head1 DESCRIPTION

C<Dot> is an object system, where an object is a hash, a method is a closure,
and a class is a
subroutine. An object always starts as nothing, i.e. C<{}>, and it could
then be modified by one or more classes at any time by adding/removing/modifying
methods to/from/inside it, with their lexical
environment behind the scene, when they're called (C<< $obj->{method}(@arg) >>)
they automatically
know to which object they're bind, on which data they should operate,
so C<this> or C<self> is not needed, and anything that's not intended to
be public could reside in its own lexical scope, in other words each
method minds its own business at its own place, and yet methods of the same class could also
cooperate by closing over the same data, and all the methods of an object
could cooperate by closing over the object itself. It's a perfect
demonstration of encapsulation, since no coordination is needed between
each method on where to store its own data, in comparison to storing
everything inside the object itself, whenever you choose a place to store
something you have to make sure it's not used by any other method, one way
or the other, otherwise you could end up overwriting somebody else's data.

	sub class {
		my $obj = shift;
		# instance properties shared by all the methods of this class.
		my %limited;
		$obj->{method} = do {
			# instance properties that's only related to this method.
			my %secret;
			sub {
				# do something with %secret, %limited.
			};
		};
		$obj;
	}
	my $obj = class({});
	$obj->{method}(...);

Classes act like hash modifiers, although you could write a class so that it
always returns a brand new object, it's best to write it as a modifier since
then not only you can create a new object from it you could apply it
to an existing object as well, like C<my $obj = class3(class2(class1({})))>.
And that's just how multiple inheritance looks like (more on that later).
One situation that you should always keep in mind is when a method
closes over this object itself, like:

	sub class {
		my $obj = shift;
		$obj->{method1} = sub {
			# I need to access another public method called method0 of
			# this object, but oops, circular reference.
			$obj->{method0}(...);
		};
		$obj;
	}

You must say C<weaken(my $obj = shift)> when this happens, and C<weaken> (from
C<Scalar::Util>) is the only thing that's necessary (sometimes) to use C<Dot>,
everything else is optional, you don't even need C<Dot> itself.

=head2 Inheritance

In C<Dot>, when a class has been called to modify an object then this object
inherits from that class, and when a class calls another class to help it
modify an object then the former class inherits from the latter. And
multiple inheritance happens when more than one classes are called directly.
As you will see, inheritance in C<Dot> is pretty different, it's dividable,
trivial, efficient, at runtime and without ambiguity.

First, by using closures as methods, they do not belong to a package anymore,
they're per object and thus disposable, which is not possible at all
when using package as class since you could easily break other objects
of the same class if you delete methods at your will. And because of
this, the smallest unit of inheritance is not class but a single method
or attribute, since you could always inherit from a class and delete
every method and attribute it provides except the ones you want. That's
why we say inheritance is dividable in C<Dot>.

In addition to that, since methods are just closures, you don't need
to create a package and put a subroutine inside it and then setup the
inheritance and then re-bless the object in order to override or add a
new method to an object, all you need to do is a single assign statement:

	$obj->{method} = sub {
		# my new implementation.
	};

or in the case of a method modifier:

	$obj->{method} = do {
		my $old = $obj->{method};
		sub {
			# do something else, or not.
			&$old;
			# do something else, or not.
		};
	};

So inheritance is not necessarily changed by a class, it could be changed
by any statement that modifies the object (In a way that its current
inheritance does not anticipate). Inheritance of an object is just the summary of all
these modifications that's been applied to this object through its lifetime,
you could group these modifications and
turn them into one or multiple subroutines (i.e. classes), only when you feel convenient to
do so. And thus the triviality, it's literally that easy.
(Example: C<method-modifier.t>)

Also, since all the public methods are stored inside the object itself and
it's only a hash look up away to call them, and all
the private methods are accessed through the lexical environment enclosed,
method dispatching is not needed at all, which means inheritance is efficient
this way.

Inheritance in C<Dot> is not static but dynamically controllable at runtime,
since inheritance is just which subroutines a class chooses to call to help
itself, for example:

	sub class {
		my $obj = shift;
		if ($some_condition) {
			classA($obj);
		} elsif ($some_other_condition) {
			classB($obj);
			classC($obj);
		} else {
			classD($obj);
			classE($obj);
			classF($obj);
		}
		$obj;
	}

As shown by the previous class, the inheritance of the objects of the same class
could be different, and they wouldn't interfere with each other, since there's
no method dispatching.

Finally, the so called diamond problem is easily solved when using mulitple
inheritance, suppose you're creating a class that inherts another two classes
which both provide a method with the same name:

	sub class {
		my $obj = shift;
		# Inherit from class1.
		class1($obj);
		# Make a backup of the method this class provides since it will
		# be overwritten.
		my $method1 = $obj->{method};
		# Inherit from class2.
		class2($obj);
		# Implementation of the method from class2.
		my $method2 = $obj->{method};
		# Now you have all the options.
		$obj->{method} = $method1;
		$obj->{method} = $method2;
		$obj->{method} = sub {
			&$method1;
			&$method2;
		};
	}

As you can see, C<Dot> gives you the ability to be explicit, and you could
always get ambiguity out of the way with explicitness. (Example: C<mi-wo-diamond.t>)

=head2 Attribute

As for attributes, you could just use methods for them, if you don't buy
the always use methods for attributes since you could change the implementation
without breaking the interface argument, you could just store them inside
the object and access them directly, and tie them when more complex behavior
is desired. See C<attribute-method.t> and C<attribute-tie.t> respectively for
a detailed example.

=head2 Metaclass

Since in C<Dot>, a class is just a subroutine which modifies a hash, by consequence
a metaclass is just a subroutine which returns a subroutine which modifies
a hash, and thus really easy to create, for example:

	sub metaclass {
		my @classes = @_;
		sub {
			my $obj = shift;
			$_->($obj) for @classes;
			$obj;
		};
	}

This metaclass takes a list of classes as its argument and returns a new
class which inherits from them all. A metaclass does the same thing to a
class as what a class does to an object, it hides the details and provides
the simplest way for others to interact, just like when you call a method
you don't have to know what data structure it uses, what lexical environment
it resides, what other private methods it calls, when you call a class you
don't have to worry about whether it's created from a metaclass, if yes what
arguments are passed to it, what private variables it closes over, you only
have to know that it's a class and if you call it with an object as the
first argument it will modify this object according to its own definition.

As you have probably guessed, a metametaclass is just a subroutine which
returns a subroutine which returns a subroutine which modifies a hash,
it's just as easy to create, but it may be hard to find concrete uses
for it.

=head1 Dot

As mentioned previously, C<Dot> is an object system without code, but it
does provides two functionalities for convenience: a class named C<mod>
and an import subroutine to be C<use>d by other modules.

=head2 C<Dot::mod>

C<Dot::mod> is a C<Dot> class, we call it C<Dot> for short, it's convenient to always inherit from
it since it provides three methods that're used frequently:

=over 4

=item weaken

Not a method exactly, but as explained previously, C<weaken> is the only thing that's sometimes
necessary to use C<Dot>, thus it's important, so instead of loading
C<Scalar::Util> everywhere, C<Dot> exports it and when you have an object
that's been modified by C<Dot> you can just call C<weaken> using C<< $obj->{weaken}($obj) >>.

=item add

Add key-value pairs to this object so that they could be accessed publicly.
It just does hash assignment and entirely for readability purpose:

	$obj->{add}(... => ...,
		    ... => ...,
		    ...);

It's usually used to add a bunch of methods.

=item del

Delete from this object and return key-value pairs:

	# returns 'method1', $obj->{method1}, 'method2', $obj->{method2}...
	my %parent = $obj->{del}(qw/method1 method2 .../);
	$obj->{add}(method1 => sub {
			    # modifier time.
			    &{$parent{method1}};
			    # modifier time.
		    },
		    ...);

It's mostly used to delete a bunch of methods from a parent class and install
new methods that're modifiers of them.

=back

=head2 import

C<Dot> is designed to be the only module you ever have to C<use>, and every
other module is loaded by it when necessary. There're three requests that
it provides:

=over 4

=item sane

When you say C<use Dot 'sane';>, it's equivalent to say the following:

	use strict;
	use warnings qw/all FATAL uninitialized/;
	use feature qw/state say/;

That's also what C<Dot> uses itself, it exports this for convenience,
so that you can use this request if you happen to agree with this, instead of
typing those pragma all over the places.

=item C<iautoload>

C<iautoload> takes an array (reference) as its argument and installs an C<AUTOLOAD>
subroutine inside the caller's package. The array is just a specification
of all the modules in which C<Dot> should search when an undefined subroutine
is called in this package. In its simplest form, it's just a list of modules.
You can also specify from which module should a subroutine be loaded, by using
an array with the first element as the module's name and the rest as the names
of the subroutines that should be loaded from it, for example:

	use Dot iautoload => ['Module::A', [qw'Module::B sub1 sub2 sub3']];

Where undefined subroutines named C<sub1>, C<sub2> or C<sub3> will be loaded
from C<Module::B> only, others will first be attempted to be loaded from
C<Module::A>, then C<Module::B> if that fails, C<Dot> will throw an exception
if a subroutine couldn't be loaded anywhere.

If you prepend C<0> to a subroutine's name then C<Dot> will try to load it
at compile time. That's often useful if its prototype matters when compiling.

As mentioned earlier, C<Dot> is designed to be the only module you ever C<use>.
I never
C<use> other modules since I don't want my namespace polluted, and I
don't want every module loaded at compile time, since some modules may
only be needed occasionally, yet I also don't want add a C<require> statement
everytime I call a subroutine inside a module that's not always loaded.
You may have seen the following idiom many times:

	if ($something_bad_happens) {
		require Carp;
		Carp::confess('whatever');
	}
	...
	if ($something_bad_happens_elsewhere) {
		require Carp;
		Carp::confess('not again');
	}

And with C<Dot> you could just say:

	use Dot iautoload => ['Carp'];
	confess('whatever') if $something_bad_happens;
	...
	confess('not again') if $something_bad_happens_elsewhere;

where module loading is handled automatically and only when necessary.

C<iautoload> is used for conditional inheritance where classes of different
name are spread across multiple modules and thus included.

=item C<oautoload>

Like C<iautoload>, but instead of installing an C<AUTOLOAD> subroutine inside
the caller's package, C<oautoload> installs it inside the package of the
module to be loaded, for example:

	use Dot oautoload => [qw'ClassA ClassB ClassC'];
	sub class {
		my $obj = shift;
		if ($some_condition) {
			ClassA::mod($obj);
		} elsif ($some_other_condition) {
			ClassB::mod($obj);
		} else {
			ClassC::mod($obj);
		}
		$obj;
	}

i.e. the module is automatically loaded when you call a subroutine inside
its package, so that you never have do a mannual C<require>.

Since a class in C<Dot> never creates but always modifies an object, I always
use C<mod> (in comparison to C<new>) as its name (which means I cannot use
C<iautoload>), and as mentioned previously, inheritance in C<Dot> is a runtime
property, C<oautoload> is especially handy when handling conditional inheritance
where classes of the same name are spread across multiple modules and thus
included here.

=back

=head1 LICENSE

GPLv3.

=head1 AUTHOR

Yang Bo <rslovers@yandex.com>
