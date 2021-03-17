package List::Helpers::XS;

use 5.026001;
use strict;
use warnings;

require Exporter;

our @ISA = qw(Exporter);

our %EXPORT_TAGS = (
  'all' => [ qw/ shuffle_multi shuffle random_slice random_slice_void / ],
  'slice' => [ qw/ random_slice random_slice_void / ],
  'shuffle' => [ qw/ shuffle shuffle_multi / ],
);

our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );

our @EXPORT = qw//;

our $VERSION = '0.08';

require XSLoader;
XSLoader::load('List::Helpers::XS', $VERSION);

1;
__END__
=head1 NAME

List::Helpers::XS - Perl extension to provide some usefull functions with arrays

=head1 SYNOPSIS

  use List::Helpers::XS qw/ :shuffle :slice /;

  my $slice = random_slice(\@list, $size); # returns array reference

  random_slice_void(\@list, $size);

  shuffle(\@list);
  shuffle(@list);

  # undef value will be skipped
  shuffle_multi(\@list1, \@list2, undef, \@list3);

  # the same for tied arrays

  tie(@list, "MyPackage");
  shuffle(@list);
  shuffle(\@list);
  random_slice_void(\@list, $size);
  my $slice = random_slice(\@list, $size); # returns array reference

=head1 DESCRIPTION

This module provides some rare but usefull functions to work with arrays.
It supports tied arrays.

=head2 random_slice

This method receives an array and amount of required elements from it,
shuffles array's elements and returns the array reference to the new
arrays with C<num> elements from original one.

If C<num> is equal or higher than amount of elements in array, then
it won't do any work.

It doesn't shuffle the whole array, it shuffles only C<num> elements and returns only them.

Also the original array will be shuffled at the end.

=head2 random_slice_void

This method receives an array and amount of required elements from it,
shuffles array's elements. Doesn't return anything.

After method being called the passed array will contain only
random C<num> elements from the original array.

This method is a memory efficient, but it can a bit slow down in case of huge arrays and C<num>.

In this case please consider the usage of C<random_slice_void> method.

=head2 shuflle

  Shuffles the provided array.
  Doesn't return anything.

=head2 shuffle_multi

  Shuffles multiple arrays.
  Each array must be passed as array reference.
  All undefined arrays will be skipped.
  This method will allow you to save some time by getting rid of extra calls.
  You can pass so many arguments as Perl stack allows.

=head1 Benchmarks

Below you can find some benchmarks of C<random_slice> and C<random_slice_void> methods
in comparison with C<Array::Shuffle::shuffle_array> / C<Array::Shuffle::shuffle_huge_array>
with C<splice> method invocation afterwards.

Total amount of elements in initial array: 250

                             Rate shuffle_array and splice random_slice random_slice_void
shuffle_array and splice  95511/s                       --         -45%              -52%
random_slice             174216/s                      82%           --              -12%
random_slice_void        198020/s                     107%          14%                --

Total amount of elements in initial array: 25_000

                            Rate shuffle_array and splice random_slice_void random_slice
shuffle_array and splice 11299/s                       --              -45%         -49%
random_slice_void        20408/s                      81%                --          -8%
random_slice             22124/s                      96%                8%           --

Total amount of elements in initial array: 250_000

                           Rate shuffle_array and splice random_slice_void random_slice
shuffle_array and splice 74.7/s                       --              -63%         -67%
random_slice_void         203/s                     172%                --          -9%
random_slice              224/s                     200%               10%           --

The benchmark code is below:

  cmpthese (
      1_000_000,
      {
          'shuffle_array and splice' => sub {
              my $arr = [@array];
              if ($slice_size < scalar $arr->@*) {
                  shuffle_array(@$arr);
                  $arr = [splice(@$arr, 0, $slice_size)];
              }
          },
          'random_slice' => sub {
              my $arr = [@array];
              $arr = random_slice($arr, $slice_size);
          },
          'random_slice_void' => sub {
              my $arr = [@array];
              random_slice_void($arr, $slice_size);
          },
      }
    );

The benchmark results for C<shuffle> method

                                Rate  shuffle_huge_array List::Helpers::XS::shuffle
shuffle_huge_array          112233/s  --                 -4%
List::Helpers::XS::shuffle  116414/s  4%                 --

                                Rate  shuffle_array  List::Helpers::XS::shuffle
shuffle_array               112233/s  --             -3%
List::Helpers::XS::shuffle  116279/s  4%             --

                               Rate  List::Util::shuffle  List::Helpers::XS::shuffle
List::Util::shuffle         62539/s  --                   -46%
List::Helpers::XS::shuffle 116550/s  86%                  --

=head1 AUTHOR

Chernenko Dmitriy, cdn@cpan.org

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2021 by Dmitriy

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.26.1 or,
at your option, any later version of Perl 5 you may have available.

=cut
