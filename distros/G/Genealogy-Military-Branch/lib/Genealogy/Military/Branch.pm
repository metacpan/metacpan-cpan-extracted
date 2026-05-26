package Genealogy::Military::Branch;

use strict;
use warnings;
use 5.014;

use Carp qw(croak);
use I18N::LangTags::Detect;
use Params::Get;
use Object::Configure 0.19;
use Readonly;
use Params::Validate::Strict qw(validate_strict);
use Return::Set qw(set_return);

our $VERSION = '0.01';

# Schema for new() arguments
Readonly my $NEW_SCHEMA => {
	language => {
		type     => 'string',
		optional => 1,
	},
	warn_on_error => {
		type     => 'boolean',
		optional => 1,
		default  => 0,
	},
};

# Schema for detect() arguments
Readonly my $DETECT_SCHEMA => {
	text => {
		type => 'string',
	},
};

# Branch detectors tried in specificity order; first match wins.
# More-specific patterns must appear before patterns that would also
# match them: Merchant Navy before Navy, RAF before Air Force.
Readonly my @DETECTORS => (
	{ pattern => qr/\bMerchant\s+Navy\b/i,                                key => 'Merchant Navy'       },
	{ pattern => qr/\bRoyal\s+Flying\s+Corps\b|\bRFC\b/i,                 key => 'Royal Flying Corps'  },
	{ pattern => qr/\bRoyal\s+Engineers\b/i,                              key => 'Royal Engineers'     },
	{ pattern => qr/\bRoyal\s+Artillery\b/i,                              key => 'Royal Artillery'     },
	{ pattern => qr/\bRAF\b|\bRoyal\s+Air\s+Force\b/i,                   key => 'RAF'                 },
	{ pattern => qr/\bAir\s+Force\b/i,                                    key => 'air force'           },
	{ pattern => qr/\bRoyal\s+Marines\b|\bMarine\s+Corps\b|\bMarines\b/i, key => 'marines'             },
	{ pattern => qr/\bNavy\b/i,                                           key => 'navy'                },
	{ pattern => qr/\bCoast\s+Guard\b/i,                                  key => 'Coast Guard'         },
	{ pattern => qr/\bNational\s+Guard\b/i,                               key => 'National Guard'      },
	{ pattern => qr/\b(?:Army|Regiment|Soldier|Infantry|Cavalry)\b/i,     key => 'army'                },
);

# Localised branch names keyed by BCP-47 primary subtag, then internal
# English key.  Falls back to English if a key has no entry for the
# current language.
Readonly my %TRANSLATIONS => (
	'en' => {
		'navy'               => 'navy',
		'RAF'                => 'RAF',
		'army'               => 'army',
		'military'           => 'military',
		'marines'            => 'marines',
		'Royal Engineers'    => 'Royal Engineers',
		'Royal Artillery'    => 'Royal Artillery',
		'Royal Flying Corps' => 'Royal Flying Corps',
		'Merchant Navy'      => 'Merchant Navy',
		'Coast Guard'        => 'Coast Guard',
		'National Guard'     => 'National Guard',
		'air force'          => 'air force',
	},
	# French translations - subset of English keys
	'fr' => {
		'navy'      => 'marine',
		'army'      => "arm\x{e9}e",
		'RAF'       => 'RAF',
		'military'  => 'militaire',
		'marines'   => 'marines',
		'air force' => "arm\x{e9}e de l'air",
	},
	# German translations - subset of English keys
	'de' => {
		'navy'      => 'Marine',
		'army'      => 'Armee',
		'RAF'       => 'RAF',
		'military'  => "Milit\x{e4}r",
		'air force' => 'Luftwaffe',
	},
);

=head1 NAME

Genealogy::Military::Branch - Extract military branch from free-text genealogy notes

=head1 VERSION

Version 0.01

=head1 SYNOPSIS

    use Genealogy::Military::Branch;

    my $detector = Genealogy::Military::Branch->new();

    my $branch = $detector->detect(
        text => 'He served in the Royal Navy from 1914 to 1918',
    );
    # Returns 'navy'

    my $branch = $detector->detect(
        text => 'Served with the RAF in Bomber Command',
    );
    # Returns 'RAF'

    my $branch = $detector->detect(
        text => 'Some unrelated text',
    );
    # Returns 'military'

=head1 DESCRIPTION

Scans free-text military service notes from genealogy records and returns
the name of the military branch mentioned.  Returns C<'military'> (localised)
when no specific branch is recognised.

Designed to replace the C<service()> helper in the C<gedcom> and C<ged2site>
distributions, which contain duplicate implementations of the same logic.

Detection patterns cover British, US and Commonwealth branches.  The returned
string is localised to the system locale, which is detected from the
environment at construction time.

=head1 METHODS

=head2 new

=head3 Purpose

Constructs a new branch detector object.

=head3 API Specification

=head4 Input

    {
        language => {
            type     => 'string',
            optional => 1,
        },
        warn_on_error => {
            type     => 'boolean',
            optional => 1,
            default  => 0,
        },
    }

=head4 Output

    { type => 'object', isa => 'Genealogy::Military::Branch' }

=head3 Arguments

=over 4

=item * C<language> - BCP-47 primary subtag e.g. C<'en'>, C<'fr'>, C<'de'>.
If not given, the language is detected from the environment using
C<I18N::LangTags::Detect> and the standard locale environment variables,
falling back to C<'en'>.  Optional.

=item * C<warn_on_error> - If true, C<carp> is called when C<detect()> is
called and no branch is identified in the supplied text.  Optional, defaults
to 0.

=back

=head3 Returns

A blessed C<Genealogy::Military::Branch> object.

=head3 Notes

The language is detected and cached once at construction time.

=head3 Example

    my $detector = Genealogy::Military::Branch->new({
        language      => 'fr',
        warn_on_error => 1,
    });

=cut

sub new {
	my $class = shift;

	# Accept both hashref and flat list; all constructor arguments are optional
	my $args = Params::Get::get_params(undef, \@_) // {};

	# Validate constructor arguments against schema
	$args = validate_strict({
		description => 'Genealogy::Military::Branch::new',
		input       => $args,
		schema      => $NEW_SCHEMA,
	});

	# Use caller-supplied language or detect from environment
	my $language = $args->{'language'} // _get_language() // 'en';

	# Load the configuration from a config file, if provided
	$args = Object::Configure::configure($class, $args);

	# Bless and return the detector object
	return bless {
		language      => $language,
		warn_on_error => $args->{'warn_on_error'} // 0,
	}, $class;
}

=head2 detect

Scans a free-text string for references to military branches and returns
the localised branch name.

=head3 API Specification

=head4 Input

    {
        text => {
            type => 'string',
        },
    }

=head4 Output

    { type => 'string' }

=head3 Arguments

=over 4

=item * C<text> - The free-text string to scan.  Required.  May be passed
positionally as a single string.

=back

=head3 Returns

A string containing the detected branch name, localised to the language
supplied at construction.  Returns C<'military'> (or its localised
equivalent) when no branch is detected.  Never returns C<undef>.

=head3 Side Effects

If C<warn_on_error> was set true at construction and no branch is detected,
emits a warning via C<carp>.

=head3 Notes

Detection patterns are tried in order of specificity.  The first pattern
to match wins, so C<'Merchant Navy'> is correctly identified as
C<'Merchant Navy'> rather than C<'navy'>.

=head3 Example

    # Named argument form
    my $branch = $detector->detect(
        text => 'He served in the Royal Engineers during the Great War',
    );
    # Returns 'Royal Engineers'

    # Positional form
    my $branch = $detector->detect('Private in the Infantry');
    # Returns 'army'

=cut

sub detect {
	my $self = shift;

	# Normalise parameters: accept positional text string, hash or hashref
	my $params = Params::Get::get_params('text', \@_);

	# Validate that text is a required string; validate_strict croaks on failure
	my $validated = validate_strict({
		description => 'Genealogy::Military::Branch::detect',
		input       => $params,
		schema      => $DETECT_SCHEMA,
	});
	my $text = $validated->{'text'};
	croak 'Genealogy::Military::Branch::detect: text is required'
		unless defined $text;

	# Walk each detector in specificity order; the first match wins
	my $branch;
	for my $d (@DETECTORS) {
		# Each entry has a compiled pattern and an English key for translation
		if($text =~ $d->{'pattern'}) {
			$branch = $self->_translate($d->{'key'});
			last;
		}
	}

	# Fall back to the default 'military' key when nothing matched
	unless(defined $branch) {
		# Optionally alert the caller that no specific branch was identified
		Carp::carp 'Genealogy::Military::Branch: no military branch detected'
			if $self->{'warn_on_error'};
		$branch = $self->_translate('military');
	}

	# Return the validated branch string; guaranteed to be a defined string
	return set_return($branch, { type => 'string' });
}

# _translate
#
# Purpose:
#   Returns the localised string for an internal branch key, falling back
#   through language-specific -> English -> bare key.
#
# Entry criteria:
#   $self - a blessed Genealogy::Military::Branch object
#   $key  - a string matching one of the keys in %TRANSLATIONS{'en'}
#
# Exit status:
#   Returns the localised branch name string.  Never returns undef:
#   if no translation or English fallback exists, returns $key itself.
#
# Side effects:
#   None.
#
# Notes:
#   The 'en' table is the canonical fallback for all languages.
#   Keys not present in the language-specific table fall through to
#   English, allowing partial translation tables (e.g. 'fr' only
#   translates the most common branches).

sub _translate {
	my ($self, $key) = @_;

	# Get the cached language code from the object
	my $lang = $self->{'language'} // 'en';

	# Try the language-specific translation first
	if(exists $TRANSLATIONS{$lang} && exists $TRANSLATIONS{$lang}{$key}) {
		return $TRANSLATIONS{$lang}{$key};
	}

	# Fall back to English, then the bare key as a last resort
	return $TRANSLATIONS{'en'}{$key} // $key;
}

# _get_language
#
# Purpose:
#   Determines the system's default language using environment variables.
#
# Entry criteria:
#   None.  Reads environment variables directly.
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

	# Fall back to checking environment variables in priority order
	if(($ENV{'LANGUAGE'}) && ($ENV{'LANGUAGE'} =~ /^([a-z]{2})/i)) {
		return lc($1);
	}
	foreach my $variable ('LC_ALL', 'LC_MESSAGES', 'LANG') {
		my $val = $ENV{$variable};
		next unless defined($val);
		# Extract the two-letter primary language subtag
		if($val =~ /^([a-z]{2})/i) {
			return lc($1);
		}
	}

	# Handle C locale explicitly - treat as English
	return 'en' if(defined($ENV{'LANG'}) && $ENV{'LANG'} =~ /^C(\.|$)/);

	return;
}

=head1 AUTHOR

Nigel Horne C<< <njh@nigelhorne.com> >>

=head1 BUGS

Please report bugs via the GitHub issue tracker:
L<https://github.com/nigelhorne/Genealogy-Military-Branch/issues>

=head1 TODO

=over 4

=item * Add Australian, Canadian and other Commonwealth branch patterns

=item * Add more US-specific patterns (Space Force etc)

=item * Consider a companion C<Genealogy::Military::Rank> module

=back

=head1 SEE ALSO

=over 4

=item * L<Test Dashboard|https://nigelhorne.github.io/Genealogy-Military-Branch/coverage/>

=item * L<Genealogy::Occupation>

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
