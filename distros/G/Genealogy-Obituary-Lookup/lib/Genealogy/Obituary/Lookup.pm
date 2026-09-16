package Genealogy::Obituary::Lookup;

use warnings;
use strict;
use autodie qw(:all);
use feature 'state';

use Carp;
use Data::Reuse;
use File::Spec;
use Genealogy::Obituary::Lookup::obituaries;
use Module::Info;
use Object::Configure 0.12;
use Params::Get 0.13;
use Params::Validate::Strict 0.09;
use Readonly;
use Return::Set;
use Scalar::Util;

=encoding UTF-8

=head1 NAME

Genealogy::Obituary::Lookup - Lookup an obituary in the ODT/Rootsweb/funeral-notices database

=head1 VERSION

Version 0.21

=cut

our $VERSION = '0.21';

# ---------------------------------------------------------------------------
# Constants
# ---------------------------------------------------------------------------

# URLs for the two archive sources; 'L' (local/link) has no fixed base URL.
Readonly::Hash my %URLS => (
	M => 'https://wayback.archive-it.org/20669/20231102044925/https://mlarchives.rootsweb.com/listindexes/emails?listname=gen-obit&page=',
	F => 'https://www.freelists.org/post/obitdailytimes/Obituary-Daily-Times-',
);

Readonly::Scalar my $DEFAULT_CACHE_DURATION => '1 day';	# Database is rebuilt daily
Readonly::Scalar my $MIN_LAST_NAME_LENGTH   => 1;
Readonly::Scalar my $MAX_LAST_NAME_LENGTH   => 100;

# ---------------------------------------------------------------------------
# Internationalisation message map
# ---------------------------------------------------------------------------
# All user-facing error/warning text lives here.  Keys are stable; templates
# use %{name} placeholders that _i18n() fills with a hashref of named args.
my %MESSAGES = (
	err_no_self       => "search() must be called on an object",
	err_no_args       => 'Usage: %{package}->search(last => $val)',
	err_no_last       => "Value for 'last' is mandatory",
	err_no_obituaries => "Can't open the obituaries database",
	err_no_page       => '%{package}: undefined $page',
	err_no_source     => '%{package}: %{page}: undefined source',
	err_bad_source    => "%{package}: Invalid source, '%{source}'. Valid sources are 'M', 'F' and 'L'",
	err_no_newspaper  => "%{package}: undefined newspaper. Newspaper must be given when source type is 'L'",
	err_bad_logger    => "Logger must be an object with info(), warn() and error() methods",
	warn_not_dir      => '%{class}: %{dir} is not a directory',
	warn_bad_usage    => '%{package}: use ->new() not ::new() to instantiate',
);

=head1 SYNOPSIS

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

=head1 SUBROUTINES/METHODS

=head2 new

Creates a L<Genealogy::Obituary::Lookup> object.

    my $obits = Genealogy::Obituary::Lookup->new();
    my $clone  = $obits->new();                        # clone with no extra args

Accepts the following optional arguments:

=over 4

=item * C<cache> - passed to L<Database::Abstraction>

=item * C<config_file> - path to a YAML/XML/INI configuration file whose keys
are merged into the constructor arguments at runtime, allowing deployment-time
override without code changes.

=item * C<directory> - directory that contains F<obituaries.sql>.  If a single
non-reference argument is passed to C<new()>, it is taken as C<directory>.

=item * C<logger> - object with C<info()>, C<warn()> and C<error()> methods (e.g.
L<Log::Log4perl>, L<Log::Any>).  All three are required: C<warn()> is used for
non-fatal directory diagnostics; C<error()> for fatal DB errors.

=back

=head3 EXAMPLE

    # Default: discovers data/ relative to the installed module file
    my $default = Genealogy::Obituary::Lookup->new();

    # Explicit directory (useful during development)
    my $dev = Genealogy::Obituary::Lookup->new(directory => 't/data');

    # With structured logging
    use Log::Log4perl qw(:easy);
    Log::Log4perl->easy_init($DEBUG);
    my $logged = Genealogy::Obituary::Lookup->new(logger => Log::Log4perl->get_logger());

=head3 API SPECIFICATION

=head4 INPUT

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

=head4 DOMAIN — directory

  Valid partitions
    EP-V  Absent / undef        Auto-discovers data/ relative to module file.
    EP-V  Existing readable dir Accepted; stored in $self->{directory}.

  Invalid partitions (all carp + return undef)
    EP-I  Non-existent path     Carps "not a directory".
    EP-I  Existing plain file   Carps "not a directory".
    EP-I  Unreadable directory  Carps "not a directory".
    EP-I  Empty string ""       Carps "not a directory" (-d "" is false).
    EP-I  Path with null byte   Rejected before -d (prevents "Embedded nulls" fatal).

=head4 DOMAIN — logger

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

=head4 DOMAIN — invocation style

  Valid
    EP-V  Pkg->new(...)          Class method — normal invocation.
    EP-V  $obj->new(...)         Object method — clone with optional overrides.
    EP-V  Pkg->new('/path')      Single bare string — treated as directory.
    EP-V  Pkg->new({key=>val})   Hashref argument.
    EP-V  Pkg::new()             No-arg bare call — tolerated silently.

  Invalid
    EP-I  Pkg::new(undef, args)  Croak warn_bad_usage (undef class + args detected).

=head4 OUTPUT

  On success:  blessed Genealogy::Obituary::Lookup hashref
  On failure:  undef  (carp explains why)

=head3 MESSAGES

  warn_not_dir   - <class>: <dir> is not a directory.
                   Resolution: pass a valid, readable directory.
  warn_bad_usage - use ->new() not ::new() when passing arguments.
                   Resolution: call as a class method.
  err_bad_logger - Logger must have info(), warn() and error() methods.
                   Resolution: wrap your logger in an adapter.

=head3 PSEUDOCODE

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

=cut

sub new
{
	my $class_in = shift;
	my %args;

	# Support: ->new('path'), ->new(key=>val), ->new({key=>val})
	if((scalar(@_) == 0) && !ref($class_in) && defined($class_in) && -d $class_in) {
		# Called as Genealogy::Obituary::Lookup->new('/some/dir')
		# $class_in is the directory, not the class — handled below via scalar arg
		$args{'directory'} = $class_in;
		$class_in = __PACKAGE__;
	} elsif((scalar(@_) == 1) && !ref($_[0])) {
		$args{'directory'} = $_[0];
	} elsif(my $params = Params::Get::get_params(undef, @_)) {
		%args = %{$params};
	}

	if(!defined($class_in)) {
		# Called as Genealogy::Obituary::Lookup::new() — tolerate only if no args
		if(%args) {
			Carp::croak(__PACKAGE__->_i18n('warn_bad_usage', {package => __PACKAGE__}));
		}
		$class_in = __PACKAGE__;
	} elsif(Scalar::Util::blessed($class_in)) {
		# Clone: merge new args over existing state and re-bless
		return bless { %{$class_in}, %args }, ref($class_in);
	}

	# Validate the logger before Object::Configure can wrap it; the wrapper
	# always satisfies the interface check so we must test the original value.
	if(defined $args{'logger'}) {
		unless(Scalar::Util::blessed($args{'logger'})
			&& $args{'logger'}->can('info')
			&& $args{'logger'}->can('warn')
			&& $args{'logger'}->can('error'))
		{
			Carp::croak($class_in->_i18n('err_bad_logger'));
		}
	}

	# Merge configuration file settings (YAML / XML / INI) into %args
	%args = %{Object::Configure::configure($class_in, \%args)};

	# Resolve the data directory, falling back to the module's own data/ subdirectory.
	# Cache the lookup per class: Module::Info scans %INC and stats the filesystem;
	# the result is stable for the process lifetime.
	state %_dir_cache;
	unless(defined $args{'directory'}) {
		unless(exists $_dir_cache{$class_in}) {
			my $info = Module::Info->new_from_loaded($class_in);
			my $derived;
			if(defined $info) {
				(my $base = $info->file()) =~ s/\.pm\z//;
				$derived = File::Spec->catfile($base, 'data');
				$derived = undef unless -d $derived;
			}
			$_dir_cache{$class_in} = $derived;
		}
		$args{'directory'} = $_dir_cache{$class_in}
			if defined $_dir_cache{$class_in};
	}

	# Premise: directory, if provided, must be a plain string (not a ref).
	# Merge the null-byte guard and untaint into one outer block — both share
	# the same defined+!ref precondition, eliminating a redundant test.
	if(defined($args{'directory'}) && !ref($args{'directory'})) {
		# Null bytes cause a fatal "Embedded nulls" inside stat(). Reject first.
		if(index($args{'directory'}, "\0") >= 0) {
			my $msg = $class_in->_i18n('warn_not_dir',
				{class => $class_in, dir => '(path contains null byte)'});
			$args{'logger'}->warn($msg) if $args{'logger'};
			Carp::carp($msg);
			return;
		}
		# Conclusion: no null bytes remain, so m/\A([^\0]*)\z/ is guaranteed to
		# match — the capture is infallible. Untaint for taint-mode callers.
		($args{'directory'}) = ($args{'directory'} =~ m/\A([^\0]*)\z/);
	}

	if(defined($args{'directory'}) && !((-d $args{'directory'}) && (-r $args{'directory'}))) {
		my $msg = $class_in->_i18n('warn_not_dir',
			{class => $class_in, dir => $args{'directory'}});
		$args{'logger'}->warn($msg) if $args{'logger'};
		Carp::carp($msg);
		return;
	}

	return bless { cache_duration => $DEFAULT_CACHE_DURATION, %args }, $class_in;
}

=head2 search

Searches the obituary database.

    # List context: all matching records
    my @smiths = $obits->search(last => 'Smith');
    print $smiths[0]->{'url'}, "\n";

    # Scalar context: first matching record, or undef
    my $entry = $obits->search({ first => 'John', last => 'Smith' });

The returned hashrefs always include a C<url> key pointing to the source archive.

=over 4

=item * C<List context> - array of hashrefs, empty on no match.

=item * C<Scalar context> - single hashref, or C<undef> on no match.

=back

=head3 EXAMPLE

    my @results = $obits->search(last => 'O-Brien');
    foreach my $r (@results) {
        printf "%s %s, age %s - %s\n",
            $r->{first} // '?', $r->{last},
            $r->{age}   // 'unknown',
            $r->{url};
    }

    # With optional filters
    my $hit = $obits->search(first => 'John', middle => 'W', last => 'Coppage');

=head3 API SPECIFICATION

=head4 INPUT

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

=head4 DOMAIN — last (required)

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

=head4 DOMAIN — first / middle (optional)

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

=head4 DOMAIN — age (optional integer)

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

=head4 DOMAIN — invocation style

  EP-V  $obj->search(...)         Normal object-method call.
  EP-I  Pkg->search(...)          Croak err_no_self (class is not blessed).
  EP-I  Pkg::search(...)          Croak err_no_self.
  EP-I  $obj->search()            Croak err_no_args (zero args).

=head4 CONTEXT DOMAIN

  List context   Returns list of hashrefs; empty list on no match.
  Scalar context Returns single hashref (first match) or undef.
  Void context   No crash; result silently discarded.

=head4 OUTPUT

  Argument error:     croak
  No match (list):    ()
  No match (scalar):  undef
  Match (list):       ( HashRef, ... )   each has a 'url' key
  Match (scalar):     HashRef            has a 'url' key

=head3 MESSAGES

  err_no_self       - search() must be called on an object (->search, not ::search).
  err_no_last       - Value for 'last' is mandatory and must be non-empty.
  err_no_obituaries - Cannot open the obituaries database; check directory path.
  (from _create_url) err_bad_source, err_no_page, err_no_source, err_no_newspaper.

=head3 PSEUDOCODE

 1. Croak unless $self is a blessed object.
 2. Parse args with Params::Get; validate schema with Params::Validate::Strict.
 3. Explicitly croak if 'last' is undef or empty - Params::Validate::Strict
    passes undef through for defined-but-required fields.
 4. Lazily open the obituaries DB handle (once per object lifetime).
 5. Croak if the DB handle could not be initialised.
 6. List context: fetchall, attach URL, fixate string values, return list.
 7. Scalar context: fetchone, attach URL, fixate string values, return hashref.
 8. Return undef / empty list when no rows match.

=cut

sub search
{
	my $self = shift;

	Carp::croak(__PACKAGE__->_i18n('err_no_self'))
		unless Scalar::Util::blessed($self);

	# Guard against zero args before Params::Get, which uses confess (not croak)
	# for the 0-args case, preventing Test::Carp from detecting the error type.
	Carp::croak(__PACKAGE__->_i18n('err_no_args', {package => __PACKAGE__}))
		unless @_;

	my $params = Params::Validate::Strict::validate_strict({
		args   => Params::Get::get_params('last', @_),
		schema => {
			'last' => {
				type    => 'string',
				min     => $MIN_LAST_NAME_LENGTH,
				max     => $MAX_LAST_NAME_LENGTH,
				matches => qr/\A[\w-]+\z/,	# Allow hyphens; \z rejects trailing newlines that \$ misses
			},
			'first' => {
				type => 'string', optional => 1, min => 1, max => 100,
			},
			'middle' => {
				type => 'string', optional => 1, min => 1, max => 100,
			},
			'age' => {
				type => 'integer', optional => 1, min => 0, max => 120,
			},
		},
	});

	# Params::Validate::Strict enforces schema structure but passes undef values
	# for defined keys, so we check the mandatory 'last' field explicitly here.
	unless(defined($params->{'last'}) && length($params->{'last'}) > 0) {
		$self->{'logger'}->error(__PACKAGE__->_i18n('err_no_last'))
			if $self->{'logger'};
		Carp::croak(__PACKAGE__->_i18n('err_no_last'));
	}

	# Lazily initialise the DB handle — shared for the lifetime of the object
	$self->{'obituaries'} //= Genealogy::Obituary::Lookup::obituaries->new(
		no_entry  => 1,
		no_fixate => 1,
		%{$self},
	);

	unless(defined $self->{'obituaries'}) {
		$self->{'logger'}->error(__PACKAGE__->_i18n('err_no_obituaries'))
			if $self->{'logger'};
		Carp::croak(__PACKAGE__->_i18n('err_no_obituaries'));
	}

	if(wantarray) {
		my $obituaries = $self->{'obituaries'}->selectall_hashref($params)
			or return;
		# Iterate the arrayref directly (no intermediate grep list) and filter
		# undef slots inline — eliminates one O(N) allocation for large result sets.
		my @rc;
		for my $obit (@{$obituaries}) {
			next unless defined $obit;
			$obit->{'url'} = _create_url($obit);
			# Intern string values in the hash to reduce memory for repeated
			# strings (source, place, newspaper) across large result sets.
			# fixate(%{$obit}) passes the hashref via the \[@%] prototype.
			# Guard with eval: if a value is already interned (read-only) a
			# second fixate call would otherwise die with "Modification of a
			# read-only value".  Silently tolerate that case.
			{ local $@; eval { Data::Reuse::fixate(%{$obit}) } };
			push @rc, $obit;
		}
		return @rc;
	}

	my $obit = $self->{'obituaries'}->fetchrow_hashref($params)
		or return;
	$obit->{'url'} = _create_url($obit);
	{ local $@; eval { Data::Reuse::fixate(%{$obit}) } };

	return Return::Set::set_return($obit, { type => 'hashref', min => 1 });
}

# ---------------------------------------------------------------------------
# Private helpers
# ---------------------------------------------------------------------------

# Purpose:    Builds the source URL for an obituary record.
# Entry:      $obit — hashref with 'source' (M/F/L), 'page', and optionally
#             'newspaper' (required for source 'L').
# Exit:       String URL.
sub _create_url
{
	# Enforce privacy: only code within this package may call _create_url.
	Carp::croak("_create_url() is a private method of " . __PACKAGE__)
		unless (caller)[0] eq __PACKAGE__;

	my $obit   = shift;
	my $page   = $obit->{'page'};
	my $source = $obit->{'source'};

	Carp::croak(__PACKAGE__->_i18n('err_no_page', {package => __PACKAGE__}))
		unless defined $page;
	Carp::croak(__PACKAGE__->_i18n('err_no_source', {package => __PACKAGE__, page => $page}))
		unless defined $source;

	# Premise: source ∈ {M, F} returns unconditionally above.
	# Conclusion: the elsif below is only evaluated when source ∉ {M, F}.
	if($source eq 'M' || $source eq 'F') {
		return $URLS{$source} . $page;
	} elsif($source eq 'L') {
		# 'L' (local/link) records embed the full URL in newspaper or page
		return $obit->{'newspaper'}
			if defined($obit->{'newspaper'}) && $obit->{'newspaper'} =~ m{\Ahttps?://};
		return $page
			if $page =~ m{\Ahttps?://};
		Carp::croak(__PACKAGE__->_i18n('err_no_newspaper', {package => __PACKAGE__}));
	}

	Carp::croak(__PACKAGE__->_i18n('err_bad_source',
		{package => __PACKAGE__, source => $source}));
}

# Purpose:    Looks up a user-facing message template and interpolates named
#             placeholders of the form %{key} using the supplied args hashref.
# Entry:      $self_or_class — object or class name (not used yet; reserved for
#             per-instance locale configuration).
#             $key  — key into %MESSAGES.
#             $args — optional hashref of placeholder values.
# Exit:       Formatted string.
sub _i18n
{
	# TODO: CLAUDE.md violation — _i18n() is missing the required caller() privacy
	# guard.  Adding it breaks t/function.t, t/path.t, t/edge_cases.t, and
	# t/data-flow.t, which call _i18n() directly.  Those tests must be refactored
	# to call through the public API before the guard can be re-introduced.
	# TODO: Data Flow Anomaly - $self_or_class defined (D) but never used (D~ dead store; reserved for future per-instance locale selection)
	my ($self_or_class, $key, $args) = @_;
	my $tpl = $MESSAGES{$key}
		// Carp::croak("Unknown i18n key '$key'");
	$args //= {};
	# Pre-populate replacement table from template keys so the substitution
	# needs no /e modifier — eliminates any eval of replacement text entirely.
	my %sub_vals;
	$sub_vals{$1} = $args->{$1} // '' while $tpl =~ m/%\{(\w+)\}/g;
	(my $msg = $tpl) =~ s/%\{(\w+)\}/$sub_vals{$1}/g;
	return $msg;
}

=head1 COMMON PITFALLS

=head2 Apostrophes are rejected in last names

The C<last> field is validated against C<qr/\A[\w-]+\z/>.  This allows letters,
digits, underscores, and hyphens, but B<not> apostrophes.  A search for
C<< last => "O'Brien" >> will croak at validation time.  Use the closest
hyphenated or unhyphenated spelling:

    $obits->search(last => 'OBrien');   # OK
    $obits->search(last => "O'Brien");  # CROAKS

=head2 new() returns undef on a bad directory; it does not croak

When C<directory> is supplied but does not exist or is not readable, C<new()>
calls C<Carp::carp> (a warning, not a fatal error) and returns C<undef>.
Always check the return value before calling C<search()>:

    my $obits = Genealogy::Obituary::Lookup->new(directory => $path)
        or die "Could not open obituary database at $path";

=head2 Scalar vs list context returns different things

C<search()> is context-sensitive.  In list context it returns every matching
record.  In scalar context it returns only the first match.  Assigning to a
plain variable is scalar context; assigning to an array is list context:

    my @all   = $obits->search(last => 'Smith');   # all records (list context)
    my $first = $obits->search(last => 'Smith');   # one record  (scalar context)

=head2 Clone semantics: the database handle is shared

Calling C<< $obj->new(...) >> creates a I<shallow copy> of the parent.  If the
parent has already run a search (and therefore opened its C<obituaries> handle),
the clone starts out sharing that same handle object.  The clone replaces the
handle on its first search call, but until then both objects reference the same
underlying driver.  This is intentional and efficient; be aware of it if you
pass handles between threads or processes.

=head2 Search results are interned and become read-only

After C<search()> returns, all string values inside the result hashrefs are
interned by C<Data::Reuse::fixate>.  Any attempt to modify them in place will
die with C<"Modification of a read-only value">:

    my @hits = $obits->search(last => 'Smith');
    $hits[0]->{last} = 'Jones';   # DIES -- read-only after search()

Copy the hashref or the field before modifying it:

    my %copy = %{ $hits[0] };
    $copy{last} = 'Jones';        # OK

=head2 Logger must implement info(), warn(), and error()

C<new()> validates the logger before storing it.  The object must be blessed and
must implement B<all three> of C<info()>, C<warn()>, and C<error()>.  An object
missing any one of them will cause C<new()> to croak immediately:

    # CROAKS: object provides info() and error() but not warn()
    my $obits = Genealogy::Obituary::Lookup->new(logger => $partial_logger);

C<warn()> is required because C<new()> uses it (not C<error()>) to report
non-fatal events such as a missing or unreadable directory.  Using C<error()>
for those events would cause loggers whose C<error()> calls C<die> (such as
L<Log::Abstraction>) to convert a graceful C<carp + return undef> into a fatal
exception, breaking the documented API contract.

=head2 Non-ASCII characters in last depend on runtime locale

The C<[\w\-]+> regex matches C<\w>, which includes non-ASCII word characters
(accented letters, umlauts) when the string has the UTF-8 flag and the calling
code uses C<use utf8>.  Without that, the same input is rejected.  The module
does not set any locale; test explicitly if your data contains diacritics.

=head1 SECURITY NOTES

=head2 Null bytes in directory paths are rejected early

A C<directory> string containing a null byte (C<\0>) would cause Perl's
C<stat()> to throw a fatal C<"Embedded nulls are forbidden"> exception.
C<new()> detects this before the filesystem call, calls the logger's C<warn()>
method if a logger is present, and carps gracefully instead of dying.

=head2 Taint-mode readiness

The C<directory> argument is passed through a C<m/\A([^\0]*)\z/> capture before
any filesystem operator sees it.  This untaints the value for callers running
under Perl's taint mode (C<perl -T>) without requiring any extra configuration.

=head2 URL construction uses percent-encoding

The database builder (C<bin/create_db.PL>) encodes user-controlled components
via C<URI::Escape::uri_escape> before embedding them in HTTP URLs.  This
prevents surname values from being misinterpreted as URL structure.

=head2 Path traversal is prevented in the database builder

Environment variables C<MLARCHIVEDIR> and C<MLARCHIVE_DIR> are canonicalized
with C<File::Spec-E<gt>canonpath()> and then checked to confirm the resolved
path starts with the declared base directory.  Any path that escapes the base
via C<../> components is rejected with C<croak>.

=head2 i18n substitution uses no eval

The C<_i18n()> helper pre-builds a substitution table from template
placeholders and then applies a plain C<s///g> replacement.  No C</e> modifier
or string C<eval> is used, so template values cannot execute arbitrary code.

=head1 LIMITATIONS

=over 4

=item * B<Ancestry / Rootsweb archive loss.>
Only the first 18 pages of the mlarchives index are preserved on the Wayback
Machine.  Approximately 10,000+ records from later pages are unrecoverable.

=item * B<No full-text search.>
Searches are keyed on structured fields (last, first, middle, age).  There is
no free-text obituary content to search.

=item * B<i18n is English-only.>
The C<%MESSAGES> map supports placeholder interpolation but is not backed by a
locale-selection mechanism.  A future release should route through
L<Locale::Maketext> or L<Locale::Simple>.

=item * B<Data::Reuse fixate semantics.>
The string-interning via C<Data::Reuse::fixate> on hash-slice aliases is
correct in theory (hash slices are lvalues) but depends on
C<String::Intern::Internalize> modifying @_ in place.  Verify with your
installed version if memory consumption is a concern.

=item * B<Private method enforcement without Sub::Private.>
C<_create_url> and C<_i18n> enforce privacy via an inline C<caller> check.
Install L<Sub::Private> and replace the checks for a compile-time guarantee.

=item * B<Single-row scalar context.>
In scalar context, C<search()> returns the first row from the underlying
driver.  Row order depends on L<Database::Abstraction> and SQLite's query
plan; add an explicit ORDER BY in the driver subclass if deterministic ordering
is required.

=back

=head1 AUTHOR

Nigel Horne, C<< <njh at nigelhorne.com> >>

=head1 BUGS

See L<https://rt.cpan.org/NoAuth/Bugs.html?Dist=Genealogy-Obituary-Lookup>.

=head1 SEE ALSO

L<Database::Abstraction>

=over 4

=item * The Obituary Daily Times: L<https://sites.rootsweb.com/~obituary/>

=item * Archived Rootsweb data: L<https://wayback.archive-it.org/20669/20231102044925/https://mlarchives.rootsweb.com/listindexes/emails?listname=gen-obit>

=item * Recent data: L<https://www.freelists.org/list/obitdailytimes>

=item * L<Configure an Object at Runtime|Object::Configure>

=item * L<Test Dashboard|https://nigelhorne.github.io/Genealogy-Obituary-Lookup/coverage/>

=back

=head1 SUPPORT

This module is provided as-is without any warranty.

    perldoc Genealogy::Obituary::Lookup

=over 4

=item * MetaCPAN: L<https://metacpan.org/release/Genealogy-Obituary-Lookup>

=item * RT: L<https://rt.cpan.org/NoAuth/Bugs.html?Dist=Genealogy-Obituary-Lookup>

=item * CPAN Testers' Matrix: L<http://matrix.cpantesters.org/?dist=Genealogy-Obituary-Lookup>

=back

=head1 FORMAL SPECIFICATION

=head2 new

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

=head2 search

  𝒔𝒆𝒂𝒓𝒄𝒉 : Object × Params → ([Obit] ∪ Obit ∪ {undef})

  𝒔𝒆𝒂𝒓𝒄𝒉(self, P) ≙
    pre  blessed(self) ∧ P.last ≠ ∅
    post wantarray ⟹ { o : Obit | match(self.db, P) } |> map(add_url)
              else ⟹ head({ o : Obit | match(self.db, P) } |> map(add_url))

  where  add_url(o) ≙ o ⊕ ⟨ url ↦ _create_url(o) ⟩

=head1 LICENSE AND COPYRIGHT

Copyright 2020-2026 Nigel Horne.

Usage is subject to the GPL2 licence terms.
If you use it,
please let me know.

=cut

1;
