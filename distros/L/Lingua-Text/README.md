# NAME

Lingua::Text - Store the same text in many languages; retrieve it in the user's language automatically

# VERSION

Version 0.09

# SYNOPSIS

## Basic use: store translations and print in the user's language

    use Lingua::Text;

    my $greeting = Lingua::Text->new(
        en => 'Hello',
        fr => 'Bonjour',
        de => 'Hallo',
    );

    # The system locale (LANG, LC_MESSAGES, etc.) picks the language.
    # No code change is needed when the user's OS language changes.
    print $greeting, "\n";

## Add translations after construction

    my $label = Lingua::Text->new();
    $label->en('Submit');
    $label->fr('Envoyer');
    $label->de('Abschicken');

    # Ask for a specific language explicitly
    print $label->as_string('fr'), "\n";   # Envoyer

## Build from a database hash

    # Suppose the database returns: { en => 'Apple', fr => 'Pomme', de => 'Apfel' }
    my $row  = $db->selectrow_hashref('SELECT en, fr, de FROM fruit WHERE id = ?', {}, $id);
    my $name = Lingua::Text->new($row);
    print $name;   # prints in the user's system language

## Add one translation to an existing object (clone)

    my $base = Lingua::Text->new(en => 'colour', fr => 'couleur');
    my $us   = $base->new(en => 'color');   # American English override

    # $us  has en => 'color',  fr => 'couleur'
    # $base is unchanged: en => 'colour', fr => 'couleur'

## Store text at runtime using a language variable

    my $message = Lingua::Text->new();
    my $user_lang = 'de';   # could come from a web request header

    $message->set(text => 'Willkommen', lang => $user_lang);
    print $message->as_string($user_lang), "\n";   # Willkommen

## Prepare multilingual text for HTML output

    my $title = Lingua::Text->new(
        en => 'read more',
        fr => "lire la suite",
    )->encode();   # converts accented characters to HTML entities

    print "<title>$title</title>";   # safe for browsers in any locale

# DESCRIPTION

Lingua::Text is a simple container that stores the same piece of text in
multiple languages inside a single Perl object.  When you ask the object to
print itself (or convert to a string), it automatically reads the user's
operating-system language setting and returns the correct translation.

## How language detection works

The module reads the following environment variables, in this order, and uses
the first one it finds that contains a two-letter language code:

- 1. `LANGUAGE` (space- or colon-separated preference list, e.g. `fr:en`)
- 2. `LC_ALL`
- 3. `LC_MESSAGES`
- 4. `LANG` (e.g. `en_US.UTF-8` or `de_DE`)

In CGI or web environments, `I18N::LangTags::Detect` also inspects the
`HTTP_ACCEPT_LANGUAGE` request header (when available in the environment)
before falling back to the variables above.  The memoisation cache tracks
this variable alongside the four above, so the cache is invalidated
correctly when the header changes between requests.

Only the first two letters are used (e.g. `en_GB.UTF-8` becomes `en`), so
you only need to store one translation per language, not per locale variant.

If none of these variables is set, or if `LANG` is set to the POSIX `C`
or `C.UTF-8` locale, the module returns `undef` (or `'en'` for the C
locale).

## How string interpolation works

The object overloads Perl's `""` (stringify) operator.  This means you can
use a Lingua::Text object directly in strings:

    print "Hello: $greeting\n";
    my $html = "<h1>" . $title . "</h1>";

You do **not** need to call `as_string()` yourself in most cases.

## Language code format

Language codes follow ISO 639-1: two lower-case letters, e.g. `en`, `fr`,
`de`, `es`, `zh`.  An optional ISO 3166-1 country suffix may follow an
underscore: `en_US`, `zh_CN`.  The module stores and retrieves by the
two-letter code only; the country part of an environment variable is ignored
during lookup.

# METHODS

## new

Create a new Lingua::Text object.  The object starts empty, or pre-loaded
with one or more translations you provide.

Calling `new()` on an **existing** object creates an independent copy (a
clone) with any extra translations you supply merged in.  The original object
is never modified.

### ARGUMENTS

You may pass arguments in any of the following forms:

- No arguments -- creates an empty object

        my $t = Lingua::Text->new();

- Key/value pairs -- one pair per language

        my $t = Lingua::Text->new(en => 'boat', fr => 'bateau');

- A hash reference

        my $t = Lingua::Text->new({ en => 'boat', fr => 'bateau' });

- A single plain string -- stored under the current system locale language

        # Only works if a locale environment variable is set.
        # If no locale is set, the text is silently discarded.  See COMMON PITFALLS.
        my $t = Lingua::Text->new('hello');

- An existing Lingua::Text object -- creates a clone

        my $clone = $original->new();                      # exact copy
        my $clone = $original->new(de => 'zusatz');        # copy + one more language

### RETURN VALUE

Returns a blessed Lingua::Text reference on success.

Returns `undef` and emits a `carp` warning when called as a plain function
with arguments (e.g. `Lingua::Text::new(en =` 'hi')> without the arrow).

### EXAMPLE

    use Lingua::Text;

    # Empty object
    my $t = Lingua::Text->new();
    $t->en('Good morning');
    $t->de('Guten Morgen');

    # Pre-populated from a hash reference
    my %translations = (en => 'cat', fr => 'chat', de => 'Katze');
    my $animal = Lingua::Text->new(\%translations);

    # Clone and override the English translation
    my $us = $animal->new(en => 'kitty');

### API SPECIFICATION

#### Input

    # Params::Validate::Strict-compatible schema
    # (all parameters are optional; the whole argument list may be empty)

    en   => { type => 'string', optional => 1 }   # and any other ISO 639-1 code
    fr   => { type => 'string', optional => 1 }
    ...  # one key per language

    # OR a single HASHREF containing the same keys

    # OR a single SCALAR (stored under the current locale language)

#### Language key domain

Keys passed to `new()` are stored verbatim in the internal `{texts}` hash
without validation at construction time.  Access restrictions come from the
consumers:

- **AUTOLOAD accessor** -- only installs an accessor for keys matching
`/^[a-z]{2}$/`: exactly two lower-case ASCII letters.  `en_US` (with
country suffix), `eng` (three letters), `EN` (upper-case) and all other
keys are silently ignored by the accessor mechanism.
- **encode()** -- only processes keys accepted by `_is_valid_language()`:
`/^[a-z]{2}(?:_[A-Z]{2})?$/`.  Keys with `en_US`-style country suffixes
are encoded; non-language keys injected by [Object::Configure](https://metacpan.org/pod/Object%3A%3AConfigure) (e.g.
`logger`, `config_path`) are skipped.

    Equivalence partitions for language keys

    PARTITION          EXAMPLE    AUTOLOAD    encode()
    --------------------------------------------------------
    2-lower (valid)    'en'       YES         YES
    2-lower + _XX      'en_US'    NO          YES
    1 char             'e'        NO          NO
    3+ chars           'eng'      NO          NO
    uppercase          'EN'       NO          NO
    non-alpha          '12'       NO          NO

#### Output

    # Return::Set schema
    on_success => Lingua::Text,   # blessed reference
    on_misuse  => undef           # with carp warning

### MESSAGES

- `"use ->new() not ::new() to instantiate"`  \[carp\]

    You called `Lingua::Text::new(...)` (double-colon, function style) with
    arguments.  Use `Lingua::Text->new(...)` (arrow, method style) instead.

## set

Store or replace a single translation.  Use this when the language code is
held in a variable at runtime; if the language is fixed at coding time, the
shorthand accessor (e.g. `$t->en('Hello')`) is simpler.

### ARGUMENTS

    text  -- the translation string (required)
    lang  -- two-letter language code (optional; defaults to the system locale)

The arguments may be passed as a hash, a hash reference, or as a plain
positional string (only `text`; `lang` then comes from the system locale).

### RETURN VALUE

Returns the object itself (`$self`) on success, so calls may be chained.
Because the object stringifies to its current-locale translation, the return
value often _looks_ like the text you just stored -- but it is the object,
not the string.  See ["COMMON PITFALLS"](#common-pitfalls).

Returns `undef` and emits a `carp` warning when required arguments are
missing or when no language can be determined.

### EXAMPLE

    my $t = Lingua::Text->new();

    # Hash-reference form
    $t->set({ text => 'House', lang => 'en' });

    # Flat hash form
    $t->set(text => 'Maison', lang => 'fr');

    # Positional: lang comes from the system locale
    $t->set('Haus');   # stored under whatever language $ENV{LANG} says

    # Method chaining (set() returns $self)
    my $t = Lingua::Text->new()->set(text => 'Hello', lang => 'en')
                                ->set(text => 'Hola',  lang => 'es');

    # Store the language code from a variable
    my $user_lang = 'de';
    $t->set(text => 'Willkommen', lang => $user_lang);

### API SPECIFICATION

#### Input

    # Params::Validate::Strict-compatible schema
    text => {
        type     => 'string',
    },
    lang => {
        type     => 'string',
        optional => 1,
        default  => _get_language(),     # falls back to system locale
        regex    => qr/^[a-z]{2}(?:_[A-Z]{2})?$/,
    }

#### lang parameter domain (BVA)

The `lang` value is validated by the regex `/^[a-z]{2}(?:_[A-Z]{2})?$/`.

    # BOUNDARY VALUE ANALYSIS
    #
    # PARTITION                  EXAMPLE     VALID?  REASON
    # -------------------------------------------------------
    # 1 char (below minimum)     'e'         NO      too short
    # 2 lowercase (MINIMUM)      'en'        YES     minimum valid length
    # 3 lowercase                'eng'       NO      exceeds simple maximum
    # 5 chars with suffix (MAX)  'en_US'     YES     2-lower + _ + 2-UPPER
    # 6 chars, country 3-long    'en_USA'    NO      country must be exactly 2
    # 4 chars, country 1-long    'en_U'      NO      country must be exactly 2
    # trailing underscore only   'en_'       NO      country code absent
    # 2 uppercase                'EN'        NO      must be lower-case
    # mixed case                 'En'        NO      must be lower-case
    # 2 digits                   '12'        NO      digits not in [a-z]
    # empty string               ''          NO      zero length

#### text parameter domain

Any defined scalar is a valid text value.  Length has no documented limit.

    # BOUNDARY VALUE ANALYSIS
    #
    # PARTITION          EXAMPLE              VALID?  REASON
    # ---------------------------------------------------------------
    # empty string       ''                   YES     length 0 (minimum)
    # falsy '0'          '0'                  YES     defined, even if falsy
    # regular ASCII      'hello'              YES     representative valid
    # Unicode            "\x{E9}tude"         YES     stored verbatim
    # 1 MB string        'x' x 1_000_000      YES     no documented size limit
    # undef              undef                NO      undefined = missing text

#### Output

    # Return::Set schema
    on_success          => $self,    # the same Lingua::Text object
    on_no_args          => undef     # with croak (programmer error)
    on_missing_lang     => undef     # with carp
    on_invalid_lang     => undef     # with carp (lang fails ISO 639-1 check)
    on_missing_text     => undef     # with carp

### MESSAGES

- `"Usage: set(text => $text, lang => $language)"`  \[croak\]

    `set()` was called with no arguments at all.  Provide at least `text`.

- `"usage: set(text => $text, lang => $language)"`  \[carp\]

    One of three conditions: `text` is missing or undef; `lang` is missing and
    no locale environment variable is set; or `lang` was supplied but fails the
    ISO 639-1 validation check (e.g. a three-letter code like `'abc'`).
    Pass `lang` as a two-letter code (e.g. `'en'`) to resolve all three.

## as\_string

Return the stored translation for a given language, or for the system locale
when no language is specified.

This method is also invoked automatically whenever Perl needs to convert the
object to a string -- for example inside `print`, in string concatenation, or
in a comparison like `$t eq 'hello'`.  You rarely need to call it directly.

### ARGUMENTS

    lang  -- two-letter language code (optional; defaults to the system locale)

Accepted forms:

    $t->as_string()                  # uses system locale
    $t->as_string('fr')              # positional
    $t->as_string(lang => 'fr')      # named
    $t->as_string({ lang => 'fr' })  # hash reference
    "$t"                             # stringification overload (uses system locale)

### RETURN VALUE

- Returns the translation string when the language is known and stored.
- Returns `undef` -- **without** a warning -- when the language is known
but no translation exists for it.  This is the normal "not translated yet"
case.
- Returns `undef` -- **with** a `carp` warning -- when no language can
be determined (no argument supplied _and_ no locale environment variable set).

### EXAMPLE

    use Lingua::Text;

    my $t = Lingua::Text->new(en => 'boat', fr => 'bateau');

    # Explicit language
    print $t->as_string('en'), "\n";              # boat
    print $t->as_string(lang => 'fr'), "\n";      # bateau

    # System locale (assume LANG=de_DE.UTF-8)
    print $t->as_string(), "\n";                  # undef -- no German stored

    # String interpolation (same as calling as_string() with no args)
    $ENV{LANG} = 'en_US.UTF-8';
    print "I see a $t.\n";                        # I see a boat.

    # Checking for a missing translation
    if(!defined($t->as_string('zh'))) {
        print "No Chinese translation available.\n";
    }

### API SPECIFICATION

#### Input

    # Params::Validate::Strict-compatible schema
    lang => {
        type     => 'string',
        optional => 1,
        default  => _get_language(),
        # NOTE: unlike set(), as_string() performs NO format validation on
        # the lang argument.  Any defined scalar is used directly as a hash
        # key into the internal {texts} store.  An unrecognised key simply
        # returns undef without a warning (the 'on_not_found' state below).
    }

#### lang argument domain

    # EQUIVALENCE PARTITIONS
    #
    # INPUT                        RESULT
    # ---------------------------------------------------------------
    # Stored key ('en' exists)     returns the text (no warning)
    # Valid format, not stored     returns undef    (no warning)
    # Invalid format, not stored   returns undef    (no warning)
    # Empty string ''              returns undef    (no warning)
    # undef                        falls back to _get_language()
    # no argument                  falls back to _get_language()
    #
    # Argument forms accepted:
    #   as_string('en')              positional
    #   as_string(lang => 'en')      named hash
    #   as_string({ lang => 'en' })  hash reference

#### Output

    # Return::Set schema
    on_found         => SCALAR,    # the translation string
    on_not_found     => undef,     # language is known; no translation stored
    on_no_language   => undef      # with carp warning

### MESSAGES

- `"usage: as_string(lang => $language)"`  \[carp\]

    No `lang` was supplied and no locale environment variable (`LANG`,
    `LC_MESSAGES`, `LC_ALL`, `LANGUAGE`) is set.  Either pass the language
    explicitly or set the locale before calling.

## encode

Convert every stored translation from raw Unicode text to HTML entities.
Call this once on an object before embedding its text in HTML pages, to make
accented characters and other special characters safe for all browsers.

For example, the French word `"\x{E9}tude"` (e-acute followed by "tude")
becomes `"&eacute;tude"` after encoding.

**Important:** This method modifies the object _in place_ and **cannot be
undone**.  There is no `decode()` counterpart.  See ["COMMON PITFALLS"](#common-pitfalls).

### ARGUMENTS

None.

### RETURN VALUE

Returns the object itself (`$self`), so `encode()` can be chained directly
onto `new()`.

### EXAMPLE

    use Lingua::Text;

    # Build an object and encode it in one step
    my $t = Lingua::Text->new(
        en => 'study',
        fr => "\x{E9}tude",     # e with acute accent (Unicode codepoint U+00E9)
    )->encode();

    print $t->fr();    # &eacute;tude
    print $t->en();    # study  (plain ASCII is unchanged)

    # Use encoded text safely inside HTML
    my $html = "<p>" . $t . "</p>";

### API SPECIFICATION

#### Input

    None.

#### Output

    # Return::Set schema
    on_success => $self    # the same Lingua::Text object, with texts encoded

## Language accessor methods

Any two-letter method name that is a valid ISO 639-1 language code acts as a
combined getter and setter for that language's translation.  These methods do
not need to be declared; Perl's `AUTOLOAD` mechanism intercepts them.

    $t->en('Hello');          # store an English translation
    my $text = $t->fr();      # retrieve the French translation (undef if not stored)
    $t->zh('');               # store an empty string (distinct from undef/not-stored)
    $t->en(0);                # store the string "0" (falsy values work correctly)

### ARGUMENTS

- **Setter form** -- pass one scalar argument

    The value is stored under the method's language code and also returned.

- **Getter form** -- call with no arguments

    Returns the stored string for that language, or `undef` if nothing has been
    stored.

### RETURN VALUE

- Returns the stored translation string (getter) or the value just stored
(setter).
- Returns `undef` -- silently -- when the language has no stored
translation.
- Returns `undef` silently for any method name that is not a recognised
two-letter ISO 639-1 code.  This means typos (e.g. `$t->enn()`) fail
invisibly.  See ["COMMON PITFALLS"](#common-pitfalls).

### EXAMPLE

    my $t = Lingua::Text->new();

    $t->en('Good morning');
    $t->fr('Bonjour');
    $t->de('Guten Morgen');

    print $t->en(), "\n";   # Good morning
    print $t->ja(), "\n";   # (nothing -- no Japanese stored)

    # Chaining setters is not supported; use set() for that.
    # Setters return the stored value, not $self.

### API SPECIFICATION

#### Method name domain (BVA)

The accessor is only created for method names that match `/^[a-z]{2}$/`:
exactly two lower-case ASCII letters.  All other names return `undef`
silently and never install an accessor.

    # BOUNDARY VALUE ANALYSIS
    #
    # NAME              CHARS  MATCHES /^[a-z]{2}$/  RESULT
    # ---------------------------------------------------------------
    # 'e'               1      NO (below minimum)     undef (silent)
    # 'en'              2      YES (minimum valid)    accessor works
    # 'eng'             3      NO (above maximum)     undef (silent)
    # 'EN'              2      NO (uppercase)         undef (silent)
    # 'En'              2      NO (mixed case)        undef (silent)
    # 'en_US'           5      NO (underscore)        undef (silent)

#### Input

    # Setter: one positional SCALAR (may be undef, '', or '0')
    # Getter: no arguments

#### Value domain (setter)

Any scalar value -- including `undef`, `''`, and `'0'` -- is accepted
and stored verbatim.  `encode()` will later skip `undef` and reference
values; the accessor itself is a transparent store.

    # EQUIVALENCE PARTITIONS
    #
    # VALUE        STORED?  ENCODE() EFFECT
    # --------------------------------------------------
    # 'hello'      YES      encoded if non-ASCII chars
    # ''           YES      unchanged (no entities)
    # '0'          YES      unchanged
    # undef        YES      skipped by encode() (preserved)
    # arrayref     YES      skipped by encode() (preserved)

#### Output

    # Return::Set schema
    on_set     => SCALAR | undef    # the value just stored
    on_get     => SCALAR | undef    # the stored value, or undef if absent
    on_invalid => undef             # silently, for non-language method names

### MESSAGES

None.  All failure cases return `undef` silently.  See ["COMMON PITFALLS"](#common-pitfalls)
for guidance on typo detection.

# COMMON PITFALLS

This section documents behaviours that often surprise first-time users.

## encode() cannot be undone

`encode()` modifies the object in place.  There is no `decode()`.  If you
call `encode()` twice on the same object, every special character is encoded
twice (e.g. `&eacute;` becomes `&amp;eacute;`).  Always call `encode()`
once, as the last step, and only on a freshly built object.

    # WRONG -- double-encoding
    my $t = Lingua::Text->new(fr => "\x{E9}tude")->encode()->encode();
    print $t->fr();    # &amp;eacute;tude  (broken HTML)

    # CORRECT
    my $t = Lingua::Text->new(fr => "\x{E9}tude")->encode();
    print $t->fr();    # &eacute;tude

## Missing translation returns undef, not an empty string

When a translation is not stored for the requested language, `as_string()`
and the accessor methods return `undef`, not `""`.  Use `defined()` to test
for absence, not a truth check.

    my $t = Lingua::Text->new(en => 'hello');

    my $de = $t->de();
    print "Missing\n" unless defined($de);   # correct
    print "Missing\n" unless $de;            # WRONG -- also triggers for $de = '0'

## Typos in language codes are silent

The AUTOLOAD accessor returns `undef` for any two-letter name that is not a
valid ISO 639-1 code, and also for valid codes that have no stored translation.
A typo like `$t->enn()` produces `undef` without any warning.

    $t->en('hello');
    print $t->enn();    # undef -- no warning, no error

To guard against this, always check with `defined()` and, during development,
consider adding a test that verifies the expected languages are present.

## new('text') silently drops the text when no locale is set

When you pass a single string to `new()`, it is stored under the current
system language.  If no locale environment variable (`LANG`, `LC_MESSAGES`,
etc.) is set, the language cannot be determined and the text is silently
discarded.

    # Safe: locale is set
    $ENV{LANG} = 'en_GB.UTF-8';
    my $t = Lingua::Text->new('hello');
    print $t->en();   # hello

    # Unsafe: no locale
    delete $ENV{LANG};
    delete $ENV{LC_MESSAGES};
    my $t = Lingua::Text->new('hello');   # text is lost
    print defined($t->en()) ? $t->en() : 'lost';   # lost

    # Safe alternative: always name the language explicitly
    my $t = Lingua::Text->new(en => 'hello');

## set() and the language accessors return $self or the value, not the text

`set()` returns the object (`$self`).  Because of the stringify overload,
when you print or compare the return value, it _looks_ like a string -- but it
is an object.  Do not rely on this behaviour; retrieve the value separately.

    my $t = Lingua::Text->new();
    my $result = $t->set(text => 'Hello', lang => 'en');

    # $result is the Lingua::Text object, not the string 'Hello'
    # This works due to stringify overload, but is misleading:
    print $result;          # Hello (via stringify)

    # Clearer intent:
    $t->set(text => 'Hello', lang => 'en');
    print $t->as_string('en');   # Hello

The AUTOLOAD setter (e.g. `$t->en('Hello')`) returns the stored value
directly, not `$self`.

## A Lingua::Text object is always true

The object overloads the boolean `bool` operator to always return true, even
when it contains no translations.  Do **not** use an object as a truth test to
check whether it has any content.

    my $t = Lingua::Text->new();   # empty
    if($t) { print "always reached\n"; }   # always true

    # To check whether a specific language is stored:
    if(defined($t->en())) { print "English is stored\n"; }

## Function-style call with arguments is an error

Perl allows calling methods as functions, but Lingua::Text::new() (with
double-colon and arguments) will emit a warning and return `undef`.

    my $t = Lingua::Text::new(en => 'hi');   # WRONG -- carp warning, returns undef
    my $t = Lingua::Text->new(en => 'hi');   # correct

Calling `Lingua::Text::new()` with **no** arguments works (it creates an empty
object), but the arrow form is still preferred.

# PERFORMANCE

Three optimisations address the hot paths in typical web or CGI use (many
objects stringified per request, same accessor called repeatedly):

- **Memoised locale detection**

    `_get_language()` is called on every `as_string()` invocation (including
    stringify via `""`).  The result is cached against a snapshot of the five
    relevant environment variables (`LANGUAGE`, `LC_ALL`, `LC_MESSAGES`,
    `LANG`, `HTTP_ACCEPT_LANGUAGE`).  As long as those variables do not change,
    subsequent calls cost only five string comparisons instead of a full
    `I18N::LangTags::Detect::detect()` scan.  The cache is invalidated
    automatically when any of those variables change -- including `local %ENV`
    in tests.

- **AUTOLOAD method installation**

    The first call to any two-letter accessor (e.g. `$t->en()`) installs a
    real subroutine in the package symbol table.  All subsequent calls for that
    code dispatch directly, bypassing the AUTOLOAD regex and guard overhead
    entirely.

- **Single-argument fast path in as\_string()**

    `$t->as_string('en')` skips `Params::Get::get_params()` when exactly
    one non-reference argument is supplied.  Named (`lang => 'en'`) and
    hashref (`{ lang => 'en' }`) forms still go through the full parser.

# LIMITATIONS

- **No decode()**: Once `encode()` is called, all translations are
HTML-entity-encoded.  There is no method to reverse this.
- **No language fallback**: If `en_GB` is the system locale but only
`en` is stored, the module finds the text correctly (because the country
suffix is stripped).  However, if `en_GB` is stored as a key and the system
locale is `en_US`, the text is _not_ found.  Only two-letter codes are used
as storage keys.
- **Silent AUTOLOAD failures**: Unrecognised method names (including
typos) return `undef` without any diagnostic.
- **Object::Configure semantics**: The exact effect of
[Object::Configure](https://metacpan.org/pod/Object%3A%3AConfigure) depends on the installed version and any project-level
configuration present.  Without a configuration file, it passes parameters
through unchanged.

# DEPENDENCIES

Runtime:

- [Carp](https://metacpan.org/pod/Carp) -- `carp`/`croak` for warnings and errors
- [HTML::Entities](https://metacpan.org/pod/HTML%3A%3AEntities) -- HTML entity encoding in `encode()`
- [I18N::LangTags::Detect](https://metacpan.org/pod/I18N%3A%3ALangTags%3A%3ADetect) -- locale detection from environment variables
- [Object::Configure](https://metacpan.org/pod/Object%3A%3AConfigure) -- optional config-file defaults for `new()`
- [Params::Get](https://metacpan.org/pod/Params%3A%3AGet) -- flexible argument parsing for public methods
- [Readonly](https://metacpan.org/pod/Readonly) -- constant definitions for the message catalog and patterns
- [Scalar::Util](https://metacpan.org/pod/Scalar%3A%3AUtil) -- `blessed()` for safe type testing
- [Sub::Private](https://metacpan.org/pod/Sub%3A%3APrivate) -- enforcement of private method access

# AUTHOR

Nigel Horne, `<njh at nigelhorne.com>`

# BUGS

Please report bugs at [https://github.com/nigelhorne/Lingua-Text/issues](https://github.com/nigelhorne/Lingua-Text/issues).

# SEE ALSO

- [Object::Configure](https://metacpan.org/pod/Object%3A%3AConfigure) -- runtime object configuration
- [I18N::LangTags::Detect](https://metacpan.org/pod/I18N%3A%3ALangTags%3A%3ADetect) -- the locale detection module used internally
- [HTML::Entities](https://metacpan.org/pod/HTML%3A%3AEntities) -- the HTML encoding module used by `encode()`
- [Test Dashboard](https://nigelhorne.github.io/CGI-Info/coverage/)

# SUPPORT

This module is provided as-is without any warranty.

Documentation:

    perldoc Lingua::Text

Online resources:

- MetaCPAN: [https://metacpan.org/release/Lingua-Text](https://metacpan.org/release/Lingua-Text)
- Bug tracker: [https://rt.cpan.org/NoAuth/Bugs.html?Dist=Lingua-Text](https://rt.cpan.org/NoAuth/Bugs.html?Dist=Lingua-Text)
- CPANTS: [http://cpants.cpanauthors.org/dist/Lingua-Text](http://cpants.cpanauthors.org/dist/Lingua-Text)
- CPAN Testers: [http://matrix.cpantesters.org/?dist=Lingua-Text](http://matrix.cpantesters.org/?dist=Lingua-Text)
- Dependencies: [http://deps.cpantesters.org/?module=Lingua-Text](http://deps.cpantesters.org/?module=Lingua-Text)

# FORMAL SPECIFICATION

## new

    -- Type definitions
    STRING == seq CHAR
    LANG   == { l : STRING | l =~ /^[a-z]{2}(_[A-Z]{2})?$/ }

    -- State: a partial function from language codes to strings
    ┌─ LinguaText ────────────────────────────────────────────
    │ texts : LANG ⇸ STRING
    └─────────────────────────────────────────────────────────

    -- Construction: initialise texts from zero or more lang/string pairs
    ┌─ new ───────────────────────────────────────────────────
    │ ΔLinguaText
    │ init? : LANG ⇸ STRING
    ├─────────────────────────────────────────────────────────
    │ texts' = init?
    └─────────────────────────────────────────────────────────

    -- Clone: merge the parent's texts with any new pairs (new pairs win)
    ┌─ clone ─────────────────────────────────────────────────
    │ ΔLinguaText
    │ parent? : LinguaText
    │ extra?  : LANG ⇸ STRING
    ├─────────────────────────────────────────────────────────
    │ texts' = parent?.texts ⊕ extra?
    └─────────────────────────────────────────────────────────

## set

    -- set: add or replace one translation; all others remain unchanged
    ┌─ set ───────────────────────────────────────────────────
    │ ΔLinguaText
    │ lang? : LANG
    │ text? : STRING
    ├─────────────────────────────────────────────────────────
    │ texts' = texts ⊕ { lang? ↦ text? }
    └─────────────────────────────────────────────────────────
    -- ⊕ denotes relational override: lang? wins over any existing entry

## as\_string

    -- as_string: look up one translation; state is unchanged (Xi schema)
    ┌─ as_string ─────────────────────────────────────────────
    │ ΞLinguaText
    │ lang?    : LANG ∪ { current_locale }
    │ result!  : STRING ∪ { undef }
    ├─────────────────────────────────────────────────────────
    │ lang? ∈ dom texts  ⟹  result! = texts(lang?)
    │ lang? ∉ dom texts  ⟹  result! = undef
    └─────────────────────────────────────────────────────────
    -- The state schema Ξ means texts is not modified by this operation.

## encode

    -- Let entity : STRING -> STRING be HTML::Entities::encode_entities
    -- and  dec   : STRING -> STRING be utf8::decode (applied only when needed)
    ┌─ encode ────────────────────────────────────────────────
    │ ΔLinguaText
    │ ∀ l : dom texts
    │     • texts'(l) = entity(dec(texts(l)))
    └─────────────────────────────────────────────────────────
    -- texts' replaces every value; dom texts is unchanged.

# LICENCE AND COPYRIGHT

Copyright 2021-2026 Nigel Horne.

Usage is subject to the GPL2 licence terms.
If you use it, please let me know.
