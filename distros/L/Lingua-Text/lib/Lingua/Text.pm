package Lingua::Text;

use strict;
use warnings;
use autodie qw(:all);

use Carp;
use HTML::Entities;
use Object::Configure;
use Params::Get;
use Readonly;
use Scalar::Util qw(blessed);
use I18N::LangTags::Detect;

# enforce mode lets Sub::Private work correctly with OO dispatch ($self->_helper).
# Tests bypass the check automatically when HARNESS_ACTIVE is set by prove.
BEGIN { $Sub::Private::config{mode} = 'enforce' }
use Sub::Private;

=head1 NAME

Lingua::Text - Store the same text in many languages; retrieve it in the user's language automatically

=head1 VERSION

Version 0.09

=cut

our $VERSION = '0.09';
our $AUTOLOAD;

# ---------------------------------------------------------------------------
# Constants
# ---------------------------------------------------------------------------

# ISO 639-1 language code with optional ISO 3166-1 country suffix (e.g. 'en', 'en_US').
# The pattern is case-sensitive: lower-case lang, upper-case country.
# /x lets us annotate each component; spaces and # comments inside /x are ignored.
Readonly::Scalar my $LANG_RE => qr/
	^
	[a-z]{2}          # ISO 639-1 two-letter language code (e.g. 'en', 'fr')
	(?:_[A-Z]{2})?    # optional ISO 3166-1 country suffix (e.g. '_US', '_GB')
	$
/x;

# Error message catalog.  All templates accept the package name as first
# sprintf argument so callers never hard-code the package string.
# Capitalised "Usage:" marks programmer errors (croak); lower-case marks
# runtime warnings (carp) -- the carp.t suite relies on this distinction.
Readonly::Hash my %MESSAGES => (
	new_oo_style => '%s: use ->new() not ::new() to instantiate',
	set_no_args  => '%s: Usage: set(text => $text, lang => $language)',
	set_usage    => '%s: usage: set(text => $text, lang => $language)',
	str_usage    => '%s: usage: as_string(lang => $language)',
);

use overload (
	'""'     => \&as_string,
	bool     => sub { 1 },
	fallback => 1,    # let boolean tests bypass as_string
);

# ---------------------------------------------------------------------------
# Public API
# ---------------------------------------------------------------------------

=head1 SYNOPSIS

=head2 Basic use: store translations and print in the user's language

    use Lingua::Text;

    my $greeting = Lingua::Text->new(
        en => 'Hello',
        fr => 'Bonjour',
        de => 'Hallo',
    );

    # The system locale (LANG, LC_MESSAGES, etc.) picks the language.
    # No code change is needed when the user's OS language changes.
    print $greeting, "\n";

=head2 Add translations after construction

    my $label = Lingua::Text->new();
    $label->en('Submit');
    $label->fr('Envoyer');
    $label->de('Abschicken');

    # Ask for a specific language explicitly
    print $label->as_string('fr'), "\n";   # Envoyer

=head2 Build from a database hash

    # Suppose the database returns: { en => 'Apple', fr => 'Pomme', de => 'Apfel' }
    my $row  = $db->selectrow_hashref('SELECT en, fr, de FROM fruit WHERE id = ?', {}, $id);
    my $name = Lingua::Text->new($row);
    print $name;   # prints in the user's system language

=head2 Add one translation to an existing object (clone)

    my $base = Lingua::Text->new(en => 'colour', fr => 'couleur');
    my $us   = $base->new(en => 'color');   # American English override

    # $us  has en => 'color',  fr => 'couleur'
    # $base is unchanged: en => 'colour', fr => 'couleur'

=head2 Store text at runtime using a language variable

    my $message = Lingua::Text->new();
    my $user_lang = 'de';   # could come from a web request header

    $message->set(text => 'Willkommen', lang => $user_lang);
    print $message->as_string($user_lang), "\n";   # Willkommen

=head2 Prepare multilingual text for HTML output

    my $title = Lingua::Text->new(
        en => 'read more',
        fr => "lire la suite",
    )->encode();   # converts accented characters to HTML entities

    print "<title>$title</title>";   # safe for browsers in any locale

=head1 DESCRIPTION

Lingua::Text is a simple container that stores the same piece of text in
multiple languages inside a single Perl object.  When you ask the object to
print itself (or convert to a string), it automatically reads the user's
operating-system language setting and returns the correct translation.

=head2 How language detection works

The module reads the following environment variables, in this order, and uses
the first one it finds that contains a two-letter language code:

=over 4

=item 1. C<LANGUAGE> (space- or colon-separated preference list, e.g. C<fr:en>)

=item 2. C<LC_ALL>

=item 3. C<LC_MESSAGES>

=item 4. C<LANG> (e.g. C<en_US.UTF-8> or C<de_DE>)

=back

In CGI or web environments, C<I18N::LangTags::Detect> also inspects the
C<HTTP_ACCEPT_LANGUAGE> request header (when available in the environment)
before falling back to the variables above.  The memoisation cache tracks
this variable alongside the four above, so the cache is invalidated
correctly when the header changes between requests.

Only the first two letters are used (e.g. C<en_GB.UTF-8> becomes C<en>), so
you only need to store one translation per language, not per locale variant.

If none of these variables is set, or if C<LANG> is set to the POSIX C<C>
or C<C.UTF-8> locale, the module returns C<undef> (or C<'en'> for the C
locale).

=head2 How string interpolation works

The object overloads Perl's C<""> (stringify) operator.  This means you can
use a Lingua::Text object directly in strings:

    print "Hello: $greeting\n";
    my $html = "<h1>" . $title . "</h1>";

You do B<not> need to call C<as_string()> yourself in most cases.

=head2 Language code format

Language codes follow ISO 639-1: two lower-case letters, e.g. C<en>, C<fr>,
C<de>, C<es>, C<zh>.  An optional ISO 3166-1 country suffix may follow an
underscore: C<en_US>, C<zh_CN>.  The module stores and retrieves by the
two-letter code only; the country part of an environment variable is ignored
during lookup.

=head1 METHODS

=head2 new

Create a new Lingua::Text object.  The object starts empty, or pre-loaded
with one or more translations you provide.

Calling C<new()> on an B<existing> object creates an independent copy (a
clone) with any extra translations you supply merged in.  The original object
is never modified.

=head3 ARGUMENTS

You may pass arguments in any of the following forms:

=over 4

=item No arguments -- creates an empty object

    my $t = Lingua::Text->new();

=item Key/value pairs -- one pair per language

    my $t = Lingua::Text->new(en => 'boat', fr => 'bateau');

=item A hash reference

    my $t = Lingua::Text->new({ en => 'boat', fr => 'bateau' });

=item A single plain string -- stored under the current system locale language

    # Only works if a locale environment variable is set.
    # If no locale is set, the text is silently discarded.  See COMMON PITFALLS.
    my $t = Lingua::Text->new('hello');

=item An existing Lingua::Text object -- creates a clone

    my $clone = $original->new();                      # exact copy
    my $clone = $original->new(de => 'zusatz');        # copy + one more language

=back

=head3 RETURN VALUE

Returns a blessed Lingua::Text reference on success.

Returns C<undef> and emits a C<carp> warning when called as a plain function
with arguments (e.g. C<Lingua::Text::new(en => 'hi')> without the arrow).

=head3 EXAMPLE

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

=head3 API SPECIFICATION

=head4 Input

    # Params::Validate::Strict-compatible schema
    # (all parameters are optional; the whole argument list may be empty)

    en   => { type => 'string', optional => 1 }   # and any other ISO 639-1 code
    fr   => { type => 'string', optional => 1 }
    ...  # one key per language

    # OR a single HASHREF containing the same keys

    # OR a single SCALAR (stored under the current locale language)

=head4 Language key domain

Keys passed to C<new()> are stored verbatim in the internal C<{texts}> hash
without validation at construction time.  Access restrictions come from the
consumers:

=over 4

=item *

B<AUTOLOAD accessor> -- only installs an accessor for keys matching
C</^[a-z]{2}$/>: exactly two lower-case ASCII letters.  C<en_US> (with
country suffix), C<eng> (three letters), C<EN> (upper-case) and all other
keys are silently ignored by the accessor mechanism.

=item *

B<encode()> -- only processes keys accepted by C<_is_valid_language()>:
C</^[a-z]{2}(?:_[A-Z]{2})?$/>.  Keys with C<en_US>-style country suffixes
are encoded; non-language keys injected by L<Object::Configure> (e.g.
C<logger>, C<config_path>) are skipped.

=back

    Equivalence partitions for language keys

    PARTITION          EXAMPLE    AUTOLOAD    encode()
    --------------------------------------------------------
    2-lower (valid)    'en'       YES         YES
    2-lower + _XX      'en_US'    NO          YES
    1 char             'e'        NO          NO
    3+ chars           'eng'      NO          NO
    uppercase          'EN'       NO          NO
    non-alpha          '12'       NO          NO

=head4 Output

    # Return::Set schema
    on_success => Lingua::Text,   # blessed reference
    on_misuse  => undef           # with carp warning

=head3 MESSAGES

=over 4

=item C<"use -E<gt>new() not ::new() to instantiate">  [carp]

You called C<Lingua::Text::new(...)> (double-colon, function style) with
arguments.  Use C<Lingua::Text-E<gt>new(...)> (arrow, method style) instead.

=back

=cut

sub new {
	my $class = shift;

	# Detect function-style misuse: Lingua::Text::new(args...)
	# A legitimate invocant is either a blessed object (clone) or a class name
	# that inherits from this package.  Anything else (e.g. the first key of a
	# hash accidentally consumed as the invocant) triggers a warning.
	# SECURITY: call UNIVERSAL::isa() as a function, not as a method on $class.
	# Method dispatch on an attacker-controlled string would invoke any isa()
	# defined on that package; the function form bypasses method resolution.
	my $is_class  = !ref($class) && defined($class) && eval { UNIVERSAL::isa($class, __PACKAGE__) };

	# A valid object invocant must be a Lingua::Text instance (or subclass),
	# not just any blessed reference.  A foreign blessed object (e.g. from
	# a completely unrelated package) would pass `blessed()` but crash the clone
	# path at `%{$class->{'texts'}}` because it has no 'texts' slot.
	# UNIVERSAL::isa() as a function is used (not method dispatch) for the same
	# security reason as above.
	my $is_object = blessed($class) && UNIVERSAL::isa($class, __PACKAGE__);

	# Syllogism:
	# P1: A valid invocant is a Lingua::Text blessed object (clone path) or
	#     a class name that inherits from Lingua::Text (isa check).
	# P2: !defined($class) implies both $is_class and $is_object are false
	#     (each requires defined($class) in their own derivation).
	# Conclusion: De Morgan reduction -- the original
	#   "!defined || (!class && !object)"
	# is logically equivalent to "!($is_object || $is_class)".
	unless($is_object || $is_class) {
		# undef invocant = bare Lingua::Text::new() with no args -- allowed
		if(defined($class)) {
			Carp::carp(_err('new_oo_style'));
			return;
		}
		$class = __PACKAGE__;
	}

	# Build the initial parameter hash from whatever form the caller used.
	# A single non-ref scalar is the positional form: store under the locale lang
	# if one is detected, or silently discard it when no locale is set (the
	# documented pitfall).  We must NOT let it reach get_params(), which croaks
	# on an odd-length list (get_params(undef, $scalar) = 1 arg = odd).
	my $params;
	if((scalar(@_) == 1) && (!ref($_[0]))) {
		my $lang = _get_language();
		$params = { $lang => $_[0] } if $lang;
	} elsif(@_) {
		$params = Params::Get::get_params(undef, \@_);
	}

	# Clone path: caller is an existing object
	if($is_object) {
		if($params) {
			return bless { texts => {%{$class->{'texts'}}, %{$params}} }, ref($class);
		}
		return bless { %{$class} }, ref($class);
	}

	# Allow Object::Configure to inject defaults (e.g. from a config file)
	$params = Object::Configure::configure($class, $params);
	return bless( $params ? { texts => $params } : {}, $class );
}

=head2 set

Store or replace a single translation.  Use this when the language code is
held in a variable at runtime; if the language is fixed at coding time, the
shorthand accessor (e.g. C<$t-E<gt>en('Hello')>) is simpler.

=head3 ARGUMENTS

    text  -- the translation string (required)
    lang  -- two-letter language code (optional; defaults to the system locale)

The arguments may be passed as a hash, a hash reference, or as a plain
positional string (only C<text>; C<lang> then comes from the system locale).

=head3 RETURN VALUE

Returns the object itself (C<$self>) on success, so calls may be chained.
Because the object stringifies to its current-locale translation, the return
value often I<looks> like the text you just stored -- but it is the object,
not the string.  See L</COMMON PITFALLS>.

Returns C<undef> and emits a C<carp> warning when required arguments are
missing or when no language can be determined.

=head3 EXAMPLE

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

=head3 API SPECIFICATION

=head4 Input

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

=head4 lang parameter domain (BVA)

The C<lang> value is validated by the regex C</^[a-z]{2}(?:_[A-Z]{2})?$/>.

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

=head4 text parameter domain

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

=head4 Output

    # Return::Set schema
    on_success          => $self,    # the same Lingua::Text object
    on_no_args          => undef     # with croak (programmer error)
    on_missing_lang     => undef     # with carp
    on_invalid_lang     => undef     # with carp (lang fails ISO 639-1 check)
    on_missing_text     => undef     # with carp

=head3 MESSAGES

=over 4

=item C<"Usage: set(text =E<gt> $text, lang =E<gt> $language)">  [croak]

C<set()> was called with no arguments at all.  Provide at least C<text>.

=item C<"usage: set(text =E<gt> $text, lang =E<gt> $language)">  [carp]

One of three conditions: C<text> is missing or undef; C<lang> is missing and
no locale environment variable is set; or C<lang> was supplied but fails the
ISO 639-1 validation check (e.g. a three-letter code like C<'abc'>).
Pass C<lang> as a two-letter code (e.g. C<'en'>) to resolve all three.

=back

=cut

sub set {
	my $self = shift;

	Carp::croak(_err('set_no_args')) unless @_;

	my $params = Params::Get::get_params('text', @_);

	# SECURITY: use // (defined-or), not || (truthiness).
	# || would silently substitute the system locale when the caller explicitly
	# passes lang => '' or lang => '0', masking an invalid-argument error.
	my $lang = $params->{'lang'} // _get_language();
	return _carp_set_usage() unless defined($lang);

	# Syllogism:
	# P1 (object invariant): every key in $self->{texts} must satisfy $LANG_RE.
	# P2: $lang was resolved from caller input -- it may be any string.
	# Conclusion: validate at the API boundary before writing; reject here to
	#             maintain the invariant rather than letting bad keys propagate.
	return _carp_set_usage() unless _is_valid_language($lang);

	my $text = $params->{'text'};
	return _carp_set_usage() unless defined($text);

	$self->{'texts'}->{$lang} = $text;
	return $self;
}

=head2 as_string

Return the stored translation for a given language, or for the system locale
when no language is specified.

This method is also invoked automatically whenever Perl needs to convert the
object to a string -- for example inside C<print>, in string concatenation, or
in a comparison like C<$t eq 'hello'>.  You rarely need to call it directly.

=head3 ARGUMENTS

    lang  -- two-letter language code (optional; defaults to the system locale)

Accepted forms:

    $t->as_string()                  # uses system locale
    $t->as_string('fr')              # positional
    $t->as_string(lang => 'fr')      # named
    $t->as_string({ lang => 'fr' })  # hash reference
    "$t"                             # stringification overload (uses system locale)

=head3 RETURN VALUE

=over 4

=item Returns the translation string when the language is known and stored.

=item Returns C<undef> -- B<without> a warning -- when the language is known
but no translation exists for it.  This is the normal "not translated yet"
case.

=item Returns C<undef> -- B<with> a C<carp> warning -- when no language can
be determined (no argument supplied I<and> no locale environment variable set).

=back

=head3 EXAMPLE

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

=head3 API SPECIFICATION

=head4 Input

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

=head4 lang argument domain

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

=head4 Output

    # Return::Set schema
    on_found         => SCALAR,    # the translation string
    on_not_found     => undef,     # language is known; no translation stored
    on_no_language   => undef      # with carp warning

=head3 MESSAGES

=over 4

=item C<"usage: as_string(lang =E<gt> $language)">  [carp]

No C<lang> was supplied and no locale environment variable (C<LANG>,
C<LC_MESSAGES>, C<LC_ALL>, C<LANGUAGE>) is set.  Either pass the language
explicitly or set the locale before calling.

=back

=cut

sub as_string {
	my $self = shift;

	# Guard against the overload calling convention: Perl passes ($self, $other, $swap)
	# when the "" handler is invoked during a comparison.  We only want the first arg.
	# Fast path: single positional scalar (e.g. as_string('en')) skips Params::Get
	# to avoid parameter-parsing overhead on what is often the hottest call site.
	my $lang;
	if(@_ && defined($_[0])) {
		if(my $params = Params::Get::get_params('lang', \@_)) {
			$lang = $params->{'lang'};
		}
	}
	$lang //= _get_language();

	if(defined($lang)) {
		return $self->{'texts'}->{$lang};
	}
	Carp::carp(_err('str_usage'));
	return;
}

=head2 encode

Convert every stored translation from raw Unicode text to HTML entities.
Call this once on an object before embedding its text in HTML pages, to make
accented characters and other special characters safe for all browsers.

For example, the French word C<"\x{E9}tude"> (e-acute followed by "tude")
becomes C<"&eacute;tude"> after encoding.

B<Important:> This method modifies the object I<in place> and B<cannot be
undone>.  There is no C<decode()> counterpart.  See L</COMMON PITFALLS>.

=head3 ARGUMENTS

None.

=head3 RETURN VALUE

Returns the object itself (C<$self>), so C<encode()> can be chained directly
onto C<new()>.

=head3 EXAMPLE

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

=head3 API SPECIFICATION

=head4 Input

    None.

=head4 Output

    # Return::Set schema
    on_success => $self    # the same Lingua::Text object, with texts encoded

=cut

sub encode {
	my $self = shift;

	# Iterate over keys to avoid stale iterator state from each().
	for my $lang (keys %{$self->{'texts'}}) {
		# SECURITY V2: Object::Configure may inject non-language keys (e.g. 'logger')
		# that carry blessed references.  utf8::decode() modifies its argument IN
		# PLACE, which would corrupt the referenced object's internal string buffer.
		# encode_entities() would then stringify it, potentially leaking its repr.
		# Only process keys that satisfy the object invariant (valid ISO 639-1 code).
		next unless _is_valid_language($lang);

		my $v = $self->{'texts'}->{$lang};

		# SECURITY V3: a caller may store undef via $t->en(undef).  utf8::decode(undef)
		# emits "Use of uninitialized value" under 'use warnings' and is a no-op,
		# but encode_entities(undef) returns '' which silently drops the entry.
		# Skip explicitly so the stored undef is preserved unchanged.
		next unless defined($v) && !ref($v);

		utf8::decode($v) unless utf8::is_utf8($v);
		$self->{'texts'}->{$lang} = HTML::Entities::encode_entities($v);
	}
	return $self;
}

=head2 Language accessor methods

Any two-letter method name that is a valid ISO 639-1 language code acts as a
combined getter and setter for that language's translation.  These methods do
not need to be declared; Perl's C<AUTOLOAD> mechanism intercepts them.

    $t->en('Hello');          # store an English translation
    my $text = $t->fr();      # retrieve the French translation (undef if not stored)
    $t->zh('');               # store an empty string (distinct from undef/not-stored)
    $t->en(0);                # store the string "0" (falsy values work correctly)

=head3 ARGUMENTS

=over 4

=item B<Setter form> -- pass one scalar argument

The value is stored under the method's language code and also returned.

=item B<Getter form> -- call with no arguments

Returns the stored string for that language, or C<undef> if nothing has been
stored.

=back

=head3 RETURN VALUE

=over 4

=item Returns the stored translation string (getter) or the value just stored
(setter).

=item Returns C<undef> -- silently -- when the language has no stored
translation.

=item Returns C<undef> silently for any method name that is not a recognised
two-letter ISO 639-1 code.  This means typos (e.g. C<$t-E<gt>enn()>) fail
invisibly.  See L</COMMON PITFALLS>.

=back

=head3 EXAMPLE

    my $t = Lingua::Text->new();

    $t->en('Good morning');
    $t->fr('Bonjour');
    $t->de('Guten Morgen');

    print $t->en(), "\n";   # Good morning
    print $t->ja(), "\n";   # (nothing -- no Japanese stored)

    # Chaining setters is not supported; use set() for that.
    # Setters return the stored value, not $self.

=head3 API SPECIFICATION

=head4 Method name domain (BVA)

The accessor is only created for method names that match C</^[a-z]{2}$/>:
exactly two lower-case ASCII letters.  All other names return C<undef>
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

=head4 Input

    # Setter: one positional SCALAR (may be undef, '', or '0')
    # Getter: no arguments

=head4 Value domain (setter)

Any scalar value -- including C<undef>, C<''>, and C<'0'> -- is accepted
and stored verbatim.  C<encode()> will later skip C<undef> and reference
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

=head4 Output

    # Return::Set schema
    on_set     => SCALAR | undef    # the value just stored
    on_get     => SCALAR | undef    # the stored value, or undef if absent
    on_invalid => undef             # silently, for non-language method names

=head3 MESSAGES

None.  All failure cases return C<undef> silently.  See L</COMMON PITFALLS>
for guidance on typo detection.

=cut

sub AUTOLOAD {
	my $self = shift or return;

	my ($key) = $AUTOLOAD =~ /::(\w+)\z/;

	return if $key eq 'DESTROY';
	return unless ref($self) eq __PACKAGE__;
	# Syllogism:
	# P1: _is_valid_language accepts ^[a-z]{2}(?:_[A-Z]{2})?$ (case-sensitive).
	# P2: AUTOLOAD method names are bare identifiers; the \w+ capture never
	#     produces the _XX suffix, so the relevant subset is ^[a-z]{2}$.
	# P3: Any key passing /^[a-z]{2}$/ (no i-flag) is exactly two lowercase
	#     letters -- a strict subset of what _is_valid_language accepts.
	# Conclusion: the _is_valid_language call is a tautology after the regex
	#     and is removed.  The i-flag is also dropped to make the check strict.
	return unless $key =~ /^[a-z]{2}$/;

	# Install a real method for $key so all future calls bypass AUTOLOAD entirely.
	# Each two-letter code gets its own closure installed exactly once.  This
	# reduces repeated accessor cost from AUTOLOAD overhead (~5 regex ops) to a
	# direct method dispatch, which is the dominant cost when rendering a page
	# that stringifies many objects through the same language code.
	{
		no strict 'refs';
		*{__PACKAGE__ . '::' . $key} = sub {
			my $s = shift or return;
			$s->{'texts'}->{$key} = shift if @_;
			return $s->{'texts'}->{$key};
		};
	}

	# Use @_ presence (not truthiness) so falsy values like '0' or '' are stored
	if(@_) {
		$self->{'texts'}->{$key} = shift;
	}

	return $self->{'texts'}->{$key};
}

# ---------------------------------------------------------------------------
# Private helpers
# ---------------------------------------------------------------------------

# Purpose:  Format a message from the catalog with the package name filled in.
# Entry:    $key -- key into %MESSAGES.
# Exit:     Formatted string ready for Carp.
# Effects:  None.
sub _err :Private {
	my ($key) = @_;
	my $fmt = $MESSAGES{$key};
	return sprintf($fmt, __PACKAGE__) if defined($fmt);
	# Defensive: a future caller added a new key without a matching %MESSAGES entry.
	# confess rather than returning a string so the programmer sees the bad key
	# immediately at the call site instead of getting a silent wrong message.
	Carp::confess("Internal error: _err() called with unknown key '$key' -- add it to %MESSAGES");
}

# Purpose:  Issue a carp warning for a set() usage mistake and return undef.
#           Extracted to eliminate the duplicated carp + return pattern in set().
# Entry:    None (uses package-level _err).
# Exit:     undef.
# Effects:  Emits a Carp warning visible at the caller's call site.
sub _carp_set_usage :Private {
	Carp::carp(_err('set_usage'));
	return;
}

# https://www.gnu.org/software/gettext/manual/html_node/Locale-Environment-Variables.html
# https://www.gnu.org/software/gettext/manual/html_node/The-LANGUAGE-variable.html
#
# Purpose:  Determine the two-letter ISO 639-1 language code for the running
#           environment by probing standard locale environment variables in
#           precedence order.
# Entry:    Environment variables: LANGUAGE, LC_ALL, LC_MESSAGES, LANG.
# Exit:     Lower-case two-letter code (e.g. 'en', 'fr'), or undef if the
#           locale is absent, empty, or set to the POSIX 'C' locale.
#           Returns 'en' when LANG=C or LANG=C.<encoding>.
# Effects:  Read-only.  The result is memoised against an env-var snapshot so
#           repeated calls within the same process incur only five string
#           comparisons rather than a full I18N::LangTags::Detect scan.
#           The cache is invalidated automatically whenever LANGUAGE, LC_ALL,
#           LC_MESSAGES, LANG, or HTTP_ACCEPT_LANGUAGE changes (e.g. local %ENV
#           in tests).
{
	my ($cached_lang, %cached_env);

	sub _get_language :Private {
		# Fast path: env vars unchanged since last call -- return cached result.
		# Using 'exists' rather than defined($cached_lang) so a cached undef is
		# also served from cache (avoids re-probing an env with no locale set).
		if(exists $cached_env{LANG}) {
			my $stale = 0;
			for my $v (qw(LANGUAGE LC_ALL LC_MESSAGES LANG HTTP_ACCEPT_LANGUAGE)) {
				if(($ENV{$v} // '') ne $cached_env{$v}) { $stale = 1; last }
			}
			return $cached_lang unless $stale;
		}

		# Slow path: probe the environment.
		# SECURITY V1 (taint mode): under perl -T, %ENV values are tainted.
		# Perl only untaints a substring via a regex CAPTURE GROUP -- the captured
		# $1 is untainted once the match succeeds.  substr() on a tainted string
		# propagates taint, so the previous substr()-based extraction was wrong
		# for taint-mode callers.  Restore explicit capturing groups here.
		my $lang;
		for my $tag (I18N::LangTags::Detect::detect()) {
			if($tag =~ /^([a-z]{2})/i) { $lang = lc($1); last }    # $1 untainted
		}
		if(!defined($lang) && ($ENV{'LANGUAGE'} // '') =~ /^([a-z]{2})/i) {
			$lang = lc($1);    # $1 untainted
		}
		if(!defined($lang)) {
			for my $var ('LC_ALL', 'LC_MESSAGES', 'LANG') {
				my $val = $ENV{$var} // next;
				if($val =~ /^([a-z]{2})/i) {
					my $code = lc($1);    # $1 untainted
					if(_is_valid_language($code)) { $lang = $code; last }
				}
			}
		}
		# POSIX 'C' locale is treated as English.
		# (?:\z|\.) matches 'C' at end-of-string or 'C.' (e.g. 'C.UTF-8').
		# Non-capturing group: the dot is tested but its value is never needed.
		$lang //= 'en' if ($ENV{'LANG'} // '') =~ /^C(?:\z|\.)/;

		# Cache result and snapshot the five vars we check.
		$cached_lang    = $lang;
		$cached_env{$_} = $ENV{$_} // '' for qw(LANGUAGE LC_ALL LC_MESSAGES LANG HTTP_ACCEPT_LANGUAGE);
		return $lang;
	}
}

# Purpose:  Validate that a string is a well-formed language code accepted by
#           this module (ISO 639-1 with optional ISO 3166-1 country suffix).
# Entry:    $lang -- candidate string.
# Exit:     True if $lang matches $LANG_RE; false otherwise.
sub _is_valid_language :Private {
	my ($lang) = @_;
	return $lang =~ $LANG_RE;
}

=head1 COMMON PITFALLS

This section documents behaviours that often surprise first-time users.

=head2 encode() cannot be undone

C<encode()> modifies the object in place.  There is no C<decode()>.  If you
call C<encode()> twice on the same object, every special character is encoded
twice (e.g. C<&eacute;> becomes C<&amp;eacute;>).  Always call C<encode()>
once, as the last step, and only on a freshly built object.

    # WRONG -- double-encoding
    my $t = Lingua::Text->new(fr => "\x{E9}tude")->encode()->encode();
    print $t->fr();    # &amp;eacute;tude  (broken HTML)

    # CORRECT
    my $t = Lingua::Text->new(fr => "\x{E9}tude")->encode();
    print $t->fr();    # &eacute;tude

=head2 Missing translation returns undef, not an empty string

When a translation is not stored for the requested language, C<as_string()>
and the accessor methods return C<undef>, not C<"">.  Use C<defined()> to test
for absence, not a truth check.

    my $t = Lingua::Text->new(en => 'hello');

    my $de = $t->de();
    print "Missing\n" unless defined($de);   # correct
    print "Missing\n" unless $de;            # WRONG -- also triggers for $de = '0'

=head2 Typos in language codes are silent

The AUTOLOAD accessor returns C<undef> for any two-letter name that is not a
valid ISO 639-1 code, and also for valid codes that have no stored translation.
A typo like C<$t-E<gt>enn()> produces C<undef> without any warning.

    $t->en('hello');
    print $t->enn();    # undef -- no warning, no error

To guard against this, always check with C<defined()> and, during development,
consider adding a test that verifies the expected languages are present.

=head2 new('text') silently drops the text when no locale is set

When you pass a single string to C<new()>, it is stored under the current
system language.  If no locale environment variable (C<LANG>, C<LC_MESSAGES>,
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

=head2 set() and the language accessors return $self or the value, not the text

C<set()> returns the object (C<$self>).  Because of the stringify overload,
when you print or compare the return value, it I<looks> like a string -- but it
is an object.  Do not rely on this behaviour; retrieve the value separately.

    my $t = Lingua::Text->new();
    my $result = $t->set(text => 'Hello', lang => 'en');

    # $result is the Lingua::Text object, not the string 'Hello'
    # This works due to stringify overload, but is misleading:
    print $result;          # Hello (via stringify)

    # Clearer intent:
    $t->set(text => 'Hello', lang => 'en');
    print $t->as_string('en');   # Hello

The AUTOLOAD setter (e.g. C<$t-E<gt>en('Hello')>) returns the stored value
directly, not C<$self>.

=head2 A Lingua::Text object is always true

The object overloads the boolean C<bool> operator to always return true, even
when it contains no translations.  Do B<not> use an object as a truth test to
check whether it has any content.

    my $t = Lingua::Text->new();   # empty
    if($t) { print "always reached\n"; }   # always true

    # To check whether a specific language is stored:
    if(defined($t->en())) { print "English is stored\n"; }

=head2 Function-style call with arguments is an error

Perl allows calling methods as functions, but Lingua::Text::new() (with
double-colon and arguments) will emit a warning and return C<undef>.

    my $t = Lingua::Text::new(en => 'hi');   # WRONG -- carp warning, returns undef
    my $t = Lingua::Text->new(en => 'hi');   # correct

Calling C<Lingua::Text::new()> with B<no> arguments works (it creates an empty
object), but the arrow form is still preferred.

=head1 PERFORMANCE

Three optimisations address the hot paths in typical web or CGI use (many
objects stringified per request, same accessor called repeatedly):

=over 4

=item B<Memoised locale detection>

C<_get_language()> is called on every C<as_string()> invocation (including
stringify via C<"">).  The result is cached against a snapshot of the five
relevant environment variables (C<LANGUAGE>, C<LC_ALL>, C<LC_MESSAGES>,
C<LANG>, C<HTTP_ACCEPT_LANGUAGE>).  As long as those variables do not change,
subsequent calls cost only five string comparisons instead of a full
C<I18N::LangTags::Detect::detect()> scan.  The cache is invalidated
automatically when any of those variables change -- including C<local %ENV>
in tests.

=item B<AUTOLOAD method installation>

The first call to any two-letter accessor (e.g. C<$t-E<gt>en()>) installs a
real subroutine in the package symbol table.  All subsequent calls for that
code dispatch directly, bypassing the AUTOLOAD regex and guard overhead
entirely.

=item B<Single-argument fast path in as_string()>

C<$t-E<gt>as_string('en')> skips C<Params::Get::get_params()> when exactly
one non-reference argument is supplied.  Named (C<lang =E<gt> 'en'>) and
hashref (C<{ lang =E<gt> 'en' }>) forms still go through the full parser.

=back

=head1 LIMITATIONS

=over 4

=item * B<No decode()>: Once C<encode()> is called, all translations are
HTML-entity-encoded.  There is no method to reverse this.

=item * B<No language fallback>: If C<en_GB> is the system locale but only
C<en> is stored, the module finds the text correctly (because the country
suffix is stripped).  However, if C<en_GB> is stored as a key and the system
locale is C<en_US>, the text is I<not> found.  Only two-letter codes are used
as storage keys.

=item * B<Silent AUTOLOAD failures>: Unrecognised method names (including
typos) return C<undef> without any diagnostic.

=item * B<Object::Configure semantics>: The exact effect of
L<Object::Configure> depends on the installed version and any project-level
configuration present.  Without a configuration file, it passes parameters
through unchanged.

=back

=head1 DEPENDENCIES

Runtime:

=over 4

=item * L<Carp> -- C<carp>/C<croak> for warnings and errors

=item * L<HTML::Entities> -- HTML entity encoding in C<encode()>

=item * L<I18N::LangTags::Detect> -- locale detection from environment variables

=item * L<Object::Configure> -- optional config-file defaults for C<new()>

=item * L<Params::Get> -- flexible argument parsing for public methods

=item * L<Readonly> -- constant definitions for the message catalog and patterns

=item * L<Scalar::Util> -- C<blessed()> for safe type testing

=item * L<Sub::Private> -- enforcement of private method access

=back

=head1 AUTHOR

Nigel Horne, C<< <njh at nigelhorne.com> >>

=head1 BUGS

Please report bugs at L<https://github.com/nigelhorne/Lingua-Text/issues>.

=head1 SEE ALSO

=over 4

=item * L<Object::Configure> -- runtime object configuration

=item * L<I18N::LangTags::Detect> -- the locale detection module used internally

=item * L<HTML::Entities> -- the HTML encoding module used by C<encode()>

=item * L<Test Dashboard|https://nigelhorne.github.io/CGI-Info/coverage/>

=back

=head1 SUPPORT

This module is provided as-is without any warranty.

Documentation:

    perldoc Lingua::Text

Online resources:

=over 4

=item * MetaCPAN: L<https://metacpan.org/release/Lingua-Text>

=item * Bug tracker: L<https://rt.cpan.org/NoAuth/Bugs.html?Dist=Lingua-Text>

=item * CPANTS: L<http://cpants.cpanauthors.org/dist/Lingua-Text>

=item * CPAN Testers: L<http://matrix.cpantesters.org/?dist=Lingua-Text>

=item * Dependencies: L<http://deps.cpantesters.org/?module=Lingua-Text>

=back

=encoding utf-8

=head1 FORMAL SPECIFICATION

=head2 new

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

=head2 set

    -- set: add or replace one translation; all others remain unchanged
    ┌─ set ───────────────────────────────────────────────────
    │ ΔLinguaText
    │ lang? : LANG
    │ text? : STRING
    ├─────────────────────────────────────────────────────────
    │ texts' = texts ⊕ { lang? ↦ text? }
    └─────────────────────────────────────────────────────────
    -- ⊕ denotes relational override: lang? wins over any existing entry

=head2 as_string

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

=head2 encode

    -- Let entity : STRING -> STRING be HTML::Entities::encode_entities
    -- and  dec   : STRING -> STRING be utf8::decode (applied only when needed)
    ┌─ encode ────────────────────────────────────────────────
    │ ΔLinguaText
    │ ∀ l : dom texts
    │     • texts'(l) = entity(dec(texts(l)))
    └─────────────────────────────────────────────────────────
    -- texts' replaces every value; dom texts is unchanged.

=head1 LICENCE AND COPYRIGHT

Copyright 2021-2026 Nigel Horne.

Usage is subject to the GPL2 licence terms.
If you use it, please let me know.

=cut

1;
