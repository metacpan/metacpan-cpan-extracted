# NAME

Encode::Wide - Convert wide characters (Unicode, UTF-8, etc.) into ASCII-safe HTML or XML entities

# VERSION

0.07

# SYNOPSIS

    use Encode::Wide qw(wide_to_html wide_to_xml);

    # Basic HTML conversion
    my $html = wide_to_html(string => "Cafe\x{E9} d\x{E9}j\x{E0} vu");
    # => 'Caf&eacute; d&eacute;j&agrave; vu'

    # Basic XML conversion (numeric entities, en-dash folded to hyphen)
    my $xml = wide_to_xml(string => "Cafe\x{E9} \x{2013} na\x{EF}ve");
    # => 'Caf&#x0E9; - na&#x0EF;ve'

    # Preserve embedded HTML markup (keep_hrefs)
    my $linked = wide_to_html(
        string     => '<a href="/menu">Caf\x{E9}</a>',
        keep_hrefs => 1,
    );
    # => '<a href="/menu">Caf&eacute;</a>'

    # Keep apostrophes literal for JavaScript contexts (keep_apos)
    my $js_safe = wide_to_html(
        string    => "it\x{2019}s na\x{EF}ve",
        keep_apos => 1,
    );
    # => "it\x{2019}s na&iuml;ve"   (curly apostrophe kept; i-umlaut encoded)

    # Get notified about unhandled characters instead of dying silently
    my $out = wide_to_html(
        string   => $untrusted,
        complain => sub { warn "Unhandled: $_[0]" },
    );

    # Accept a scalar reference
    my $text = "na\x{EF}ve";
    my $safe = wide_to_html(string => \$text);
    # => 'na&iuml;ve'

# DESCRIPTION

Encode::Wide converts strings that contain non-ASCII (wide) characters into
pure 7-bit ASCII output suitable for embedding in HTML pages or XML documents.
Every non-ASCII codepoint is replaced by the appropriate entity reference so
the output can be safely placed in HTML attributes, HTML body text, or XML
element content without triggering encoding errors or security issues.

## Why use this module?

[HTML::Entities](https://metacpan.org/pod/HTML%3A%3AEntities) is the obvious alternative for HTML, but it makes strict
assumptions about input encoding that cause silent failures when the input
arrives as raw UTF-8 bytes, already-partially-encoded entities, or a mix of
both.  Encode::Wide handles all three representations through a multi-pass
pipeline and falls back to [HTML::Entities](https://metacpan.org/pod/HTML%3A%3AEntities) numeric encoding for any
character not explicitly listed in its tables.

For XML, [XML::Entities](https://metacpan.org/pod/XML%3A%3AEntities) works in the opposite direction (decoding entities,
not encoding them).  Encode::Wide fills that gap.

## Input

Both functions accept:

- A **Perl Unicode string** (the internal `utf8` flag is set) - the normal case
when input comes from ["decode" in Encode](https://metacpan.org/pod/Encode#decode), a database driver with `pg_enable_utf8`,
or a source file declared `use utf8`.
- A **raw UTF-8 byte string** - the common case when input arrives from a legacy
web form or an older database driver without automatic decoding.  The pipeline's
raw-byte substitution pass handles this transparently.
- A **scalar reference** - `wide_to_html(string => \$var)`.  The string is
read from the referent; the referent is not modified.
- **Already-encoded HTML entities** - e.g. `&eacute;` or `&lt;`.
By default the pipeline decodes these first so they are not double-encoded.
Pass `keep_hrefs => 1` to suppress decoding when the input contains
trusted HTML that must pass through unchanged.

## Output

Both functions return a **defined scalar string** containing **only ASCII
characters** (code points 0x00-0x7F).  The output is safe to concatenate
directly into an HTML or XML document without further escaping.

## Choosing between the two functions

Use `wide_to_html` when writing into an HTML context (`<p>`, `<td>`,
attribute values, etc.).  Named entities such as `&eacute;` and `&ndash;`
are used wherever possible; they are compact and human-readable in the source.

Use `wide_to_xml` when writing into an XML context (XHTML, RSS, Atom, custom
XML schemas).  Named HTML entities other than the five predefined XML entities
(`&amp;` `&lt;` `&gt;` `&apos;` `&quot;`) are not valid in XML.
This function uses only hexadecimal numeric entities (`&#x0E9;`), which are
valid in all XML 1.0 processors.  Em-dashes and en-dashes are folded to a
plain ASCII hyphen because many XML consumers normalise whitespace and
punctuation anyway.

# EXPORT

Nothing is exported by default.  Import the functions you need explicitly:

    use Encode::Wide qw(wide_to_html);          # one function
    use Encode::Wide qw(wide_to_html wide_to_xml);  # both

# COMMON PARAMETERS

Both functions accept the following named parameters in addition to `string`.
Pass them as a flat key-value list:

    wide_to_html(string => $text, keep_hrefs => 1, complain => \&handler);

- `string` (required)

    The text to encode.  May be a plain scalar or a **reference to a scalar**.
    Must be defined; passing `undef` causes the function to `croak` with a
    usage message.

- `keep_hrefs` (optional, default 0)

    When true, angle brackets (`<`, `>`) and double-quotes (`"`) are
    **not** escaped, allowing embedded HTML or XML markup to survive intact.

    **Security note:** when `keep_hrefs` is set, entity-decoding is also
    suppressed.  Without this suppression, an encoded payload such as
    `&lt;script&gt;` would be decoded to `<script>` and then pass through
    unescaped, creating an XSS vector.  With `keep_hrefs => 1` it is the
    **caller's responsibility** to ensure that the input does not contain untrusted
    content that could be exploited.

- `complain` (optional)

    A code reference called with a diagnostic string when the pipeline encounters a
    character it cannot encode.  The function still `croak`s with a `BUG:`
    prefix after invoking the callback - `complain` is for logging, not recovery.

        wide_to_html(
            string   => $text,
            complain => sub {
                my ($msg) = @_;
                warn "Encode::Wide gap: $msg";
            },
        );

## wide\_to\_html

Convert a Unicode or UTF-8 string into a pure-ASCII HTML fragment.  Every
non-ASCII character is replaced by its named HTML entity (e.g. `&eacute;`)
where one exists, or a hexadecimal numeric entity (e.g. `&#xNNNN;`) otherwise.
Bare ampersands, angle brackets, and double-quotes are also escaped so the
result is safe to embed in HTML body text or attribute values without further
processing.

### Arguments

All parameters are passed as a flat key-value list.  The `string` key may be
omitted when passing a bare positional string as the first argument.

See ["COMMON PARAMETERS"](#common-parameters) for `string`, `keep_hrefs`, and `complain`.

- `keep_apos` (optional, default 0)

    When true, apostrophes and their typographic variants (curly single quotes
    U+2018, U+2019; grave accent U+0060; Windows-1252 byte 0x98) are **not**
    converted to `&apos;`.  Useful when the result will be embedded inside a
    JavaScript string literal where `&apos;` is not valid syntax.

### Returns

A defined scalar string whose every character is in the ASCII range
(code points 0x00-0x7F).  The empty string is returned unchanged.

### EXAMPLE

    use Encode::Wide qw(wide_to_html);

    # Accented characters to named entities
    my $out = wide_to_html(string => "na\x{EF}ve caf\x{E9}");
    # => 'na&iuml;ve caf&eacute;'

    # Ampersands and angle brackets are escaped
    $out = wide_to_html(string => 'Price < 100 & cost > 0');
    # => 'Price &lt; 100 &amp; cost &gt; 0'

    # Existing entities are decoded then re-encoded (no double-encoding)
    $out = wide_to_html(string => '&eacute;');
    # => '&eacute;'

    # keep_hrefs: HTML markup passes through; only wide chars are encoded
    $out = wide_to_html(
        string     => '<a href="/m\x{E9}nu">Men\x{FC}</a>',
        keep_hrefs => 1,
    );
    # => '<a href="/m&eacute;nu">Men&uuml;</a>'

    # keep_apos: apostrophes kept for JavaScript contexts
    $out = wide_to_html(
        string    => "it\x{2019}s clich\x{E9}",
        keep_apos => 1,
    );
    # => "it\x{2019}s clich&eacute;"

    # Scalar reference input
    my $text = "caf\x{E9}";
    $out = wide_to_html(string => \$text);
    # => 'caf&eacute;'

### MESSAGES

- `Usage: wide_to_html() string not set`

    **Fatal** (via `croak`).  The `string` parameter was `undef`.
    Resolution: pass a defined scalar or scalar reference.

- `TODO: wide_to_html(<hex-tokens...>)`

    **Warning** (via `carp`).  A character survived all three byte\_map passes and
    the `encode_entities_numeric` fallback.  The hex tokens in the message
    identify the unhandled codepoint(s).
    Resolution: add the character to the appropriate byte\_map array, or file a bug
    report at [https://rt.cpan.org/Public/Dist/Display.html?Name=Encode-Wide](https://rt.cpan.org/Public/Dist/Display.html?Name=Encode-Wide).

- `BUG: wide_to_html(<hex-tokens...>)`

    **Fatal** (via `croak`), always preceded by the `TODO` warning above.
    The same unhandled-character condition caused a hard failure.  This should
    never occur in normal use; it indicates a gap in the character tables.

### API SPECIFICATION

#### Input

    {
        string     => { type => SCALAR | SCALARREF, required => 1, defined => 1 },
        keep_hrefs => { type => BOOLEAN, optional => 1, default => 0 },
        keep_apos  => { type => BOOLEAN, optional => 1, default => 0 },
        complain   => { type => CODEREF,  optional => 1 },
    }

#### Output

    { type => SCALAR, constraint => sub { $_[0] !~ /[^[:ascii:]]/ } }

### PSEUDOCODE

     1. Unless keep_hrefs: decode HTML entities via HTML::Entities::decode
        and the four extra named entities (&ccaron; &zcaron; &Zcaron; &Scaron;)
     2. Escape bare & not followed by a valid entity name
        (possessive ++ quantifier prevents ReDoS backtracking)
     3. Unless keep_hrefs: escape <, >, and " using %_HTML_ESCAPE (no /e eval)
     4. First byte_map pass: typographic punctuation and exclamation mark
     5. Unless keep_apos: encode apostrophe variants to &apos;
        using an alternation regex built from the apostrophe key set
     6. Early return if the string is now pure ASCII
     7. Second byte_map pass: raw UTF-8 byte sequences -> named HTML entities
     8. Third byte_map pass: Perl Unicode chars (\N{U+...}) -> named HTML entities
     9. Fallback: HTML::Entities::encode_entities_numeric for any remaining
        non-ASCII codepoints
    10. If non-ASCII still remains after the fallback: invoke complain callback,
        carp a TODO warning, then croak a BUG error

## wide\_to\_xml

Convert a Unicode or UTF-8 string into a pure-ASCII XML fragment.  Every
non-ASCII character is replaced by a hexadecimal numeric entity
(e.g. `&#x0E9;`).  Only numeric entities are used because named HTML entities
such as `&eacute;` are not defined in XML 1.0 outside of XHTML with a DTD.
Em-dashes and en-dashes are folded to a plain ASCII hyphen `-`.
Bare ampersands, angle brackets, and double-quotes are escaped so the output
is valid XML element content.

### Arguments

All parameters are passed as a flat key-value list.  The `string` key may be
omitted when passing a bare positional string as the first argument.

See ["COMMON PARAMETERS"](#common-parameters) for `string`, `keep_hrefs`, and `complain`.
This function does not accept `keep_apos`.

### Returns

A defined scalar string whose every character is in the ASCII range
(code points 0x00-0x7F).  The empty string is returned unchanged.

### EXAMPLE

    use Encode::Wide qw(wide_to_xml);

    # Accented characters become numeric entities
    my $out = wide_to_xml(string => "SURN \x{017D}ganjar");
    # => 'SURN &#x17D;ganjar'

    # En-dash and em-dash are folded to a plain hyphen
    $out = wide_to_xml(string => "2020\x{2013}2026");
    # => '2020-2026'

    # Ampersands and angle brackets are XML-escaped
    $out = wide_to_xml(string => 'a < b & c > 0');
    # => 'a &lt; b &amp; c &gt; 0'

    # keep_hrefs: XML tags pass through; wide chars are still encoded
    $out = wide_to_xml(
        string     => '<item lang="fr">Caf\x{E9}</item>',
        keep_hrefs => 1,
    );
    # => '<item lang="fr">Caf&#x0E9;</item>'

    # Scalar reference input
    my $text = "caf\x{E9}";
    $out = wide_to_xml(string => \$text);
    # => 'caf&#x0E9;'

### MESSAGES

- `Usage: wide_to_xml() string not set`

    **Fatal** (via `croak`).  The `string` parameter was `undef`.
    Resolution: pass a defined scalar or scalar reference.

- `TODO: wide_to_xml(<hex-tokens...>)`

    **Warning** (via `carp`).  A character survived all three byte\_map passes.
    The hex tokens in the message identify the unhandled codepoint(s).
    Resolution: add the character to the appropriate byte\_map array, or file a bug
    report at [https://rt.cpan.org/Public/Dist/Display.html?Name=Encode-Wide](https://rt.cpan.org/Public/Dist/Display.html?Name=Encode-Wide).

- `BUG: wide_to_xml(<hex-tokens...>)`

    **Fatal** (via `croak`), always preceded by the `TODO` warning above.
    This should never occur in normal use; it indicates a gap in the XML character
    tables.  Unlike `wide_to_html`, there is no numeric-entity fallback for XML
    because there is no safe generic fallback that is valid in all XML contexts.

### API SPECIFICATION

#### Input

    {
        string     => { type => SCALAR | SCALARREF, required => 1, defined => 1 },
        keep_hrefs => { type => BOOLEAN, optional => 1, default => 0 },
        complain   => { type => CODEREF,  optional => 1 },
    }

#### Output

    { type => SCALAR, constraint => sub { $_[0] !~ /[^[:ascii:]]/ } }

### PSEUDOCODE

    1. Unless keep_hrefs: decode HTML entities via HTML::Entities::decode
       and the four extra named entities (&ccaron; &zcaron; &Zcaron; &Scaron;)
    2. Escape bare & not followed by a valid entity name
       (possessive ++ quantifier prevents ReDoS backtracking)
    3. Unless keep_hrefs: escape <, >, and " using %_HTML_ESCAPE (no /e eval)
    4. First byte_map pass: curly quotes -> &quot;, dashes -> -, apostrophes
    5. Early return if the string is now pure ASCII
    6. Second byte_map pass: raw UTF-8 byte sequences -> numeric XML entities
    7. Third byte_map pass: Perl Unicode chars (\N{U+...}) -> numeric XML entities
    8. If non-ASCII still remains: invoke complain callback, carp a TODO warning,
       then croak a BUG error

# SECURITY

## XSS via entity decode and keep\_hrefs

By default both functions call `HTML::Entities::decode` as the first pipeline
step, normalising input like `&lt;b&gt;` to `<b>` before re-escaping it.
This round-trip is safe when `keep_hrefs` is false because the re-escape step
then converts `<` and `>` back to `&lt;` and `&gt;`.

When `keep_hrefs => 1` is set, the re-escape step is skipped so that
existing markup survives intact.  If the decode step still ran, a malicious
input such as `&lt;script&gt;alert(1)&lt;/script&gt;` would become the raw
string `<script>alert(1)</script>` and pass through to the output
unescaped, creating a stored XSS vector.

**Fix applied in 0.07:** when `keep_hrefs` is true, the decode step is also
skipped.  The pipeline treats the input as already-trusted HTML; wide
characters are still encoded, but entity normalisation becomes the caller's
responsibility.

## ReDoS in bare-ampersand substitution

The substitution that escapes bare `&` characters uses a negative lookahead
to distinguish bare ampersands from valid entity references.  A naive
backtracking quantifier inside that lookahead creates O(n^2) work for inputs
such as `&aaaaa...X` (many word characters, no closing semicolon).

**Fix applied in 0.07:** the character class inside the lookahead uses a
possessive quantifier `[A-Za-z#0-9]++`, which commits matches and prevents
backtracking.  Perl 5.10 or later is required, consistent with the declared
`MIN_PERL_VERSION`.

## Eval-free substitutions

All substitutions in this module use plain `/g` rather than `/ge` (evaluate
replacement as Perl code).  The `/e` flag was present in earlier versions but
was unnecessary: hash lookups are value interpolation, not executable code.
Removing `/e` eliminates a class of potential code-injection issues should a
future change inadvertently expose user-controlled data in the replacement
expression.

# LIMITATIONS

- Character coverage is hand-maintained

    Both functions use explicit `@byte_map` tables organised into three passes
    (raw UTF-8 bytes, `\N{U+...}` named chars, literal Unicode source chars).
    Characters not covered by these tables fall back to
    `HTML::Entities::encode_entities_numeric` in `wide_to_html`, or trigger a
    fatal `BUG:` error in `wide_to_xml` (XML has no safe generic numeric
    fallback).  To add a missing character, extend all three passes for the
    relevant function and add a regression test in `t/30-basics.t`.

- No `<script>` or `<style>` awareness

    `wide_to_html` encodes wide characters uniformly regardless of context.  It
    does not detect content inside `<script>` or `<style>` blocks, so
    passing a complete HTML document through this function will corrupt embedded
    scripts and stylesheets.  Feed only text fragments or attribute values, not
    full documents.

- XML numeric entity format uses a minimal hex width

    The XML pipeline outputs `&#x0E9;` (three hex digits with one leading zero
    for values below 0x100) rather than the canonical four-digit form `&#x00E9;`.
    Both representations are valid XML 1.0.  Consumers that perform strict byte-
    level comparison of entity strings should normalise to a consistent width
    before comparing.

- Raw binary input is not supported

    The module assumes its input is either a Perl Unicode string (internal `utf8`
    flag set) or a valid UTF-8 byte string.  Passing arbitrary binary data or
    text in a single-byte encoding other than Latin-1 will produce incorrect
    output or trigger decoding errors.  Decode the input with ["decode" in Encode](https://metacpan.org/pod/Encode#decode)
    before calling these functions.

- `keep_hrefs` shifts trust to the caller

    When `keep_hrefs => 1` is set, entity-decoding is suppressed and markup
    characters pass through unescaped.  The caller must guarantee that the input
    does not contain untrusted content that could produce XSS output.

# SEE ALSO

- [Test Dashboard](https://nigelhorne.github.io/Encode-Wide/coverage/)
- [HTML::Entities](https://metacpan.org/pod/HTML%3A%3AEntities) — the standard module for HTML entity encoding and decoding
- [Encode](https://metacpan.org/pod/Encode) — Perl's core character encoding framework
- [XML::Entities](https://metacpan.org/pod/XML%3A%3AEntities) — decodes XML named entities (the inverse of wide\_to\_xml)
- [Unicode::Escape](https://metacpan.org/pod/Unicode%3A%3AEscape) — alternative Unicode escaping approaches
- [https://www.compart.com/en/unicode/](https://www.compart.com/en/unicode/) — Unicode character reference

# SUPPORT

Please report bugs and feature requests through the RT bug tracker:

    https://rt.cpan.org/Public/Dist/Display.html?Name=Encode-Wide

Or by email: `bug-encode-wide at rt.cpan.org`

You will be notified automatically of progress on your report.

# FORMAL SPECIFICATION

## wide\_to\_html

Let S be the input string, S' the output string.

    ∀ c ∈ S' : ord(c) ≤ 0x7F                           (ASCII-only output)
    S = ""  ⟹  S' = ""                                  (empty pass-through)
    keep_hrefs = 0 ⟹ "<" ∉ S' ∧ ">" ∉ S' ∧ ∄ bare " in S'
    keep_apos  = 0 ⟹ ∄ bare apostrophe in S'
    ¬∃ bare & in S'  (& appears only as part of a valid &name; or &#xNN; entity)
    string = undef ⟹ croak("Usage: wide_to_html() string not set")

## wide\_to\_xml

Let S be the input string, S' the output string.

    ∀ c ∈ S' : ord(c) ≤ 0x7F                           (ASCII-only output)
    S = ""  ⟹  S' = ""                                  (empty pass-through)
    keep_hrefs = 0 ⟹ "<" ∉ S' ∧ ">" ∉ S' ∧ ∄ bare " in S'
    U+2013 ∈ S ⟹ "-" ∈ S' ∧ U+2013 ∉ S'               (en-dash collapsed)
    U+2014 ∈ S ⟹ "-" ∈ S' ∧ U+2014 ∉ S'               (em-dash collapsed)
    ¬∃ bare & in S'  (& appears only as part of a valid &name; or &#xNN; entity)
    string = undef ⟹ croak("Usage: wide_to_xml() string not set")

# AUTHOR

Nigel Horne, `<njh at nigelhorne.com>`

# LICENCE AND COPYRIGHT

Copyright 2025-2026 Nigel Horne.

This library is free software; you may redistribute it and/or modify it under
the same terms as Perl itself (GPL version 2 or later).

If you use this module, please let me know at
`njh at nigelhorne.com`.
