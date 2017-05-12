package Math::Pandigital;

use Moo;
use MooX::Types::MooseLike::Base qw( Int Bool ArrayRef RegexpRef );

use strict;
use warnings;

use Carp;

our $VERSION = '0.04';

has base     => ( is => 'ro', isa => Int,  default => sub { 10; } );
has unique   => ( is => 'ro', isa => Bool, default => sub { 0; } );
has zeroless => ( is => 'ro', isa => Bool, default => sub { 0; } );


has _digits_array => (
    is      => 'ro',
    isa     => ArrayRef,
    lazy    => 1,
    builder => '_build_digits_array'
);

has _digits_regexp => (
    is      => 'ro',
    isa     => RegexpRef,
    lazy    => 1,
    builder => '_build_digits_regexp'
);

has _min_length => (
    is      => 'ro',
    isa     => Int,
    lazy    => 1,
    builder => '_build_min_length'
);

sub BUILD {
    my $self = shift;
    if( $self->base != 16 ) {
      if( $self->base <= 0 || $self->base > 10 ) {
        croak "Base must be 1 .. 10, or 16";
      }
    }
    croak "Unary base must be zeroless."
      if $self->base == 1 && ! $self->zeroless;
    return;
}

sub _build_digits_array {
    my $self  = shift;
    my $base = $self->base;

    # Special case for unary: 1 is the only reasonable digit.
    return [1] if $base == 1;

    # Determine our set's lowest value.
    my $start = $self->zeroless ? 1 : 0;

    # A hexidecimal set.
    return [ $start .. 9, 'A' .. 'F' ] if $base == 16;

    # Base 2 - 10 set.
    return [ $start .. $base - 1 ];
}

sub _build_digits_regexp {
    my $self = shift;

    # Calculate the quantifier.
    my $min_length = $self->_min_length;
    my $quantifier = $self->unique ? "{$min_length}" : "{$min_length,}";

    # Compose a regex string with character class and quantifier.
    # Will look similar to "(?i:^[0123456789]{4,})", for example.
    my $re_str =
      join( '', '(?i:^[', @{ $self->_digits_array() }, "]$quantifier)\$" );

    # Turn it into a Regexp object and return.
    return qr/$re_str/;
}

sub _build_min_length {
    my $self = shift;

    # Special case for unary
    return 1 if $self->base == 1;
    
    # Calculate the minimum possible input length for $value to qualify.
    return $self->base - ( $self->zeroless ? 1 : 0 );
}

sub is_pandigital {
    my ( $self, $value ) = @_;
    $value =~ s/^0+//; # Strip insignificant leading zeros from strings.

    # The regexp test is done before we proceed to even more work.
    return if not $value =~ $self->_digits_regexp; # Case insensitive.

    # Next, count individual digits to verify we have enough of each digit, and
    # that we don't violate unique settings.
    my $unique = $self->unique;
    my %hash;
    for my $digit ( split //,  uc $value ) {
      return if ++$hash{$digit} > 1 && $unique;
    }
    return keys %hash == $self->_min_length;

}

1;

__END__

=pod

=head1 NAME

Math::Pandigital - Pandigital number detection.

=head1 SYNOPSIS


    use Math::Pandigital;

    my $p = Math::Pandigital->new;
    my $test = '1234567890';
    if( $p->is_pandigital( $test ) ) {
      print "$test is pandigital.\n";
    }
    else {
      print "$test is not pandigital.\n";
    }


    my $p = Math::Pandigital->new( base => 8, zeroless => 1, unique => 1 );

    print "012345567 is pandigital\n" if $p->is_pandigital('012345567'); # No.
    print "1234567 is pandigital\n" if $p->is_pandigital('1234567');     # Yes.

    
=head1 DESCRIPTION

A Pandigital number is an integer that contains at least one of each digit in
its base system.  For example, a base-2 pandigital number must contain both 0
and 1. A base-10 pandigital number must contain 0, 1, 2, 3, 4, 5, 6, 7, 8,
and 9.  This module can detect pandigital numbers in base 1 through base 10, as
well as hexidecimal.

Pandigital numbers usually include zero.  However, zeroless pandigital numbers,
containing (in base-10), 1 .. 9, and not 0 are sometimes permitted.  This module
can accommodate that need.

Additionally, some uses of pandigital numbers require that there be no repeated
digits.  In such a case, the base-2 number 10 would be pandigital, whereas 101
would not.  Again, this module accommodates that possibility.

L<Math::Pandigital> provides a class that can be instantiated in any base, from
1 through 10, or 16 (hex), and can be used to detect pandigital numbers.  It may
also be configured to accept repeated digits, or to reject them, and to require
the 'zero' digit, or to reject it.


=head1 EXPORTS

No exports.

=head1 SUBROUTINES AND METHODS

=head2 new

    my $p = Math::Pandigital->new;

Constructs a Math::Pandigital test object.  If no parameters are passed, the
tests will assume base ten, requiring a "zero", and permitting repeated digits.

=head3 Optional constructor parameters

Any (or all) of the following parameters may optionally be used to configure the
test object.

=head4 base

    my $p = Math::Pandigital->new( base => 16 );

Set's the base to any value from 1 to 10, or 16.  If the goal is to detect
pandigitality of a binary number, select C<< base => 2 >>, for example.  If not
specified, the default is base ten.  Common options are 2 (binary), 8 (octal),
10 (decimal), and 16 (hex). Base 1 is permitted (unary), as is any value
between one and ten, inclusive.

For base-16 tests, the digits C<A..F> will be treated case-insensitively.

Unary (base 1) pandigital numbers are zeroless; the only reasonable digit
is 'C<1>'.  Therefore, when setting C<< base => 1 >>, one must also set
C<< zeroless => 1 >>.


=head4 unique

    my $p = Math::Pandigital->new( unique => 1 );

A Boolean flag used to set whether or not the pandigital number may contain
repeated digits.  For example, in base 2, with unique set, there are only two
pandigital numbers: 01, and 10.  With unique unset (the default), any binary
number of any length is permitted so long as it has at least one zero, and one
one.  The default is the traditional definition of a pandigital number: repeated
digits allowed.

=head4 zeroless

    my $p = Math::Pandigital->new( zeroless => 1 );

A Boolean flag.  The default is false (zeros required).  When unset (or the
default accepted), the pandigital number must include a zero.  When set to true,
the pandigital number may not include a zero.

When a base 1 is selected (unary), it's required to explicitly set C<zeroless>
to true; the only reasonable digit is 'C<1>'.

A brief example:

    my $p = Math::Pandigital->new( base => 4, zeroless => 1, unique => 1 );

The preceeding instantiation would set up a test that allows the following
numbers to match:  123, 231, 213, 321, 312, and 132.  It would reject any number
with a zero, or more (or less) than three digits.

=head2 is_pandigital

    $p->is_pandigital($n);

C<$n> may be any string.  If the string contains only numeric digits that match
the criteria set forth when the test object is constructed, true is returned.
If the string contains any digits that aren't part of the base, or if it fails
to contain all necessary digits, or if it violates the uniqueness setting (if
set), it will return false.  The letters 'A' through 'F' (case insensitive) are
considered numeric digits when operating in base 16 (hex) mode, and in base 1
(unary), the numeral C<1> is the only possible digit.

In keeping with the definition for pandigital numbers, leading zeros are not
significant, and will be stripped before testing.  Thus, '0123456789' is I<not>
zerofull pandigital in base ten, because it is considered as '123456789'.

Pass hexidecimal numbers as a string of hex digits, not as their native
C<0xNNNNNNNNNNNNNNNN> representations.  This is for two reasons.  First, a
16-digit hex number corresponds to 1.84467440737E+19, which is large enough that
the internal representation will lose significant digits if stored and passed
numerically.  Second, within Math::Pandigital the string of digits is treated
just as that, a I<string> of digits.

Setting a base of 1 (unary), and a zeroless of false (zeros included, or
zeroful) will cause the constructor to throw an exception; the only permissible
digit in a unary pandigital is '1'.  If this seems counterintuitive, remember
that leading zeros are stripped, so it wouldn't make sense for unary pandigitals
to use '0' as the marker digit.  This being the case, zeroless base-2 (binary)
pandigitals, and base-1 (unary) pandigitals, which must always be zeroless are
practically the same thing, though conceptually they differ.

=head1 CAVEATS & WARNINGS

While any length of string of digits is permitted, there is no silver bullet;
the computational complexity of the C<is_pandigital()> test is linear in the
worst case.  However, where profiling for the general case has shown them to
be beneficial, optimizations have been used to reject non-pandigitals as quickly
as practical.

L<Math::Pandigital>'s test suite currently has 100% coverage.

=head1 CONFIGURATION AND ENVIRONMENT

No special considerations.

=head1 DEPENDENCIES

Perl 5.6.2, L<Moo>, and L<MooX::Types::MooseLike> are required.

=head1 INCOMPATIBILITIES

No known incompatibilities.

=head1 SEE ALSO

L<http://en.wikipedia.org/wiki/Pandigital_number>

=head1 AUTHOR

David Oswald C<< <davido at cpan dot org> >>

=head1 DIAGNOSTICS

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Math::Pandigital

This module is maintained in a public repo at Github. You may look for
information at:

=over 4

=item * Github: Development is hosted on Github at:

L<http://www.github.com/daoswald/Math-Pandigital>

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Math-Pandigital>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Math-Pandigital>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Math-Pandigital>

=item * Search CPAN

L<http://search.cpan.org/dist/Math-Pandigital/>

=back

=head1 ACKNOWLEDGEMENTS

=head1 LICENSE AND COPYRIGHT

Copyright 2012 David Oswald.

This program is free software; you can redistribute it and/or modify it under
the terms of either: the GNU General Public License as published by the Free
Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.

=cut

