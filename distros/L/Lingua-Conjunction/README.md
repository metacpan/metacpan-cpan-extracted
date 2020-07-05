# NAME

Lingua::Conjunction - Convert lists into simple linguistic conjunctions

# VERSION

version v2.1.4

# SYNOPSIS

```perl
use Lingua::Conjunction;

# emits "Jack"
$name_list = conjunction('Jack');

# emits "Jack and Jill"
$name_list = conjunction('Jack', 'Jill');

# emits "Jack, Jill, and Spot"
$name_list = conjunction('Jack', 'Jill', 'Spot');

# emits "Jack, a boy; Jill, a girl; and Spot, a dog"
$name_list = conjunction('Jack, a boy', 'Jill, a girl', 'Spot, a dog');

# emits "Jacques, un garcon; Jeanne, une fille; et Spot, un chien"
Lingua::Conjunction->lang('fr');
$name_list = conjunction(
    'Jacques, un garcon',
    'Jeanne, une fille',
    'Spot, un chien'
);
```

# DESCRIPTION

Lingua::Conjunction exports a single subroutine, `conjunction`, that
converts a list into a properly punctuated text string.

You can cause `conjunction` to use the connectives of other languages, by
calling the appropriate subroutine:

```perl
Lingua::Conjunction->lang('en');   # use 'and' (default)
Lingua::Conjunction->lang('es');   # use 'y'
```

Supported languages in this version are
Afrikaans,
Danish,
Dutch,
English,
French,
German,
Indonesian,
Italian,
Latin,
Norwegian,
Portuguese,
Spanish,
and Swahili.

You can also set connectives individually:

```
Lingua::Conjunction->separator("...");
Lingua::Conjunction->separator_phrase("--");
Lingua::Conjunction->connector_type("or");

# emits "Jack... Jill... or Spot"
$name_list = conjunction('Jack', 'Jill', 'Spot');
```

The `separator_phrase` is used whenever the separator already appears in
an item of the list. For example:

```
# emits "Doe, a deer; Ray; and Me"
$name_list = conjunction('Doe, a deer', 'Ray', 'Me');
```

You may use the `penultimate` routine to diable the separator after the
next to last item. Generally this is bad English practice but the option
is there if you want it:

```
# emits "Jack, Jill and Spot"
Lingua::Conjunction->penultimate(0);
$name_list = conjunction('Jack', 'Jill', 'Spot');
```

I have been told that the penultimate comma is not standard for some
languages, such as Norwegian. Hence the defaults set in the `%languages`.

# SEE ALSO

`Locale::Language`

The _Perl Cookbook_ in Section 4.2 has a simular subroutine called
`commify_series`. The difference is that 1. this routine handles
multiple languages and 2. being a module, you do not have to add
the subroutine to a script every time you need it.

# SOURCE

The development version is on github at [https://github.com/robrwo/Lingua-Conjunction](https://github.com/robrwo/Lingua-Conjunction)
and may be cloned from [git://github.com/robrwo/Lingua-Conjunction.git](git://github.com/robrwo/Lingua-Conjunction.git)

# BUGS

Please report any bugs or feature requests on the bugtracker website
[https://github.com/robrwo/Lingua-Conjunction/issues](https://github.com/robrwo/Lingua-Conjunction/issues)

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

# AUTHORS

- Robert Rothenberg <rrwo@cpan.org>
- Damian Conway <damian@conway.org>

# CONTRIBUTORS

- Ade Ishs <adeishs@cpan.org>
- Mohammad S Anwar <mohammad.anwar@yahoo.com>

# COPYRIGHT AND LICENSE

This software is Copyright (c) 1999-2020 by Robert Rothenberg.

This is free software, licensed under:

```
The Artistic License 2.0 (GPL Compatible)
```
