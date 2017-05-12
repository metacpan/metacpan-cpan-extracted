package Math::Random::MT::Auto::Range; {

use strict;
use warnings;

our $VERSION = '6.22';
$VERSION = eval $VERSION;

use Scalar::Util 1.18;

# Declare ourself as a subclass
use Object::InsideOut 'Math::Random::MT::Auto' => [ ':!auto' ];


### Inside-out Object Attributes ###

# Object data is stored in these attribute hashes, and is keyed to the object
# by a unique ID that is stored in the object's scalar reference.
#
# These hashes are declared using the 'Field' attribute.

# Range information for our objects
my %type_of   :Field;  # Type of return value:  INTEGER or DOUBLE
my %low_for   :Field;  # Low end of the range
my %high_for  :Field;  # High end of the range
my %range_for :Field;  # 'Difference' between LOW and HIGH
                       #   (used for performance considerations)


### Inside-out Object Internal Subroutines ###

my %init_args :InitArgs = (
    'LOW' => {
        'REGEX'     => qr/^lo(?:w)?$/i,
        'MANDATORY' => 1,
        'TYPE'      => 'NUMBER',
    },
    'HIGH' => {
        'REGEX'     => qr/^hi(?:gh)?$/i,
        'MANDATORY' => 1,
        'TYPE'      => 'NUMBER',
    },
    'TYPE' => qr/^type$/i,   # Range type
);

# Object initializer
sub _init :Init
{
    my $self = $_[0];
    my $args = $_[1];   # Hash ref containing arguments from object
                        # constructor as specified by %init_args above

    # Default 'TYPE' to 'INTEGER' if 'LOW' and 'HIGH' are both integers.
    # Otherwise, default to 'DOUBLE'.
    if (! exists($$args{'TYPE'})) {
        my $lo = $$args{'LOW'};
        my $hi = $$args{'HIGH'};
        $$args{'TYPE'} = (($lo == int($lo)) && ($hi == int($hi)))
                         ? 'INTEGER'
                         : 'DOUBLE';
    }

    # Initialize object
    $self->set_range_type($$args{'TYPE'});
    $self->set_range($$args{'LOW'}, $$args{'HIGH'});
}


### Object Methods ###

# Sets numeric type random values
sub set_range_type
{
    my $self = shift;

    # Check argument
    my $type = $_[0];
    if (! defined($type) || $type !~ /^[ID]/i) {
        MRMA::Args->die(
            'caller_level' => (caller() eq __PACKAGE__) ? 2 : 0,
            'message'      => "Bad range type: $type",
            'Usage'        => q/Range type must be 'INTEGER' or 'DOUBLE'/);
    }

    $type_of{$$self} = ($type =~ /^I/i) ? 'INTEGER' : 'DOUBLE';
}


# Return current range type
sub get_range_type
{
    my $self = shift;
    return ($type_of{$$self});
}


# Set random number range
sub set_range
{
    my $self = shift;

    # Check for arguments
    my ($lo, $hi) = @_;
    if (! Scalar::Util::looks_like_number($lo) ||
        ! Scalar::Util::looks_like_number($hi))
    {
        MRMA::Args->die(
            'message'      => q/Bad range arguments/,
            'Usage'        => q/Range must be specified using 2 numeric arguments/);
    }

    # Ensure arguments are of the proper type
    if ($type_of{$$self} eq 'INTEGER') {
        $lo = int($lo);
        $hi = int($hi);
    } else {
        $lo = 0.0 + $lo;
        $hi = 0.0 + $hi;
    }
    # Make sure 'LOW' and 'HIGH' are not the same
    if ($lo == $hi) {
        MRMA::Args->die(
            'caller_level' => (caller() eq __PACKAGE__) ? 2 : 0,
            'message'      => q/Invalid arguments: LOW and HIGH are equal/,
            'Usage'        => q/The range must be a non-zero interval/);
    }
    # Ensure LOW < HIGH
    if ($lo > $hi) {
        ($lo, $hi) = ($hi, $lo);
    }

    # Set range parameters
    $low_for{$$self}  = $lo;
    $high_for{$$self} = $hi;
    if ($type_of{$$self} eq 'INTEGER') {
        $range_for{$$self} = ($high_for{$$self} - $low_for{$$self}) + 1;
    } else {
        $range_for{$$self} = $high_for{$$self} - $low_for{$$self};
    }
}


# Return object's random number range
sub get_range
{
    my $self = shift;
    return ($low_for{$$self}, $high_for{$$self});
}


# Return a random number of the configured type and within the configured
# range.
sub rrand
{
    my $self = $_[0];

    if ($type_of{$$self} eq 'INTEGER') {
        # Integer random number range [LOW, HIGH]
        return (($self->irand() % $range_for{$$self}) + $low_for{$$self});
    } else {
        # Floating-point random number range [LOW, HIGH)
        return ($self->rand($range_for{$$self}) + $low_for{$$self});
    }
}


### Overloading ###

sub as_string :Stringify :Numerify
{
    return ($_[0]->rrand());
}

sub bool :Boolify
{
    return ($_[0]->rrand() & 1);
}

sub array :Arrayify
{
    my $self  = $_[0];
    my $count = $_[1] || 1;

    my @ary;
    do {
        push(@ary, $self->rrand());
    } while (--$count > 0);

    return (\@ary);
}

sub _code :Codify
{
    my $self = $_[0];
    return (sub { $self->rrand(); });
}


### Serialization ###

# Support for ->dump() method
sub _dump :Dumper
{
    my $obj = shift;

    return ({
                'HIGH'  => $high_for{$$obj},
                'LOW'   => $low_for{$$obj},
                'TYPE'  => $type_of{$$obj}
            });
}

# Support for Object::InsideOut::pump()
sub _pump :Pumper
{
    my ($obj, $data) = @_;

    $obj->set_range_type($$data{'TYPE'});
    $obj->set_range($$data{'LOW'}, $$data{'HIGH'});
}

}  # End of package's lexical scope

1;

__END__

=head1 NAME

Math::Random::MT::Auto::Range - Range-valued PRNGs

=head1 SYNOPSIS

    use strict;
    use warnings;
    use Math::Random::MT::Auto::Range;

    # Integer random number range
    my $die = Math::Random::MT::Auto::Range->new(LO => 1, HI => 6);
    my $roll = $die->rrand();

    # Floating-point random number range
    my $compass = Math::Random::MT::Auto::Range->new(LO => 0, HI => 360,
                                                     TYPE => 'DOUBLE');
    my $course = $compass->rrand();

=head1 DESCRIPTION

This module creates range-valued pseudorandom number generators (PRNGs) that
return random values between two specified limits.

While useful in itself, the primary purpose of this module is to provide an
example of how to create subclasses of Math::Random::MT::Auto within
L<Object::InsideOut>'s inside-out object model.

=head1 MODULE DECLARATION

Add the following to the top of our application code:

    use strict;
    use warnings;
    use Math::Random::MT::Auto::Range;

This module is strictly OO, and does not export any functions or symbols.

=head1 METHODS

=over

=item Math::Random::MT::Auto::Range->new

Creates a new range-valued PRNG.

    my $prng = Math::Random::MT::Auto::Range->new( %options );

Available options are:

=over

=item 'LOW' => $num

=item 'HIGH' => $num

Sets the limits over which the values return by the PRNG will range.  These
arguments are mandatory, and C<LOW> must not be equal to C<HIGH>.

If the C<TYPE> for the PRNG is C<INTEGER>, then the range will be C<LOW> to
C<HIGH> inclusive (i.e., [LOW, HIGH]).  If C<DOUBLE>, then C<LOW> inclusive to
C<HIGH> exclusive (i.e., [LOW, HIGH)).

C<LO> and C<HI> can be used as synonyms for C<LOW> and C<HIGH>, respectively.

=item 'TYPE' => 'INTEGER'

=item 'TYPE' => 'DOUBLE'

Sets the type for the values returned from the PRNG.  If C<TYPE> is not
specified, it will default to C<INTEGER> if both C<LOW> and C<HIGH> are
integers.

=back

The options above are also supported using lowercase and mixed-case (e.g.,
'low', 'hi', 'Type', etc.).

Additionally, objects created with this package can take any of the options
supported by the L<Math::Random::MT::Auto> class, namely, C<STATE>, C<SEED>
and C<STATE>.

=item $obj->new

Creates a new PRNG in the same manner as
L</"Math::Random::MT::Auto::Range-E<gt>new">.

    my $prng2 = $prng1->new( %options );

=back

In addition to the methods describe below, the objects created by this package
inherit all the object methods provided by the L<Math::Random::MT::Auto>
class, including the C<->clone()> method.

=over

=item $obj->rrand

Returns a random number of the configured type within the configured range.

    my $rand = $prng->rrand();

If the C<TYPE> for the PRNG is C<INTEGER>, then the range will be C<LOW> to
C<HIGH> inclusive (i.e., [LOW, HIGH]).  If C<DOUBLE>, then C<LOW> inclusive to
C<HIGH> exclusive (i.e., [LOW, HIGH)).

=item $obj->set_range_type

Sets the numeric type for the random numbers returned by the PRNG.

    $prng->set_range_type('INTEGER');
      # or
    $prng->set_range_type('DOUBLE');

=item $obj->get_range_type

Returns the numeric type ('INTEGER' or 'DOUBLE') for the random numbers
returned by the PRNG.

    my $type = $prng->get_range_type();

=item $obj->set_range

Sets the limits for the PRNG's return value range.

    $prng->set_range($lo, $hi);

C<$lo> must not be equal to C<$hi>.

=item $obj->get_range

Returns a list of the PRNG's range limits.

    my ($lo, $hi) = $prng->get_range();

=back

=head1 INSIDE-OUT OBJECTS

Capabilities provided by L<Object::InsideOut> are supported by this modules.
See L<Math::Random::MT::Auto/"INSIDE-OUT OBJECTS"> for more information.

=head2 Coercion

Object coercion is supported in the same manner as documented in
See L<Math::Random::MT::Auto/"Coercion"> except that the underlying random
number method is C<-E<gt>rrand()>.

=head1 DIAGNOSTICS

=over

=item * Missing parameter: LOW

=item * Missing parameter: HIGH

The L<LOW and HIGH|/"'LOW' =E<gt> $num"> values for the range must be
specified to L<-E<gt>new()|/"Math::Random::MT::Auto::Range-E<gt>new">.

=item * Arg to ->set_range_type() must be 'INTEGER' or 'DOUBLE'

Self explanatory.

=item * ->range() requires two numeric args

Self explanatory.

=item * Invalid arguments: LOW and HIGH are equal

You cannot specify a range of zero width.

=back

This module will reverse the range limits if they are specified in the wrong
order (i.e., it makes sure that C<LOW < HIGH>).

=head1 SEE ALSO

L<Math::Random::MT::Auto>

L<Object::InsideOut>

=head1 AUTHOR

Jerry D. Hedden, S<E<lt>jdhedden AT cpan DOT orgE<gt>>

=head1 COPYRIGHT AND LICENSE

Copyright 2005 - 2009 Jerry D. Hedden. All rights reserved.

This program is free software; you can redistribute it and/or modify it under
the same terms as Perl itself.

=cut
