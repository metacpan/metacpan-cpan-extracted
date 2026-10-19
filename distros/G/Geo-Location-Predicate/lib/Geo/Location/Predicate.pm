package Geo::Location::Predicate;

# The one definition of what counts as a location.
#
# It was a module of Geo::Coder::Free until 0.48, and lives in a distribution of
# its own now for two reasons.  The first is weight: the six geocoders that ask
# the rule - Geo::Coder::CA, DataScienceToolkit, GeoApify, List, Postcodes and
# XYZ - are releases of their own, and while the rule lived inside
# Geo::Coder::Free the only way for them to name it in their metadata was to
# require the facade too, with its backends, its databases and its cache; so each
# looked for the module when it loaded instead of declaring it.  The second is
# that the rule is useful on its own and does not need any of that: it is a cheap
# syntactic test with no dependencies at all, so it can be the dependency the six
# declare - a recommendation in their META, which an installer fetches by
# default.
#
# The name says the question, not the namespace it was written in.  It is a
# predicate - could this string be a location? - and not a validator, which
# would promise that the string is a correct address or a real place; the answer
# is a policy about whether a lookup is worth making, so a numeric geocoder may
# want it to say true where this says false.  Geo::Location::* is where a
# location is looked at rather than where one is looked up (that is Geo::Coder::*,
# ::CA and ::OSM being geocoders for a service each), and it sits beside
# Geo::Location::Point for a caller who already has coordinates in hand.  Every
# caller says Geo::Location::Predicate::_valid_location(), including the facade
# and both of its backends; the sub keeps its private name so that it does not
# compete with the public spelling the facade already offers.
#
# The class - not the file - is the unit: L<Geo::Coder::Free> calls this rule and
# depends on this distribution, and the six call it when it is installed and fall
# back to refusing a reference when it is not.
#
# Zero dependencies is the point of the distribution, so nothing beyond core
# perl is loaded here - not Params::Validate::Strict, not Readonly, not
# Sub::Private.  Each of those would become a prerequisite of eight
# distributions to guard one line, and Sub::Private would stop the eight
# callers from calling the rule at all.

use strict;
use warnings;

# Exporter's import() is inherited by name rather than through @ISA; that form
# needs Exporter 5.57, which is first in perl 5.8.3 (hence MIN_PERL_VERSION).
use Exporter qw(import);
our @EXPORT_OK = qw(_valid_location);

=head1 NAME

Geo::Location::Predicate - The rule that decides whether a string could be a location

=head1 VERSION

Version 0.02

=cut

our $VERSION = '0.02';

=head1 SYNOPSIS

Ask the question before you spend time on a lookup:

    use Geo::Location::Predicate qw(_valid_location);

    if(_valid_location($row->{'place'})) {
        # The value could be a place, so it is worth a lookup
    }

Remove the rows that cannot be places, before a batch of lookups:

    use Geo::Location::Predicate qw(_valid_location);

    my @to_look_up = grep { _valid_location($_->{'place'}) } @rows;

Call the rule by its full name, without importing anything:

    require Geo::Location::Predicate;

    my $ok = Geo::Location::Predicate::_valid_location($text);

Use the rule only when it is installed, and fall back to a weaker test when it
is not.  This is what the six sibling geocoders do:

    my $is_location = eval { require Geo::Location::Predicate; 1 }
        ? \&Geo::Location::Predicate::_valid_location
        : sub { defined($_[0]) && !ref($_[0]) && length($_[0]) };

    return unless $is_location->($location);

Clean the value first, if it comes from a file:

    chomp(my $place = <$fh>);
    $place =~ s/^\s+|\s+$//g;     # remove spaces at the start and the end
    next unless _valid_location($place);

=head1 DESCRIPTION

This module answers one question: B<could this value be a location?>

The answer is "no" (C<0>) for:

=over 4

=item * C<undef> (no value)

=item * the empty string C<''>

=item * a reference of any kind (an array, a hash, an object, ...)

=item * a string that contains only digits, for example C<'0044'>

=back

The answer is "yes" (C<1>) for every other value.  The value needs only one
character that is not a digit.  So C<'London'>, C<'Ramsgate, Kent'>, C<'3.14'>,
C<'-'> and even C<' '> (one space) all get "yes".

=head2 Why this rule exists

A geocoder often reads a table, such as a CSV file.  When a program reads the
wrong column by mistake, it gets numbers (an ID, a phone number, a count)
instead of place names.  A number made only of digits is never a place name,
so a lookup for it wastes time and may return a wrong match.  This rule stops
those lookups.

=head2 What "yes" means

"Yes" does B<not> mean that the place exists.  It means only that the value is
not obviously wrong.  C<'Ramsgate, Kent'> gets "yes", and a geocoder may still
find nothing for it.  The test only looks at the characters.  It does not use a
database or the network, so it is very fast.

=head2 Who uses it

L<Geo::Coder::Free> asks this question before it searches.  Its two backends,
L<Geo::Coder::Free::MaxMind> and L<Geo::Coder::Free::OpenAddresses>, ask it too.
Six other geocoders also ask it: Geo::Coder::CA, Geo::Coder::DataScienceToolkit,
Geo::Coder::GeoApify, Geo::Coder::List, Geo::Coder::Postcodes and
Geo::Coder::XYZ.

All of them use this one copy of the rule.  This is on purpose: if each one had
its own copy, the copies could change in different ways, and one program could
accept a value that another refuses.

L<Geo::Coder::Free> needs this module.  For the six other geocoders it is
optional: they list it as "recommended", and they load it only when they first
need it.  Without it, they can still refuse a reference, but they cannot refuse
a string of digits.

This module has no dependencies outside core Perl.  That is why it is a
separate distribution: the six geocoders can recommend it without also
installing Geo::Coder::Free and its databases.

=head2 Should I call it?

Usually not.  If you use L<Geo::Coder::Free>, call its public method
C<< $geo->valid_location($place) >>, which gives the same answer.  The name of
this function starts with C<_> because it is meant for the geocoders listed
above.  But the name will not change, because those geocoders depend on it.

=head1 SUBROUTINES/METHODS

=head2 _valid_location

    my $answer = _valid_location($value);

=over 4

=item Purpose

Says whether a value could be a location, so that the caller can skip a lookup
that cannot work.

=item Arguments

One value of any kind.  If you give more than one argument, only the first is
used.  If you give no argument, it is treated as C<undef>.

=item Returns

The number C<1> ("yes, it could be a location") if the value is a plain string
or number and has at least one character that is not a digit.

The number C<0> ("no") in every other case.

It always returns exactly one value, also in list context.  So it is safe to
use inside C<map>.

=item Side effects

None.  It does not die and does not warn, whatever you give it.  It does not
change its argument, C<$_>, C<$!>, C<$@>, or the match variables (C<$1> and so
on) of the caller.  It does not call the stringify (C<"">) overload of an
object.

=item Usage

Call it as a plain function, not as a method.  There is no object and no
C<new()>.  Import it by name, because it is not exported by default:

    use Geo::Location::Predicate qw(_valid_location);

=back

=head3 EXAMPLE

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

=head3 API SPECIFICATION

=head4 INPUT

One positional argument, written in L<Params::Validate::Strict> form.  Every
value is accepted, so validation never fails: the job of this function is to
answer "no" for a bad value, not to reject it.

    [
        {
            name     => 'location',
            type     => 'any',      # a string, a number, undef or a reference
            optional => 1,          # no argument means undef
        },
    ]

=head4 OUTPUT

Written in L<Return::Set> form:

    {
        type => 'integer',
        min  => 0,
        max  => 1,
    }

=head3 MESSAGES

The function itself never gives an error or a warning.  The only messages come
from Perl when the module is loaded in a wrong way:

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

=cut

# One expression, one exit: the three disqualifications are tested in order of
# cost, and each short-circuits the next.  ref() comes before the match so that
# an object is never stringified - its "" overload is not called and cannot die
# or have side effects.  No length() test is needed: '' has no non-digit, so the
# match already refuses it.
sub _valid_location {
	my $location = shift;

	return (defined($location) && !ref($location) && $location =~ /\D/) ? 1 : 0;
}

1;

__END__

=head1 ENCODING

The function works on Perl B<characters>, not on bytes.

=over 4

=item * Plain ASCII text

Fully supported.  The digits are C<0> to C<9>.

=item * Non-ASCII text and other scripts (UTF-8)

Fully supported, if the text is B<decoded> first (for example with
C<< open(my $fh, '<:encoding(UTF-8)', $file) >> or C<Encode::decode('UTF-8', $bytes)>).
Names such as C<"M\x{fc}nchen"> (Munich) or C<"\x{6771}\x{4eac}"> (Tokyo) get
"yes".

=item * Digits from other scripts

A "digit" is any Unicode decimal digit, not only C<0> to C<9>.  So
C<"\x{0661}\x{0662}"> (Arabic-Indic 1 and 2) and C<"\x{FF11}\x{FF12}"> (full-width
1 and 2) get "no", the same as C<'12'>.  Superscript digits such as
C<"\x{b2}"> are B<not> decimal digits in Unicode, so they get "yes".

=item * Emoji

Supported.  An emoji is not a digit, so a string that contains one gets "yes".

=item * Bytes that were not decoded

B<Not> safe.  See L</COMMON PITFALLS>.

=back

The answer does not depend on the locale (C<LC_ALL>, C<LANG>), on
C<use locale> in your code, or on whether Perl stores the string internally as
UTF-8.

=head1 COMMON PITFALLS

=over 4

=item * Undecoded UTF-8 bytes give a different answer

If you read text as raw bytes, digits from other scripts become several bytes
that are not digits.  So C<_valid_location("\x{0661}\x{0662}")> is C<0>, but the
same text as undecoded UTF-8 bytes, C<"\xd9\xa1\xd9\xa2">, is C<1>.  Decode your
input before you ask.

=item * A newline or a space makes the answer "yes"

C<"0044\n"> and C<' 0044 '> get "yes", because a newline and a space are not
digits.  This often happens when you forget C<chomp> after reading a line, or
when a field has padding.  Remove spaces before you ask (see the SYNOPSIS).
A string of only spaces, such as C<' '>, also gets "yes".

=item * C<undef> is "no", not an error

C<undef> does not cause a warning or an error; it gets C<0>.  So you cannot use
this function to find out whether a value is missing; it only tells you that
you should not look it up.  A missing argument is also C<undef>.

=item * Numbers are judged by how Perl writes them

The function looks at the number as text.  C<44> gets "no", but C<-44> gets
"yes" (because of the C<->), and C<0.5> gets "yes" (because of the C<.>).  The
number C<1e3> is written by Perl as C<1000>, so it gets "no", but the string
C<'1e3'> gets "yes".

=item * Objects always get "no"

An object gets C<0> even if it turns into a place name when you print it.
Turn it into a string yourself first:

    _valid_location("$address_object");

=item * A hash or a list as the argument

C<_valid_location(%row)> or C<_valid_location(@list)> only looks at the first
item, and gives no warning.  Pass one value.

=item * "Yes" does not mean "found"

"Yes" only means "not obviously wrong".  Always check the result of the
lookup itself.

=back

=head1 LIMITATIONS

These are design decisions.  Each one can be argued with, but changing any of
them would change the answer for all nine programs that use this rule at the
same time, so they are listed here and not changed silently.

=over 4

=item * White space counts as a non-digit

See L</COMMON PITFALLS>.  A stricter rule would be C</[^\d\s]/>: "at least one
character that is not a digit and not white space".

=item * The rule sees the text, not the number

It refuses "only digits", not "a number".  See L</COMMON PITFALLS>.

=item * Objects are refused even when they print as a place

The function does not turn an object into a string, so that a broken overload
cannot make it die.

=item * The name looks private

The function is public and exported, but its name starts with C<_>.  Tools such
as L<Pod::Coverage> treat it as private.  The name cannot change, because other
modules call it by that name.

=item * Extra arguments are ignored

There is no warning when more than one argument is given.

=back

=head1 SEE ALSO

L<Geo::Coder::Free>, L<Geo::Location::Point>

=head1 AUTHOR

Nigel Horne, C<< <njh at nigelhorne.com> >>

=encoding utf-8

=head1 FORMAL SPECIFICATION

This section describes the function in the Z notation.  You do not need it to
use the module.

=head2 _valid_location

The module keeps no state, so there is no state schema and no C<Delta>
operation: the function only reads its input.

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

The empty string needs no rule of its own: C<dom E<lt>E<gt> = ∅>, so no C<i>
exists, and C<result! = 0>.

=head1 STATE DIAGRAM

The module has no data that changes between calls.  So it has only two kinds
of state: the state of the module in a program (diagram 1), and the steps of
one call (diagram 2).  A call always starts and ends in the same module state.

Diagram 1 - the module in a program:

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

Diagram 2 - one call of _valid_location($value):

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

=head1 LICENSE AND COPYRIGHT

Copyright 2026 Nigel Horne.

This program is free software; you can redistribute it and/or modify it under
the terms of the GNU General Public License, version 2.
