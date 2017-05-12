package JE::Object;

# This has to come before any pragmas and sub declarations.
sub evall { my $global = shift; my $r = eval 'local *_;' . shift;
            $@ and die; $r }

our $VERSION = '0.066';

use strict;
use warnings;

use overload fallback => 1,
	'%{}'=>  \&_get_tie,
	'""' => 'to_string',
        '0+' => 'to_number',
#	 cmp =>  sub { "$_[0]" cmp $_[1] },
	bool =>  sub { 1 };

use Scalar::Util qw'refaddr blessed';
use List::Util 'first';
use B 'svref_2object';
#use Data::Dumper;


require JE::Code;
require JE::Object::Error::TypeError;
require JE::Object::Function;
require JE::Boolean;
require JE::String;

import JE::Code 'add_line_number';
sub add_line_number;

sub in_list { 
	my $str = shift;
	shift eq $str and return 1 while @_;
	!1;
}


=head1 NAME

JE::Object - Base class for all JavaScript objects

=head1 SYNOPSIS

  use JE;
  use JE::Object;

  $j = new JE;

  $obj = new JE::Object $j;

  $obj->prop('property1', $new_value);  # sets the property
  $obj->prop('property1');              # returns $new_value;
  $obj->{property1} = $new_value;       # or use it as a hash
  $obj->{property1};                    # ref like this

  $obj->keys; # returns a list of the names of enumerable property
  keys %$obj;

  $obj->delete('property_name');
  delete $obj->{property_name};

  $obj->method('method_name', 'arg1', 'arg2');
    # calls a method with the given arguments

  $obj->value ;    # returns a value useful in Perl (a hashref)

  "$obj";  # "[object Object]" -- same as $obj->to_string->value
  0+$obj"; #  nan -- same as $obj->to_number->value
  # etc.

=head1 DESCRIPTION

This module implements JavaScript objects for JE.  It serves as a base
class
for all other JavaScript objects.

A JavaScript object is an associative array, the elements of which are
its properties.  A method is a property that happens to be an instance
of the
C<Function> class (C<JE::Object::Function>).

JE::Object objects can be used in Perl as a number, string or boolean.  The 
result will be the same as in JavaScript.  The C<%{}> (hashref) operator is 
also overloaded and returns a hash that can be used to modify the object.
See L<"USING AN OBJECT AS A HASH">.

See also L<JE::Types> for descriptions of most of the methods.  Only what
is specific to JE::Object is explained here.

=head1 METHODS

=over 4

=item $obj = JE::Object->new( $global_obj )

=item $obj = JE::Object->new( $global_obj, $value )

=item $obj = JE::Object->new( $global_obj, \%options )

This class method constructs and returns a new JavaScript object, unless 
C<$value> is
already a JS object, in which case it just returns it.  The behaviour is
the
same as the C<Object> constructor in JavaScript.

The C<%options> are as follows:

  prototype  the object to be used as the prototype for this
             object (Object.prototype is the default)
  value      the value to be turned into an object

C<prototype> only applies when C<value> is omitted, undef, undefined
or null.

To convert a hash into an object, you can use the hash ref syntax like
this:

  new JE::Object $j, { value => \%hash }

Though it may be easier to write:

  $j->upgrade(\%hash)

The former is what C<upgrade> itself uses.

=cut

# ~~~ Perhaps I should eliminate the hash ref syntax and have new()
#     check to see if $j->exists($class->class), and use that as the
#     prototype. That would make the other constructors simpler, but would
#     it make it harder to control JE and customise host objects?

sub new {
	my($class, $global, $value) = @_;

	if (defined blessed $value
	    and can $value 'to_object') {
		return to_object $value;
	}
	
	my $p;
	my %hash;
	my %opts;

	ref $value eq 'HASH' and (%opts = %$value), $value = $opts{value};
	
	local $@;
	if (!defined $value || !defined eval{$value->value} && $@ eq '') {
		$p = exists $opts{prototype} ? $opts{prototype}
		      : $global->prototype_for("Object");
	}
	elsif(ref $value eq 'HASH') {
		%hash = %$value;
		$p = $global->prototype_for("Object");
	}
	else {
		return $global->upgrade($value);
	}

	my $self =
	bless \{ prototype => $p,
	         global    => $global,
	         props     => \%hash,
	         keys      => [keys %hash]  }, $class;

	$JE::Destroyer && JE::Destroyer'register($self);

	$self;
}

sub destroy { # not DESTROY; called by JE::Destroyer
 undef ${$_[0]};
}


=item $obj->new_function($name, sub { ... })

=item $obj->new_function(sub { ... })

This creates and returns a new function object.  If $name is given,
it will become a property of the object.  The function is enumerable, like
C<alert> I<et al.> in web browsers.

For more ways to create functions, see L<JE::Object::Function>.

=cut

sub new_function {
	my $self = shift;
	my $f = JE::Object::Function->new({
		scope   => $self->global,
		function   => pop,
		function_args => ['args'],
		@_ ? (name => $_[0]) : ()
	});
	@_ and $self->prop({
		name => shift,
		value=>$f,
	});
	$f;
}




=item $obj->new_method($name, sub { ... })

=item $obj->new_method(sub { ... })

This is the same as C<new_function>, except that the subroutine's first
argument will be the object with which the function is called, and that the 
property created will not be enumerable.  This allows one to add methods to
C<Object.prototype>, for instance, without making every for-in loop list
that method.

For more ways to create functions, see L<JE::Object::Function>.

=cut

sub new_method {
	my $self = shift;
	my $f = JE::Object::Function->new({
		scope   => $self->global,
		function   => pop,
		function_args => ['this','args'],
		@_ ? (name => $_[0]) : ()
	});
	@_ and $self->prop({
		name => shift,
		value=>$f,
		dontenum=>1
	});
	$f;
}

=item $obj->prop( $name )

=item $obj->prop( $name => $value )

=item $obj->prop({ ... })

See C<JE::Types> for the first two uses.

When the C<prop> method is called with a hash ref as its argument, the 
prototype chain is I<not> searched.
The elements of the hash are as follows:

  name      property name
  value     new value
  dontenum  whether this property is unenumerable
  dontdel   whether this property is undeletable
  readonly  whether this property is read-only
  fetch     subroutine called when the property is fetched
  store     subroutine called when the property is set
  autoload  see below

If C<dontenum>, C<dontdel> or C<readonly> is given, the attribute in 
question will be set.
If C<value> is given, the value of the property will be set, regardless of
the attributes.

C<fetch> and C<store>, if specified, must be subroutines for
fetching/setting the value of the property.  The 'fetch' subroutine will be
called with ($object, $storage_space) as the arguments, where
C<$storage_space> is a hash key inside the object that the two subroutines
can use for storing the value (they can ignore it if they like).  The
'store' subroutine will be call with
($object, $new_value, $storage_space) as
the arguments.  Values assigned to the storage space from within these 
routines are I<not>
upgraded, neither is the return value of C<fetch>. C<fetch> and C<store> do 
not necessarily have to go
together.  If you only specify C<fetch>, then the value will be set as
usual, but C<fetch> will be able to mangle the value when it is retrieved.
Likewise, if you only specify C<store>, the value will be retrieved the
usual way, so you can use this for validating or normalising the assigned
value, for
instance.  B<Note:> Currently, a simple scalar or unblessed coderef in the
storage space will cause autoloading, but that is subject to change.

C<autoload> can be a string or a coderef.  It will be called/evalled the
first time the property is accessed (accessing it with a hash ref as
described here does not count). If it is a string, it will be
evaluated in the calling package (see warning below), in a scope that has a 
variable named
C<$global> that refers to the global object. The result will become the
property's value.  The value returned is not currently upgraded.  The behaviour when a simple scalar or unblessed reference is returned is
undefined.  C<autoload> will be
ignored completely if C<value> or C<fetch> is also given.  B<Warning:> The
'calling package' may not be what you think it is if a subclass overrides
C<prop>.  It may be the subclass in such cases.  To be on the safe side,
always begin the string of code with an explicit C<package> statement.  (If
anyone knows of a clean solution to this, please let the author know.)

This hash ref calling convention does not work on Array
objects when the property name is C<length> or an array index (a 
non-negative integer 
below
4294967295).  It does not work on String objects if the
property name is C<length>.

=cut

sub prop {
	my ($self, $opts) = (shift, shift);
	my $guts = $$self;

	if(ref $opts eq 'HASH') { # special use
		my $name = $$opts{name};
		for (qw< dontdel readonly >) {
			exists $$opts{$_}
				and $$guts{"prop_$_"}{$name} = $$opts{$_};
		}

		my $props = $$guts{props};

		my $dontenum;
		if(exists $$opts{dontenum}) {
			if($$opts{dontenum}) {
				@{$$guts{keys}} = 
					grep $_ ne $name, @{$$guts{keys}};
			}
			else {
				push @{ $$guts{keys} }, $name
			    	unless first {$_ eq $name} @{$$guts{keys}};
			}
		}
		elsif(!exists $$props{$name}) { # new property
			push @{ $$guts{keys} }, $name
		}

		if(exists $$opts{fetch}) {
			$$guts{fetch_handler}{$name} = $$opts{fetch};
			$$props{$name} = undef if !exists $$props{$name};
		}
		if(exists $$opts{store}) {
			$$guts{store_handler}{$name} = $$opts{store};
			$$props{$name} = undef if !exists $$props{$name};
		}
		if(exists $$opts{value}) {
			return $$props{$name} = $$opts{value};
		}
		elsif(!exists $$opts{fetch} && exists $$opts{autoload}) {
			my $auto = $$opts{autoload};
			$$props{$name} = ref $auto eq 'CODE' ? $auto :
				"package " . caller() . "; $auto";
			return # ~~~ Figure out what this should
			       #     return, if anything
		}

		# ~~~ what should we return if fetch is given,
		#     but not value?

		return exists $$opts{fetch} ? () :
		       exists $$props{$name} ? $$props{$name} : undef;
	}

	else { # normal use
		my $name = $opts;
		my $props = $$guts{props};
		if (@_) { # we is doing a assignment
			my($new_val) = shift;

			return $new_val if $self->is_readonly($name);

			# Make sure we don't change attributes if the
			# property already exists
			my $exists = exists $$props{$name} &&
				defined $$props{$name};

			exists $$guts{store_handler}{$name}
			? $$guts{store_handler}{$name}->(
				$self, $new_val, $$props{$name})
			: ($$props{$name} = $new_val);

			push @{ $$guts{keys} }, $name
			    unless $exists; 

			return $new_val;
		}
		elsif (exists $$props{$name}) {
			if(exists $$guts{fetch_handler}{$name}) {
				return $$guts{fetch_handler}{$name}-> (
					$self, $$props{$name}
				);
			}

			my $val = $$props{$name};
			ref $val eq 'CODE' ?
				$val = $$props{$name} = &$val() :
			defined $val && ref $val eq '' &&
				($val = $$props{$name} =
					evall $$guts{global}, $val
				);
			return $val;
		}
		else {
			my $proto = $self->prototype;
			return $proto ?
				$proto->prop($name) :
				undef;
		}	
	}

}


sub exists { # = hasOwnProperty
	my($self,$name) = @_;
	return exists $$$self{props}{$name}
}


sub is_readonly { # See JE::Types for a description of this.
	my ($self,$name) = (shift,@_);  # leave $name in @_

	my $guts = $$self;

	my $props = $$guts{props};
	if( exists $$props{$name}) {
		my $read_only_list = $$guts{prop_readonly};
		return exists $$read_only_list{$name} ?
			$$read_only_list{$name} : !1;
	}

	if(my $proto = $self->prototype) {
		return $proto->is_readonly(@_);
	}

	return !1;
}




sub is_enum {
	my ($self, $name) = @_;
	$self = $$self;
	in_list $name, @{ $$self{keys} };
}




sub keys {
	my $self = shift;
	my $proto = $self->prototype;
	@{ $$self->{keys} }, defined $proto ? $proto->keys : ();
}




=item $obj->delete($property_name, $even_if_it's_undeletable)

Deletes the property named $name, if it is deletable.  If the property did 
not exist or it was deletable, then
true is returned.  If the property exists and could not be deleted, false
is returned.

If the second argument is given and is true, the property will be deleted
even if it is marked is undeletable.  A subclass may override this,
however.
For instance, Array and String objects always have a 'length' property
which cannot be deleted.

=cut

sub delete {
	my ($self, $name) = @_;
	my $guts = $$self;

	unless($_[2]) { # second arg means always delete
		my $dontdel_list = $$guts{prop_dontdel};
		exists $$dontdel_list{$name} and $$dontdel_list{$name}
			and return !1;
	}
	
	delete $$guts{prop_dontdel }{$name};
	delete $$guts{prop_dontenum}{$name};
	delete $$guts{prop_readonly}{$name};
	delete $$guts{props}{$name};
	$$guts{keys} = [ grep $_ ne $name, @{$$guts{keys}} ];
	return 1;
}




sub method {
	my($self,$method) = (shift,shift);

	$self->prop($method)->apply($self, $self->global->upgrade(@_));
}

=item $obj->typeof

This returns the string 'object'.

=cut

sub typeof { 'object' }




=item $obj->class

Returns the string 'Object'.

=cut

sub class { 'Object' }




=item $obj->value

This returns a hash ref of the object's enumerable properties.  This is a 
copy of the object's properties.  Modifying it does not modify the object
itself.

=cut

sub value {
	my $self = shift;
	+{ map +($_ => $self->prop($_)), $self->keys };
}

*TO_JSON=*value;




sub id {
	refaddr shift;
}

sub primitive { !1 };

sub prototype {
	@_ > 1 ? (${+shift}->{prototype} = $_[1]) : ${+shift}->{prototype};
}




sub to_primitive {
	my($self, $hint) = @_;

	my @methods = ('valueOf','toString');
	defined $hint && $hint eq 'string' and @methods = reverse @methods;

	my $method; my $prim;
	for (@methods) {
		defined($method = $self->prop($_)) || next;
		($prim = $method->apply($self))->primitive || next;
		return $prim;
	}

	die new JE::Object::Error::TypeError $self->global,
	  add_line_number "An object of type " .
		(eval {$self->class} || ref $self) .
		" cannot be converted to a primitive";
}




sub to_boolean { 
	JE::Boolean->new( $${+shift}{global}, 1 );
}

sub to_string {
	shift->to_primitive('string')->to_string;
}


sub to_number {
	shift->to_primitive('number')->to_number;
}

sub to_object { $_[0] }

sub global { ${+shift}->{global} }

=back

=cut




#----------- PRIIVATE ROUTIES ---------------#

# _init_proto takes the Object prototype (Object.prototype) as its sole
# arg and adds all the default properties thereto.

sub _init_proto {
	my $proto = shift;
	my $global = $$proto->{global};

	# E 15.2.4

	$proto->prop({
		dontenum => 1,
		name => 'constructor',
		value => $global->prop('Object'),
	});

	my $toString_sub = sub {
		my $self = shift;
		JE::String->new($global,
			'[object ' . $self->class . ']');
	};

	$proto->prop({
		name      => 'toString',
		value     => JE::Object::Function->new({
			scope    => $global,
			name     => 'toString',
			length   => 0,
			function_args => ['this'],
			function => $toString_sub,
			no_proto => 1,
		}),
		dontenum  => 1,
	});

	$proto->prop({
		name      => 'toLocaleString',
		value     => JE::Object::Function->new({
			scope    => $global,
			name     => 'toLocaleString',
			length   => 0,
			function_args => ['this'],
			function => sub { shift->method('toString') },
			no_proto => 1,
		}),
		dontenum  => 1,
	});

	$proto->prop({
		name      => 'valueOf',
		value     => JE::Object::Function->new({
			scope    => $global,
			name     => 'valueOf',
			length   => 0,
			function_args => ['this'],
			function => sub { $_[0] },
			no_proto => 1,
		}),
		dontenum  => 1,
	});

	$proto->prop({
		name      => 'hasOwnProperty',
		value     => JE::Object::Function->new({
			scope    => $global,
			name     => 'hasOwnProperty',
			argnames => ['V'],
			function_args => ['this', 'args'],
			function => sub {
				JE::Boolean->new($global, 
				    shift->exists(
				        defined $_[0] ? $_[0] : 'undefined'
				    )
				);
			},
			no_proto => 1,
		}),
		dontenum  => 1,
	});

	$proto->prop({
		name      => 'isPrototypeOf',
		value     => JE::Object::Function->new({
			scope    => $global,
			name     => 'isPrototypeOf',
			argnames => ['V'],
			function_args => ['this', 'args'],
			function => sub {
				my ($self, $obj) = @_;

				!defined $obj || $obj->primitive and return 
					JE::Boolean->new($global, 0);

				my $id = $self->id;
				my $proto = $obj;

				while (defined($proto = $proto->prototype))
				{
					$proto->id eq $id and return
					    JE::Boolean->new($global, 1);
				}

				return JE::Boolean->new($global, 0);
			},
			no_proto => 1,
		}),
		dontenum  => 1,
	});

	$proto->prop({
		name      => 'propertyIsEnumerable',
		value     => JE::Object::Function->new({
			scope    => $global,
			name     => 'propertyIsEnumerable',
			argnames => ['V'],
			function_args => ['this', 'args'],
			function => sub {	
				return JE::Boolean->new($global,
				    shift->is_enum(
				        defined $_[0] ? $_[0] : 'undefined'
				    )
				);
			},
			no_proto => 1,
		}),
		dontenum  => 1,
	});
}



#----------- TYING MAGIC ---------------#

# I'm putting the object itself behind the tied hash, so that no new object
# has to be created.
# That means that tied %$obj returns $obj.


sub _get_tie {
	my $self = shift;
	my $guts = $$self;
	$$guts{tie} or tie %{ $$guts{tie} }, __PACKAGE__, $self;	
	$$guts{tie};
}

sub TIEHASH  { $_[1] }
sub FETCH    { $_[0]->prop($_[1]) }
sub STORE    {
	my($self, $key, $val) = @_;
	my $global = $self->global;
	if(ref $val eq 'HASH' && !blessed $val
  	   && !%$val && svref_2object($val)->REFCNT == 2) {
		$val = tie %$val, __PACKAGE__, __PACKAGE__->new(
			$global);
	} elsif (ref $val eq 'ARRAY' && !blessed $val && !@$val && 
	         svref_2object($val)->REFCNT == 2) {
		require JE::Object::Array;
		$val = tie @$val, 'JE::Object::Array',
			JE::Object::Array->new($global);
	}
	$self->prop($key => $global->upgrade($val))
}
#sub CLEAR   {  }
	# ~~~ have yet to implement this
sub DELETE   {
	my $val = $_[0]->prop($_[1]);
	$_[0]->delete($_[1]);
	$val;
}
sub EXISTS   { $_[0]->exists($_[1]) }
sub FIRSTKEY { ($_[0]->keys)[0] }
sub NEXTKEY  {
	my @keys = $_[0]->keys;
	my $last = $_[1];
	for (0..$#keys) {
		if ($last eq $keys[$_]) {
			return $keys[$_+1]
		}
	}

	# ~~~ What *should* we do if the property has been
	#     deleted?
	# I think this means the iterator should have been reset (from the
	# user's point of view), so we'll start from the beginning.

	return $keys[0];
}

sub DDS_freeze { my $self = shift; delete $$$self{tie}; $self }


#----------- THE REST OF THE DOCUMENTATION ---------------#

=head1 USING AN OBJECT AS A HASH

Note first of all that C<\%$obj> is I<not> the same as C<< $obj->value >>.
The C<value> method creates a new hash containing just the enumerable
properties of the object and its prototypes.  It's just a plain hash--no
ties, no magic.  C<%$obj>, on the other hand, is another creature...

C<%$obj> returns a magic hash which only lists enumerable properties
when you write C<keys %$obj>, but still provides access to the rest.

Using C<exists> on this hash will check to see whether it is the object's
I<own> property, and not a prototype's.

Assignment to the hash itself currently
throws an error:

  %$obj = (); # no good!

This is simply because I have not yet figured out what it should do.  If
anyone has any ideas, please let me know.

Autovivification works, so you can write

  $obj->{a}{b} = 3;

and the 'a' element will be created if did not already exist.  Note that,
if the property C<did> exist but was undefined (from JS's point of view),
this throws an error.

=begin paranoia

One potential problem with this is that, when perl autovivifies in the 
example
above, it first calls C<FETCH> and, when it sees that the result is not
defined, then calls C<STORE> with C<{}> as the value.  It then uses that
same hash that it passed to C<STORE>, and does I<not> make a second call to
C<FETCH>.  This means that, for autovivification to work, the empty hash
that perl automatically assigns has to be tied to the new JE::Object that
is created.  Now, the same sequence of calls to tie 
handlers can be triggered by the following lines:

  my %h;
  $obj->{a};
  $h{b} = 3;

And, of course, you don't want your %h hash transmogrified and tied to a 
JE::Object, do you?  (Normally
hashes and arrays are copied by STORE.)  So the only feasible way (I can 
think of) to
make the distinction is to use reference counts (which is what I'm using), 
but I don't know whether they will change
between versions of Perl.

=end paranoia

=head1 INNARDS

Each C<JE::Object> instance is a blessed reference to a hash ref.  The 
contents of the hash
are as follows:

  $$self->{global}         a reference to the global object
  $$self->{props}          a hash ref of properties, the values being
                           JavaScript objects
  $$self->{prop_readonly}  a hash ref with property names for the keys
                           and booleans  (that indicate  whether  prop-
                           erties are read-only) for the values
  $$self->{prop_dontdel}   a hash ref in the same format as
                           prop_readonly that indicates whether proper-
                           ties are undeletable
  $$self->{keys}           an array of the names of enumerable
                           properties
  $$self->{prototype}      a reference to this object's prototype

In derived classes, if you need to store extra information, begin the hash 
keys with an underscore or use at least one capital letter in each key. 
Such keys 
will never be used by the
classes that come with the JE distribution.

=head1 SEE ALSO

L<JE>

L<JE::Types>

=cut


1;

