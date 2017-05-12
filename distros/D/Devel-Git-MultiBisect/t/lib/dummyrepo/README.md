# NAME

Dummy::Repo - A repo solely for testing other git repos

# INSTALL

```
perl Makefile.PL
make
make test
make install
```

If you are on a windows box you should use `nmake` rather than `make`.

# SYNOPSIS

```perl
use Dummy::Repo;
use Test::More qw(no_plan);

my ($word, $rv);
$word = 'alpha';
$rv = word($word);
is($rv, $word, "Got expected word: $word");

my ($n);
$n = 7;
$rv = p51($n);
is($rv, $n + 51, "Got expected sum: $rv);
```

# DESCRIPTION

This library exists solely for the purpose of providing a git repository to be
used in the testing of other git repositories or git functionality.

This library is set up in the form of a CPAN-ready Perl distribution
consisting of:

- A module, `Dummy::Repo`,  which exports two subroutines:
    - `word()`

        `word()` does nothing but return a string provided as its argument.

    - `p51()`

        `p51()` does nothing but add 51 to the positive or negative integer provided as its argument.
- Two test files:
    - `t/001_load.t`, which confirms that `word()` works as expected.

        This file is present in all commits in this repository.

    - `t/002_add.t`, which confirms that `p51()` works as expected.

        This file is not present in all commits in this repository.

What is more important is the fact that `t/001_load.t` has been modified in a
series of commits, sometimes to change the word used in testing `word()` and
sometimes only to add or subtract whitespace within the test file.  We end up
with a series of commits which can each be tested with:

```
prove -vb t/001_load.t
```

The objective is to generate **differences** in the output of `prove` at
certain commits but not other commits.

# AUTHOR

James E Keenan (jkeenan at cpan dot org).  Copyright 2016.
