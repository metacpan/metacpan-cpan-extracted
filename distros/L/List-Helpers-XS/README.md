# perl_list_helpers_xs

### NAME
    List::Helpers::XS - Perl extension to provide some usefull functions with arrays

### SYNOPSIS

```perl
  use List::Helpers::XS qw/ :shuffle :slice /;

  my @slice = random_slice(\@list, $size);

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
```

### DESCRIPTION
    This module provides some rare but usefull functions to work with
    arrays.
    It supports tied arrays.

##### random_slice
    This method receives the array and the amount of required elements to be shuffled,
    shuffles array's elements and returns the array reference to the new
    arrays with C<num> elements from original one.

    If "num" is equal or higher than amount of elements in array, then it
    won't do any work.

    It doesn't shuffle the whole array, it shuffle only "num" elements and
    returns only them.

    This method can a bit slow down in case of huge arrays and "num",
    because of it copies chosen elements into the new array to be returned

    In this case please consider the usage of "random_slice" method.

    Also the original array will be shuffled at the end.

##### random_slice_void

    This method receives the array and the amount of required elements to be shuffled,
    shuffles array's elements and returns the array reference to the new
    arrays with C<num> elements from original one.

    If "num" is equal or higher than amount of elements in array, then
    it won't do any work.

    It doesn't shuffle the whole array, it shuffles only C<num> elements and returns only them.
    So, if you need to shuffle and get back only a part of array, then this method can be faster than others approaches.

    Be aware that the original array will be shuffled too, but it won't be sliced.

##### shuflle
      Shuffles the provided array.
      Doesn't return anything.

##### shuffle_multi
    Shuffles multiple arrays.
    Each array must be passed as array reference.
    All undefined arrays will be skipped.
    This method will allow you to save some time by getting rid of extra calls.
    You can pass so many arguments as Perl stack allows.

### Benchmarks
    Below you can find some benchmarks of "random_slice" and
    "random_slice_void" methods in comparison with
    "Array::Shuffle::shuffle_array" /
    "Array::Shuffle::shuffle_huge_array" with "splice" method
    invocation afterwards.

Total amount of elements in initial array: 250
```
                            shuffle_array and splice  random_slice  random_slice_void
shuffle_array and splice                          --          -45%               -52%
random_slice                                     82%            --               -12%
random_slice_void                               107%           14%                 --

Total amount of elements in initial array: 25_000

                         shuffle_array and splice  random_slice_void  random_slice
shuffle_array and splice                      --                -45%          -49%
random_slice_void                             81%                 --           -8%
random_slice                                  96%                 8%            --

Total amount of elements in initial array: 250_000

                           shuffle_array and splice  random_slice_void  random_slice
shuffle_array and splice                         --               -63%          -67%
random_slice_void                              172%                 --           -9%
random_slice                                   200%                10%            --
```

The benchmark code is below:

```perl
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
```

The benchmark results for "shuffle"

```
                            shuffle_huge_array  List::Helpers::XS::shuffle
shuffle_huge_array                          --                         -4%
List::Helpers::XS::shuffle                  4%                          --

                            shuffle_array  List::Helpers::XS::shuffle
shuffle_array                                      --             -3%
List::Helpers::XS::shuffle                          4%             --

                            List::Util::shuffle  List::Helpers::XS::shuffle
List::Util::shuffle                          --                        -46%
List::Helpers::XS::shuffle                   86%                         --
```

### AUTHOR
    Chernenko Dmitriy, cdn@cpan.org

### COPYRIGHT AND LICENSE
    Copyright (C) 2021 by Dmitriy

    This library is free software; you can redistribute it and/or modify it
    under the same terms as Perl itself, either Perl version 5.26.1 or, at
    your option, any later version of Perl 5 you may have available.
