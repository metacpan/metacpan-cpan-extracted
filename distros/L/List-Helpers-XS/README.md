# perl_list_helpers_xs

### NAME
    List::Helpers::XS - Perl extension to provide some usefull functions with arrays

### SYNOPSIS

```perl
  use List::Helpers::XS qw/ :shuffle :slice /;

  my $slice = random_slice(\@list, $size); # returns array reference, @list is partitial shuffled

  random_slice(\@list, $size); # @list is now truncated and shuffled

  shuffle(\@list);
  shuffle(@list);

  # undef value will be skipped
  shuffle_multi(\@list1, \@list2, undef, \@list3);

  # the same for tied arrays

  tie(@list, "MyPackage");
  shuffle(@list);
  shuffle(\@list);
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

    In void context the original list will be truncated and shuffled.


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
    Benchmarks of "random_slice" method in comparison with
    "List::MoreUtils::samples" and "List::Util::sample" showed that current
    version of "random_slice" is very similar to the first ones in some
    cases. But in case of huge amount of iterations it starts to slow down
    due to some performance degradation.

    So, the usage of "List::MoreUtils::samples" (it's the fastest now) and
    "List::Util::sample" is more preferable. I'll keep "random_slice" for
    backward compatibility.

The benchmark results for "shuffle"

```
                            shuffle_huge_array  List::Helpers::XS::shuffle
shuffle_huge_array                          --                         -5%
List::Helpers::XS::shuffle                  5%                          --

                            shuffle_array  List::Helpers::XS::shuffle
shuffle_array                          --                         -4%
List::Helpers::XS::shuffle             4%                          --

                            List::Util::shuffle  List::Helpers::XS::shuffle
List::Util::shuffle                          --                        -63%
List::Helpers::XS::shuffle                 170%                         --
```

### AUTHOR
    Chernenko Dmitriy, cdn@cpan.org

### COPYRIGHT AND LICENSE
    Copyright (C) 2021 by Dmitriy

    This library is free software; you can redistribute it and/or modify it
    under the same terms as Perl itself, either Perl version 5.26.1 or, at
    your option, any later version of Perl 5 you may have available.
