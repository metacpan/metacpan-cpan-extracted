=for gpg
-----BEGIN PGP SIGNED MESSAGE-----
Hash: SHA1

=head1 NAME

Enumeration - Yet Another enumeration class implementation.

=head1 VERSION

This is version 0.03 of Enumeration, of March 26, 2008.

=cut

use strict;
use warnings;
package Enumeration;
$Enumeration::VERSION = '0.03';

use Scalar::Util qw(refaddr);

use overload '""' => \&value,
             'eq' => \&equals,
             'ne' => \&not_equals;

# Auto-croaking saves program startup time:
sub croak { require Carp; goto &Carp::croak }

# Enumeration constants for each subclass
my %class_symbols;

# This should ONLY be called by subclasses.
# Call as:    __PACKAGE__->set_enumerations(@list_of_symbols);
sub set_enumerations
{
    my $class = shift;
    $class_symbols{$class}{$_} = 1 for @_;
    return 1;
}

# Return a list of enumerations allowable in the given class.
sub enumerations
{
    my $class = shift;
    return keys %{ $class_symbols{$class} };
}

sub import
{
    my $class = shift;
    my $import = @_ && $_[0] eq ':all';

    my $cpkg = caller;
    foreach my $sym (keys %{$class_symbols{$class}})
    {
        no strict 'refs';
        my $full_name  = $cpkg  . '::' . $sym;
        my $local_name = $class . '::' . $sym;

        *$full_name  = sub () { $sym } if $import;
        *$local_name = sub () { $sym }
    }
}


# OO enclosure.
{
    # Enumeration constants for objects created directly from the Enumeration class.
    my %instance_symbols;
    my %instance_value;

    sub new
    {
        my $class = shift;
        my $self = bless \do { my $dummy } => $class;

        # Caller is creating an on-the-fly enumeration
        if ($class eq 'Enumeration')
        {
            my %values = map {$_ => 1} @_;
            $instance_symbols{refaddr $self} = \%values;
        }
        else    # Caller is using a subclass
        {
            croak "Too many arguments to ${class}->new" if @_ > 1;
            $instance_symbols{refaddr $self} = $class_symbols{$class};
            $self->set(shift) if @_;
        }

        return $self;
    }

    sub DESTROY
    {
        my $self = shift;
        delete $instance_symbols{refaddr $self};
        delete $instance_value{refaddr $self};
    }

    # Is a given value in the list of enumeration values that are legal
    # for this class or object?
    sub is_allowable_value
    {
        my $what = shift;    # may be class name string or an object reference
        my $value = shift;
        return 1 if not defined $value;    # undef is always allowed.

        # It's a "free" enum object -- instance contains the allowable values.
        if (ref $what eq 'Enumeration')
        {
            return $instance_symbols{refaddr $what}{$value};
        }

        # It's a subclass-based object -- enumeration is at the class level.
        $what = ref ($what) || $what;
        return $class_symbols{$what}{$value};
    }

    # simple internal routine for generating a consistent error message
    # throughout.
    sub _check
    {
        croak qq{"$_[1]" is not an allowable value}
            if not $_[0]->is_allowable_value($_[1]);
    }

    # Set the object's value.
    sub set
    {
        my $self  = shift;
        my $value = shift;

        $self->_check($value);
        $instance_value{refaddr $self} = $value;
    }

    # Return the object's value.
    sub value
    {
        my $self  = shift;
        return ref($self) . '::' . $instance_value{refaddr $self}
    }
    sub bare_value
    {
        my $self  = shift;
        return $instance_value{refaddr $self}
    }

    # Query the object's status; check to see if it is a given value.
    sub is
    {
        my $self  = shift;
        my $value = shift;

        # Comparing to another enum object?
        if (ref $value && $value->isa('Enumeration'))
        {
            # Compatible classes?  Equivalent values?
            return ref $value eq ref $self  &&
                   _defeq($instance_value{refaddr $self},
                          $instance_value{refaddr $value});
        }

        $self->_check($value);
        return _defeq($instance_value{refaddr $self}, $value);
    }

    # "Complex" equality:
    #     If either value is undef, then they're equal only if both are undef
    #     Otherwise, just a simple string equality.
    sub _defeq
    {
        my ($v1, $v2) = @_;

        return (!defined $v1 && !defined $v2)
            if (!defined $v1 || !defined $v2);

        return $v1 eq $v2;
    }

    # Query the object's status; check to see if it is any of a number
    # of possible values.
    # Each status passed must be an allowable value.
    sub is_any
    {
        my $self = shift;

        foreach my $value (@_)
        {
            next if ref $value && $value->isa('Enumeration');
            $self->_check($value);
        }

        foreach my $value (@_)
        {
            return 1 if $self->is($value);
        }
        return;
    }

    # Opposite of is_any.  (Duh)
    sub is_none
    {
        my $self = shift;
        return ! $self->is_any(@_);
    }

    # Overload methods

    sub equals
    {
        return $_[0]->is($_[1]);
    }

    sub not_equals
    {
        return ! $_[0]->is($_[1]);
    }

}


return 'a true value';
__END__

=head1 SYNOPSIS

 # Usually you will subclass Enumeration, and others will use your subclass.
 use YourSubClass;
 use YourSubClass ':all';   # import enumeration constants

 # Class methods (used when subclassing; see below)
 __PACKAGE__->set_enumerations( qw(red yellow blue green) );

 # Creation
 $var = new Enumeration (@allowable_values);
 $var = new YourSubClass;
 $var = new YourSubClass($initial_value);

 # Set the value
 $var->set($new_value);        # (note: undef is always allowed)

 # Return the value
 $string = $var->value;        # "YourSubClass::enum_value"
 $string = $var->bare_value;   # "enum_value"
 $string = "$var";             # same as ->value

 # Compare
 $boolean = $var eq $some_value;
 $boolean = $var ne $some_value;
 $boolean = $var->is_any(@list_of_possible_values);
 $boolean = $var->is_none(@list_of_possible_values);

 # Test whether some value is a member of the set
 $boolean = YourSubClass->is_allowable_value($some_value);
 $boolean = $var->is_allowable_value($some_value);

=head1 DESCRIPTION

This module provides an enumeration class for Perl.  For those of you
who are not familiar with this concept from other languages, an
enumeration is a class whose instantiated objects may only be assigned
values that come from a fixed list.

There are two ways of using this module.  Typically, you will create a
subclass that inherits from C<Enumeration> and which specifies the
list of allowable values.  This is very simple.  Your class module
will contain only three lines of code:

 # MyEnumeration.pm
 #
 package MyEnumeration;
 use base 'Enumeration';
 __PACKAGE__->set_enumerations( qw(red yellow blue green) );

Programs will use this class as follows:

 # some_program.pl
 #
 use MyEnumeration;
 # ....
 my $var = new MyEnumeration(MyEnumeration::yellow);
 # or just: $var = new MyEnumeration;

Users of your subclass may choose to have all of your enumeration
symbols imported into their namespace.  They do this by using the
string C<':all'> on the C<use> line:

 use MyEnumeration ':all';
 # ....
 my $var = new MyEnumeration(yellow);

The other way to use this module is for when you need an ad-hoc
enumeration at run-time:

 # some_program.pl
 #
 my $var = new Enumeration qw(whee this is fun);


=head1 CLASS METHODS

=over 4

=item set_enumerations

 __PACKAGE__->set_enumerations(@list_of_values);

If you choose to create an enumeration by subclassing C<Enumeration>
(which is the typical way of using this module), your module will need
to use this method to indicate which values are legal for objects to
hold.

Each of these symbols will be converted into a constant in the
namespace of your subclass module.  This is to make it easy for your
callers to use the enumerations symbolically:

 my $thing = new MySubClass;
 $thing->set(MySubClass::yellow);

Users of your module may choose to import your symbols into their own
namespace as well, by using the special symbol C<':all'> on the
C<use> line.

Users may also use string values (C<'yellow'> instead of
C<MySubClass::yellow>), but this makes the user's code more
susceptible to typos, as the strings will be checked at run-time
instead of at compile-time.

Because the values are converted to perl constants (subroutines), it
makes sense for you to choose enumeration values that are also
syntactically-valid perl symbols.  That is, they should contain only
alphanumeric and underscore characters, and should not begin with a
numeric character.  I<This is not a requirement, just a guideline.> It
is perfectly valid to use any characters whatsoever; but your users
will not be able to use the symbolic form if you don't follow this
guideline.

This method always returns a true value, so your module will compile
correctly; that is, you do not need the silly "C<1;>" line that
modules generally need in order to avoid the common "did not return a
true value" error.

=item is_allowable_value

 $boolean = SomeClass->is_allowable_value(some_value);

Simple boolean test as to whether a given value is in the enumeration
list for a given class.

=back

=head1 OBJECT METHODS

=over 4

=item new

 $obj = new YourSubClass;
 $obj = new YourSubClass (initial_value);
 $obj = new Enumeration qw(list of allowable values);

Creates a new C<Enumeration> object.  If an ad-hoc list of allowable
values is provided, an initial value cannot be specified (so use
L</set>).  If an initial value is provided (to an C<Enumeration>
subclass), it must be C<undef> or in the class's list of enumerated
values.  Otherwise, it will croak.

=item is_allowable_value

 $boolean = $obj->is_allowable_value(some_value);

Returns true if the value specified is an allowable value for the
object to have.  (This has nothing to do with the object's I<current>
value; it's a test of whether the value passed I<could> be assigned to
the object, based on its class's allowable list of values).

=item set

 $obj->set(new_value);

Sets the enumeration object's value to the specified new value.
Croaks if the new value is not allowed for this enumeration.

=item value

 $str = $obj->value;

Returns the object's current value as a string.  This string is the
object's class, two colons, and its enumeration value.  So it is of
the form:

 YourSubClass::your_value

=item bare_value

 $str = $obj->bare_value;

Returns the object's current value as a string, I<without> the
object's class prepended to it.

=item "" (stringification overload)

 print "Its value is '$obj'\n";

In string context, an enumeration constant is converted to its current
value; that is, the same string that L</value> would return.

=item is

 $bool = $obj->is(some_value);
 $bool = $obj->is($another_enum_object);

Compares an enumeration object's current value to the specified value,
or to another enumeration object.

If two objects are being compared, they must be of the same class as
well as value in order to be considered equal.

If a value is being compared, it must be an allowable value for the
object to take on, or else this method will croak.

=item is_any

 $bool = $obj->is_any (value, another_value, $object, ...);

Returns true if an enumeration object's current value matches any of a
given list of possible values.

Croaks if any of the values in the list are not legal values for the
object to have.

=item is_none

 $bool = $obj->is_none (value, another_value, $object, ...);

Returns true if an enumeration object's current value does NOT match
ANY of a given list of possible values.

Croaks if any of the values in the list are not legal values for the
object to have.

=item eq

 $boolean = $obj eq some_value;
 $boolean = $obj1 eq $obj2;

Compares the object for equality to a value or another object.  The
same thing as the L</is> method, but easier to use.

=item ne

 $boolean = $obj ne some_value;
 $boolean = $obj1 ne $obj2;

Compares the object for inequality to a value or another object.

=back

=head1 EXAMPLE

 # File: Color.pm
 #
 package Color;
 use base 'Enumeration';
 __PACKAGE__->set_enumerations(qw(red yellow blue brown black green white));

 # File: some_program.pl
 #
 use strict;
 use warnings;
 use Color ':all';
 #
 #
 my $color = new Color(red);
 print "Color is currently $color\n";
 #
 $color->set(white);
 print "Color is now $color\n";
 #
 print "I TOLD you it's white!\n" if $color eq white;
 #
 $color->set('purple');   # dies.


=head1 EXPORTS

None.  But if you subclass this module, then people who use your
module will have the option to have symbols imported into their
namespace.

=head1 AUTHOR/COPYRIGHT

Copyright (c) 2008 by Eric J. Roode, ROODE I<-at-> cpan I<-dot-> org

All rights reserved.

To avoid my spam filter, please include "Perl", "module", or this
module's name in the message's subject line, and/or GPG-sign your
message.

This module is copyrighted only to ensure proper attribution of
authorship and to ensure that it remains available to all.  This
module is free, open-source software.  This module may be freely used
for any purpose, commercial, public, or private, provided that proper
credit is given, and that no more-restrictive license is applied to
derivative (not dependent) works.

Substantial efforts have been made to ensure that this software meets
high quality standards; however, no guarantee can be made that there
are no undiscovered bugs, and no warranty is made as to suitability to
any given use, including merchantability.  Should this module cause
your house to burn down, your dog to collapse, your heart-lung machine
to fail, your spouse to desert you, or George Bush to be re-elected, I
can offer only my sincere sympathy and apologies, and promise to
endeavor to improve the software.

=cut

=begin gpg

-----BEGIN PGP SIGNATURE-----
Version: GnuPG v1.4.8 (Cygwin)

iEYEARECAAYFAkfqxEIACgkQwoSYc5qQVqrvSwCcDFVRb/5BAIVrA/QB6An8v6UM
srQAoInszO8WzxLTNqpdiwFLHMTyHGSn
=O1zc
-----END PGP SIGNATURE-----

=end gpg
