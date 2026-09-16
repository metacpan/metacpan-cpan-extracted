Genealogy::Obituary::Lookup
===========================

[![Appveyor status](https://ci.appveyor.com/api/projects/status/w2kcdehjtofvt55t?svg=true)](https://ci.appveyor.com/project/nigelhorne/Genealogy-Obituary-Lookup)
[![CPAN](https://img.shields.io/cpan/v/Genealogy-Obituary-Lookup.svg)](http://search.cpan.org/~nhorne/Genealogy-Obituary-Lookup/)
![GitHub Workflow Status](https://img.shields.io/github/actions/workflow/status/nigelhorne/genealogy-obituarydailytimes/test.yml?branch=master)
[![Kritika Analysis Status](https://kritika.io/users/nigelhorne/repos/7086407966497872/heads/master/status.svg)](https://kritika.io/users/nigelhorne/repos/7086407966497872/heads/master/)
[![Kwalitee](https://cpants.cpanauthors.org/dist/Genealogy-Obituary-Lookup.png)](http://cpants.cpanauthors.org/dist/Genealogy-Obituary-Lookup)
[![Travis Status](https://www.travis-ci.com/nigelhorne/Genealogy-Obituary-Lookup.svg?branch=master)](https://www.travis-ci.com/nigelhorne/Genealogy-Obituary-Lookup)
[![Tweet](https://img.shields.io/twitter/url/http/shields.io.svg?style=social)](https://twitter.com/intent/tweet?text=Look+up+an+obituary+#perl+#gedcom+#genealogy&url=https://github.com/nigelhorne/Genealogy-Obituary-Lookup&via=nigelhorne)

# NAME

Genealogy::Obituary::Lookup - Lookup an obituary in the ODT/Rootsweb/funeral-notices database

# VERSION

Version 0.21

# SYNOPSIS

    use Genealogy::Obituary::Lookup;

    # --- 1. Basic search: list context, all matching records ---
    my $obits  = Genealogy::Obituary::Lookup->new();
    my @smiths = $obits->search(last => 'Smith');
    foreach my $r (@smiths) {
        printf "%s %s -- %s\n",
            $r->{first} // '?', $r->{last}, $r->{url};
    }

    # --- 2. Scalar context: first matching record only ---
    my $hit = $obits->search({ first => 'Eric', last => 'Baal' });
    print $hit->{url}, "\n" if $hit;

    # --- 3. Narrow a search with optional first, middle, and age ---
    my @results = $obits->search(
        first  => 'Jean',
        middle => 'Emily',
        last   => 'McCarthy',
    );

    # --- 4. Clone an object to use a different data directory ---
    my $prod = Genealogy::Obituary::Lookup->new(directory => '/data/obits');
    my $test = $prod->new(directory => 't/data');   # clone with override
    my @test_hits = $test->search(last => 'Jones');

    # --- 5. Attach a structured logger ---
    use Log::Log4perl qw(:easy);
    Log::Log4perl->easy_init($DEBUG);
    my $logged = Genealogy::Obituary::Lookup->new(
        logger => Log::Log4perl->get_logger(),
    );
    my @hits = $logged->search(last => 'Brown');

# SUBROUTINES/METHODS

## new

Creates a [Genealogy::Obituary::Lookup](https://metacpan.org/pod/Genealogy%3A%3AObituary%3A%3ALookup) object.

    my $obits = Genealogy::Obituary::Lookup->new();
    my $clone  = $obits->new();                        # clone with no extra args

Accepts the following optional arguments:

- `cache` - passed to [Database::Abstraction](https://metacpan.org/pod/Database%3A%3AAbstraction)
- `config_file` - path to a YAML/XML/INI configuration file whose keys
are merged into the constructor arguments at runtime, allowing deployment-time
override without code changes.
- `directory` - directory that contains `obituaries.sql`.  If a single
non-reference argument is passed to `new()`, it is taken as `directory`.
- `logger` - object with `info()`, `warn()` and `error()` methods (e.g.
[Log::Log4perl](https://metacpan.org/pod/Log%3A%3ALog4perl), [Log::Any](https://metacpan.org/pod/Log%3A%3AAny)).  All three are required: `warn()` is used for
non-fatal directory diagnostics; `error()` for fatal DB errors.

### EXAMPLE

    # Default: discovers data/ relative to the installed module file
    my $default = Genealogy::Obituary::Lookup->new();

    # Explicit directory (useful during development)
    my $dev = Genealogy::Obituary::Lookup->new(directory => 't/data');

    # With structured logging
    use Log::Log4perl qw(:easy);
    Log::Log4perl->easy_init($DEBUG);
    my $logged = Genealogy::Obituary::Lookup->new(logger => Log::Log4perl->get_logger());

### API SPECIFICATION

#### INPUT

    {
      'directory'   => { type => 'string', optional => 1 },
      'cache'       => { type => 'any',    optional => 1 },
      'config_file' => { type => 'string', optional => 1 },
      'logger'      => {
          type => 'object',
          optional => 1,
          can => [ 'info', 'error' ]
      }
    }

#### DOMAIN — directory

    Valid partitions
      EP-V  Absent / undef        Auto-discovers data/ relative to module file.
      EP-V  Existing readable dir Accepted; stored in $self->{directory}.

    Invalid partitions (all carp + return undef)
      EP-I  Non-existent path     Carps "not a directory".
      EP-I  Existing plain file   Carps "not a directory".
      EP-I  Unreadable directory  Carps "not a directory".
      EP-I  Empty string ""       Carps "not a directory" (-d "" is false).
      EP-I  Path with null byte   Rejected before -d (prevents "Embedded nulls" fatal).

#### DOMAIN — logger

    Valid partition
      EP-V  Blessed object with can('info') && can('warn') && can('error')   Accepted.
            Additional methods beyond these three are fine.

    Method roles
      info()  Informational messages (progress, cache hits).  Non-fatal.
      warn()  Non-fatal diagnostics: bad directory, null byte in path.
              Called instead of error() so that new() can carp+return undef
              rather than die.  Log::Abstraction::error() calls die(); using
              it here would violate the graceful-return contract.
      error() Fatal-severity events from search() when the DB cannot be opened.

    Invalid partitions (all croak err_bad_logger)
      EP-I  String                Not an object.
      EP-I  Number                Not an object.
      EP-I  Unblessed hashref     Not blessed.
      EP-I  Coderef               Not blessed.
      EP-I  Object missing info() Incomplete interface.
      EP-I  Object missing warn() Incomplete interface.
      EP-I  Object missing error() Incomplete interface.

#### DOMAIN — invocation style

    Valid
      EP-V  Pkg->new(...)          Class method — normal invocation.
      EP-V  $obj->new(...)         Object method — clone with optional overrides.
      EP-V  Pkg->new('/path')      Single bare string — treated as directory.
      EP-V  Pkg->new({key=>val})   Hashref argument.
      EP-V  Pkg::new()             No-arg bare call — tolerated silently.

    Invalid
      EP-I  Pkg::new(undef, args)  Croak warn_bad_usage (undef class + args detected).

#### OUTPUT

    On success:  blessed Genealogy::Obituary::Lookup hashref
    On failure:  undef  (carp explains why)

### MESSAGES

    warn_not_dir   - <class>: <dir> is not a directory.
                     Resolution: pass a valid, readable directory.
    warn_bad_usage - use ->new() not ::new() when passing arguments.
                     Resolution: call as a class method.
    err_bad_logger - Logger must have info(), warn() and error() methods.
                     Resolution: wrap your logger in an adapter.

### PSEUDOCODE

    1. Parse arguments: accept hashref, key=>value list, or single bare string
       (treated as directory).
    2. If called as a function (::new) with no args, tolerate and self-correct;
       croak if args were given - the invocation is ambiguous.
    3. If $class is already a blessed object, clone it: merge new args into a
       copy of the existing hash and bless into the same class.
    4. Validate the logger object if provided (must have info() and error()).
    5. Merge config-file settings via Object::Configure.
    6. Resolve the data directory: explicit arg > module-relative default.
    7. For a plain-string directory: (a) reject null bytes immediately
       (logger->warn + carp + return undef); (b) untaint via regex — the
       capture is guaranteed to succeed because null bytes were just excluded.
    8. Carp and call logger->warn if the directory is missing or unreadable;
       return undef.
    9. Bless and return with cache_duration defaulted (overridable by caller).

## search

Searches the obituary database.

    # List context: all matching records
    my @smiths = $obits->search(last => 'Smith');
    print $smiths[0]->{'url'}, "\n";

    # Scalar context: first matching record, or undef
    my $entry = $obits->search({ first => 'John', last => 'Smith' });

The returned hashrefs always include a `url` key pointing to the source archive.

- `List context` - array of hashrefs, empty on no match.
- `Scalar context` - single hashref, or `undef` on no match.

### EXAMPLE

    my @results = $obits->search(last => 'O-Brien');
    foreach my $r (@results) {
        printf "%s %s, age %s - %s\n",
            $r->{first} // '?', $r->{last},
            $r->{age}   // 'unknown',
            $r->{url};
    }

    # With optional filters
    my $hit = $obits->search(first => 'John', middle => 'W', last => 'Coppage');

### API SPECIFICATION

#### INPUT

    {
      'last' => {
        type    => 'string',
        min     => 1,
        max     => 100,
        matches => qr/\A[\w-]+\z/     # hyphens allowed; \z rejects trailing newlines
      },
      'first' => {
        type     => 'string',
        optional => 1,
        min      => 1,
        max      => 100
      },
      'middle' => {
        type     => 'string',
        optional => 1,
        min      => 1,
        max      => 100
      },
      'age' => {
        type     => 'integer',
        optional => 1,
        min      => 0,
        max      => 120
      }
    }

#### DOMAIN — last (required)

    Boundary values
      BVA MIN-1  ""          (0 chars)   INVALID — croak err_no_last
      BVA MIN    "A"         (1 char)    valid
      BVA MAX    "A"x100     (100 chars) valid
      BVA MAX+1  "A"x101     (101 chars) INVALID — croak (schema max exceeded)

    Equivalence partitions
      EP-V  "Smith"           Typical ASCII surname.
      EP-V  "Smith-Jones"     Hyphen is allowed (in [\w-]).
      EP-V  "Mc_Arthur"       Underscore is \w.
      EP-V  "Smith2"          Digit is \w.
      EP-I  undef             Croak err_no_last.
      EP-I  "O'Brien"         Apostrophe not in [\w\-] — rejected.
      EP-I  "van Berg"        Space not in [\w\-] — rejected.
      EP-I  "Smith; DROP ..." SQL injection metacharacters rejected.

    Character-domain (format partition)
      FMT   German umlauts (u-umlaut, sharp-s)
                              Matched by \w only when string has the UTF-8 flag
                              AND the calling program uses "use utf8" (or the
                              runtime locale enables Unicode semantics).  Without
                              those, the same characters are rejected.  No crash
                              either way; behaviour depends on runtime locale.
      FMT   Accented Latin (e.g. e-acute, n-tilde)
                              Same as German umlauts — locale-dependent.
      FMT   Emoji             Not \w under any locale — always rejected.
      FMT   Zalgo combining marks  Not \w — always rejected.
      FMT   RTL-override (U+202E)  Not \w — always rejected.
      FMT   Full-width ASCII (e.g. U+FF33)  Not \w — rejected.

    Encoding note
      The field value is stored and searched as received; the module does not
      normalize Unicode (NFC/NFD) or transliterate diacritics.  Ensure the caller
      and the database were built with the same normalization if non-ASCII
      surnames are used.

#### DOMAIN — first / middle (optional)

    Boundary values
      BVA MIN-1  ""       (0 chars)   INVALID — croak (schema min exceeded)
      BVA MIN    "J"      (1 char)    valid
      BVA MAX    "J"x100  (100 chars) valid
      BVA MAX+1  "J"x101  (101 chars) INVALID

    Equivalence partitions
      EP-V  Absent                   Valid — field is optional.
      EP-V  "John"                   Typical value.
      EP-V  "O'Malley"               No format constraint on first/middle.
      EP-I  ""  (empty string)       INVALID (min=1).

    Character-domain (format partition)
      FMT   ASCII text               Always accepted within length limits.
      FMT   Non-ASCII / UTF-8        Accepted — no regex constraint on first/middle.
                                     Diacritics, accented letters, and multibyte
                                     sequences are passed through unchanged.
      FMT   Emoji                    Accepted syntactically; matched literally in
                                     SQL LIKE comparisons (no normalization).
      FMT   Zalgo / RTL overrides    Accepted syntactically; may produce unexpected
                                     SQL matches or rendering artifacts.

    Encoding note
      first and middle are the safest fields for non-ASCII input: no regex
      validation is applied and UTF-8 strings are stored and searched as-is.
      Length is measured in Perl characters, not bytes; a 4-byte emoji counts
      as 1 character toward the 100-character limit.

#### DOMAIN — age (optional integer)

    Boundary values
      BVA MIN-1  -1    INVALID — croak (schema min=0 exceeded)
      BVA MIN     0    valid (newborn)
      BVA MAX   120    valid (maximum recorded human lifespan)
      BVA MAX+1 121    INVALID — croak (schema max exceeded)

    Equivalence partitions
      EP-V  65           Typical adult age.
      EP-V  Absent       Valid — field is optional.
      EP-I  -1           Below minimum.
      EP-I  121          Above maximum.
      EP-I  1.5          Non-integer float — rejected (type=integer).
      EP-I  "old"        Non-numeric string — rejected.

#### DOMAIN — invocation style

    EP-V  $obj->search(...)         Normal object-method call.
    EP-I  Pkg->search(...)          Croak err_no_self (class is not blessed).
    EP-I  Pkg::search(...)          Croak err_no_self.
    EP-I  $obj->search()            Croak err_no_args (zero args).

#### CONTEXT DOMAIN

    List context   Returns list of hashrefs; empty list on no match.
    Scalar context Returns single hashref (first match) or undef.
    Void context   No crash; result silently discarded.

#### OUTPUT

    Argument error:     croak
    No match (list):    ()
    No match (scalar):  undef
    Match (list):       ( HashRef, ... )   each has a 'url' key
    Match (scalar):     HashRef            has a 'url' key

### MESSAGES

    err_no_self       - search() must be called on an object (->search, not ::search).
    err_no_last       - Value for 'last' is mandatory and must be non-empty.
    err_no_obituaries - Cannot open the obituaries database; check directory path.
    (from _create_url) err_bad_source, err_no_page, err_no_source, err_no_newspaper.

### PSEUDOCODE

    1. Croak unless $self is a blessed object.
    2. Parse args with Params::Get; validate schema with Params::Validate::Strict.
    3. Explicitly croak if 'last' is undef or empty - Params::Validate::Strict
       passes undef through for defined-but-required fields.
    4. Lazily open the obituaries DB handle (once per object lifetime).
    5. Croak if the DB handle could not be initialised.
    6. List context: fetchall, attach URL, fixate string values, return list.
    7. Scalar context: fetchone, attach URL, fixate string values, return hashref.
    8. Return undef / empty list when no rows match.

# COMMON PITFALLS

## Apostrophes are rejected in last names

The `last` field is validated against `qr/\A[\w-]+\z/`.  This allows letters,
digits, underscores, and hyphens, but **not** apostrophes.  A search for
`last => "O'Brien"` will croak at validation time.  Use the closest
hyphenated or unhyphenated spelling:

    $obits->search(last => 'OBrien');   # OK
    $obits->search(last => "O'Brien");  # CROAKS

## new() returns undef on a bad directory; it does not croak

When `directory` is supplied but does not exist or is not readable, `new()`
calls `Carp::carp` (a warning, not a fatal error) and returns `undef`.
Always check the return value before calling `search()`:

    my $obits = Genealogy::Obituary::Lookup->new(directory => $path)
        or die "Could not open obituary database at $path";

## Scalar vs list context returns different things

`search()` is context-sensitive.  In list context it returns every matching
record.  In scalar context it returns only the first match.  Assigning to a
plain variable is scalar context; assigning to an array is list context:

    my @all   = $obits->search(last => 'Smith');   # all records (list context)
    my $first = $obits->search(last => 'Smith');   # one record  (scalar context)

## Clone semantics: the database handle is shared

Calling `$obj->new(...)` creates a _shallow copy_ of the parent.  If the
parent has already run a search (and therefore opened its `obituaries` handle),
the clone starts out sharing that same handle object.  The clone replaces the
handle on its first search call, but until then both objects reference the same
underlying driver.  This is intentional and efficient; be aware of it if you
pass handles between threads or processes.

## Search results are interned and become read-only

After `search()` returns, all string values inside the result hashrefs are
interned by `Data::Reuse::fixate`.  Any attempt to modify them in place will
die with `"Modification of a read-only value"`:

    my @hits = $obits->search(last => 'Smith');
    $hits[0]->{last} = 'Jones';   # DIES -- read-only after search()

Copy the hashref or the field before modifying it:

    my %copy = %{ $hits[0] };
    $copy{last} = 'Jones';        # OK

## Logger must implement info(), warn(), and error()

`new()` validates the logger before storing it.  The object must be blessed and
must implement **all three** of `info()`, `warn()`, and `error()`.  An object
missing any one of them will cause `new()` to croak immediately:

    # CROAKS: object provides info() and error() but not warn()
    my $obits = Genealogy::Obituary::Lookup->new(logger => $partial_logger);

`warn()` is required because `new()` uses it (not `error()`) to report
non-fatal events such as a missing or unreadable directory.  Using `error()`
for those events would cause loggers whose `error()` calls `die` (such as
[Log::Abstraction](https://metacpan.org/pod/Log%3A%3AAbstraction)) to convert a graceful `carp + return undef` into a fatal
exception, breaking the documented API contract.

## Non-ASCII characters in last depend on runtime locale

The `[\w\-]+` regex matches `\w`, which includes non-ASCII word characters
(accented letters, umlauts) when the string has the UTF-8 flag and the calling
code uses `use utf8`.  Without that, the same input is rejected.  The module
does not set any locale; test explicitly if your data contains diacritics.

# SECURITY NOTES

## Null bytes in directory paths are rejected early

A `directory` string containing a null byte (`\0`) would cause Perl's
`stat()` to throw a fatal `"Embedded nulls are forbidden"` exception.
`new()` detects this before the filesystem call, calls the logger's `warn()`
method if a logger is present, and carps gracefully instead of dying.

## Taint-mode readiness

The `directory` argument is passed through a `m/\A([^\0]*)\z/` capture before
any filesystem operator sees it.  This untaints the value for callers running
under Perl's taint mode (`perl -T`) without requiring any extra configuration.

## URL construction uses percent-encoding

The database builder (`bin/create_db.PL`) encodes user-controlled components
via `URI::Escape::uri_escape` before embedding them in HTTP URLs.  This
prevents surname values from being misinterpreted as URL structure.

## Path traversal is prevented in the database builder

Environment variables `MLARCHIVEDIR` and `MLARCHIVE_DIR` are canonicalized
with `File::Spec->canonpath()` and then checked to confirm the resolved
path starts with the declared base directory.  Any path that escapes the base
via `../` components is rejected with `croak`.

## i18n substitution uses no eval

The `_i18n()` helper pre-builds a substitution table from template
placeholders and then applies a plain `s///g` replacement.  No `/e` modifier
or string `eval` is used, so template values cannot execute arbitrary code.

# LIMITATIONS

- **Ancestry / Rootsweb archive loss.**
Only the first 18 pages of the mlarchives index are preserved on the Wayback
Machine.  Approximately 10,000+ records from later pages are unrecoverable.
- **No full-text search.**
Searches are keyed on structured fields (last, first, middle, age).  There is
no free-text obituary content to search.
- **i18n is English-only.**
The `%MESSAGES` map supports placeholder interpolation but is not backed by a
locale-selection mechanism.  A future release should route through
[Locale::Maketext](https://metacpan.org/pod/Locale%3A%3AMaketext) or [Locale::Simple](https://metacpan.org/pod/Locale%3A%3ASimple).
- **Data::Reuse fixate semantics.**
The string-interning via `Data::Reuse::fixate` on hash-slice aliases is
correct in theory (hash slices are lvalues) but depends on
`String::Intern::Internalize` modifying @\_ in place.  Verify with your
installed version if memory consumption is a concern.
- **Private method enforcement without Sub::Private.**
`_create_url` and `_i18n` enforce privacy via an inline `caller` check.
Install [Sub::Private](https://metacpan.org/pod/Sub%3A%3APrivate) and replace the checks for a compile-time guarantee.
- **Single-row scalar context.**
In scalar context, `search()` returns the first row from the underlying
driver.  Row order depends on [Database::Abstraction](https://metacpan.org/pod/Database%3A%3AAbstraction) and SQLite's query
plan; add an explicit ORDER BY in the driver subclass if deterministic ordering
is required.

# AUTHOR

Nigel Horne, `<njh at nigelhorne.com>`

# BUGS

See [https://rt.cpan.org/NoAuth/Bugs.html?Dist=Genealogy-Obituary-Lookup](https://rt.cpan.org/NoAuth/Bugs.html?Dist=Genealogy-Obituary-Lookup).

# SEE ALSO

[Database::Abstraction](https://metacpan.org/pod/Database%3A%3AAbstraction)

- The Obituary Daily Times: [https://sites.rootsweb.com/~obituary/](https://sites.rootsweb.com/~obituary/)
- Archived Rootsweb data: [https://wayback.archive-it.org/20669/20231102044925/https://mlarchives.rootsweb.com/listindexes/emails?listname=gen-obit](https://wayback.archive-it.org/20669/20231102044925/https://mlarchives.rootsweb.com/listindexes/emails?listname=gen-obit)
- Recent data: [https://www.freelists.org/list/obitdailytimes](https://www.freelists.org/list/obitdailytimes)
- [Configure an Object at Runtime](https://metacpan.org/pod/Object%3A%3AConfigure)
- [Test Dashboard](https://nigelhorne.github.io/Genealogy-Obituary-Lookup/coverage/)

# SUPPORT

This module is provided as-is without any warranty.

    perldoc Genealogy::Obituary::Lookup

- MetaCPAN: [https://metacpan.org/release/Genealogy-Obituary-Lookup](https://metacpan.org/release/Genealogy-Obituary-Lookup)
- RT: [https://rt.cpan.org/NoAuth/Bugs.html?Dist=Genealogy-Obituary-Lookup](https://rt.cpan.org/NoAuth/Bugs.html?Dist=Genealogy-Obituary-Lookup)
- CPAN Testers' Matrix: [http://matrix.cpantesters.org/?dist=Genealogy-Obituary-Lookup](http://matrix.cpantesters.org/?dist=Genealogy-Obituary-Lookup)

# FORMAL SPECIFICATION

## new

    𝒏𝒆𝒘 : Class × Args → (Object ∪ {⊥})

    𝒏𝒆𝒘(C, A) ≙
      let D = A.directory ∨ dir_cache(C)        { dir_cache memoises module_data_path(C) }
      in  A.logger ≠ ∅ ∧ ¬(can(A.logger,'info') ∧
                            can(A.logger,'error'))               ⟹ abort
        ∥  is_string(D) ∧ null_byte(D)                          ⟹ ⊥
        ∥  is_string(D) ⟹ D ← untaint(D)          { guaranteed: no null bytes }
        ∥  ¬readable(D)                                         ⟹ ⊥
        ∥  otherwise   ⟹ ⟨ cache_duration ↦ DEFAULT_CACHE_DURATION ⟩ ⊕ A

    where  dir_cache(C) ≙ state map C ↦ module_data_path(C)    { per-class, per-process }

## search

    𝒔𝒆𝒂𝒓𝒄𝒉 : Object × Params → ([Obit] ∪ Obit ∪ {undef})

    𝒔𝒆𝒂𝒓𝒄𝒉(self, P) ≙
      pre  blessed(self) ∧ P.last ≠ ∅
      post wantarray ⟹ { o : Obit | match(self.db, P) } |> map(add_url)
                else ⟹ head({ o : Obit | match(self.db, P) } |> map(add_url))

    where  add_url(o) ≙ o ⊕ ⟨ url ↦ _create_url(o) ⟩

# LICENSE AND COPYRIGHT

Copyright 2020-2026 Nigel Horne.

Usage is subject to the GPL2 licence terms.
If you use it,
please let me know.
