## Name

Geo::Location::Predicate - The rule that decides whether a string could be a location

## Version

Version 0.02

## Synopsis

Ask the question before you spend time on a lookup:

```perl
use Geo::Location::Predicate qw(_valid_location);

if(_valid_location($row->{'place'})) {
    # The value could be a place, so it is worth a lookup
}
```

Remove the rows that cannot be places, before a batch of lookups:

```perl
use Geo::Location::Predicate qw(_valid_location);

my @to_look_up = grep { _valid_location($_->{'place'}) } @rows;
```

Call the rule by its full name, without importing anything:

```perl
require Geo::Location::Predicate;

my $ok = Geo::Location::Predicate::_valid_location($text);
```

Use the rule only when it is installed, and fall back to a weaker test when it
is not.  This is what the six sibling geocoders do:

```perl
my $is_location = eval { require Geo::Location::Predicate; 1 }
    ? \&Geo::Location::Predicate::_valid_location
    : sub { defined($_[0]) && !ref($_[0]) && length($_[0]) };

return unless $is_location->($location);
```

Clean the value first, if it comes from a file:

```perl
chomp(my $place = <$fh>);
$place =~ s/^\s+|\s+$//g;     # remove spaces at the start and the end
next unless _valid_location($place);
```

## Description

This module answers one question: **could this value be a location?**

The answer is "no" (`0`) for:

- `undef` (no value)
- the empty string `''`
- a reference of any kind (an array, a hash, an object, ...)
- a string that contains only digits, for example `'0044'`

The answer is "yes" (`1`) for every other value.  The value needs only one
character that is not a digit.  So `'London'`, `'Ramsgate, Kent'`, `'3.14'`,
`'-'` and even `' '` (one space) all get "yes".

### Why This Rule Exists

A geocoder often reads a table, such as a CSV file.  When a program reads the
wrong column by mistake, it gets numbers (an ID, a phone number, a count)
instead of place names.  A number made only of digits is never a place name,
so a lookup for it wastes time and may return a wrong match.  This rule stops
those lookups.

### What "Yes" Means

"Yes" does **not** mean that the place exists.  It means only that the value is
not obviously wrong.  `'Ramsgate, Kent'` gets "yes", and a geocoder may still
find nothing for it.  The test only looks at the characters.  It does not use a
database or the network, so it is very fast.

### Who Uses It

[Geo::Coder::Free](https://metacpan.org/pod/Geo%3A%3ACoder%3A%3AFree) asks this question before it searches.  Its two backends,
[Geo::Coder::Free::MaxMind](https://metacpan.org/pod/Geo%3A%3ACoder%3A%3AFree%3A%3AMaxMind) and [Geo::Coder::Free::OpenAddresses](https://metacpan.org/pod/Geo%3A%3ACoder%3A%3AFree%3A%3AOpenAddresses), ask it too.
Six other geocoders also ask it: Geo::Coder::CA, Geo::Coder::DataScienceToolkit,
Geo::Coder::GeoApify, Geo::Coder::List, Geo::Coder::Postcodes and
Geo::Coder::XYZ.

All of them use this one copy of the rule.  This is on purpose: if each one had
its own copy, the copies could change in different ways, and one program could
accept a value that another refuses.

[Geo::Coder::Free](https://metacpan.org/pod/Geo%3A%3ACoder%3A%3AFree) needs this module.  For the six other geocoders it is
optional: they list it as "recommended", and they load it only when they first
need it.  Without it, they can still refuse a reference, but they cannot refuse
a string of digits.

This module has no dependencies outside core Perl.  That is why it is a
separate distribution: the six geocoders can recommend it without also
installing Geo::Coder::Free and its databases.

### Should I Call It?

Usually not.  If you use [Geo::Coder::Free](https://metacpan.org/pod/Geo%3A%3ACoder%3A%3AFree), call its public method
`$geo->valid_location($place)`, which gives the same answer.  The name of
this function starts with `_` because it is meant for the geocoders listed
above.  But the name will not change, because those geocoders depend on it.

## Subroutines/Methods

### \_Valid\_Location

```perl
my $answer = _valid_location($value);
```

- Purpose

    Says whether a value could be a location, so that the caller can skip a lookup
    that cannot work.

- Arguments

    One value of any kind.  If you give more than one argument, only the first is
    used.  If you give no argument, it is treated as `undef`.

- Returns

    The number `1` ("yes, it could be a location") if the value is a plain string
    or number and has at least one character that is not a digit.

    The number `0` ("no") in every other case.

    It always returns exactly one value, also in list context.  So it is safe to
    use inside `map`.

- Side effects

    None.  It does not die and does not warn, whatever you give it.  It does not
    change its argument, `$_`, `$!`, `$@`, or the match variables (`$1` and so
    on) of the caller.  It does not call the stringify (`""`) overload of an
    object.

- Usage

    Call it as a plain function, not as a method.  There is no object and no
    `new()`.  Import it by name, because it is not exported by default:

    ```perl
    use Geo::Location::Predicate qw(_valid_location);
    ```

#### Example

```perl
use Geo::Location::Predicate qw(_valid_location);

_valid_location('Ramsgate, Kent');  # 1 - a place name
_valid_location('GB');              # 1 - a country code
_valid_location('3.14');            # 1 - the '.' is not a digit
_valid_location(' ');               # 1 - a space is not a digit
_valid_location('0044');            # 0 - only digits
_valid_location(44);                # 0 - a number is read as '44'
_valid_location(-44);               # 1 - a number is read as '-44'
_valid_location('');                # 0 - empty
_valid_location(undef);             # 0 - no value
_valid_location(['London']);        # 0 - a reference

# Keep only the rows that could be places
my @to_look_up = grep { _valid_location($_->{'place'}) } @rows;
```

#### Api Specification

##### Input

One positional argument, written in [Params::Validate::Strict](https://metacpan.org/pod/Params%3A%3AValidate%3A%3AStrict) form.  Every
value is accepted, so validation never fails: the job of this function is to
answer "no" for a bad value, not to reject it.

```perl
[
    {
        name     => 'location',
        type     => 'any',      # a string, a number, undef or a reference
        optional => 1,          # no argument means undef
    },
]
```

##### Output

Written in [Return::Set](https://metacpan.org/pod/Return%3A%3ASet) form:

```perl
{
    type => 'integer',
    min  => 0,
    max  => 1,
}
```

#### Messages

The function itself never gives an error or a warning.  The only messages come
from Perl when the module is loaded in a wrong way:

```perl
+------------------------------------+----------------------+----------------------+
| Message                            | Meaning              | What to do           |
+------------------------------------+----------------------+----------------------+
| "NAME" is not exported by the      | You asked to import  | Import only          |
| Geo::Location::Predicate module    | a name that does not | _valid_location      |
| Can't continue after import errors | exist, for example   | (with the leading    |
|                                    | valid_location       | underscore)          |
+------------------------------------+----------------------+----------------------+
| Geo::Location::Predicate version N | You asked for a      | Install a newer      |
| required--this is only version M   | newer version than   | version, or ask for  |
|                                    | the one installed    | a lower one          |
+------------------------------------+----------------------+----------------------+
| Can't locate                       | The module is not    | Install it, or load  |
| Geo/Location/Predicate.pm in @INC  | installed            | it inside eval {} as |
|                                    |                      | in the SYNOPSIS      |
+------------------------------------+----------------------+----------------------+
| Undefined subroutine               | You called the       | Import it by name,   |
| &main::_valid_location called      | function without     | or use its full name |
|                                    | importing it         |                      |
+------------------------------------+----------------------+----------------------+
```

## Encoding

The function works on Perl **characters**, not on bytes.

- Plain ASCII text

    Fully supported.  The digits are `0` to `9`.

- Non-ASCII text and other scripts (UTF-8)

    Fully supported, if the text is **decoded** first (for example with
    `open(my $fh, '<:encoding(UTF-8)', $file)` or `Encode::decode('UTF-8', $bytes)`).
    Names such as `"M\x{fc}nchen"` (Munich) or `"\x{6771}\x{4eac}"` (Tokyo) get
    "yes".

- Digits from other scripts

    A "digit" is any Unicode decimal digit, not only `0` to `9`.  So
    `"\x{0661}\x{0662}"` (Arabic-Indic 1 and 2) and `"\x{FF11}\x{FF12}"` (full-width
    1 and 2) get "no", the same as `'12'`.  Superscript digits such as
    `"\x{b2}"` are **not** decimal digits in Unicode, so they get "yes".

- Emoji

    Supported.  An emoji is not a digit, so a string that contains one gets "yes".

- Bytes that were not decoded

    **Not** safe.  See ["COMMON PITFALLS"](#common-pitfalls).

The answer does not depend on the locale (`LC_ALL`, `LANG`), on
`use locale` in your code, or on whether Perl stores the string internally as
UTF-8.

## Common Pitfalls

- Undecoded UTF-8 bytes give a different answer

    If you read text as raw bytes, digits from other scripts become several bytes
    that are not digits.  So `_valid_location("\x{0661}\x{0662}")` is `0`, but the
    same text as undecoded UTF-8 bytes, `"\xd9\xa1\xd9\xa2"`, is `1`.  Decode your
    input before you ask.

- A newline or a space makes the answer "yes"

    `"0044\n"` and `' 0044 '` get "yes", because a newline and a space are not
    digits.  This often happens when you forget `chomp` after reading a line, or
    when a field has padding.  Remove spaces before you ask (see the SYNOPSIS).
    A string of only spaces, such as `' '`, also gets "yes".

- `undef` is "no", not an error

    `undef` does not cause a warning or an error; it gets `0`.  So you cannot use
    this function to find out whether a value is missing; it only tells you that
    you should not look it up.  A missing argument is also `undef`.

- Numbers are judged by how Perl writes them

    The function looks at the number as text.  `44` gets "no", but `-44` gets
    "yes" (because of the `-`), and `0.5` gets "yes" (because of the `.`).  The
    number `1e3` is written by Perl as `1000`, so it gets "no", but the string
    `'1e3'` gets "yes".

- Objects always get "no"

    An object gets `0` even if it turns into a place name when you print it.
    Turn it into a string yourself first:

    ```
    _valid_location("$address_object");
    ```

- A hash or a list as the argument

    `_valid_location(%row)` or `_valid_location(@list)` only looks at the first
    item, and gives no warning.  Pass one value.

- "Yes" does not mean "found"

    "Yes" only means "not obviously wrong".  Always check the result of the
    lookup itself.

## Limitations

These are design decisions.  Each one can be argued with, but changing any of
them would change the answer for all nine programs that use this rule at the
same time, so they are listed here and not changed silently.

- White space counts as a non-digit

    See ["COMMON PITFALLS"](#common-pitfalls).  A stricter rule would be `/[^\d\s]/`: "at least one
    character that is not a digit and not white space".

- The rule sees the text, not the number

    It refuses "only digits", not "a number".  See ["COMMON PITFALLS"](#common-pitfalls).

- Objects are refused even when they print as a place

    The function does not turn an object into a string, so that a broken overload
    cannot make it die.

- The name looks private

    The function is public and exported, but its name starts with `_`.  Tools such
    as [Pod::Coverage](https://metacpan.org/pod/Pod%3A%3ACoverage) treat it as private.  The name cannot change, because other
    modules call it by that name.

- Extra arguments are ignored

    There is no warning when more than one argument is given.

## See Also

[Geo::Coder::Free](https://metacpan.org/pod/Geo%3A%3ACoder%3A%3AFree), [Geo::Location::Point](https://metacpan.org/pod/Geo%3A%3ALocation%3A%3APoint)

## Author

Nigel Horne, `<njh at nigelhorne.com>`

## Formal Specification

This section describes the function in the Z notation.  You do not need it to
use the module.

### \_Valid\_Location

The module keeps no state, so there is no state schema and no `Delta`
operation: the function only reads its input.

```
[VALUE, CHAR]

STRING  : ℙ VALUE                 -- defined values that are not references
chars   : STRING → seq CHAR       -- the value as Perl writes it as text
DIGIT   : ℙ CHAR                  -- Unicode general category Nd

┌─ ValidLocation ─────────────────────────────────
│ location? : VALUE
│ result!   : {0, 1}
├─────────────────────────────────────────────────
│ result! = 1 ⇔
│     location? ∈ STRING ∧
│     (∃ i : dom chars(location?) • chars(location?) i ∉ DIGIT)
└─────────────────────────────────────────────────
```

The empty string needs no rule of its own: `dom <> = ∅`, so no `i`
exists, and `result! = 0`.

## State Diagram

The module has no data that changes between calls.  So it has only two kinds
of state: the state of the module in a program (diagram 1), and the steps of
one call (diagram 2).  A call always starts and ends in the same module state.

Diagram 1 - the module in a program:

```perl
+--------------+  use / require              +--------------+
|  NOT LOADED  |---------------------------->|    LOADED    |
+--------------+  (file compiled once;       +--------------+
       |           $VERSION set)                    |
       |                                            | import qw(_valid_location)
       | require fails                              | (the caller gets the name
       | (not installed)                            |  _valid_location; no other
       v                                            |  name is added)
+--------------+                                    v
| UNAVAILABLE  |                             +--------------+
+--------------+                             |   IMPORTED   |<--+
  the caller uses                            +--------------+   |
  its own fallback                                  |           |
  (see SYNOPSIS)                                    | _valid_   | returns 1 or 0;
                                                    | location()| nothing changes
                                                    +-----------+

import of an unknown name, or a too-high version:
  LOADED --> compile error (see MESSAGES); the program does not start
```

Diagram 2 - one call of \_valid\_location($value):

```
+-----------+
|  CALLED   |  $value is copied; the caller's value is not touched
+-----------+
      |
      | defined($value)?
      +------- no ------------------------------+
      | yes                                     |
      v                                         |
+-----------+                                   |
|  DEFINED  |                                   |
+-----------+                                   |
      |                                         |
      | ref($value)?                            |
      +------- yes (no overload is called) -----+
      | no                                      |
      v                                         |
+-----------+                                   |
|  STRING   |                                   |
+-----------+                                   |
      |                                         |
      | contains a non-digit (/\D/)?            |
      +------- no (only digits, or '') ---------+
      | yes                                     |
      v                                         v
+-----------+                             +-----------+
| ACCEPTED  |  returns 1                  |  REFUSED  |  returns 0
+-----------+                             +-----------+

Side effects of every step: none.
```

## License and Copyright

Copyright 2026 Nigel Horne.

This program is free software; you can redistribute it and/or modify it under
the terms of the GNU General Public License, version 2.
