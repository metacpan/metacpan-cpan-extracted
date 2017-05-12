# LEMBAS

Lembas is a testing framework for command line applications inspired
by [Cram](https://bitheap.org/cram/).

# SYNOPSIS

```perl
use Test::More;
use Lembas;

open my $specs, '<', 'hg-for-dummies.lembas'
    or BAILOUT("can't open Mercurial session test specs: $!");

my $lembas = Lembas->new_from_test_spec(handle => $specs);
plan tests => $lembas->plan_size;
$lembas->run;
```

# DESCRIPTION

In short, you write down shell sessions verbatim, allowing for
variance such as "this part here should match this regex" or "then
there's some output nobody really cares about" or even "this output
should be printed within N seconds". The markup is really very simple
so you can almost copy-paste real shell sessions and have it work.

Then Lembas will spawn a shell process of your choice and pass it the
commands and test if the output matches what's expected, thereby
turning your shell session into a test suite!

# EXAMPLES

Examples are provided in the `examples/` folder of this distribution.

# AUTHOR

Fabrice Gabolde <fabrice.gabolde@gmail.com>

# COPYRIGHT AND LICENSE

Copyright (C) 2013 Fabrice Gabolde

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.10.0 or,
at your option, any later version of Perl 5 you may have available.
