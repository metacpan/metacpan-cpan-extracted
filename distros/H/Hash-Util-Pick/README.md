[![Build Status](https://travis-ci.org/pine/p5-Hash-Util-Pick.svg?branch=master)](https://travis-ci.org/pine/p5-Hash-Util-Pick) [![Build Status](https://img.shields.io/appveyor/ci/pine/p5-Hash-Util-Pick/master.svg?logo=appveyor)](https://ci.appveyor.com/project/pine/p5-Hash-Util-Pick/branch/master)
# NAME

Hash::Util::Pick - The non-destructive utilities for picking hash

# SYNOPSIS

```perl
use Hash::Util::Pick qw/pick/;

my $src = {
    foo => 0,
    bar => 1,
    baz => 2,
};

my $dest = pick $hash => qw/foo bar/;
# => { foo => 0, bar => 1 }
```

# DESCRIPTION

Hash::Util::Pick is the non-destructive utilities for picking hash

# METHODS

## `pick(\%hash, @keys)`

Create hash reference picked by special keys.

```perl
pick { } => qw/foo/; # { }
pick { foo => 0 } => qw/bar/; # { }
pick { foo => 0, bar => 1 } => qw/foo/; # { foo => 0 }
```

## `pick_by(\%hash, \&predicate)`

Create hash reference picked by block.

```perl
pick_by { foo => 0, bar => 1 } => sub { $_ > 0 }; # { bar => 1 }
```

## `omit(\%hash, @keys)`

Create hash reference omitted by special keys.

```perl
omit { } => qw/foo/; # { }
omit { foo => 0 } => qw/bar/; # { foo => 0 }
omit { foo => 0, bar => 1 } => qw/foo/; # { bar => 1 }
```

## `omit_by(\%hash, \&predicate)`

Create hash reference omitted by block.

```perl
omit_by { foo => 0, bar => 1 } => sub { $_ > 0 }; # { foo => 0 }
```

# SEE ALSO

- [Lodash Documentation](https://lodash.com/docs/)

# LICENSE

The MIT License (MIT)

Copyright (c) 2016-2019 Pine Mizune

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in
all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
THE SOFTWARE.

# AUTHOR

Pine Mizune <pinemz@gmail.com>
