# NAME

Devel::TraceRun - Shows all the function calls and returns in a Perl program

# PROJECT STATUS

[![CPAN version](https://badge.fury.io/pl/Devel-TraceRun.svg)](https://metacpan.org/pod/Devel::TraceRun)

# SYNOPSIS

    $ perl -d -d:TraceRun -S yourscript

# DESCRIPTION

Figuring out a large system's workings is hard. Figuring out why it's
not working, and where it's going wrong, is even harder.

This tool produces an indented list of all function calls with parameters
(in a very very concise format) and return values (ditto). It aims to
minimise diffs between runs of a program that are doing the same thing,
so that differences stand out.

The output is on `STDOUT` currently. That may become overridable in
due course.

## Example

This code (from the test - `Thing::func` calls `Thing::func2` which
returns "2nd retval"):

    use Thing;
    my $f = sub { Thing::func() };
    Thing::func([2]); # void
    my @r = Thing::func([2]);
    my @r2 = $f->("very long string", 2, bless {}, 'Thing');

run with:

    perl -d -d:TraceRun script.pl

produces on perl 5.8 - 5.14 (output is slightly different from 5.16,
and again from 5.28):

    main::(script.pl:1)()
    return()
    Thing::func(ARRAY)
      Thing::func2()
      return()
    return()
    Thing::func(ARRAY)
      Thing::func2()
      return(2nd retval)
    return(2nd retval)
    main entry(very long ,2,Thing)
      Thing::func()
        Thing::func2()
        return(2nd retval)
      return(2nd retval)
    return(2nd retval)

Note that in void context, nothing is returned. Also note the `very long
string` is truncated to (currently) 10 characters, array- and hash-refs
are printed just as `ARRAY` and `HASH`, and objects as their classname.

There is currently no way to change what is printed. One thing that would
increase homogeneity across runs would be a way to specify for certain
function-names, which inputs or outputs to mask. Obvious examples where
this would help are functions that return the current time, or a random
number, or the port number of an incoming IP connection.

Another source of output variation is the change in Perl 5.18 to randomise
the order hash-keys are returned in. You can overcome this for tracing
purposes by setting the environment variable `PERL_HASH_SEED` to 0,
which also has the effect of setting `PERL_PERTURB_KEYS` to 0.

## How it works

As may be discerned from the command line, it uses Perl's debugging
functionality. However, unlike the normal use of that, it is entirely
non-interactive. Instead, it replaces `DB::DB` with a no-op, and uses
the `DB::sub` hook to report function entries and returns.

These reports are indented (currently hardcoded to two spaces), nested
according to stack depth. It is intended to be completely obvious what
everything means.

# SEE ALSO

[perldebguts](https://metacpan.org/pod/perldebguts)

# AUTHOR

Ed J

# COPYRIGHT AND LICENSE

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.
