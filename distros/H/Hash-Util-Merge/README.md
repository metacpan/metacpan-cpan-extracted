# NAME

Hash::Util::Merge - utility functions for merging hashes

# VERSION

version v0.2.0

# SYNOPSIS

```perl
use Hash::Util::Merge qw/ mergemap /;

my %a = ( x => 1, y => 2 );
my %b = ( x => 3, y => 7 );

my $c = mergemap { $a + $b } \%a, \%b;

# %c = ( x => 4, y => 9 );
```

# DESCRIPTION

This module provides some syntactic sugar for merging simple
hashes with a function.

# EXPORTS

None by default.

## mergemap

```
$hashref = mergemap { fn($a,$b) } \%a, \%b;
```

For each key in the hashes `%a` and `%b`, this function applies the
user-supplied function `fn` to the corresponding values of that key,
in the resulting hash reference.

If a key does not exist in either of the hashes, then it will return
`undef`.

# SUPPORT FOR OLDER PERL VERSIONS

Since v0.2.0, the this module requires Perl v5.14 or later.

Future releases may only support Perl versions released in the last ten years.

If you need this module on Perl v5.10, please use one of the v0.1.x
versions of this module.  Significant bug or security fixes may be
backported to those versions.

# KNOWN ISSUES

[Readonly](https://metacpan.org/pod/Readonly) hashes, or those with locked keys, may return an error
when merged with a hash that has other keys.

# SEE ALSO

[Hash::Merge](https://metacpan.org/pod/Hash%3A%3AMerge)

# SOURCE

The development version is on github at [https://github.com/robrwo/Hash-Util-Merge](https://github.com/robrwo/Hash-Util-Merge)
and may be cloned from [git://github.com/robrwo/Hash-Util-Merge.git](git://github.com/robrwo/Hash-Util-Merge.git)

# BUGS

Please report any bugs or feature requests on the bugtracker website
[https://github.com/robrwo/Hash-Util-Merge/issues](https://github.com/robrwo/Hash-Util-Merge/issues)

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

# AUTHOR

Robert Rothenberg <rrwo@cpan.org>

This module uses code from [List::Util::PP](https://metacpan.org/pod/List%3A%3AUtil%3A%3APP).

This module was developed from work for Science Photo Library
[https://www.sciencephoto.com](https://www.sciencephoto.com).

# CONTRIBUTOR

Mohammad S Anwar <mohammad.anwar@yahoo.com>

# COPYRIGHT AND LICENSE

This software is Copyright (c) 2020-2023 by Robert Rothenberg.

This is free software, licensed under:

```
The Artistic License 2.0 (GPL Compatible)
```
