package List::Utils::MoveElement;

use 5.008;
use strict;
use warnings;
use Exporter;

BEGIN {
  our $VERSION   = qw/0.03/;
  our @ISA       = qw/Exporter/;
  our @EXPORT    = qw/move_element_left move_element_right move_element_to_beginning move_element_to_end/;
  our $xs_loaded;

  # Load XS version if available, otherwise load PP version
  local $@;
  eval {
    require XSLoader;
    XSLoader::load('List::Utils::MoveElement', $VERSION);
    $xs_loaded = 1;
  } or do {
    require List::Utils::MoveElement::PP;
    no strict 'refs';
    *left          = \&{'List::Utils::MoveElement::PP::left'};
    *right         = \&{'List::Utils::MoveElement::PP::right'};
    *to_beginning  = \&{'List::Utils::MoveElement::PP::to_beginning'};
    *to_end        = \&{'List::Utils::MoveElement::PP::to_end'};
  };

  # Alias long names to short names
  {
    no strict 'refs';
    *move_element_left         = \&{__PACKAGE__ . '::left'};
    *move_element_right        = \&{__PACKAGE__ . '::right'};
    *move_element_to_beginning = \&{__PACKAGE__ . '::to_beginning'};
    *move_element_to_end       = \&{__PACKAGE__ . '::to_end'};
  }
}

1;

__END__

=head1 NAME

List::Utils::MoveElement - Move elements of a list, optionally with XS.

=head1 SYNOPSIS

  use List::Utils::MoveElement;

  my @fruit = qw/apple banana cherry date eggplant/;

  my @array = move_element_to_beginning(2, @fruit);
  # returns (cherry apple banana date eggplant)

  @array = move_element_to_end(0, @fruit);
  # returns (banana cherry date eggplant apple)

  @array = move_element_left(-1, @array);
  # returns (apple banana cherry eggplant date)

  @array = move_element_right(0, @array);
  # returns (banana apple cherry date eggplant)

=head1 INSTALL

The XS module is built by default. To enable the pure Perl version only, pass
C<--pureperl-only> to Build.PL or, if installing via cpanm, C<--pp> (or
C<--pureperl>).

=head1 DESCRIPTION

List::Utils::Move provides four functions for moving an element of an array
to the beginning or end of the array, or left or right by one place. All
functions return the new array without modifying the original.

=head2 move_element_left

    @array = move_element_left(N, @array)

Moves element at index C<N> of C<@array> left by one place by swapping
element C<N> with element C<N-1>.

If C<N> is already the first element, it does nothing.

=head2 move_element_right

    @array = move_element_right(N, @array)

Moves element at index C<N> of C<@array> right by one place by swapping
element C<N> with element C<N+1>.

If C<N> is already the last element, it does nothing.

=head2 move_element_to_beginning

    @array = move_element_to_beginning(N, @array)

Moves element at index C<N> of C<@array> to the beginning of the array, shifting
elements to the right as necessary. In other words, element C<N> becomes
element C<0> and elements C<0..N-1> become elements C<1..N>.

If C<N> is already the first element, it does nothing.

=head2 move_element_to_end

    @array = move_element_to_end(N, @array)

Moves element at index C<N> of C<@array> to the end of the array, shifting
elements to the left as necessary. In other words, element C<N> becomes
element C<$#array> and elements C<N..$#array> become
elements C<N+1..$#array>.

If C<N> is already the last element, it does nothing.

=head2 EXPORT

By default all four functions are exported. If you would rather not import
anything, you can use the shorter function names (without the "move_element_"
prefix) in the following style:

    use List::Utils::MoveElement (); # Do not import
    @array = List::Utils::MoveElement::left(1, @array);

=head1 BUGS and CAVEATS

There is a difference between the Pure Perl and XS versions of this module when 
one if its functions is called in scalar context.

The Pure Perl functions will return the number of elements in the list, while
the XS version will return the last element. 

Scalar context of these functions does not seem useful, so I do not plan to
address this inconsistency.

=head1 SEE ALSO

L<List::Util>,
L<List::MoreUtils>

=head1 AUTHOR

Dondi Michael Stroma, E<lt>dstroma@gmail.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2017, 2021 by Dondi Michael Stroma

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
