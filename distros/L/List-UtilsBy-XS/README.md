[![Actions Status](https://github.com/syohex/p5-List-Utils-By/workflows/CI/badge.svg)](https://github.com/syohex/p5-List-Utils-By/actions) [![MetaCPAN Release](https://badge.fury.io/pl/List-UtilsBy-XS.svg)](https://metacpan.org/release/List-UtilsBy-XS)
# NAME

List::UtilsBy::XS - XS implementation of List::UtilsBy

# SYNOPSIS

    use List::UtilsBy::XS qw(sort_by);

    sort_by { $_->{foo} } @hash_ref_list

You can use those functions same as List::UtilsBy ones,
but some functions have limitation. See [LIMITATION](https://metacpan.org/pod/LIMITATION) section.

# DESCRIPTION

List::UtilsBy::XS is XS implementation of List::UtilsBy.
Functions are more fast than original ones.

# FUNCTIONS

Same as [List::UtilsBy](https://metacpan.org/pod/List%3A%3AUtilsBy)

List::UtilsBy::XS implements following functions.

- sort\_by
- nsort\_by
- rev\_sort\_by
- rev\_nsort\_by
- max\_by (alias nmax\_by)
- min\_by (alias nmin\_by)
- uniq\_by
- partition\_by
- count\_by
- zip\_by
- unzip\_by
- extract\_by
- weighted\_shuffle\_by
- bundle\_by

# LIMITATIONS

Some functions are implemented by lightweight callback API.
`sort_by`, `rev_sort_by`, `nsort_by`, `rev_nsort_by`,
`min_by`, `max_by`, `nmin_by`, `nmax_by`, `uniq_by`, `partion_by`,
`count_by`, `extract_by`, `weighted_shuffle_by` are limited some features.

Limitations are:

## Don't change argument `$_` in code block

[List::UtilsBy](https://metacpan.org/pod/List%3A%3AUtilsBy) localizes `$_` in the code block, but List::UtilsBy::XS
doesn't localize it and it is only alias same as `map`, `grep`. So you
should not modify `$_` in callback subroutine.

## Can't access to arguments as `@_` in code block

You can access argument as only `$_` and cannot access as `@_`,
`$_[n]`.

# AUTHOR

Syohei YOSHIDA <syohex@gmail.com>

# COPYRIGHT

Copyright 2013- Syohei YOSHIDA

# LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

# SEE ALSO

[List::UtilsBy](https://metacpan.org/pod/List%3A%3AUtilsBy)
