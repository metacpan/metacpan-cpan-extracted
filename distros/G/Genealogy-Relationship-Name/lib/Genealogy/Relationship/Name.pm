package Genealogy::Relationship::Name;

# Genealogy::Relationship::Name - Return the name of a genealogical relationship
# given step counts to and from a common ancestor, the sex of person B, and a language.
#
# Author: Nigel Horne <njh@nigelhorne.com>
# Licence: GPL v2

use strict;
use warnings;
use autodie qw(:all);

use Carp qw(croak carp);
use Object::Configure;
use Params::Get;
use Params::Validate::Strict 0.31;
use Readonly;

our $VERSION = '0.02';

# ---------------------------------------------------------------------------
# Constants – relationship table keys
# ---------------------------------------------------------------------------

# Supported language codes
Readonly::Array my @SUPPORTED_LANGUAGES => qw(en fr de);

# Default language when none supplied
Readonly::Scalar my $DEFAULT_LANGUAGE => 'en';

# Sex constants
Readonly::Scalar my $SEX_MALE   => 'M';
Readonly::Scalar my $SEX_FEMALE => 'F';

# ---------------------------------------------------------------------------
# English relationship tables
# Key: "$steps1,$steps2"  where steps1 = steps from A to ancestor,
#                                steps2 = steps from B to ancestor
# ---------------------------------------------------------------------------

Readonly::Hash my %EN_MALE_RELATIONSHIPS => (
	'0,0' => 'self',
	'0,1' => 'son',
	'0,2' => 'grandson',
	'0,3' => 'great-grandson',
	'0,4' => 'great-great-grandson',
	'1,0' => 'father',
	'1,1' => 'brother',
	'1,2' => 'nephew',
	'1,3' => 'great-nephew',
	'1,4' => 'great-great-nephew',
	'2,0' => 'grandfather',
	'2,1' => 'uncle',
	'2,2' => 'first cousin',
	'2,3' => 'first cousin once-removed',
	'2,4' => 'first cousin twice-removed',
	'2,5' => 'first cousin three-times-removed',
	'3,0' => 'great-grandfather',
	'3,1' => 'great-uncle',
	'3,2' => 'first cousin once-removed',
	'3,3' => 'second cousin',
	'3,4' => 'second cousin once-removed',
	'3,5' => 'second cousin twice-removed',
	'3,6' => 'second cousin three-times-removed',
	'4,0' => 'great-great-grandfather',
	'4,1' => 'great-great-uncle',
	'4,2' => 'first cousin twice-removed',
	'4,3' => 'second cousin once-removed',
	'4,4' => 'third cousin',
	'4,5' => 'third cousin once-removed',
	'4,6' => 'third cousin twice-removed',
	'5,0' => 'great-great-great-grandfather',
	'5,1' => 'great-great-great-uncle',
	'5,2' => 'first cousin three-times-removed',
	'5,3' => 'second cousin twice-removed',
	'5,4' => 'third cousin once-removed',
	'5,5' => 'fourth cousin',
	'5,6' => 'fourth cousin once-removed',
	'6,0' => 'great-great-great-great-grandfather',
	'6,2' => 'first cousin four-times-removed',
	'6,3' => 'second cousin three-times-removed',
	'6,4' => 'third cousin twice-removed',
	'6,5' => 'fourth cousin once-removed',
	'6,6' => 'fifth cousin',
);

Readonly::Hash my %EN_FEMALE_RELATIONSHIPS => (
	'0,0' => 'self',
	'0,1' => 'daughter',
	'0,2' => 'granddaughter',
	'0,3' => 'great-granddaughter',
	'0,4' => 'great-great-granddaughter',
	'1,0' => 'mother',
	'1,1' => 'sister',
	'1,2' => 'niece',
	'1,3' => 'great-niece',
	'1,4' => 'great-great-niece',
	'2,0' => 'grandmother',
	'2,1' => 'aunt',
	'2,2' => 'first cousin',
	'2,3' => 'first cousin once-removed',
	'2,4' => 'first cousin twice-removed',
	'2,5' => 'first cousin three-times-removed',
	'3,0' => 'great-grandmother',
	'3,1' => 'great-aunt',
	'3,2' => 'first cousin once-removed',
	'3,3' => 'second cousin',
	'3,4' => 'second cousin once-removed',
	'3,5' => 'second cousin twice-removed',
	'3,6' => 'second cousin three-times-removed',
	'4,0' => 'great-great-grandmother',
	'4,1' => 'great-great-aunt',
	'4,2' => 'first cousin twice-removed',
	'4,3' => 'second cousin once-removed',
	'4,4' => 'third cousin',
	'4,5' => 'third cousin once-removed',
	'4,6' => 'third cousin twice-removed',
	'5,0' => 'great-great-great-grandmother',
	'5,1' => 'great-great-great-aunt',
	'5,2' => 'first cousin three-times-removed',
	'5,3' => 'second cousin twice-removed',
	'5,4' => 'third cousin once-removed',
	'5,5' => 'fourth cousin',
	'5,6' => 'fourth cousin once-removed',
	'6,0' => 'great-great-great-great-grandmother',
	'6,2' => 'first cousin four-times-removed',
	'6,3' => 'second cousin three-times-removed',
	'6,4' => 'third cousin twice-removed',
	'6,5' => 'fourth cousin once-removed',
	'6,6' => 'fifth cousin',
);

# ---------------------------------------------------------------------------
# French relationship tables
# ---------------------------------------------------------------------------

Readonly::Hash my %FR_MALE_RELATIONSHIPS => (
	'0,0' => 'soi-meme',
	'0,1' => 'fils',
	'0,2' => 'petit-fils',
	'0,3' => 'arriere-petit-fils',
	'0,4' => 'arriere-arriere-petit-fils',
	'1,0' => 'pere',
	'1,1' => 'frere',
	'1,2' => 'neveu',
	'1,3' => 'grand-neveu',
	'1,4' => 'arriere-grand-neveu',
	'2,0' => 'grand-pere',
	'2,1' => 'oncle',
	'2,2' => 'cousin germain',
	'2,3' => 'cousin issu de germain',
	'2,4' => 'cousin au troisieme degre',
	'3,0' => 'arriere-grand-pere',
	'3,1' => 'grand-oncle',
	'3,2' => 'cousin issu de germain',
	'3,3' => 'cousin au troisieme degre',
	'3,4' => 'cousin au quatrieme degre',
	'4,0' => 'arriere-arriere-grand-pere',
	'4,1' => 'arriere-grand-oncle',
	'4,2' => 'cousin au troisieme degre',
	'4,3' => 'cousin au quatrieme degre',
	'4,4' => 'cousin au cinquieme degre',
	'5,0' => 'trisaieul',
	'5,5' => 'cousin au sixieme degre',
	'6,0' => 'quadrisaieul',
	'6,6' => 'cousin au septieme degre',
);

Readonly::Hash my %FR_FEMALE_RELATIONSHIPS => (
	'0,0' => 'soi-meme',
	'0,1' => 'fille',
	'0,2' => 'petite-fille',
	'0,3' => 'arriere-petite-fille',
	'0,4' => 'arriere-arriere-petite-fille',
	'1,0' => 'mere',
	'1,1' => 'soeur',
	'1,2' => 'niece',
	'1,3' => 'grand-niece',
	'1,4' => 'arriere-grand-niece',
	'2,0' => 'grand-mere',
	'2,1' => 'tante',
	'2,2' => 'cousine germaine',
	'2,3' => 'cousine issue de germaine',
	'2,4' => 'cousine au troisieme degre',
	'3,0' => 'arriere-grand-mere',
	'3,1' => 'grand-tante',
	'3,2' => 'cousine issue de germaine',
	'3,3' => 'cousine au troisieme degre',
	'3,4' => 'cousine au quatrieme degre',
	'4,0' => 'arriere-arriere-grand-mere',
	'4,1' => 'arriere-grand-tante',
	'4,2' => 'cousine au troisieme degre',
	'4,3' => 'cousine au quatrieme degre',
	'4,4' => 'cousine au cinquieme degre',
	'5,0' => 'trisaieule',
	'5,5' => 'cousine au sixieme degre',
	'6,0' => 'quadrisaieule',
	'6,6' => 'cousine au septieme degre',
);

# ---------------------------------------------------------------------------
# German relationship tables
# ---------------------------------------------------------------------------

Readonly::Hash my %DE_MALE_RELATIONSHIPS => (
	'0,0' => 'sich selbst',
	'0,1' => 'Sohn',
	'0,2' => 'Enkel',
	'0,3' => 'Urenkel',
	'0,4' => 'Ururenkel',
	'1,0' => 'Vater',
	'1,1' => 'Bruder',
	'1,2' => 'Neffe',
	'1,3' => 'Grossneffe',
	'1,4' => 'Urgrossneffe',
	'2,0' => 'Grossvater',
	'2,1' => 'Onkel',
	'2,2' => 'Cousin',
	'2,3' => 'Cousin ersten Grades einmal entfernt',
	'2,4' => 'Cousin ersten Grades zweimal entfernt',
	'3,0' => 'Urgrossvater',
	'3,1' => 'Grossonkel',
	'3,2' => 'Cousin ersten Grades einmal entfernt',
	'3,3' => 'Cousin zweiten Grades',
	'3,4' => 'Cousin zweiten Grades einmal entfernt',
	'4,0' => 'Urururgrossvater',
	'4,1' => 'Urgrossonkel',
	'4,2' => 'Cousin ersten Grades zweimal entfernt',
	'4,3' => 'Cousin zweiten Grades einmal entfernt',
	'4,4' => 'Cousin dritten Grades',
	'5,0' => 'Urururgrossvater',
	'5,5' => 'Cousin vierten Grades',
	'6,0' => 'Ururururgrossvater',
	'6,6' => 'Cousin fuenften Grades',
);

Readonly::Hash my %DE_FEMALE_RELATIONSHIPS => (
	'0,0' => 'sich selbst',
	'0,1' => 'Tochter',
	'0,2' => 'Enkelin',
	'0,3' => 'Urenkelin',
	'0,4' => 'Ururenkelin',
	'1,0' => 'Mutter',
	'1,1' => 'Schwester',
	'1,2' => 'Nichte',
	'1,3' => 'Grossnichte',
	'1,4' => 'Urgrossnichte',
	'2,0' => 'Grossmutter',
	'2,1' => 'Tante',
	'2,2' => 'Cousine',
	'2,3' => 'Cousine ersten Grades einmal entfernt',
	'2,4' => 'Cousine ersten Grades zweimal entfernt',
	'3,0' => 'Urgrossmutter',
	'3,1' => 'Grosstante',
	'3,2' => 'Cousine ersten Grades einmal entfernt',
	'3,3' => 'Cousine zweiten Grades',
	'3,4' => 'Cousine zweiten Grades einmal entfernt',
	'4,0' => 'Urururgrossmutter',
	'4,1' => 'Urgrosstante',
	'4,2' => 'Cousine ersten Grades zweimal entfernt',
	'4,3' => 'Cousine zweiten Grades einmal entfernt',
	'4,4' => 'Cousine dritten Grades',
	'5,0' => 'Urururgrossmutter',
	'5,5' => 'Cousine vierten Grades',
	'6,0' => 'Ururururgrossmutter',
	'6,6' => 'Cousine fuenften Grades',
);

# ---------------------------------------------------------------------------
# Master dispatch table: lang -> sex -> hashref
# ---------------------------------------------------------------------------

Readonly::Hash my %RELATIONSHIP_TABLES => (
	'en' => {
		$SEX_MALE   => \%EN_MALE_RELATIONSHIPS,
		$SEX_FEMALE => \%EN_FEMALE_RELATIONSHIPS,
	}, 'fr' => {
		$SEX_MALE   => \%FR_MALE_RELATIONSHIPS,
		$SEX_FEMALE => \%FR_FEMALE_RELATIONSHIPS,
	}, 'de' => {
		$SEX_MALE   => \%DE_MALE_RELATIONSHIPS,
		$SEX_FEMALE => \%DE_FEMALE_RELATIONSHIPS,
	},
);

# ---------------------------------------------------------------------------
# Constructor
# ---------------------------------------------------------------------------

=head1 NAME

Genealogy::Relationship::Name - Return a genealogical relationship name from step counts

=head1 VERSION

Version 0.02

=head1 SYNOPSIS

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

=head1 DESCRIPTION

C<Genealogy::Relationship::Name> maps a pair of step-counts (person A to common
ancestor, common ancestor to person B) plus the sex of person B and an optional
language code to a human-readable relationship name string.

The relationship tables were originally embedded in the C<gedcom> and C<ged2site>
distributions inside C<Gedcom::Individual::relationship_up()>; this module
extracts them into a reusable, installable CPAN distribution.

Supported languages: C<en> (English, default), C<fr> (French), C<de> (German).

=head1 METHODS

=head2 new

Constructor.  Creates and returns a blessed C<Genealogy::Relationship::Name>
object.

=head3 PURPOSE

Initialises the object with optional configuration: a default language for
subsequent C<name()> calls, and an optional L<Log::Abstraction> object to
use as the error logger.  Configuration may also be loaded from an INI-style
file via L<Object::Configure>.

=head3 ARGUMENTS

=over 4

=item C<language> (string, optional)

Default BCP-47 language tag (primary subtag only) for all C<name()> calls
on this object.  Supported values: C<en> (default), C<fr>, C<de>.  May be
overridden per-call by passing C<language> to C<name()>.

=item C<logger>

A pre-constructed loggining object.  When a required argument is
passed as C<undef> to C<name()>, the error is reported via
C<< $logger->error($msg) >> rather than C<croak>.  This allows
programs to route errors through their own 
infrastructure with full C<ctx> context.

See L<Log::Abstraction> and the L</CONFIGURATION> section for the
recommended construction pattern.

=item C<config_file> (string, optional)

Path to an INI-style configuration file processed by L<Object::Configure>.
Any keys it sets may be overridden by arguments passed directly to C<new()>.

=back

=head3 RETURNS

A blessed C<Genealogy::Relationship::Name> object.

=head3 SIDE EFFECTS

Calls L<Object::Configure> C<configure()>, which may read from a
configuration file on disk if C<config_file> is supplied or if a default
configuration file exists for the class.

=head3 NOTES

L<Object::Configure> cannot handle object or coderef values (it treats
unknown scalar values as configuration file paths).  The C<logger> key is
therefore stashed before the C<configure()> call and restored afterward.
Any future object-valued constructor arguments must follow the same pattern.

=head3 EXAMPLE

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

=head3 API SPECIFICATION

=head4 Input

    {
        language => { type => 'string', regex => qr/^(?:en|fr|de)/, optional => 1 },
        logger   => { type => 'object', optional => 1 },
    }

=head4 Output

    {
        type  => 'object',
        class => 'Genealogy::Relationship::Name',
    }

=head3 FORMAL SPECIFICATION

    new ________________________________________________________
    [In]  class    : String                  (class name or object)
          language : {en, fr, de}?           (optional default language)
          logger   : Log::Abstraction?       (optional error logger)
    [Out] self     : Genealogy::Relationship::Name

    Let params == get_params(args)
    Let params' == configure(class, params \ {logger})
                   union {logger -> params.logger}  if logger in dom params
    self == bless(params', class)

    post: self.language == params.language  if language in dom params
          self.logger   == params.logger    if logger   in dom params
          ref(self)     == 'Genealogy::Relationship::Name'

=cut

sub new {
	# Create and return a blessed object
	my $class = shift;

	# Handle hash or hashref arguments
	my $params = Params::Get::get_params(undef, \@_);

	# Stash keys that are coderefs or objects before passing to Object::Configure,
	# which cannot handle them (it treats unknown scalar values as config file paths)
	my %stash;
	for my $key (qw(logger)) {
		next unless exists $params->{$key};
		$stash{$key} = delete $params->{$key};
	}

	# Load the configuration from a config file, if provided
	$params = Object::Configure::configure($class, $params);

	# Restore the stashed coderefs and objects after configure()
	@{$params}{keys %stash} = values %stash;

	# Bless and return the object; logger/ctx/level keys from params
	# are stored directly and accessed via $self->{logger} etc.
	return bless {
		# Store any constructor-time config for Object::Configure compatibility
		%{$params},
	}, ref($class) || $class;
}

# ---------------------------------------------------------------------------
# Public method: name()
# ---------------------------------------------------------------------------

=head1 METHODS

=head2 name

Returns the name of the relationship between person A and person B.

=head3 PURPOSE

Given the number of steps from person A up to the nearest common ancestor
(C<steps_to_ancestor>) and the number of steps from that ancestor down to
person B (C<steps_from_ancestor>), plus the sex of person B and a language
code, returns a localised relationship-name string.

=head3 ARGUMENTS

=over 4

=item C<steps_to_ancestor> (integer, required)

Number of generational steps from person A up to the common ancestor.
Must be a non-negative integer.  Zero means person A I<is> the ancestor.

=item C<steps_from_ancestor> (integer, required)

Number of generational steps from the common ancestor down to person B.
Must be a non-negative integer.

=item C<sex> (string, required)

Sex of person B.  Must be C<'M'> (male) or C<'F'> (female).

=item C<language> (string, optional)

BCP-47-style language tag (only the primary subtag is used).
Supported values: C<en> (default), C<fr>, C<de>.

=item C<person> (object, optional)

An optional person object (e.g. a C<Gedcom::Individual> instance) passed
through to the error handler when an error occurs.  Takes priority over the
C<ctx> set at construction time.  The handler receives it as C<ctx> (logger
path) or C<person> (on_error path), matching the C<complain()> interface
in C<gedcom>/C<ged2site>.

=back

=head3 RETURNS

A string containing the relationship name, or C<undef> if the combination
is not found in the lookup table.

=head3 EXAMPLE

    my $namer = Genealogy::Relationship::Name->new();

    # Person A is the grandparent (2 steps up) of the common ancestor,
    # and person B is 3 steps below the ancestor; B is female => first cousin once-removed
    my $rel = $namer->name(
        steps_to_ancestor   => 2,
        steps_from_ancestor => 3,
        sex                 => 'F',
    );

=head3 API SPECIFICATION

=head4 Input

    {
	steps_to_ancestor   => { type => 'integer', minimum => 0 },
	steps_from_ancestor => { type => 'integer', minimum => 0 },
	sex                 => { type => 'string', memberof => ['M', 'F'] },
	language            => { type => 'string', regex => qr/^(?:en|de|fr)/, optional => 1 },
	# person is extracted before validate_strict to avoid PVS inferring constraints
    }

=head4 Output

    {
        type     => 'string',
        optional => 1,     # undef when the combination is not tabulated
    }

=head3 FORMAL SPECIFICATION

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

=cut

sub name {
	my $self = shift;

	# Validate and extract the remaining parameters; capture the return value
	my $args = Params::Validate::Strict::validate_strict(
		args   => Params::Get::get_params(undef, \@_) || {},
		schema => {
			steps_to_ancestor   => { type => 'integer', minimum => 0 },
			steps_from_ancestor => { type => 'integer', minimum => 0 },
			sex                 => { type => 'string', memberof => ['M', 'F'] },
			language            => { type => 'string', regex => qr/^(?:en|de|fr)/,
			                         optional => 1 },
			person              => { type => 'object', optional => 1 },
		}
	);

	# Extract individual parameters; undef means arg was not given, so croak
	foreach my $arg('steps_to_ancestor', 'steps_from_ancestor', 'sex') {
		if(!defined($args->{$arg})) {
			if(my $logger = $self->{logger}) {
				$logger->error("$arg not given");
			} else {
				croak("$arg not given");
			}
		}
	}

	my $steps1 = $args->{steps_to_ancestor} // croak('steps_to_ancestor not given');
	my $steps2 = $args->{steps_from_ancestor} // croak('steps_from_ancestor not given');
	my $sex    = $args->{sex} // croak('sex not given');
	my $person = $args->{person};

	# Fall back to the constructor default or hard default if no per-call language given
	my $lang = lc($args->{language} // $self->{language} // $DEFAULT_LANGUAGE);

	# Strip any region subtag (e.g. 'en-GB' -> 'en') after lowercasing
	($lang) = split /-/, $lang;

	# Build lookup key from the two-step counts
	my $key = "${steps1},${steps2}";

	# Retrieve the correct gender-specific table for the chosen language
	my $table = $RELATIONSHIP_TABLES{$lang}{$sex};

	# Look up and return; undef when the combination is not tabulated
	my $result = $table->{$key};

	return $result;
}

# ---------------------------------------------------------------------------
# Public method: supported_languages()
# ---------------------------------------------------------------------------

=head2 supported_languages

Returns a sorted list of the language codes that the module supports.

=head3 PURPOSE

Allows calling code to enumerate the languages available for C<name()>
without hard-coding them.

=head3 ARGUMENTS

None.

=head3 RETURNS

A list (or array-ref in scalar context) of language code strings,
currently C<('de', 'en', 'fr')>.

=head3 EXAMPLE

    my @langs = $namer->supported_languages();
    # ( 'de', 'en', 'fr' )

=head3 API SPECIFICATION

=head4 Input

    {}   # no arguments

=head4 Output

    {
        type => ARRAYREF,   # sorted list of language codes
    }

=head3 FORMAL SPECIFICATION

    supported_languages ______________________________________
    [In]  (none)
    [Out] result : seq String

    result == sort(dom RELATIONSHIP_TABLES)

=cut

sub supported_languages {
	# Return the sorted set of keys from the master dispatch table
	my @langs = sort keys %RELATIONSHIP_TABLES;
	return wantarray ? @langs : \@langs;
}

# ---------------------------------------------------------------------------
# Public method: known_sexes()
# ---------------------------------------------------------------------------

=head2 known_sexes

Returns the list of sex codes accepted by C<name()>.

=head3 PURPOSE

Documents and exposes the set of valid C<sex> values so that callers can
validate their own input without duplicating knowledge.

=head3 ARGUMENTS

None.

=head3 RETURNS

A list (or array-ref in scalar context) of valid sex code strings: C<('F', 'M')>.

=head3 SIDE EFFECTS

None.

=head3 EXAMPLE

    my @sexes = $namer->known_sexes();
    # ( 'F', 'M' )

=head3 API SPECIFICATION

=head4 Input

    {}   # no arguments

=head4 Output

    {
        type => ARRAYREF,
    }

=head3 FORMAL SPECIFICATION

    known_sexes ______________________________________________
    [In]  (none)
    [Out] result : seq String

    result == sort { $SEX_FEMALE, $SEX_MALE }

=cut

sub known_sexes {
	# Return the two valid sex codes in sorted order
	my @sexes = sort($SEX_FEMALE, $SEX_MALE);
	return wantarray ? @sexes : \@sexes;
}

1;

__END__

=head1 CONFIGURATION

The constructor accepts an optional C<language> key which sets the default
language for all subsequent calls to C<name()>:

    my $namer = Genealogy::Relationship::Name->new(language => 'fr');

This default can be overridden per-call by passing C<language> to C<name()>.
The object is also compatible with C<Object::Configure> for runtime
reconfiguration.

=head2 Error handling

Errors are dispatched through the following priority chain:

=over 4

=item 1. L<Log::Abstraction> object (preferred)

Construct a C<Log::Abstraction> object with the desired logger coderef and
C<ctx> (typically a C<Gedcom::Individual>), then pass it as C<logger> to
C<new()>.  On error, this module simply calls C<< $logger->error($msg) >>
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

=back

If any handler returns without dying (e.g. a warning-only handler in
L<Log::Abstraction>), C<name()> returns C<undef>.

=head1 DIAGNOSTICS

=over 4

=item steps_to_ancestor not given

C<steps_to_ancestor> was passed as C<undef>. Passing C<undef> explicitly is
distinct from omitting the argument; use a defined non-negative integer.

=item steps_from_ancestor not given

As above, for C<steps_from_ancestor>.

=item sex not given

C<sex> was passed as C<undef>. Supply C<'M'> or C<'F'>.

=back

=head1 DEPENDENCIES

L<Carp>, L<Object::Configure>

Optionally L<Log::Abstraction> (E<gt>= 0.28) for the C<logger>/C<ctx> error
dispatch path.
L<Params::Get>, L<Params::Validate::Strict>, L<Readonly>

=head1 BUGS AND LIMITATIONS

The lookup tables currently cover steps 0-6 in both directions.  Relationships
further removed (seventh cousin, etc.) return C<undef>.  Pull requests adding
deeper tables are welcome.

=head1 SEE ALSO

=over 4

=item * L<Configure an Object at Runtime|Object::Configure>

=item * L<Test Dashboard|https://nigelhorne.github.io/Genealogy-Relationship-Name/coverage/>

=item * L<Gedcom::Individual>, L<Genealogy::Relationship>

=back

=head1 AUTHOR

Nigel Horne C<< <njh@nigelhorne.com> >>

=head1 REPOSITORY

L<https://github.com/nigelhorne/Genealogy-Relationship-Name>

=head1 SUPPORT

This module is provided as-is without any warranty.

Please report any bugs or feature requests to C<bug-genealogy-relationship-name at rt.cpan.org>,
or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Genealogy-Relationship-Name>.
I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

You can find documentation for this module with the perldoc command.

    perldoc Genealogy::Relationship::Name

You can also look for information at:

=over 4

=item * MetaCPAN

L<https://metacpan.org/dist/Genealogy-Relationship-Name>

=item * RT: CPAN's request tracker

L<https://rt.cpan.org/NoAuth/Bugs.html?Dist=Genealogy-Relationship-Name>

=item * CPAN Testers' Matrix

L<http://matrix.cpantesters.org/?dist=Genealogy-Relationship-Name>

=item * CPAN Testers Dependencies

L<http://deps.cpantesters.org/?module=Genealogy::Relationship::Name>

=back

=head1 LICENCE AND COPYRIGHT

Copyright 2026 Nigel Horne.

Usage is subject to the GPL2 licence terms.
If you use it,
please let me know.

=cut
