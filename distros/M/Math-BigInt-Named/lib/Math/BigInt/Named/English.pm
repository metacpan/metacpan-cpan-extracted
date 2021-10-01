# -*- mode: perl; -*-

package Math::BigInt::Named::English;

use strict;
use warnings;

use Math::BigInt::Named;
our @ISA = qw< Math::BigInt::Named >;

our $VERSION = '0.08';

my $SMALL = [ qw/
  zero
  one
  two
  three
  four
  five
  six
  seven
  eight
  nine
  ten
  eleven
  twelve
  thirteen
  fourteen
  fifteen
  sixteen
  seventeen
  eighteen
  nineteen
  / ];

my $TENS = [ qw /
  ten
  twenty
  thirty
  fourty
  fifty
  sixty
  seventy
  eighty
  ninety
  / ];

my $HUNDREDS = [ qw /
  one
  two
  three
  four
  five
  six
  seven
  eight
  nine
  / ];

my $TRIPLE = [ qw /
  mi
  bi
  tri
  quadri
  penti
  hexi
  septi
  octi
  / ];

sub name {
    my $x = shift;
    $x = Math::BigInt -> new($x) unless ref($x);

    my $class = ref($x);

    return '' if $x -> is_nan();

    my $ret = '';
    my $y = $x -> copy();
    my $rem;

    if ($y -> sign() eq '-') {
        $ret = 'minus ';
        $y -> babs();
    }

    if ($y < 1000) {
        return $ret . $class -> _triple($y, 1, 0);
    }

    # Split the number into numerical triplets.

    my @num = ();
    while (!$y -> is_zero()) {
        ($y, $rem) = $y -> bdiv(1000);
        unshift @num, $rem;
    }

    # Convert each numerical triplet into a string.

    my @str = ();
    for my $i (0 .. $#num) {
        my $num = $num[$i];
        my $str;
        my $index = $#num - $i;

        my $count;
        $count = $class -> _triple($num, 0, $i);
        $str .= $count;

        if ($index > 0) {
            my $triple_name = $class -> _triple_name($#num - $i, $num);
            $str .= ' ' . $triple_name;
        }

        $str[$i] = $str;
    }

    # 1100 -> "one thousand one hundred"      (not "one thousand and one hundred")
    # 1099 -> "one thousand and ninety-nine"  (not "one thousand ninety-nine")
    # 1098 -> "one thousand and ninety-eight" (not "one thousand ninety-eight")
    # ...
    # 1001 -> "one thousand and one"          (not "one thousand one")
    # 1000 -> "one thousand"                  (not "one thousand and zero")

    if (@num > 1 && 0 < $num[-1] && $num[-1] < 100) {
        splice @str, -1, 0, "and";
    }

    $ret . join(" ", grep /\S/, @str);
}

sub _triple_name {
    my ($self, $index, $number) = @_;
    # index => 0 hundreds, tens and ones
    # index => 1 thousands
    # index => 2 millions

    return '' if $index == 0 || $number -> is_zero();
    return 'thousand' if $index == 1;

    my $postfix = 'llion';
    my $plural = 's';
    if (($index & 1) == 1) {
        $postfix = 'lliard';
    }
    $postfix .= $plural unless $number -> is_one();
    $index -= 2;
    return $TRIPLE -> [$index >> 1] . $postfix;
}

sub _triple {
    # return name of a triple
    # input: number     >= 0, < 1000
    #        only       true if triple is the only triple
    my ($self, $number, $only) = @_;

    # 0 => null, but only if there is just one triple
    return '' if $number -> is_zero() && !$only;

    # we have the full name for these
    return $SMALL -> [$number] if $number <= $#$SMALL;

    # New code:

    my @num = ();
    $num[1] = $number % 100;                # tens and ones
    $num[0] = ($number - $num[1]) / 100;    # hundreds

    my @str = ();

    # Do the hundreds, if any.

    if ($num[0]) {
        my $str;
        $str = $HUNDREDS -> [$num[0] - 1];
        $str .= " hundred";
        push @str, $str;
    }

    # Do the tens and ones, if any.

    if ($num[1]) {
        my $str;
        my $ones = $num[1] % 10;
        my $tens = ($num[1] - $ones) / 10;
        if ($num[1] <= $#$SMALL) {
            $str = $SMALL -> [ $num[1] ];
        } else {
            $str = $TENS -> [ $tens - 1];
            if ($ones > 0) {
                $str .= "-";
                $str .= $SMALL -> [ $ones ];
            }
        }
        push @str, $str;
    }

    return join " and ", @str;
}

1;

__END__

=pod

=head1 NAME

Math::BigInt::Named::English - Math::BigInt objects that know their name in English

=head1 SYNOPSIS

    use Math::BigInt::Named::English;

    $x = Math::BigInt::Named::English -> new("123");
    $str = $x -> name();

    $str = "ett hundre og to";
    $x = Math::BigInt::Named::English -> from_name($str);

=head1 DESCRIPTION

This is a subclass of Math::BigInt and adds support for named numbers
with their name in English to Math::BigInt::Named.

Usually you do not need to use this directly, but rather go via
L<Math::BigInt::Named>.

=head1 METHODS

=head2 name()

    print Math::BigInt::Name -> name( 123 );

Convert a Math::BigInt to a name.

=head2 from_name()

    my $bigint = Math::BigInt::Name -> from_name('twenty-four');

Create a Math::BigInt::Name from a name string. B<Not yet implemented!>

=head1 BUGS

For information about bugs and how to report them, see the BUGS section in the
documentation available with the perldoc command.

    perldoc Math::BigInt::Named

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Math::BigInt::Named::English

For more information, see the SUPPORT section in the documentation available
with the perldoc command.

    perldoc Math::BigInt::Named

=head1 LICENSE

This program is free software; you may redistribute it and/or modify it under
the same terms as Perl itself.

=head1 SEE ALSO

L<Math::BigInt::Named> and L<Math::BigInt>.

=head1 AUTHORS

=over 4

=item *

Peter John Acklam E<lt>pjacklam@gmail.comE<gt>, 2021.

=back

=cut
