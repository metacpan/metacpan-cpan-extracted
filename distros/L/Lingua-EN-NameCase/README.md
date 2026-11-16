## Name

Lingua::EN::NameCase - Correctly case a person's name from UPPERCASE or lowercase

## Version

Version 1.22

## Synopsis

```perl
    use Lingua::EN::NameCase qw( nc NameCase );

    # Pattern 1: fix one name.  nc() is like lc() and uc().
    my $name = nc('JOHN O\'CALLAGHAN');     # "John O'Callaghan"
    my $same = nc( \$name );                # a reference works too
                                            # ($name itself is not changed)

    # Pattern 2: fix a list of names.  You get a new list back.
    my @clean = NameCase( 'ANNE JONES', 'BOB MCVEY' );

    # Pattern 3: fix an array in place.
    my @names = ( 'ANNE JONES', 'BOB MCVEY' );
    NameCase( \@names );                    # @names is now fixed

    # Pattern 4: clean data read from a file or database.
    open( my $fh, '<:encoding(UTF-8)', 'names.txt' );
    while ( my $line = <$fh> ) {
            chomp $line;
            print nc($line), "\n";
    }

    # Pattern 5: change the rules for part of your program only.
    {
            local $Lingua::EN::NameCase::SPANISH = 1;   # keep "El" and "La"
            print nc('EL PASO');                        # "El Paso"
    }
    print nc('EL PASO');                            # "el Paso"

    # Pattern 6: catch bad input.
    eval { nc( { not => 'a name' } ) };
    print "Problem: $@" if $@;

    # Other switches (all are package variables):
    #   $Lingua::EN::NameCase::HEBREW      = 0;  # "Ben" stays "Ben"
    #   $Lingua::EN::NameCase::ROMAN       = 0;  # "Li" stays "Li", not "LI"
    #   $Lingua::EN::NameCase::POSTNOMINAL = 0;  # "PHD" becomes "Phd"
```

## Description

Forenames and surnames are often stored either wholly in UPPERCASE
or wholly in lowercase. This module allows you to convert names into
the correct case where possible.

Although forenames and surnames are normally stored separately if they
do appear in a single string, whitespace separated, NameCase and nc deal
correctly with them.

NameCase currently correctly name cases names which include any of the
following:

```
    Mc, Mac, al, el, ap, da, de, delle, della, di, du, del, der,
    la, le, lo, van and von.
```

It correctly deals with names which contain apostrophes and hyphens too.

### Example Fixes

```
    Original            Name Case
    --------            ---------
    KEITH               Keith
    LEIGH-WILLIAMS      Leigh-Williams
    MCCARTHY            McCarthy
    O'CALLAGHAN         O'Callaghan
    ST. JOHN            St. John
```

plus "son (daughter) of" etc. in various languages, e.g.:

```
    VON STREIT          von Streit
    VAN DYKE            van Dyke
    AP LLWYD DAFYDD     ap Llwyd Dafydd
    etc.
```

plus names with roman numerals (up to 89, LXXXIX), e.g.:

```
    henry viii          Henry VIII
    louis xiv           Louis XIV
```

### Configuration

The behaviour is controlled by package variables, read on every call
so they may be changed at any time:

- `$Lingua::EN::NameCase::HEBREW` (default 1)

    Lowercase the Hebrew particles "ben" and "bat" when they follow another word.

- `$Lingua::EN::NameCase::SPANISH` (default 0)

    Keep "El" and "La" capitalised (Spanish) instead of lowercasing them
    (Greek and French).

- `$Lingua::EN::NameCase::ROMAN` (default 1)

    Upper-case roman numerals (I to LXXXIX).

- `$Lingua::EN::NameCase::POSTNOMINAL` (default 1)

    Normalise a trailing post-nominal such as "PhD" or "MBE".

- `$Lingua::EN::NameCase::MAX_LENGTH` (default `undef`, no limit)

    The longest name, in characters, that `nc` will accept.  A longer name makes
    `nc` croak with the `too_long` message instead of using time and memory on
    it.  Set this when names come from an untrusted source.

- `%Lingua::EN::NameCase::MESSAGES`

    Overrides the text of an error message by key (see ["MESSAGES"](#messages) under
    each routine).  The text may contain `{name}` placeholders, which are
    replaced by the arguments given when the error is raised.
    This is the hook for translating the error messages.

## Common Pitfalls

- A scalar is never changed in place

    `NameCase(\$name)` and `nc(\$name)` read the string and return a new
    one.  Always use the return value:  `$name = nc($name);`.
    Only an _array reference_ is changed in place.

- Empty and undefined input

    `undef`, an empty string and the string "0" are returned as they are.
    No warning is given.  Check for `undef` yourself if you need to know.

- Switches are global

    The four switches are package variables.  If you change one, it changes for
    the whole program until you change it back.  Use `local` inside a block
    to limit the change.

- Only the last word can be a post-nominal

    "JANE PHD SMITH" is not changed to "Jane PhD Smith".  "SMITH PHD" is
    changed to "Smith PhD".

- One name per string, with no extra text

    "MR. AND MRS. SMITH" and similar text get the same treatment as a name.
    Words like "Of" are not changed to "of".

- The result is a guess

    Some names are cased wrongly.  For example "MACINNES" becomes "Macinnes".
    Check important data by hand.  See ["LIMITATIONS"](#limitations).

- Wrong number of arguments

    `nc` takes at most one argument.  `NameCase` in scalar context takes
    exactly one.  Anything else stops the program with an error message,
    so wrap the call in `eval` if the input is not trusted.

- Untrusted input

    Set `$Lingua::EN::NameCase::MAX_LENGTH` when names come from users.  Without
    it, a very large string is processed in full, using memory in proportion to
    its size.  A class name in an error message is shortened and any odd
    character in it becomes "?".

- `nc()` with no argument uses `$_`

    This is the same as the built-in `lc`.  It can surprise you inside a loop.

## Encoding

The module works on Perl character strings.  Decode your input first,
for example with `Encode::decode('UTF-8', $bytes)` or by reading a file
with `open(my $fh, '<:encoding(UTF-8)', $file)`.  Print the result
through an encoded handle, for example `binmode(STDOUT, ':encoding(UTF-8)')`.

- Safe (decoded characters)

    Accented letters ("EMILE ZOLA" with an accent), Greek and other alphabets
    that have upper and lower case, and emojis.  An emoji is left as it is,
    and the words around it are fixed: `john <emoji> smith` becomes
    `John <emoji> Smith`.

- Not safe (raw bytes)

    A UTF-8 byte string that was not decoded.  The ASCII letters are fixed, but
    the bytes of non-ASCII letters are left alone and are not changed to
    capitals.

- Scripts without case

    Chinese, Japanese, Korean, Arabic, Hebrew and similar text is returned
    unchanged.  It is safe to pass in.

- Apostrophes

    Only the plain apostrophe (`'`) is understood in the 's rule.
    "FRED'S" becomes "Fred's", but "FRED" followed by a curly apostrophe and "S"
    becomes "Fred" followed by the curly apostrophe and a capital "S".

- Sharp s

    The German sharp s at the start of a word becomes "Ss".

- Error messages

    The built-in messages are plain ASCII English.  Text you put in
    `%MESSAGES` may be any characters; use character strings.

The module ignores the process locale (`LC_ALL`, `LC_CTYPE`): the result
is the same everywhere.

## Functions

### NameCase

Takes a scalar, scalarref, array or arrayref, and changes the case of the
contents, as appropriate. Essentially a wrapper around nc().

#### Purpose

Case one name, or a whole list of names, in one call.

#### Args

One scalar, one scalar reference, one array reference, or (in list context
only) a list of scalars.

#### Returns

- List context with a list, or an array reference

    A list of name-cased copies.  The source is not modified.

- Scalar or void context with an array reference

    The array is modified in place; the array reference is returned so calls
    can be chained.  The new names are stored into the existing elements, so a
    reference to an element, or an array that aliases other variables (such as
    `\@_`), sees the change.

- Scalar or scalar reference

    A name-cased copy.  A scalar reference is _not_ modified (see ["LIMITATIONS"](#limitations)).
    An undefined, empty or "0" value comes back unchanged.

If the first argument is an array reference, any further arguments are
ignored.  An empty array reference gives an empty list (or an unchanged
empty array).  In list context a single scalar or scalar reference gives a
list of one name.

#### Side Effects

Modifies the referenced array only in the in-place case above.  If any
element is invalid, the function croaks and the array is left unchanged.
Dies (via ["croak" in Carp](https://metacpan.org/pod/Carp#croak)) on bad arguments.

#### Usage

See ["SYNOPSIS"](#synopsis).

#### Example

```perl
    my @fixed = NameCase( 'JOHN SMITH', 'mary o\'neil' );
    # ('John Smith', "Mary O'Neil")

    my @names = ( 'ANNE JONES', 'BOB MCVEY' );
    NameCase( \@names );
    # @names is now ('Anne Jones', 'Bob McVey')

    my $one = NameCase( 'DAVID VAN DYKE' );   # 'David van Dyke'
```

#### Api Specification

##### Input

```perl
    {
            names => {
                    type     => 'arrayref',    # list of scalars, or one [] / \scalar
                    optional => 0,
                    min      => 1,
            },
    }
```

A single hash reference, or any reference type other than SCALAR or ARRAY,
is rejected.

Valid and invalid input, by partition:

- Argument form

    Valid: one string, one scalar reference (copied, not changed), one array
    reference, or a list of strings.  Invalid: no argument or, in scalar or
    void context, more than one (croak `single_arg`); a HASH, CODE, GLOB or
    other reference (croak `usage_namecase`).

- Array size

    0, 1, 2 and many are all valid.  An empty array returns an empty result.
    In list context the original is never changed.  In scalar or void context
    an array reference is changed in place and returned.

- Each element

    Must satisfy the `nc` domain (see below), including `$MAX_LENGTH`.  One
    bad element croaks, and then no element of the array is changed.

The domain of each element is the domain of ["nc"](#nc).

##### Output

```perl
    { type => 'arrayref', element_type => 'string' }    # list context
    { type => 'string' }                                # one scalar
    { type => 'arrayref' }                              # in place
```

#### Messages

- `usage_namecase`

    _Usage: $SCALAR|@ARRAY = NameCase \[\\\]$SCALAR|@ARRAY (got {got})_.
    The first argument was a reference of an unsupported type (`{got}`).
    Pass a scalar, a scalar ref or an array ref.

- `single_arg`

    _NameCase only accepts a single scalar, array or array ref_.
    No arguments were given, or several were given in scalar context.
    Pass exactly one value, or call in list context.

#### Pseudocode

```
    validate: reject refs that are neither ARRAY nor SCALAR
    if list context and (more than one arg or an ARRAY ref):
            return nc of each element
    elsif ARRAY ref:
            replace each element by nc(element); return the ref
    elsif SCALAR ref:
            return nc(dereferenced value)
    elsif exactly one arg:
            return nc(arg)
    else:
            croak single_arg
```

### Nc

Takes a scalar or scalarref, and change the case of the name in the
corresponding string appropriately.

#### Purpose

Name-case a single string.

#### Args

Zero or one argument: a string or a scalar reference to a string.
With no argument, `$_` is used (like `lc` and `uc`).

#### Returns

The name-cased string.  An undefined, empty or "0" input is returned
unchanged.  The input is never modified.

#### Side Effects

None.  Reads the package variables listed under ["CONFIGURATION"](#configuration).
It does not change `$_`, `$@`, `$!` or any `alarm` timer.

#### Usage

```perl
    use Lingua::EN::NameCase qw(nc);
    print nc('MR. JON WHITACRE III');    # Mr. Jon Whitacre III
```

#### Example

```
    nc('KEITH');              # 'Keith'
    nc('o\'callaghan');       # "O'Callaghan"
    nc('mccarthy');           # 'McCarthy'
    nc(\ 'henry viii');       # 'Henry VIII'
    nc('van der post');       # 'van der Post'

    local $Lingua::EN::NameCase::ROMAN = 0;
    nc('na li');              # 'Na Li'
```

#### Api Specification

##### Input

```perl
    {
            name => {
                    type     => 'string',     # or a scalarref to a string
                    optional => 1,            # defaults to $_
                    max      => undef,        # $MAX_LENGTH, when set
            },
    }
```

Valid and invalid input, by partition:

- Argument count

    Valid: 0 (`$_` is used) or 1.  Invalid: 2 or more (croak `usage_nc`,
    reported as `list`).

- Argument type

    Valid: a string, a number, a scalar reference, `undef`, `''` and `'0'`
    (the last three are returned unchanged).  Invalid: any other reference
    (HASH, ARRAY, CODE, GLOB, REF, Regexp, or an object); croak `usage_nc`,
    with the type or class name made safe and cut to 64 characters.

- Length (`$MAX_LENGTH`)

    Counted in characters, never bytes.  `undef` means no limit.  A length
    equal to the maximum is accepted.  One character more croaks `too_long`.
    A maximum of 0 admits only the false values.  Negative or non-numeric
    maximums are not checked; keep to non-negative integers.

- Text

    Any character string is accepted: ASCII, accented Latin, Greek, Cyrillic,
    CJK, Hebrew, emoji, combining marks (Zalgo), and bidi controls such as
    U+202E.  None of these crash or lose characters.  The result is at most 3
    times as long as the input.  Undecoded bytes are not cased.

- Recognised patterns

    `Mac` is split when 3 or more letters follow and the last is not one of
    `a c i o z j`; `Mc` is always split.  Roman numerals I to LXXXIX are
    converted; 90 (XC), IIII, XXXX and LXXXX are not.  Post-nominals are
    converted only at the end of the string.

##### Output

```perl
    { type => 'string', optional => 1 }    # undef in, undef out
```

#### Messages

- `usage_nc`

    _Usage: nc \[\[\\\]$SCALAR\] (got {got})_.
    More than one argument, or a reference that is not a scalar reference,
    was supplied (`{got}` names the type).  Pass one string or `\$string`.

- `too_long`

    _Name is too long: {length} characters (the maximum is {max})_.
    `$MAX_LENGTH` is set and the name is longer.  Shorten the input, or raise
    the limit.

#### Pseudocode

```perl
    validate arguments (at most one; a plain scalar or SCALAR ref)
    take the argument, or $_ when none was given
    dereference it if it is a reference
    return it at once if it is false (undef, '', '0')
    lowercase it, capitalise each word, lowercase 's
    apply the Mc/Mac rules
    lowercase the particles (da, de, van, von, ...)
    if ROMAN: upper-case roman numerals
    if POSTNOMINAL: normalise a trailing PhD, MBE, ...
    return the result
```

## Security

The module only reads and builds strings.  It opens no files, runs no
programs, uses no string `eval`, and never turns its input into code or
into part of a regular expression.  Notes for programs that use it:

- Taint mode

    Taint is kept: a name that is tainted gives a tainted result.  The module
    never launders data and works under `perl -T`.

- Untrusted names

    Names from users can be very long.  Set `$Lingua::EN::NameCase::MAX_LENGTH`.
    Case mapping can lengthen text: the result is at most three times as long as
    the input.  The length check is on the input, before the mapping.

- Error messages

    The type or class name of a bad argument is cut to 64 characters and any
    character other than a letter, digit, underscore or colon is shown as "?",
    so a hostile class name cannot add lines or escape codes to a log.

- Settings are global

    The switches, `$MAX_LENGTH` and `%MESSAGES` are package variables, so any
    code in the same program can change them.  Use `local`.  They are not a
    security boundary.

- Locked internals

    [Sub::Private](https://metacpan.org/pod/Sub%3A%3APrivate), when installed, stops other packages calling the internal
    routines.  This is for tidiness, not security; it is switched off when the
    environment variable `HARNESS_ACTIVE` is true, and it is absent when
    [Sub::Private](https://metacpan.org/pod/Sub%3A%3APrivate) is not installed.

- Malformed text

    Invalid characters (lone surrogates, code points above U+10FFFF) are passed
    through without a warning.  Check the encoding of untrusted input before
    calling this module.

## Performance

A typical name (two to four words) takes about 10 microseconds, which is
about 100,000 names a second, measured on an ordinary desktop with Perl 5.40.
The time grows in step with the length of the name.  Each step is a small
number of regular expression passes over the name, and
the cost of each pass was measured and tuned:

- The roman numeral and particle rules each make one pass.
- A trailing post-nominal is found by matching the reversed name at its
start, so a very long name costs no more for this step than a short one.
- Patterns are compiled once, when the module loads.
- If [Sub::Private](https://metacpan.org/pod/Sub%3A%3APrivate) is installed each internal call is about 0.4
microseconds slower; this is the price of locking the internals.

Set `$Lingua::EN::NameCase::MAX_LENGTH` to bound the time spent on any one
name.

## Limitations

The design choices below are known weaknesses.

- Global configuration

    `$HEBREW`, `$SPANISH`, `$ROMAN` and `$POSTNOMINAL` are package
    variables, so one part of a program changing them changes the result for
    all of it.  Use `local` to scope a change.  A per-call options hash would
    be better, but would change the API.

- Scalar references are not modified in place

    `NameCase(\$name)` returns a copy.  Changing this would break existing
    callers.

- Exceptions are prefixes

    The "Mac" exceptions match the start of a word, so MacInnes becomes
    Macinnes and MacKenzie becomes Mackenzie.  An exact-surname list would be
    more accurate but needs data this module does not have.

- Everything is an English-language heuristic

    Names are not cased by a grammar.  "Ben" and "Van" are lowercased only when
    they follow another word, and every word of a name is treated alike
    (`Estate Of Laura Jones`).  For real name parsing use
    [Lingua::EN::NameParse](https://metacpan.org/pod/Lingua%3A%3AEN%3A%3ANameParse).

- Locale is ignored

    Case rules are the Unicode rules, whatever the locale.  Older versions used
    `use locale`, which gave different answers on different machines.  Data in
    a legacy 8-bit code page must be decoded first (see ["ENCODING"](#encoding)).  Language
    rules are not applied, so Turkish "I" becomes "i", not a dotless "i".

- The Mac test covers the whole string

    Whether the "Mac" rules apply is decided once for the whole string, not word
    by word.  A string that holds both a name such as "Mcdonald" and a name such
    as "Macchiato" will have both treated as Mac names.  Pass one name at a time.

- Hebrew particles need one space

    "ben" and "bat" are recognised only when exactly one white space character
    separates them from the word in front.

- Post-nominals only at the end

    Only the last word is checked, and the list is not exhaustive.
    Since the entries are now matched literally, "MCh." and "FCSP." require
    their final dot (the dot used to match any character).

- Error messages

    Messages are English templates with `{name}` placeholders, replaceable
    through `%MESSAGES`.  There is no plural or gender handling because none
    of the messages needs it.

- Encapsulation

    The internal routines are guarded with [Sub::Private](https://metacpan.org/pod/Sub%3A%3APrivate) in enforce mode, but
    only if that module is installed.  It is optional because it needs Perl 5.14
    or later and heavy dependencies; without it the internals are ordinary
    subroutines whose names start with an underscore.  [Sub::Protected](https://metacpan.org/pod/Sub%3A%3AProtected) is not
    used because the module has no classes or methods to protect.

## Bugs

The module covers the rules that I know of. There are probably a lot
more rules, exceptions etc. for "Western"-style languages which could be
incorporated.

There are probably lots of exceptions and problems - but as a general
data 'cleaner' it may be all you need.

Use Kim Ryan's [Lingua::EN::NameParse](https://metacpan.org/pod/Lingua%3A%3AEN%3A%3ANameParse) for any really sophisticated name parsing.

## See Also

- [Test Dashboard](https://nigelhorne.github.io/Lingua-EN-NameCase/coverage/)

## Support

You can find documentation for this module with the perldoc command.

```
    perldoc Lingua::EN::NameCase
```

You can also look for information at:

- MetaCPAN

    [https://metacpan.org/release/Lingua-EN-NameCase](https://metacpan.org/release/Lingua-EN-NameCase)

- RT: CPAN's request tracker

    [https://rt.cpan.org/NoAuth/Bugs.html?Dist=Lingua-EN-NameCase](https://rt.cpan.org/NoAuth/Bugs.html?Dist=Lingua-EN-NameCase)

- CPANTS

    [http://cpants.cpanauthors.org/dist/Lingua-EN-NameCase](http://cpants.cpanauthors.org/dist/Lingua-EN-NameCase)

- CPAN Testers' Matrix

    [http://matrix.cpantesters.org/?dist=Lingua-EN-NameCase](http://matrix.cpantesters.org/?dist=Lingua-EN-NameCase)

- CPAN Testers Dependencies

    [http://deps.cpantesters.org/?module=Lingua::EN::NameCase](http://deps.cpantesters.org/?module=Lingua::EN::NameCase)

## Author

```
1998-2014    Mark Summerfield <summer@qtrac.eu>
2014-present Barbie <barbie@cpan.org>

2020- Maintained by Nigel Horne, C<< <njh at nigelhorne.com> >>
```

## Acknowledgements

Thanks to Kim Ryan <kimaryan@ozemail.com.au> for his Mc/Mac solution.

## Formal Specification

This section is for readers who know Z notation.  It is the only part of
this file that is not plain ASCII.  Each schema describes one function.
A prime (') marks a value after the call.  `ARGS` is the list of arguments,
`ANY` is any Perl value, and `STRING` is a Perl string.

### NameCase

```
    ┌─ NameCase ─────────────────────────────────────────────
    │ args? : seq ANY
    │ ctx?  : { list, scalar, void }
    │ out!  : seq STRING ∪ STRING ∪ ARRAYREF
    ├────────────────────────────────────────────────────────
    │ ref(head args?) ∉ { ARRAY, SCALAR, ∅ } ⇒ croak usage_namecase
    │ ctx? = list ∧ (#args? > 1 ∨ ref(head args?) = ARRAY)
    │     ⇒ out! = nc ∘ (elements args?)
    │ ctx? ≠ list ∧ ref(head args?) = ARRAY
    │     ⇒ head args? ' = nc ∘ (head args?) ∧ out! = head args?
    │ ref(head args?) = SCALAR ⇒ out! = nc(↑(head args?))
    │ ref(head args?) = ∅ ∧ #args? = 1 ⇒ out! = nc(head args?)
    │ otherwise ⇒ croak single_arg
    └────────────────────────────────────────────────────────
```

### Nc

```
    ┌─ nc ───────────────────────────────────────────────────
    │ name? : STRING ∪ ↑STRING ∪ {⊥}
    │ out!  : STRING ∪ {⊥}
    ├────────────────────────────────────────────────────────
    │ #args > 1 ∨ ref(name?) ∉ { ∅, SCALAR } ⇒ croak usage_nc
    │ MAX_LENGTH ≠ ⊥ ∧ value ∉ {⊥, "", "0"} ∧ #value > MAX_LENGTH ⇒ croak too_long
    │ value = (name? ∈ ↑STRING ⇒ ↑name?  ∨  name?)
    │ value ∈ {⊥, "", "0"} ⇒ out! = value
    │ otherwise
    │   out! = postnominal ∘ roman ∘ particles ∘ mac ∘ base (value)
    │   where roman and postnominal apply only when enabled
    └────────────────────────────────────────────────────────
```

### Configuration

```
    ┌─ Config ───────────────────────────────────────────────
    │ HEBREW, SPANISH, ROMAN, POSTNOMINAL : { 0, 1 }
    │ MAX_LENGTH : ℕ ∪ {⊥}
    │ MESSAGES : KEY ⇸ STRING
    └────────────────────────────────────────────────────────
    ┌─ Init ─────────────────────────────────────────────────
    │ Config'
    ├────────────────────────────────────────────────────────
    │ HEBREW' = 1 ∧ SPANISH' = 0 ∧ ROMAN' = 1 ∧ POSTNOMINAL' = 1
    │ MESSAGES' = ∅ ∧ MAX_LENGTH' = ⊥
    └────────────────────────────────────────────────────────
    ┌─ Set ──────────────────────────────────────────────────
    │ ΔConfig ; flag? : { HEBREW, SPANISH, ROMAN, POSTNOMINAL } ; v? : { 0, 1 }
    ├────────────────────────────────────────────────────────
    │ flag?' = v? ∧ all other variables are unchanged
    └────────────────────────────────────────────────────────
```

nc and NameCase read Config and never change it (ΞConfig).

## State Diagram

The module keeps no data between calls except the configuration.  So there
are two small machines: the configuration, and what happens during one call.

Configuration (the four switches, `$MAX_LENGTH` and `%MESSAGES`):

```perl
      use Lingua::EN::NameCase
                |
                v
       +-----------------+   set a switch or %MESSAGES key   +-----------------+
       |    DEFAULTS     |---------------------------------->|   CUSTOMISED    |
       | HEBREW=1        |   action: later calls use it      | any switch or   |
       | SPANISH=0       |<----------------------------------| message differs |
       | ROMAN=1         |   set back, or leave a block      +-----------------+
       | POSTNOMINAL=1   |   that used "local"                  |          ^
       +-----------------+                                      +----------+
                                                                set again
```

DEFAULTS also means that `$MAX_LENGTH` is `undef` and `%MESSAGES` is
empty.  Both states accept every call below.  Calls never change the
configuration.

One call to `nc` or `NameCase`:

```
     nc(...) / NameCase(...)
            |
            v
      +------------+  bad type, wrong count   +----------+
      | VALIDATING |------------------------->|  FAILED  |
      +------------+  action: croak with the  +----------+
            |         message (usage_nc,       (the caller
            | ok      usage_namecase,           gets an
            v         single_arg)               exception)
      +------------+  undef, "" or "0"        +----------+
      |  READING   |------------------------->|   DONE   |
      +------------+  action: return it as is +----------+
            |                                       ^
            | has text                              |
            v                                       |
      +------------+  base case, Mc/Mac, particles,  |
      |   CASING   |  roman numerals (if ROMAN),     |
      +------------+  post-nominal (if POSTNOMINAL)  |
            |                                       |
            +---------------------------------------+
              action: return the new string

      READING also goes to FAILED when $MAX_LENGTH is set and the text is
      longer (message too_long).  The caller gets an exception and nothing
      is changed.

      NameCase only: an array ref in scalar or void context goes from
      CASING to DONE after replacing each element (the only side effect
      on caller data), and returns the array ref.
```

## License and Copyright

Copyright (c) Mark Summerfield 1998-2014. All Rights Reserved.
Copyright (c) Barbie 2014-2015. All Rights Reserved.
Copyright (c) Nigel Horne 2020-2026. All Rights Reserved.

This distribution is free software; you can redistribute it and/or
modify it under the Artistic License 2.0.
