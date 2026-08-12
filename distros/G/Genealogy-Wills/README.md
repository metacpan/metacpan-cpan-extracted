# NAME

Genealogy::Wills - Search a local database of historical wills

# VERSION

Version 0.11

# DESCRIPTION

A "will" (short for "last will and testament") is a legal document in which a
person states who should receive their money and property after they die. Courts
record when a will is officially accepted (called "probate"). This module gives
you a simple way to search those records.

The data comes from the **Kent Wills Transcript**, a free online collection of
wills proved in Kent, covering roughly the 1500s through the 1900s.
That data is stored in a local SQLite file (`wills.sql`), so **no internet
connection is needed** when you run a search. The database is built once by
running `perl bin/create_db.PL`.

Each record in the database describes one will and contains:

- The person's first name, optional middle name, and last name (surname).
- The town where the person lived or died.
- The year the will was proved (officially accepted by the court).
- A URL linking to the original entry on the Kent Wills Transcript website.

Using the module is a two-step process: create one `Genealogy::Wills` object
with `new()`, then call `search()` as many times as you like.

# SYNOPSIS

    use Genealogy::Wills;

    # -------------------------------------------------------------------
    # Example 1: Find all records for a given last name.
    # -------------------------------------------------------------------
    my $wills = Genealogy::Wills->new();
    die "Could not load wills database" unless defined $wills;

    my @smiths = $wills->search(last => 'Smith');
    for my $r (@smiths) {
        printf "%s %s, %s (%d)\n  %s\n\n",
            $r->{first}, $r->{last},
            $r->{town},  $r->{year},
            $r->{url};
    }

    # -------------------------------------------------------------------
    # Example 2: Short form -- pass just the last name as a plain string.
    # -------------------------------------------------------------------
    my @joneses = $wills->search('Jones');

    # -------------------------------------------------------------------
    # Example 3: Narrow by first name, town, and year.
    # -------------------------------------------------------------------
    my @johns = $wills->search(
        first => 'John',
        last  => 'Smith',
        town  => 'Canterbury, Kent, England',
        year  => 1750,
    );

    # -------------------------------------------------------------------
    # Example 4: Scalar context -- get only the first matching record.
    # Use this when you want one result, not a list.
    # -------------------------------------------------------------------
    my $will = $wills->search(last => 'Carlton');
    if (defined $will) {
        print "First match: $will->{first} $will->{last} ($will->{year})\n";
        print "See: $will->{url}\n";
    } else {
        print "No record found.\n";
    }

    # -------------------------------------------------------------------
    # Example 5: Check whether anything was found.
    # -------------------------------------------------------------------
    my @results = $wills->search(last => 'Xyz');
    if (@results) {
        print scalar(@results), " records found.\n";
    } else {
        print "No records found.\n";
    }

    # -------------------------------------------------------------------
    # Example 6: Point at a different database directory.
    # -------------------------------------------------------------------
    my $wills2 = Genealogy::Wills->new(directory => '/var/data/wills');

    # -------------------------------------------------------------------
    # Example 7: Load settings from a config file.
    # The YAML key must use double underscores: Genealogy__Wills
    # -------------------------------------------------------------------
    # Contents of /etc/wills.yml:
    #   Genealogy__Wills:
    #     directory: /var/data/wills
    my $wills3 = Genealogy::Wills->new(config_file => '/etc/wills.yml');

    # -------------------------------------------------------------------
    # Example 8: Clone an existing object, changing one setting.
    # -------------------------------------------------------------------
    my $wills4 = $wills->new(cache_duration => '12 hours');

# SUBROUTINES/METHODS

## new

Creates and returns a `Genealogy::Wills` object.

No arguments are required. All arguments are optional and may be passed in any
of these forms:

    Genealogy::Wills->new()                        # no arguments
    Genealogy::Wills->new(key => value, ...)       # flat key-value list
    Genealogy::Wills->new({ key => value, ... })   # hash reference
    Genealogy::Wills->new('/path/to/data')         # single string = directory

**Returns** the new object on success, or `undef` on failure (for example,
if the database directory does not exist). A warning is printed to explain
what went wrong.

**Always check the return value** before calling `search()`. If `new()`
returns `undef` and you ignore it, a call to `search()` will crash your
program later with a confusing error.

    my $wills = Genealogy::Wills->new();
    die "Could not load database" unless defined $wills;

### ARGUMENTS

- `directory` (optional, string)

    The path to the directory that contains the `wills.sql` file.

    If you do not provide this, the module uses its own built-in data directory,
    which is set up when you run `perl bin/create_db.PL`.

    You can also pass a single bare string as a shortcut:

        Genealogy::Wills->new('/path/to/data')
        # is the same as
        Genealogy::Wills->new(directory => '/path/to/data')

- `config_file` (optional, string)

    Path to a configuration file in `YAML`, `XML`, `INI`, or another format
    supported by [Object::Configure](https://metacpan.org/pod/Object%3A%3AConfigure).

    The file must have a top-level section named `Genealogy__Wills` (the class
    name with `::` replaced by `__`). For example:

        # /etc/wills.yml
        Genealogy__Wills:
          directory: /var/data/wills

    Environment variables of the form `Genealogy__Wills__key` override values
    read from the file. For example, setting
    `Genealogy__Wills__directory=/tmp/wills` in the shell overrides the
    `directory` from the file.

    **Croaks** (the program stops with an error message) if you provide a
    `config_file` path that does not exist or cannot be read.

- `logger` (optional, object)

    An object used to write diagnostic messages. It must have both an `info()`
    method and an `error()` method. Any [Log::Log4perl](https://metacpan.org/pod/Log%3A%3ALog4perl) logger, or any object
    that implements those two methods, works.

    **Croaks** if an object is provided but is missing the required methods.

- `cache_duration` (optional, string)

    How long the underlying `Database::Abstraction` layer caches query results.
    Default is `'1 day'`. Accepts strings like `'12 hours'`, `'2 days'`.

### RETURNS

On success: a `Genealogy::Wills` object.

On failure: `undef`, with a warning printed to STDERR naming the problem.

### EXAMPLE

    # Minimal -- uses the bundled database
    my $w = Genealogy::Wills->new();
    die "Failed to load database" unless defined $w;

    # Explicit directory path
    my $w = Genealogy::Wills->new(directory => '/data/kent-wills');

    # Hash-reference form (same result)
    my $w = Genealogy::Wills->new({ directory => '/data/kent-wills' });

    # Single-string shortcut (treated as the directory path)
    my $w = Genealogy::Wills->new('/data/kent-wills');

    # From a YAML config file
    my $w = Genealogy::Wills->new(config_file => '/etc/wills.yml');

    # Clone an existing object, changing the cache duration
    my $w2 = $w->new(cache_duration => '12 hours');

### API SPECIFICATION

#### input

`new()` uses `Params::Get` to normalize its arguments but does not apply
`Params::Validate::Strict` validation. The recognized parameters are:

    # Params::Get::get_params(undef, @_) -- normalizes to a hashref.
    # Accepted as: flat list, hash reference, or a single string (= directory).
    {
        directory      => { type => 'string' },   # readable directory path
        config_file    => { type => 'string' },   # readable path; croaks if missing
        logger         => { type => 'object',
                            can => [ 'info', 'error' ],
                            optional => 1
                          },
        cache_duration => { type => 'string',
                            default => '1 day',
                            optional => 1
                          },
    }

#### output

    # Return::Set is not used by new().
    {
        type => 'hashref',
        optional => 1
    }

### MESSAGES

- **Can't load configuration from &lt;path>**

    Fatal. The `config_file` path was given but the file is missing or
    unreadable. Check the path and file permissions.

- **Logger must be an object with info() and error() methods**

    Fatal. The `logger` argument is not an object, or is missing `info()`
    or `error()`. Pass a compatible logger such as [Log::Log4perl](https://metacpan.org/pod/Log%3A%3ALog4perl).

- **Genealogy::Wills: &lt;dir> is not a directory**

    Warning (not fatal). The resolved directory does not exist or cannot be read.
    `new()` returns `undef`. Verify the path; if using the bundled database run
    `perl bin/create_db.PL`.

## search

Search the wills database for records that match the criteria you provide.

The last name (`last`) is the only required field. All other fields are
optional and narrow the results further. If more than one field is given, a
record must match **all** of them to be returned.

**Important -- context matters**: what you get back depends on how you call the
method:

- **List context** (`my @results = $w->search(...)`)

    Returns **all** matching records as a list of hash references. Returns an empty
    list (`()`) when nothing matches.

- **Scalar context** (`my $result = $w->search(...)`)

    Returns **one** hash reference (the first match found), or `undef` when
    nothing matches.

Each returned hash reference has these keys:

    first  -- first name (string)
    last   -- last name (string)
    middle -- middle name (string, or undef if not recorded)
    town   -- town, e.g. "Canterbury, Kent, England" (string, or undef)
    year   -- year the will was proved (integer, or undef)
    url    -- full URL to the source page, e.g. "https://freepages..."

The `url` field always starts with `https://`.

### ARGUMENTS

- `last` (required, string)

    The surname (last name, family name) to search for.

    Must be non-empty and contain only letters, digits, underscores (the `\w`
    set), and hyphens. Any other characters (including apostrophes) cause the
    call to fail validation. For example, `"O'Brien"` must be passed as
    `"OBrien"`.

    The search is **exact-match**: `"Smith"` finds only the exact string
    `"Smith"`, not `"Smithson"`.

- `first` (optional, string, 1-100 characters)

    The first name (given name) to filter by.

- `middle` (optional, string, 1-100 characters)

    The middle name to filter by.

- `town` (optional, string, 1-100 characters)

    The town to filter by. Records use the format `"Townname, Kent, England"`.
    Use the exact spelling seen in earlier results, or leave this out and
    narrow by other fields instead.

- `year` (optional, integer, 1 to current year)

    The year the will was proved. Must be a positive whole number no greater
    than the current calendar year.

You may pass arguments in three ways:

    $w->search(last => 'Smith')              # flat key-value list
    $w->search({ last => 'Smith' })          # hash reference
    $w->search('Smith')                      # bare string = last name only

### RETURNS

**List context**: a list of hash references (may be empty).

**Scalar context**: one hash reference, or `undef` if nothing matched.

Each hash reference has these keys: `first`, `last`, `middle`, `town`,
`year`, `url`.

### EXAMPLE

    my $w = Genealogy::Wills->new();

    # All records for the surname "Cowell"
    my @all = $w->search(last => 'Cowell');
    print scalar(@all), " records found.\n";

    # Bare string shortcut
    my @smiths = $w->search('Smith');

    # Multiple filters
    my @hits = $w->search(
        first => 'Stephen',
        last  => 'Carlton',
        town  => 'Ash, Kent, England',
    );

    # Scalar context: one result or undef
    my $one = $w->search(last => 'Horne');
    if (defined $one) {
        printf "%s %s (%d): %s\n",
            $one->{first}, $one->{last}, $one->{year}, $one->{url};
    }

    # url always starts with https://
    for my $r ($w->search(last => 'Smith')) {
        print $r->{url}, "\n";
    }

### API SPECIFICATION

#### input

    schema => {
        last   => { type => 'string',
                    min  => 1, max => 100,
                    matches => qr/^[\w-]+\z/a },
        first  => { type => 'string',
                    min  => 1, max => 100,
                    optional => 1 },
        middle => { type => 'string',
                    min  => 1, max => 100,
                    optional => 1 },
        town   => { type => 'string',
                min  => 1, max => 100,
                    optional => 1 },
        year   => { type => 'integer',
                    min  => 1, max => $MAX_WILL_YEAR,
                    optional => 1 },
    };

`$MAX_WILL_YEAR` is `(localtime)[5] + 1900` computed once at module load.
`Params::Get::get_params('last', ...)` maps a bare string argument to
`{ last => $string }` before validation runs.
The schema hashref itself is a module-level constant allocated once at load
time and shared across all calls; it is never modified at runtime.

#### output

    # List context -- no Return::Set wrapping
    Returns: Array of HashRef
             Each HashRef: { first  => { type => 'string',  optional => 1 },
                             last   => { type => 'string' },
                             middle => { type => 'string',  optional => 1 },
                             town   => { type => 'string',  optional => 1 },
                             year   => { type => 'integer', optional => 1 },
                             url    => { type => 'string',  matches  => qr/^https:\/\// },
                           }
             Empty list when nothing matches.

    # Scalar context -- wrapped by Return::Set
    Return::Set::set_return($will, { type => 'hashref', min => 1 });
    Returns: HashRef (same shape) | undef

### MESSAGES

- **search() must be called on an object**

    Fatal. You called `search()` as a class method
    (`Genealogy::Wills->search(...)`) instead of on an object. Create the
    object first with `new()`, then call `search()` on it.

- **Usage: search({ last => $last\_name })**

    Fatal. `search()` was called with no arguments at all.
    Always provide at least `last => $name`.

- **Value for 'last' is mandatory**

    Warning (not fatal). The `last` argument was provided but its value was
    `undef` or an empty string. `search()` returns no results in this case.
    Supply a non-empty string.

- **Can't open the wills database**

    Fatal. The internal database object could not be created. The database file
    may be missing or corrupted. Rebuild with `perl bin/create_db.PL -f`.

### PSEUDOCODE

A plain-English description of what `search()` does, step by step:

    1. If the caller is not a Genealogy::Wills object, die immediately.

    2. If no arguments were given, die immediately.

    3. Parse the arguments:
         - A single bare string becomes { last => $string }.
         - A hash reference or flat key-value list is used as-is.

    4. Validate the parsed arguments:
         - 'last' must match /^[\w-]+$/ and be 1-100 characters.
         - 'first', 'middle', 'town': optional strings, 1-100 characters each.
         - 'year': optional integer between 1 and the current year.

    5. If 'last' is undef or empty after parsing, print a warning and return
       nothing (an empty list or undef, depending on context).

    6. (Removed: sanitization was a no-op. Validation in step 4 already
       enforces [\w-] only via PVS matches => qr/^[\w-]+\z/a.)

    7. If this is the first search() call on this object, open the SQLite
       database. Reuse the existing connection on subsequent calls.

    8. If the database could not be opened, die immediately.

    9. Execute the query:
         List context:
           Fetch all matching rows.
           Prepend "https://" to the url of every row.
           Intern all strings (Data::Reuse::fixate) to save memory.
           Return the list of hashrefs.

         Scalar context:
           Fetch the first matching row.
           Prepend "https://" to its url.
           Intern all strings.
           Return the hashref (or undef if nothing matched).

# COMMON PITFALLS

This section describes the most common mistakes when using this module.
Read it before reporting a bug.

## List context vs. scalar context give different results

This is the single most important thing to understand. The same call returns
different things depending on whether you store the result in an array or a
scalar variable:

    my @all   = $wills->search(last => 'Smith');  # ALL Smiths (may be many)
    my $first = $wills->search(last => 'Smith');  # ONE Smith only

If you accidentally write `my $r = $wills->search(...)`, you get at most
one record even if hundreds matched. Use `my @results = ...` unless you
specifically want only the first match.

## new() returns undef on failure -- it does not crash

If the directory does not exist or cannot be read, `new()` prints a warning
and returns `undef`. Your program does **not** stop. If you then call
`search()` on the `undef` value, it will crash later with an unhelpful error.

Always check the return value:

    my $wills = Genealogy::Wills->new();
    die "Could not load wills database" unless defined $wills;

## No arguments is fatal; undef is only a warning

These two situations look similar but have very different consequences:

    $wills->search();               # FATAL -- program stops with an exception
    $wills->search(last => undef);  # WARNING only -- returns no results

Always provide at least `last => $name`.

## The url field already contains https://

Every returned record has its `url` field set to a full URL starting with
`https://`. Do not add the scheme prefix yourself:

    print $r->{url};               # correct: https://freepages.rootsweb.com/...
    print 'https://' . $r->{url}; # WRONG:   https://https://freepages...

## Apostrophes and punctuation are rejected in last names

The module accepts only word characters (`\w`) and hyphens in the `last`
argument. Any other character -- including apostrophes -- causes validation
to fail, not silent stripping.

    $wills->search(last => "O'Brien");  # FAILS validation; pass "OBrien"

If the record you are looking for has a name like `O'Brien`, search for
`OBrien` instead (that is how it was recorded in the database).

## Search is exact-match -- no wildcards or fuzzy matching

The query looks for an exact match on every field you provide. Partial
last names and wildcard patterns (such as `Smith*`) are not supported
through this interface.

    $wills->search(last => 'Smith');  # finds "Smith" only
    # Does NOT find "Smithson", "Blacksmith", "Goldsmith", etc.

## The config file key uses double underscores, not colons

When using a YAML (or other) config file, the section name for this class
must use two underscores in place of each `::` in the package name:

    # CORRECT
    Genealogy__Wills:
      directory: /var/data/wills

    # WRONG (causes the config to be silently ignored)
    Genealogy::Wills:
      directory: /var/data/wills

The same rule applies to environment variable overrides:
`Genealogy__Wills__directory=/tmp/wills`.

## Do not use the function-call syntax with arguments

Calling `new()` as a plain function (`::` instead of `->`) with
arguments does not work correctly. The first argument is misread as the
class name.

    Genealogy::Wills->new()            # correct -- arrow syntax
    Genealogy::Wills::new()            # tolerated -- no args, defaults to package
    Genealogy::Wills::new('/data')     # WRONG -- '/data' is misused as class name

## The year upper limit is fixed when the module loads

The maximum allowed `year` value is computed once the first time
`use Genealogy::Wills` is executed. If your process runs for a very long
time and crosses a year boundary (e.g. from 31 December to 1 January), the
cap will be stale by one year until the module is reloaded.

# LIMITATIONS

- Only data from Kent is available at the moment.
- **`::new()` with arguments is unsupported.**

    `Genealogy::Wills::new('Smith')` shifts `'Smith'` into `$class` and
    attempts to bless into it. Only the no-argument form
    `Genealogy::Wills::new()` is partially handled (it defaults to
    `__PACKAGE__`). Always use the arrow form: `Genealogy::Wills->new()`.

- **Year upper bound is capped at load time.**

    `MAX_WILL_YEAR` is computed once when the module is first loaded. In the
    unlikely event the module remains loaded across a year boundary the cap will
    be one year stale.

- **No full-text or fuzzy search.**

    Searches are exact-match on the columns provided. There is no fuzzy or
    phonetic matching (e.g. Soundex, Levenshtein distance). Wildcard support
    depends on the `Database::Abstraction` layer.

- **The `logger` argument is silently discarded.**

    `Object::Configure` always supplies its own `Log::Abstraction` logger.
    Any object passed as `logger` to `new()` is replaced before it is stored.
    See the ["SECURITY"](#security) section, Finding 3.

- **Single database source.**

    The data comes from a single scraped source (the Kent Wills Transcript). It
    does not cover wills from other counties or archives.

# SECURITY

This section documents the attack surface of the module, the controls in
place, and known open findings. It is intended for developers integrating
this module into a web application or CGI script.

## Attack surface summary

The module has two entry points: `new()` and `search()`. Neither reads
from `%ENV`, `STDIN`, or any HTTP source directly. In a CGI context,
the calling script is responsible for parsing HTTP inputs before passing
them to this module.

## Controls in place

- `last` is strictly validated

    `Params::Validate::Strict` enforces `matches => qr/^[\w-]+\z/a` on
    the `last` argument before any database call. This blocks SQL injection,
    XSS, shell metacharacters, CRLF sequences, and null bytes for that field.
    The `/a` modifier restricts `\w` to ASCII `[0-9A-Za-z_]`, blocking
    Unicode homograph queries. The `\z` anchor is strictly end-of-string,
    unlike `$` which matches before a trailing newline.

- `year` is range-validated as an integer

    `Params::Validate::Strict` enforces `type => 'integer'`, `min => 1`,
    and `max => MAX_WILL_YEAR`. Non-integer strings, floats, and
    out-of-range values are all rejected before DB access.

- Directory and config-file paths are checked before use

    `new()` verifies `-d $dir && -r _` for the data directory and `-r`
    for any `config_file`. Paths that do not pass these checks cause `new()`
    to return `undef` (with a warning) or croak immediately.

- Logger injection is blocked by Object::Configure

    `Object::Configure::configure()` always replaces the caller-supplied
    `logger` argument with its own `Log::Abstraction` object, regardless
    of what was passed. A hostile logger (missing methods, wrong type, or
    carrying malicious extra methods) is discarded before any logging call
    occurs. The module-level interface check `(blessed && can 'info' && can 'error')`
    runs against the `Object::Configure`-supplied logger, which always passes.

- No shell operations

    The module performs no `system()`, `exec()`, backtick, or
    `open(FH, "...|")` calls. Shell metacharacters in any field pose no
    command-injection risk within this module.

- Database access is parameterised

    All SQL is executed via `Database::Abstraction` (v0.37+), which uses
    DBI prepared statements. Values are bound as parameters, not interpolated
    into SQL strings.

## Known findings

- **Finding 1 (fixed): `first`, `middle`, `town` now have `matches` constraints**

    Previously these optional fields were validated for type and length only,
    allowing SQL metacharacters (`;`, `=`, `|`, `<`, `>`,
    `\r`, `\n`, `\0`) to reach the database layer verbatim.

    **Applied fix**: the schema now enforces:

        first/middle: matches => qr/^[\w '.-]+\z/
        town:         matches => qr/^[\w ',.-]+\z/

    These allow legitimate name characters (Unicode word chars, space,
    apostrophe as in `O'Brien`, period as in `St. John`, hyphen as in
    `Mary-Anne`, comma in town as in `"Canterbury, Kent, England"`) while
    blocking injection metacharacters.

    **Residual surface**: the pattern `Smith'--`, which contains only
    apostrophe and hyphens, passes the constraint. It is neutralised by
    `Database::Abstraction`'s parameterised queries - the value is bound
    as a literal string, never interpolated into SQL.

    **Primary defence**: parameterised queries (`Database::Abstraction`).
    The `matches` constraint is defence-in-depth only.

    **Test coverage**: `t/cgi_security.t`, section 10.

- **Finding 4: `Genealogy__Wills__directory` environment variable can redirect the data directory**

    `Object::Configure` reads environment variables of the form
    `Genealogy__Wills__key` and merges them into the configuration before
    `new()` applies defaults. Setting
    `Genealogy__Wills__directory=/attacker/path` in the process environment
    redirects `new()` to any SQLite file the attacker can create at that
    path, causing `search()` to return results from a malicious database.

    **Conditions required**: the attacker must control the process environment
    (`%ENV`) before `new()` is called. In a CGI context this requires
    compromising the web server's environment-variable namespace, not merely
    sending HTTP headers.

    **Mitigation**: ensure the web server or process supervisor sanitises
    `%ENV` before execution. The `-d $dir && -r _` check in `new()`
    prevents non-existent paths but does not block a readable
    attacker-controlled directory.

    **Test coverage**: none (requires process-level ENV control; mocked ENV
    in tests does not reach `Object::Configure`).

- **Finding 2 (fixed): `matches => qr/^[\w-]+\z/a` - Unicode and trailing-newline issues resolved**

    The `\w` class without `/a` matched Unicode word characters (Cyrillic,
    Greek, Hebrew, etc.), allowing a homograph query such as `"\x{0430}mith"`
    to pass validation silently (returning zero results, not an error).

    Additionally, the former `$` anchor matches before a trailing `\n`,
    meaning `"Smith\n"` would have passed the pattern.

    **Applied fix**: the schema now uses `qr/^[\w-]+\z/a`: `/a` restricts
    `\w` to ASCII `[0-9A-Za-z_]`, and `\z` anchors to the absolute
    end-of-string with no `\n` exception. The `\-` escape inside `[]`
    has also been normalised to the idiomatic unescaped `-` at the end
    of the character class.

    **Test coverage**: `t/cgi_security.t`, section 19.

- **Finding 3: caller-supplied logger is silently discarded**

    `Object::Configure` always replaces the `logger` argument with a
    `Log::Abstraction` instance. A caller who passes a custom logger (for
    example, a `Log::Log4perl` object) will find it silently ignored. The
    POD documents this parameter, but its effect is a no-op.

    **Impact**: this is a usability limitation, not a security risk.

    **Test coverage**: `t/cgi_security.t`, section 15.

# AUTHOR

Nigel Horne, `<njh at nigelhorne.com>`

# BUGS

Please report bugs at
[https://rt.cpan.org/NoAuth/Bugs.html?Dist=Genealogy-Wills](https://rt.cpan.org/NoAuth/Bugs.html?Dist=Genealogy-Wills)
or by email to `bug-Genealogy-Wills@rt.cpan.org`.

When reporting a bug, please include:

- The version of this module (run `perl -MGenealogy::Wills -e 'print $Genealogy::Wills::VERSION'`).
- The version of Perl (run `perl -V`).
- A short script that shows the problem.

# SEE ALSO

- The Kent Wills Transcript

    [https://freepages.rootsweb.com/~mrawson/genealogy/wills.html](https://freepages.rootsweb.com/~mrawson/genealogy/wills.html)

- [Database::Abstraction](https://metacpan.org/pod/Database%3A%3AAbstraction) -- the SQL layer used internally by this module.
- [Configure an Object at Runtime](https://metacpan.org/pod/Object%3A%3AConfigure)
- [Test Dashboard](https://nigelhorne.github.io/Genealogy-Wills/coverage/)
- [Return::Set](https://metacpan.org/pod/Return%3A%3ASet) -- enforces return-type contracts on `search()`.

# SUPPORT

This module is provided as-is without any warranty.

You can find documentation for this module with the perldoc command:

    perldoc Genealogy::Wills

Other resources:

- MetaCPAN

    [https://metacpan.org/release/Genealogy-Wills](https://metacpan.org/release/Genealogy-Wills)

- RT: CPAN's request tracker

    [https://rt.cpan.org/NoAuth/Bugs.html?Dist=Genealogy-Wills](https://rt.cpan.org/NoAuth/Bugs.html?Dist=Genealogy-Wills)

- CPAN Testers' Matrix

    [http://matrix.cpantesters.org/?dist=Genealogy-Wills](http://matrix.cpantesters.org/?dist=Genealogy-Wills)

- CPAN Testers Dependencies

    [http://deps.cpantesters.org/?module=Genealogy::Wills](http://deps.cpantesters.org/?module=Genealogy::Wills)

# FORMAL SPECIFICATION

System-level Z-notation for `Genealogy::Wills`. The `search()`
function's specification also appears in detail under its own section.

    -- Scalar type definitions
    NAME     == seq₁ CHAR      -- non-empty character sequence
    PATHNAME == seq₁ CHAR      -- non-empty filesystem path
    YEAR     == 1 .. MaxYear   -- positive integer up to the current year

    -- The database object created by new()
    WillsDatabase
      directory      : PATHNAME
      cache_duration : seq CHAR
      records        : ℙ WillRecord

    -- Successful construction invariant
    ┌ InitWillsDatabase ─────────────────────────────────┐
    │ WillsDatabase                                       │
    │ ──────────────────────────────────────────────────  │
    │ ∃ d : PATHNAME • directory = d ∧ is_readable(d)    │
    │ cache_duration = "1 day"                            │
    │ records = load_sqlite(directory ++ "/wills.sql")    │
    └─────────────────────────────────────────────────────┘

## search

The following Z-notation gives the precise mathematical meaning of `search()`.
Optional fields that the caller did not supply are modelled as undefined.

    -- Type aliases
    NAME == seq₁ CHAR       -- a non-empty sequence of characters
    YEAR == 1 .. MaxYear    -- positive integer bounded by current year

    -- One record stored in the database
    WillRecord
      first  : NAME
      last   : NAME
      middle : NAME | undefined
      town   : NAME | undefined
      year   : YEAR | undefined
      url    : NAME           -- stored without "https://"; prefixed by search()

    -- Parameters passed to search()
    SearchParams
      last   : NAME
      first  : NAME | undefined
      middle : NAME | undefined
      town   : NAME | undefined
      year   : YEAR | undefined

    -- Invariant: last name must be non-empty
    ┌ SearchParams ──────────────────┐
    │ last : NAME                    │
    │ ─────────────────────────────  │
    │ last ≠ ⟨⟩                      │
    └────────────────────────────────┘

    -- Predicate: does record r satisfy all supplied parameters?
    matches : WillRecord × SearchParams → BOOL
    matches(r, p) ==
        r.last = p.last
        ∧  (p.first  = undefined  ∨  r.first  = p.first)
        ∧  (p.middle = undefined  ∨  r.middle = p.middle)
        ∧  (p.town   = undefined  ∨  r.town   = p.town)
        ∧  (p.year   = undefined  ∨  r.year   = p.year)

    -- Function signature
    search : WillsDatabase × SearchParams → ℙ WillRecord

    -- When last is non-empty, return all records that match
    ∀ db : WillsDatabase; p : SearchParams •
        p.last ≠ ⟨⟩  ⟹
            search(db, p) = { r : WillRecord | r ∈ db.records ∧ matches(r, p) }

    -- When last is empty, return nothing
    ∀ db : WillsDatabase; p : SearchParams •
        p.last = ⟨⟩  ⟹
            search(db, p) = ∅

# LICENSE AND COPYRIGHT

Copyright 2023-2026 Nigel Horne.

Usage is subject to the GPL2 licence terms.
If you use it, please let me know.
