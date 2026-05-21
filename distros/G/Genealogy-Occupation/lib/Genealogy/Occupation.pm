package Genealogy::Occupation;

# TODO: railway/railroad = le chemin de fer

use strict;
use warnings;
use 5.014;

use Carp qw(croak);
use I18N::LangTags::Detect;
use Lingua::EN::ABC;
use Params::Get;
use Readonly;
use Params::Validate::Strict qw(validate_strict);
use Return::Set qw(set_return);

our $VERSION = '0.02';

# Schema for new() arguments
Readonly my $NEW_SCHEMA => {
	warn_on_error => {
		type     => 'boolean',
		optional => 1,
		default  => 0,
	},
};

# Schema for normalise() arguments.
# Note: occupation is extracted and normalised to an arrayref BEFORE
# validate_strict is called, because Params::Validate::Strict does not
# yet support union types.  Only the remaining named arguments (sex)
# are validated here.
Readonly my $NORMALISE_SCHEMA => {
	sex => {
		type     => 'string',
		optional => 1,
		memberof => ['M', 'F'],
	},
};

# Occupations to filter out entirely - these are not real occupations
# but rather descriptions of status or domestic roles
Readonly my %FILTER => map { lc($_) => 1 } qw(
	unemployed
	retired
);

# Filter patterns - matched case-insensitively against the occupation
Readonly my @FILTER_PATTERNS => (
	qr/^scho(?:ol|lar)/i,
	qr/wife$/i,
	qr/seeking work/i,
	qr/domestic duties/i,
	qr/home duties/i,
	qr/house\s?hold duties/i,
	qr/^at school$/i,
);

# Direct lookup table for exact normalisation matches.
# Keyed on lowercase occupation string.
Readonly my %DIRECT => (
	'ag lab'                          => 'Agricultural Labourer',
	'ag labourer'                     => 'Agricultural Labourer',
	'ag labourer pauper'              => 'Agricultural Labourer',
	'agric labourer'                  => 'Agricultural Labourer',
	'ag lab pauper'                   => 'Agricultural Labourer',
	'farm labourer'                   => 'Agricultural Labourer',
	'agricultural farm labourer'      => 'Agricultural Labourer',
	'ordinary agricultural labourer'  => 'Agricultural Labourer',
	'work on farm'                    => 'Agricultural Labourer',
	'agricultural lab'                => 'Agricultural Labourer',
	'agril labourer'                  => 'Agricultural Labourer',
	'labourer ag'                     => 'Agricultural Labourer',
	'labourer (ag)'                   => 'Agricultural Labourer',
	'platelayer railway'              => 'Railway Platelayer',
	'general servant domestic'        => 'Domestic Servant',
	'domestic servant'                => 'Domestic Servant',
	'lorry driver heavy worker'       => 'Lorry Driver',
	'laundry man'                     => 'Laundryman',
	"brewer's labourer"               => 'Brewery Labourer',
	'labourer builders'               => "Builder's Labourer",
	'gardener domestic'               => 'Gardener and Domestic',
	'gardner and domestic servant'    => 'Gardener and Domestic',  # sic
	'under gardener domestic'         => 'Domestic Gardener',
	'domestic under gardner'          => 'Domestic Gardener',      # sic
	'market gardener'                 => 'Market Gardener',
	'plate glass cutter'              => 'Plate Glass Cutter',
	'pfc us army'                     => 'Private First Class',
	'labourer gas stoker'             => 'Gas Stoker',
);

# Pattern that matches "general serv*dom*" variants
Readonly my $GENERAL_SERVANT_RE => qr/^general serv.+dom/i;

# French translations keyed on lowercase English occupation.
# Values are either a plain string or a hashref with M/F keys
# for gendered translations.
Readonly my %FRENCH => (
	'postman'   => { M => 'Facteur',      F => 'Factrice' },
	'farmer'    => { M => 'Agriculteur',  F => 'Agricultrice' },
	'teacher'   => 'Professeur',
	'nurse'     => { M => 'Infirmier',    F => 'Infirmière' },
);

# German translations keyed on lowercase English occupation.
# Values are either a plain string or a hashref with M/F keys.
Readonly my %GERMAN => (
    'teacher'    => { M => 'Lehrer',     F => 'Lehrerin' },
    'farmer'     => { M => 'Bauer',      F => 'Bauerin' },
    'bus driver' => { M => 'Busfahrer',  F => 'Busfahrerin' },
    'doctor'     => 'Arzt',   # simplified non-gendered form for fallback
);

=head1 NAME

Genealogy::Occupation - Normalise and translate genealogical occupation strings

=head1 VERSION

Version 0.02

=head1 SYNOPSIS

    use Genealogy::Occupation;

    my $normaliser = Genealogy::Occupation->new();

    my @occupations = $normaliser->normalise(
        occupation => 'Ag Lab',
        sex        => 'M',
    );
    # Returns ('Agricultural Labourer')

    # Or pass an arrayref
    my @more = $normaliser->normalise(
        occupation => ['Ag Lab', 'Ag Lab', 'Retired'],
        sex        => 'M',
    );
    # Returns ('Agricultural Labourer') - deduplicated and filtered

=head1 DESCRIPTION

Normalises occupation strings found in genealogical records, handling
common abbreviations, malformed entries, locale-specific spellings and
translations into French and German.

Designed to handle poor-quality data from genealogy software imports
where occupation strings may be abbreviated, inconsistent or use
archaic terminology.

Processing steps applied in order:

=over 4

=item 1. Filter out non-occupations (Scholar, Retired, Domestic Duties etc)

=item 2. Normalise abbreviations and malformed entries to canonical forms

=item 3. Deduplicate consecutive identical or equivalent entries (compared on pre-translation normalised forms)

=item 4. Apply locale-specific spellings via C<Lingua::EN::ABC>

=item 5. Translate to French or German if system locale requires it

=back

=head1 METHODS

=head2 new

=head3 Purpose

Constructs a new normaliser object.

=head3 API Specification

=head4 Input

    {
        warn_on_error => {
            type     => 'boolean',
            optional => 1,
            default  => 0,
        },
    }

=head4 Output

    { type => 'object', isa => 'Genealogy::Occupation' }

=head3 Arguments

=over 4

=item * C<warn_on_error> - If true, unknown occupations that cannot be
translated will emit a warning via C<carp> rather than silently falling
back to English. Optional, defaults to 0.

=back

=head3 Returns

A blessed C<Genealogy::Occupation> object.

=head3 Side Effects

None.

=head3 Notes

The system locale is detected once at construction time and cached for
the lifetime of the object.

=head3 Example

    my $normaliser = Genealogy::Occupation->new({
        warn_on_error => 1,
    });

=cut

sub new {
	my $class = shift;

	# Accept both hashref and flat list, defaulting to empty hashref
	# since all constructor arguments are optional
	my $args = Params::Get::get_params(undef, @_) // {};

	# Validate constructor arguments
	validate_strict({
		description => 'Genealogy::Occupation::new',
		input       => $args,
		schema      => $NEW_SCHEMA,
	});

	# Detect and cache the system language at construction time
	my $language = _get_language();

	return bless {
		warn_on_error => $args->{warn_on_error} // 0,
		language      => $language,
	}, $class;
}

=head2 normalise

=head3 Purpose

Normalises one or more occupation strings, applying filtering,
deduplication, abbreviation expansion, locale spelling and
translation in order.

=head3 API Specification

=head4 Input

    {
        occupation => {
            type => ['string', 'arrayref'],
        },
        sex => {
            type     => 'string',
            optional => 1,
            memberof => ['M', 'F'],
        },
    }

=head4 Output

    {
        type         => 'arrayref',
        element_type => 'string',
    }

=head3 Arguments

=over 4

=item * C<occupation> - A single occupation string or an arrayref of
occupation strings. Required.

=item * C<sex> - The sex of the person, C<'M'> or C<'F'>. Optional
but required for correct gendered translations in French and German.
Defaults to C<'M'> if not provided when a gendered translation is
needed.

=back

=head3 Returns

An arrayref of normalised occupation strings. May be empty if all
occupations were filtered out.

=head3 Side Effects

If C<warn_on_error> was set at construction and an occupation cannot
be translated, emits a warning via C<carp>.

=head3 Notes

Deduplication operates across the full list of occupations passed in.
Processing a single occupation at a time will not deduplicate across
multiple calls.

Deduplication compares the pre-translation normalised English forms, not
the translated output.  This means two consecutive identical English
occupations correctly collapse to one entry even in French or German
locales, where the translated results stored in the output array would
otherwise never match the incoming English string.

=head3 Example

    my $result = $normaliser->normalise(
        occupation => ['Ag Lab', 'Ag Lab', 'Retired'],
        sex        => 'M',
    );
    # Returns ['Agricultural Labourer']

    my $result = $normaliser->normalise(
        occupation => 'Platelayer Railway',
    );
    # Returns ['Railway Platelayer']

=cut

sub normalise {
	my $self = shift;

	# Accept both hashref and flat list
	my $args = Params::Get::get_params(undef, @_);

	# Extract and normalise occupation to an arrayref BEFORE calling
	# validate_strict.  Params::Validate::Strict does not yet support
	# union types, so passing an arrayref against a 'string' schema
	# would die.  We handle the type check here explicitly instead.
	my $raw = delete $args->{occupation};
	croak 'Genealogy::Occupation::normalise: occupation is required'
		unless defined $raw;
	my $occupations = ref($raw) eq 'ARRAY' ? $raw : [ $raw ];

	# Validate remaining named arguments (sex) strictly
	validate_strict({
		description => 'Genealogy::Occupation::normalise',
		input       => $args,
		schema      => $NORMALISE_SCHEMA,
	});

	# Default sex to M if not provided, needed for gendered translations
	my $sex = $args->{sex} // 'M';

	my $language = $self->{language} // 'en';
	my @result;
	# Track the last normalised English form for deduplication.  We cannot
	# use $result[-1] for this because @result stores the translated output;
	# comparing a translated value against a pre-translation English string
	# means consecutive identical occupations are never deduplicated in
	# French or German locales.
	my $last_normalised = '';

	foreach my $occupation (@{$occupations}) {
		# Clean up whitespace and punctuation artifacts
		$occupation =~ tr/\r\n/ /;
		$occupation =~ s/\.+$//;
		$occupation =~ s/[\(\)]//g;
		$occupation =~ s/\s\s+/ /g;
		$occupation =~ s/\s+$//;
		$occupation =~ s/\./;/g;

		# Step 1: filter out non-occupations
		next if $FILTER{lc($occupation)};
		my $filtered = 0;
		foreach my $pattern (@FILTER_PATTERNS) {
			if($occupation =~ $pattern) {
				$filtered = 1;
				last;
			}
		}
		next if $filtered;

		# Step 2: normalise the occupation string
		$occupation = _normalise_single($occupation);
		next unless length($occupation);

		# Step 3: deduplicate against the previous normalised (pre-translation)
		# entry, not against $result[-1] which holds the translated form
		next if lc($last_normalised) eq lc($occupation);
		$last_normalised = $occupation;

		# Step 4: apply locale-specific spellings for English variants
		if($language eq 'en') {
			$occupation = _apply_locale($occupation);
		}

		# Step 5: translate to target language if not English
		if($language eq 'fr') {
			$occupation = _translate_french($occupation, $sex,
				$self->{warn_on_error});
		} elsif($language eq 'de') {
			$occupation = _translate_german($occupation, $sex,
				$self->{warn_on_error});
		}

		push @result, ucfirst($occupation);
	}

	return set_return(\@result, { type => 'arrayref', element_type => 'string' });
}

# _normalise_single
#
# Purpose:
#   Normalises a single occupation string by expanding abbreviations,
#   fixing malformed entries and applying pattern-based corrections.
#
# Entry criteria:
#   $occupation - a non-empty string, already cleaned of whitespace
#
# Exit status:
#   Returns the normalised occupation string, or empty string if the
#   entry should be discarded after normalisation.
#
# Side effects:
#   None.
#
# Notes:
#   Checks the direct lookup table first for exact matches,
#   then applies pattern-based rules for more complex cases.
#   The "sic" comments mark known data quality issues in real
#   genealogy records that we intentionally handle.

sub _normalise_single {
	my $occupation = shift;

	# Check direct lookup table first for exact matches
	if(my $match = $DIRECT{lc($occupation)}) {
		return $match;
	}

	# Handle "general servant domestic" pattern variants
	if($occupation =~ $GENERAL_SERVANT_RE) {
		return 'Domestic Servant';
	}

	# Remove common suffixes that add no occupational meaning
	$occupation =~ s/\s+own account$//i;
	$occupation =~ s/^formerly //i;
	$occupation =~ s/\s+retired$//i;
	$occupation =~ s/\s+heavy worker$//i;
	$occupation =~ s/\s+own business$//i;
	$occupation =~ s/Labor/Labour/ig;

	# Reorder "X domestic" and "X dom" patterns to "Domestic X"
	if($occupation =~ /^(.+)\s(?:domestic|dom)$/i) {
		return "Domestic $1";
	}

	# Convert "works on/for X" to "X worker"
	if($occupation =~ /works?\s+(?:on|for)\s+(.+)/i) {
		return "$1 worker";
	}

	# Convert "Cleaner X" prefix form to "X cleaner"
	if($occupation =~ /^Cleaner\s+(.+)/i) {
		return "$1 cleaner";
	}

	# Reorder clerk, salesman, foreman, manager patterns
	if($occupation =~ /^Clerk\s+(.+)/i) {
		return "$1 Clerk";
	}
	if($occupation =~ /^Salesman\s+(.*)/i) {
		return "$1 Salesman";
	}
	if($occupation =~ /^Foreman\s+(.*)/i) {
		my $of = $1;
		$of =~ s/^of the //i;
		return "$of Foreman";
	}
	if($occupation =~ /^Manager\s+(.*)/i
		&& $occupation !~ /^Manager of /i
		&& $occupation !~ /Manager & /i) {
		return "$1 Manager";
	}

	# Convert "Shop Assistant X" to "X's Shop Assistant"
	if($occupation =~ /^Shop Assistant\s+(.+)/i) {
		return "$1's Shop Assistant";
	}

	# Convert "X Assistant" to "X's Assistant" for known trade forms
	if($occupation =~ /^(.+)\s+Assistant$/i) {
		my $trade = $1;
		if(lc($trade) eq 'bakers') {
			return "Baker's Assistant";
		}
		if(lc($trade) eq 'butchers') {
			return "Butcher's Assistant";
		}
		unless($trade =~ /'s$/ || lc($trade) eq 'shop') {
			return "${trade}'s Assistant";
		}
	}

	# Convert police* to "police officer"
	if($occupation =~ /police$/i) {
		return "$occupation officer";
	}

	# Convert pluralised trade forms e.g. "Builders Labourer"
	# to possessive "Builder's Labourer".
	#
	# The regex captures:
	#   $base ($1) - the word stem without the trailing 's'
	#   $last ($2) - the final character of $base (used to reconstruct
	#                the stem; not used in the guard comparison)
	#   $role ($3) - the following word
	#
	# Guard against false positives: "Bus Driver" ($base eq 'Bu') and
	# "Harness Maker" ($base eq 'Harnes') must not be rewritten.
	# Compare against $base directly - using "$base$last" is wrong
	# because it appends the final character a second time.
	if($occupation !~ /gas works/i
		&& $occupation =~ /^(.+([a-z]))s\s+([a-z]+)$/i) {
		my ($base, $last, $role) = ($1, $2, $3);
		unless(lc($base) eq 'bu' || lc($base) eq 'harnes') {
			return "${base}'s $role";
		}
	}

	# Handle "on farm" pattern
	if($occupation =~ /^(.+)\s+on farm$/i) {
		return "$1 on a farm";
	}

	return $occupation;
}

# _apply_locale
#
# Purpose:
#   Applies locale-specific English spelling variants using Lingua::EN::ABC.
#   Handles en_US (labour->labor), en_CA, and en_GB (default) variants.
#
# Entry criteria:
#   $occupation - a normalised English occupation string (may be title-cased)
#
# Exit status:
#   Returns the occupation string with locale-appropriate spellings.
#   Original capitalisation is preserved; Lingua::EN::ABC performs
#   case-insensitive substitutions and does not require lowercased input.
#
# Side effects:
#   None.
#
# Notes:
#   Reads $ENV{'LANG'} to determine the locale.
#   Defaults to British English if no locale is detected.
#   Do NOT pass lc($occupation) here - doing so strips title case that
#   cannot be fully recovered by ucfirst() alone.

sub _apply_locale {
	my $occupation = shift;

	# Apply American English spelling variants
	if(defined($ENV{'LANG'}) && ($ENV{'LANG'} =~ /^en_US/)) {
		$occupation = Lingua::EN::ABC::b2a($occupation);
		$occupation =~ s/labour/labor/ig;
		return $occupation;
	}

	# Apply Canadian English spelling variants
	if(defined($ENV{'LANG'}) && ($ENV{'LANG'} =~ /^en_CA/)) {
		return Lingua::EN::ABC::b2c($occupation);
	}

	# Default to British English spelling
	return Lingua::EN::ABC::a2b($occupation);
}

# _translate_french
#
# Purpose:
#   Translates a normalised English occupation string to French,
#   applying gendered forms where appropriate.
#
# Entry criteria:
#   $occupation    - normalised English occupation string
#   $sex           - 'M' or 'F'
#   $warn_on_error - boolean, if true carp on unknown occupation
#
# Exit status:
#   Returns the French occupation string, or the original English
#   string if no translation is available and warn_on_error is false.
#
# Side effects:
#   Carps if warn_on_error is true and no translation is found.
#
# Notes:
#   Only a subset of occupations have French translations.
#   The retired/teaching special cases are handled via regex
#   rather than the lookup table since they modify rather than
#   replace the occupation string.

sub _translate_french {
	my ($occupation, $sex, $warn_on_error) = @_;

	# Handle teaching as a special regex case
	if($occupation =~ /teaching/i) {
		return 'professeur';
	}

	# Handle retired as a suffix replacement
	$occupation =~ s/retired/\x{00E0} la retraite/i;

	# Handle X Farmer pattern
	if($occupation =~ /^(.+)\sFarmer$/i) {
		my $type = $1;
		return $sex eq 'F'
			? "Agricultrice de $type"
			: "Agriculteur de $type";
	}

	# Check the French translation lookup table
	if(my $translation = $FRENCH{lc($occupation)}) {
		if(ref($translation) eq 'HASH') {
			return $translation->{$sex} // $translation->{'M'};
		}
		return $translation;
	}

	# Fall back to English with optional warning
	if($warn_on_error) {
		Carp::carp "Genealogy::Occupation: no French translation for '$occupation'";
	}

	return $occupation;
}

# _translate_german
#
# Purpose:
#   Translates a normalised English occupation string to German,
#   applying gendered forms where appropriate.
#
# Entry criteria:
#   $occupation    - normalised English occupation string
#   $sex           - 'M' or 'F'
#   $warn_on_error - boolean, if true carp on unknown occupation
#
# Exit status:
#   Returns the German occupation string, or the original English
#   string if no translation is available and warn_on_error is false.
#
# Side effects:
#   Carps if warn_on_error is true and no translation is found.
#
# Notes:
#   Only a subset of occupations have German translations.
#   The retired and self-employed special cases are handled via
#   regex rather than the lookup table.

sub _translate_german {
	my ($occupation, $sex, $warn_on_error) = @_;

	# Handle teaching as a special regex case
	if($occupation =~ /teaching/i) {
		return $sex eq 'F' ? 'Lehrerin' : 'Lehrer';
	}

	# Handle X Farmer pattern
	if($occupation =~ /^(.+)\sFarmer$/i) {
		return $sex eq 'F' ? 'Landwirtin' : 'Landwirt';
	}

	# Handle retired and self-employed as suffix replacements
	$occupation =~ s/retired/im ruhestand/i;
	$occupation =~ s/self-employed/selbstst\x{00E4}ndig/i;

	# Check the German translation lookup table
	if(my $translation = $GERMAN{lc($occupation)}) {
		if(ref($translation) eq 'HASH') {
			return $translation->{$sex} // $translation->{'M'};
		}
		return $translation;
	}

	# Fall back to English with optional warning
	if($warn_on_error) {
		Carp::carp "Genealogy::Occupation: no German translation for '$occupation'";
	}

	return $occupation;
}

# _get_language
#
# Purpose:
#   Determines the system's default language using environment variables.
#
# Entry criteria:
#   None. Reads environment variables directly.
#
# Exit status:
#   Returns a two-letter language code string e.g. 'en', 'fr', 'de',
#   or undef if no language can be determined.
#
# Side effects:
#   None.
#
# Notes:
#   Checks in order: I18N::LangTags::Detect, LANGUAGE, LC_ALL,
#   LC_MESSAGES, LANG environment variables.
#   Returns 'en' for C locale.
#   See https://www.gnu.org/software/gettext/manual/html_node/Locale-Environment-Variables.html

sub _get_language {
	# Try I18N::LangTags::Detect first for most accurate detection
	for my $tag (I18N::LangTags::Detect::detect()) {
		if($tag =~ /^([a-z]{2})/i) {
			return lc($1);
		}
	}

	# Fall back to checking environment variables in order
	if(($ENV{'LANGUAGE'}) && ($ENV{'LANGUAGE'} =~ /^([a-z]{2})/i)) {
		return lc($1);
	}
	foreach my $variable ('LC_ALL', 'LC_MESSAGES', 'LANG') {
		my $val = $ENV{$variable};
		next unless defined($val);
		if($val =~ /^([a-z]{2})/i) {
			return lc($1);
		}
	}

	# Handle C locale explicitly
	return 'en' if(defined($ENV{'LANG'}) && $ENV{'LANG'} =~ /^C(\.|$)/);

	return;
}

=head1 AUTHOR

Nigel Horne C<< <njh@bandsman.co.uk> >>

=head1 BUGS

Please report bugs via the GitHub issue tracker:
L<https://github.com/nigelhorne/Genealogy-Occupation/issues>

=head1 TODO

=over 4

=item * Expand French and German translation tables

=item * Add support for additional languages

=item * Add C<normalise_place()> equivalent for occupation place strings

=back

=head1 SEE ALSO

=over 4

=item * L<Test Dashboard|https://nigelhorne.github.io/Genealogy-Occupation/coverage/>

=item * L<Lingua::EN::ABC>

=item * L<Params::Get>

=item * L<Params::Validate::Strict>

=item * L<Return::Set>

=back

=head1 LICENSE AND COPYRIGHT

Copyright 2026 Nigel Horne.

This program is released under the following licence: GPL2
If you use it, please let me know.

=cut

1;
