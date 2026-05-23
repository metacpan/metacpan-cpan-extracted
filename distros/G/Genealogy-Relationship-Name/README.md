# NAME

Genealogy::Relationship::Name - Return a genealogical relationship name from step counts

# VERSION

Version 0.03

# SYNOPSIS

    use Genealogy::Relationship::Name;

    my $namer = Genealogy::Relationship::Name->new();

    my $name = $namer->name(
        steps_to_ancestor   => 2,
        steps_from_ancestor => 3,
        sex                 => 'F',
    );
    # Returns 'first cousin once-removed'

    # With language
    my $name_fr = $namer->name(
        steps_to_ancestor   => 2,
        steps_from_ancestor => 2,
        sex                 => 'M',
        language            => 'fr',
    );
    # Returns 'cousin germain'

# DESCRIPTION

`Genealogy::Relationship::Name` maps a pair of step-counts (person A to common
ancestor, common ancestor to person B) plus the sex of person B and an optional
language code to a human-readable relationship name string.

The relationship tables were originally embedded in the `gedcom` and `ged2site`
distributions inside `Gedcom::Individual::relationship_up()`; this module
extracts them into a reusable, installable CPAN distribution.

Supported languages: `en` (English, default), `de` (German), `es` (Spanish),
`fa` (Farsi/Persian), `fr` (French), `la` (Classical Latin).

# METHODS

## new

Constructor.  Creates and returns a blessed `Genealogy::Relationship::Name`
object.

### PURPOSE

Initialises the object with optional configuration: a default language for
subsequent `name()` calls, and an optional [Log::Abstraction](https://metacpan.org/pod/Log%3A%3AAbstraction) object to
use as the error logger.  Configuration may also be loaded from an INI-style
file via [Object::Configure](https://metacpan.org/pod/Object%3A%3AConfigure).

### ARGUMENTS

- `language` (string, optional)

    Default BCP-47 language tag (primary subtag only) for all `name()` calls
    on this object.  Supported values: `en` (default), `fr`, `de`.  May be
    overridden per-call by passing `language` to `name()`.

- `logger`

    A pre-constructed loggining object.  When a required argument is
    passed as `undef` to `name()`, the error is reported via
    `$logger->error($msg)` rather than `croak`.  This allows
    programs to route errors through their own
    infrastructure with full `ctx` context.

    See [Log::Abstraction](https://metacpan.org/pod/Log%3A%3AAbstraction) and the ["CONFIGURATION"](#configuration) section for the
    recommended construction pattern.

- `config_file` (string, optional)

    Path to an INI-style configuration file processed by [Object::Configure](https://metacpan.org/pod/Object%3A%3AConfigure).
    Any keys it sets may be overridden by arguments passed directly to `new()`.

### RETURNS

A blessed `Genealogy::Relationship::Name` object.

### SIDE EFFECTS

Calls [Object::Configure](https://metacpan.org/pod/Object%3A%3AConfigure) `configure()`, which may read from a
configuration file on disk if `config_file` is supplied or if a default
configuration file exists for the class.

### NOTES

[Object::Configure](https://metacpan.org/pod/Object%3A%3AConfigure) cannot handle object or coderef values (it treats
unknown scalar values as configuration file paths).  The `logger` key is
therefore stashed before the `configure()` call and restored afterward.
Any future object-valued constructor arguments must follow the same pattern.

### EXAMPLE

    use Genealogy::Relationship::Name;
    use Log::Abstraction;

    # Minimal construction
    my $namer = Genealogy::Relationship::Name->new();

    # With a default language
    my $namer_fr = Genealogy::Relationship::Name->new(language => 'fr');

    # With a Log::Abstraction logger
    my $la = Log::Abstraction->new(
        logger => sub {
            my $args = shift;
            my $msg = $args->{ctx}
                ? $args->{ctx}->as_string() . ': ' . join('', @{$args->{message}})
                : join('', @{$args->{message}});
            complain({ message => $msg, person => $args->{ctx} });
        },
        ctx => $individual,
    );
    my $namer = Genealogy::Relationship::Name->new(language => 'en', logger => $la);

### API SPECIFICATION

#### Input

    {
        language => { type => 'string', regex => qr/^(?:en|de(?:-ch)?|es|fa|fr|la)/, optional => 1 },
        logger   => { type => 'object', optional => 1 },
    }

#### Output

    {
        type  => 'object',
        class => 'Genealogy::Relationship::Name',
    }

## name

Returns the name of the relationship between person A and person B.

### PURPOSE

Given the number of steps from person A up to the nearest common ancestor
(`steps_to_ancestor`) and the number of steps from that ancestor down to
person B (`steps_from_ancestor`), plus the sex of person B and a language
code, returns a localised relationship-name string.

### ARGUMENTS

- `steps_to_ancestor` (integer, required)

    Number of generational steps from person A up to the common ancestor.
    Must be a non-negative integer.  Zero means person A _is_ the ancestor.

- `steps_from_ancestor` (integer, required)

    Number of generational steps from the common ancestor down to person B.
    Must be a non-negative integer.

- `sex` (string, required)

    Sex of person B.  Must be `'M'` (male) or `'F'` (female).

- `language` (string, optional)

    BCP-47-style language tag (only the primary subtag is used).
    Supported values: `en` (default), `de`, `es`, `fa`, `fr`, `la`.

    Note: `fa` (Farsi/Persian) values are stored as `\N{U+XXXX}` Unicode
    escapes and render correctly in any Unicode-aware context.  `la`
    (Classical Latin) has a sparse table; many step-count combinations have
    no classical term and return `undef`.

- `person` (object, optional)

    An optional person object (e.g. a `Gedcom::Individual` instance) passed
    through to the error handler when an error occurs.  Takes priority over the
    `ctx` set at construction time.  The handler receives it as `ctx` (logger
    path) or `person` (on\_error path), matching the `complain()` interface
    in `gedcom`/`ged2site`.

- `family_side` (string, optional)

    `'paternal'` or `'maternal'`.  Used by languages that distinguish the
    paternal from the maternal line for the same step counts.  Currently
    relevant for:

    - `la` (Latin) -- uncle/aunt (`patruus`/`avunculus`,
    `amita`/`matertera`) and first cousin (`patruelis`/`consobrinus`)
    - `fa` (Farsi) -- uncle (`amoo`/`dayi`) and aunt
    (`ammeh`/`khaleh`)

    When `family_side` is not supplied, the table falls back to the generic
    (non-side-specific) entry for that step-count pair.

### RETURNS

A string containing the relationship name, or `undef` if the combination
is not found in the lookup table.

### EXAMPLE

    my $namer = Genealogy::Relationship::Name->new();

    # Person A is the grandparent (2 steps up) of the common ancestor,
    # and person B is 3 steps below the ancestor; B is female => first cousin once-removed
    my $rel = $namer->name(
        steps_to_ancestor   => 2,
        steps_from_ancestor => 3,
        sex                 => 'F',
    );

### API SPECIFICATION

#### Input

    {
        steps_to_ancestor   => { type => 'integer', minimum => 0 },
        steps_from_ancestor => { type => 'integer', minimum => 0 },
        sex                 => { type => 'string', memberof => ['M', 'F'] },
        language => { type => 'string', regex => qr/^(?:en|de(?:-ch)?|es|fa|fr|la)/, optional => 1 },
        # person is handled before validate_strict (PVS infers constraints from objects)
        family_side => { type => 'string', memberof => ['paternal','maternal'], optional => 1 },
    }

#### Output

    {
        type     => 'string',
        optional => 1,     # undef when the combination is not tabulated
    }

### FORMAL SPECIFICATION

    name ______________________________________________________
    [In]  steps_to_ancestor   : N0
          steps_from_ancestor : N0
          sex                 : {M, F}
          language            : {en, es, fa, fr, de, la}?  (default en)
          person              : Object?
    [Out] result              : String | undef

    Let key      == steps_to_ancestor ++ "," ++ steps_from_ancestor
    Let side_key == key ++ "," ++ family_side  if family_side defined
    Let table    == RELATIONSHIP_TABLES(language)(sex)
    result == table(side_key)  if family_side defined and side_key in dom table
           == table(key)       if key in dom table
           == undef            otherwise

## supported\_languages

Returns a sorted list of the language codes that the module supports.

### PURPOSE

Allows calling code to enumerate the languages available for `name()`
without hard-coding them.

### ARGUMENTS

None.

### RETURNS

A list (or array-ref in scalar context) of language code strings,
currently `('de', 'de_ch', 'en', 'es', 'fa', 'fr', 'la')`.

### EXAMPLE

    my @langs = $namer->supported_languages();
    # ( 'de', 'de_ch', 'en', 'es', 'fa', 'fr', 'la' )

### API SPECIFICATION

#### Input

    {}   # no arguments

#### Output

    {
        type => ARRAYREF,   # sorted list of language codes
    }

## known\_sexes

Returns the list of sex codes accepted by `name()`.

### PURPOSE

Documents and exposes the set of valid `sex` values so that callers can
validate their own input without duplicating knowledge.

### ARGUMENTS

None.

### RETURNS

A list (or array-ref in scalar context) of valid sex code strings: `('F', 'M')`.

### SIDE EFFECTS

None.

### EXAMPLE

    my @sexes = $namer->known_sexes();
    # ( 'F', 'M' )

### API SPECIFICATION

#### Input

    {}   # no arguments

#### Output

    {
        type => ARRAYREF,
    }

# CONFIGURATION

The constructor accepts an optional `language` key which sets the default
language for all subsequent calls to `name()`:

    my $namer = Genealogy::Relationship::Name->new(language => 'fr');

This default can be overridden per-call by passing `language` to `name()`.
The object is also compatible with `Object::Configure` for runtime
reconfiguration.

## Error handling

Errors are dispatched through the following priority chain:

- 1. [Log::Abstraction](https://metacpan.org/pod/Log%3A%3AAbstraction) object (preferred)

    Construct a `Log::Abstraction` object with the desired logger coderef and
    `ctx` (typically a `Gedcom::Individual`), then pass it as `logger` to
    `new()`.  On error, this module simply calls `$logger->error($msg)`
    and Log::Abstraction handles ctx forwarding, formatting, and dispatch.

        use Log::Abstraction;

        my $logger = Log::Abstraction->new(
            logger => sub {
                my $args = shift;
                my $msg = $args->{ctx}
                    ? $args->{ctx}->as_string() . ': ' . join('', @{$args->{message}})
                    : join('', @{$args->{message}});
                complain({ message => $msg, person => $args->{ctx} });
            },
            ctx => $individual,
        );

        my $namer = Genealogy::Relationship::Name->new(logger => $logger);

If any handler returns without dying (e.g. a warning-only handler in
[Log::Abstraction](https://metacpan.org/pod/Log%3A%3AAbstraction)), `name()` returns `undef`.

# DIAGNOSTICS

- steps\_to\_ancestor not given

    `steps_to_ancestor` was passed as `undef`. Passing `undef` explicitly is
    distinct from omitting the argument; use a defined non-negative integer.

- steps\_from\_ancestor not given

    As above, for `steps_from_ancestor`.

- sex not given

    `sex` was passed as `undef`. Supply `'M'` or `'F'`.

# DEPENDENCIES

[Carp](https://metacpan.org/pod/Carp), [Object::Configure](https://metacpan.org/pod/Object%3A%3AConfigure)

Optionally [Log::Abstraction](https://metacpan.org/pod/Log%3A%3AAbstraction) (>= 0.28) for the `logger`/`ctx` error
dispatch path.
[Params::Get](https://metacpan.org/pod/Params%3A%3AGet), [Params::Validate::Strict](https://metacpan.org/pod/Params%3A%3AValidate%3A%3AStrict), [Readonly](https://metacpan.org/pod/Readonly)

# BUGS AND LIMITATIONS

The lookup tables currently cover steps 0-6 in both directions.  Relationships
further removed (seventh cousin, etc.) return `undef`.  Pull requests adding
deeper tables are welcome.

# TODO

- Extract and integrate the Latin relationship handling code currently
embedded in the `gedcom` and `ged2site` programs, adding `la` as a
supported language alongside `en`, `fr`, and `de`.

# SEE ALSO

- [Configure an Object at Runtime](https://metacpan.org/pod/Object%3A%3AConfigure)
- [Test Dashboard](https://nigelhorne.github.io/Genealogy-Relationship-Name/coverage/)
- [Gedcom::Individual](https://metacpan.org/pod/Gedcom%3A%3AIndividual), [Genealogy::Relationship](https://metacpan.org/pod/Genealogy%3A%3ARelationship), [https://www.tfcg.ca/tableau-des-liens-de-parente](https://www.tfcg.ca/tableau-des-liens-de-parente),

# AUTHOR

Nigel Horne `<njh@nigelhorne.com>`

# REPOSITORY

[https://github.com/nigelhorne/Genealogy-Relationship-Name](https://github.com/nigelhorne/Genealogy-Relationship-Name)

# SUPPORT

This module is provided as-is without any warranty.

Please report any bugs or feature requests to `bug-genealogy-relationship-name at rt.cpan.org`,
or through the web interface at
[http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Genealogy-Relationship-Name](http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Genealogy-Relationship-Name).
I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

You can find documentation for this module with the perldoc command.

    perldoc Genealogy::Relationship::Name

You can also look for information at:

- MetaCPAN

    [https://metacpan.org/dist/Genealogy-Relationship-Name](https://metacpan.org/dist/Genealogy-Relationship-Name)

- RT: CPAN's request tracker

    [https://rt.cpan.org/NoAuth/Bugs.html?Dist=Genealogy-Relationship-Name](https://rt.cpan.org/NoAuth/Bugs.html?Dist=Genealogy-Relationship-Name)

- CPAN Testers' Matrix

    [http://matrix.cpantesters.org/?dist=Genealogy-Relationship-Name](http://matrix.cpantesters.org/?dist=Genealogy-Relationship-Name)

- CPAN Testers Dependencies

    [http://deps.cpantesters.org/?module=Genealogy::Relationship::Name](http://deps.cpantesters.org/?module=Genealogy::Relationship::Name)

# FORMAL SPECIFICATION

## new

    new ________________________________________________________
    [In]  class    : String                  (class name or object)
          language            : {en, es, fa, fr, de, la}?  (optional default language
          logger   : Log::Abstraction?       (optional error logger)
    [Out] self     : Genealogy::Relationship::Name

    Let params == get_params(args)
    Let params' == configure(class, params \ {logger})
                   union {logger -> params.logger}  if logger in dom params
    self == bless(params', class)

    post: self.language == params.language  if language in dom params
          self.logger   == params.logger    if logger   in dom params
          ref(self)     == 'Genealogy::Relationship::Name'

## name

    name ______________________________________________________
    [In]  steps_to_ancestor   : N0
          steps_from_ancestor : N0
          sex                 : {M, F}
          language            : {en, fr, de}?  (default en)
          person              : Object?
    [Out] result              : String | undef

    Let key == steps_to_ancestor ++ "," ++ steps_from_ancestor
    Let table == RELATIONSHIP_TABLES(language)(sex)
    result == table(key)  if key in dom table
           == undef       otherwise

## supported\_languages

    supported_languages ______________________________________
    [In]  (none)
    [Out] result : seq String

    result == sort(dom RELATIONSHIP_TABLES)

## known\_sexes

    known_sexes ______________________________________________
    [In]  (none)
    [Out] result : seq String

    result == sort { $SEX_FEMALE, $SEX_MALE }

# LICENCE AND COPYRIGHT

Copyright 2026 Nigel Horne.

Usage is subject to the GPL2 licence terms.
If you use it,
please let me know.
