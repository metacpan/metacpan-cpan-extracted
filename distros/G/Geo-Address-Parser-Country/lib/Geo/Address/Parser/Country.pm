package Geo::Address::Parser::Country;

use strict;
use warnings;

use Carp qw(croak carp);
use Locale::Object::Country;
use Object::Configure;
use Params::Get;
use Params::Validate::Strict qw(validate_strict);
use Return::Set qw(set_return);

our $VERSION = '0.04';

# Direct component-to-country mappings, keyed on lowercase component.
# Values are either a plain country string, or a hashref with
# 'country' and optional 'warning' keys.
my %DIRECT = (
	'england'                => 'United Kingdom',
	'scotland'               => 'United Kingdom',
	'wales'                  => 'United Kingdom',
	'isle of man'            => 'United Kingdom',
	'northern ireland'       => 'United Kingdom',
	'uk'                     => 'United Kingdom',
	'england, uk'            => 'United Kingdom',
	'england uk'             => 'United Kingdom',

	# Malformed but seen in real data
	'scot'                   => {
		country => 'United Kingdom',
		warning => "country should be 'Scotland' not 'Scot'",
	},

	# US variants
	'usa'                    => 'United States',
	'us'                     => 'United States',
	'u.s.a.'                 => 'United States',
	'united states of america' => 'United States',
	'united states'          => 'United States',

	# German historical names
	'preussen'               => 'Germany',
	"preu\x{00DF}en"         => 'Germany',
	'deutschland'            => 'Germany',

	# Dutch variants
	'holland'                => 'Netherlands',
	'the netherlands'        => 'Netherlands',
	# 'nl'                   => {	# Not a common abbreviation and clashes with Newfoundland in Canada
		# country => 'Netherlands',
		# warning => 'assuming country is Netherlands',
	# },

	# Slovenian historical name
	'slovenija'              => 'Slovenia',

	# Canadian provinces/territories missing their country
	'nova scotia'            => {
		country => 'Canada',
		warning => "country 'Canada' missing from record",
	},
	'newfoundland'           => {
		country => 'Canada',
		warning => "country 'Canada' missing from record",
	},
	'nfld'                   => {
		country => 'Canada',
		warning => "country 'Canada' missing from record",
	},
	'ns'                     => {
		country => 'Canada',
		warning => "country 'Canada' missing from record",
	},
	'can.'                   => {
		country => 'Canada',
		warning => "country 'Canada' missing from record",
	},
);

# Schema for new() arguments, used by Params::Validate::Strict
my $NEW_SCHEMA = {
	us    => { type => 'object' },
	ca_en => { type => 'object' },
	ca_fr => { type => 'object' },
	au    => { type => 'object' },
	geonames => {
		type     => 'object',
		# can      => 'search',	# Geo::GeoNames is broken, it uses AUTOLOAD.  I must fix that.
		optional => 1,
	},
};

# Schema for resolve() arguments.
# component is optional: when absent, resolve() extracts it from place
# automatically as the last comma-separated token.
my $RESOLVE_SCHEMA = {
	place     => { type => 'string', min => 1 },
	component => { type => 'string', min => 1, optional => 1 },
};

# Schema for the resolve() return value
my $RESOLVE_RETURN_SCHEMA = {
	type   => 'hashref',
	schema => {
		country  => { type => 'string',   optional => 1 },
		place    => { type => 'string',   min => 1 },
		warnings => { type => 'arrayref' },
		unknown  => { type => 'boolean' },
	},
};

# Schema for normalise_place() arguments
my $NORMALISE_SCHEMA = {
	place => { type => 'string', min => 1 },
};

# Schema for the normalise_place() return value
my $NORMALISE_RETURN_SCHEMA = {
	type   => 'hashref',
	schema => {
		place    => { type => 'string', min => 1 },
		warnings => { type => 'arrayref' },
	},
};

=head1 NAME

Geo::Address::Parser::Country - Resolve a place string component to a
canonical country name

=head1 VERSION

Version 0.04

=head1 SYNOPSIS

    use Geo::Address::Parser::Country;
    use Locale::US;
    use Locale::CA;
    use Locale::AU;

    my $resolver = Geo::Address::Parser::Country->new({
        us    => Locale::US->new(),
        ca_en => Locale::CA->new(lang => 'en'),
        ca_fr => Locale::CA->new(lang => 'fr'),
        au    => Locale::AU->new(),
    });

    # Simple form: component extracted automatically from place
    my $result = $resolver->resolve(
        place => 'Ramsgate, Kent, England',
    );

    # Explicit form: caller supplies the component directly
    my $result = $resolver->resolve(
        component => 'England',
        place     => 'Ramsgate, Kent, England',
    );

    # $result->{country}  eq 'United Kingdom'
    # $result->{place}    eq 'Ramsgate, Kent, England'
    # $result->{warnings} is []
    # $result->{unknown}  is 0

=head1 DESCRIPTION

Resolves the last comma-separated component of a place string into a
canonical country name. Handles common variants, abbreviations, and
historical names found in genealogy data and other poorly-normalised
address sources.

Designed specifically to tolerate poor-quality data from software
imports where place strings may be inconsistent, abbreviated, or use
historical country names no longer in common use.

Resolution proceeds through the following steps in order:

=over 4

=item 1. Direct lookup table (covers historical names, abbreviations,
common variants)

=item 2. US state code or name via Locale::US

=item 3. Canadian province code or name via Locale::CA (English and French)

=item 4. Australian state code or name via Locale::AU

=item 5. Locale::Object::Country by name

=item 6. Geo::GeoNames search (optional, only if object provided at
construction)

=item 7. Unknown - returns with C<unknown =E<gt> 1>

=back

=head1 TODO

=over 4

=item * Complete C<normalise_place()> to handle missing commas before
country and state names in raw uncleaned input strings. Poor data
import means strings like C<"Houston TX USA"> or
C<"Some Place England"> need comma insertion before component
extraction can work correctly. This should be called before
C<resolve()> for raw uncleaned input.

=back

=head1 METHODS

=head2 new

=head3 Purpose

Constructs a new resolver object. The locale objects are used for
state and province lookups and are retained for the lifetime of the
object.

=head3 API Specification

=head4 Input

    {
        us    => { type => 'object' },  # Locale::US instance
        ca_en => { type => 'object' },  # Locale::CA English instance
        ca_fr => { type => 'object' },  # Locale::CA French instance
        au    => { type => 'object' },  # Locale::AU instance
        geonames => {                   # Optional Geo::GeoNames instance
            type     => 'object',
            optional => 1,
        },
    }

=head4 Output

    { type => 'object', isa => 'Geo::Address::Parser::Country' }

=head3 Arguments

=over 4

=item * C<us> - A L<Locale::US> instance. Required.

=item * C<ca_en> - A L<Locale::CA> instance with C<lang =E<gt> 'en'>. Required.

=item * C<ca_fr> - A L<Locale::CA> instance with C<lang =E<gt> 'fr'>. Required.

=item * C<au> - A L<Locale::AU> instance. Required.

=item * C<geonames> - An optional L<Geo::GeoNames> instance used as a
last-resort fallback when all other resolution methods fail.

=back

=head3 Returns

A blessed C<Geo::Address::Parser::Country> object.

=head3 Side Effects

None.

=head3 Notes

The locale objects are stored by reference and shared for all calls to
C<resolve()>. Constructing them once and reusing the resolver object
is more efficient than constructing a new resolver for each lookup.

C<Object::Configure> is used after validation to allow locale objects
to be supplied via environment variables or a config file rather than
always being passed explicitly.

=head3 Example

    my $resolver = Geo::Address::Parser::Country->new({
        us    => Locale::US->new(),
        ca_en => Locale::CA->new(lang => 'en'),
        ca_fr => Locale::CA->new(lang => 'fr'),
        au    => Locale::AU->new(),
    });

=cut

sub new {
	my $class = shift;

	# Accept both hashref and flat list via Params::Get
	my $args = Params::Get::get_params(undef, @_);

	# Validate all constructor arguments strictly
	validate_strict({
		description => 'Geo::Address::Parser::Country::new',
		input       => $args,
		schema      => $NEW_SCHEMA,
	});

	$args = Object::Configure::configure($class, $args);

	# Build and return the blessed object
	return bless {
		us       => $args->{us},
		ca_en    => $args->{ca_en},
		ca_fr    => $args->{ca_fr},
		au       => $args->{au},
		geonames => $args->{geonames},
	}, $class;
}

=head2 resolve

=head3 Purpose

Resolves the last comma-separated component of a place string to a
canonical country name, and returns the (possibly modified) place
string alongside any warnings generated during resolution.

=head3 API Specification

=head4 Input

    {
        place     => { type => 'string', min => 1 },           # required
        component => { type => 'string', min => 1, optional => 1 },
    }

=head4 Output

    {
        type   => 'hashref',
        schema => {
            country  => { type => 'string',   optional => 1 },
            place    => { type => 'string',   min => 1 },
            warnings => { type => 'arrayref' },
            unknown  => { type => 'boolean' },
        },
    }

=head3 Arguments

=over 4

=item * C<place> - The full place string, e.g.
C<"Ramsgate, Kent, England">. Required. May be modified by appending a
country suffix where needed.

=item * C<component> - The last comma-separated component of the place
string, e.g. C<"England">, C<"TX">, C<"NSW">. Optional. When absent,
C<resolve()> extracts it automatically as the last comma-separated
token of C<place>. When C<place> contains no comma, the entire
C<place> string is used as the component. Supplying C<component>
explicitly is useful when the caller already has it available from a
structured data source.

=back

=head3 Returns

A hashref containing:

=over 4

=item * C<country> - The canonical country name as a string, e.g.
C<"United Kingdom">. C<undef> if resolution failed.

=item * C<place> - The full place string, possibly with a country
suffix appended (e.g. C<", USA">). Always returned even if unmodified.

=item * C<warnings> - An arrayref of warning strings generated during
resolution. May be empty. The caller is responsible for acting on
these, e.g. by passing them to a C<complain()> function.

=item * C<unknown> - A boolean. True if the country could not be
resolved by any method.

=back

=head3 Side Effects

None. All warnings are returned to the caller rather than emitted
directly.

=head3 Notes

Resolution order is: direct lookup, US state, Canadian province,
Australian state, Locale::Object::Country, GeoNames (if available).
The first successful match wins.

When a US state, Canadian province, or Australian state is recognised,
the appropriate country string (C<", USA">, C<", Canada">,
C<", Australia">) is appended to C<place> if not already present.

=head3 Example

    # Simple form - component extracted automatically
    my $result = $resolver->resolve(
        place => 'Houston, TX',
    );

    # Explicit form - component supplied by caller
    my $result = $resolver->resolve(
        component => 'TX',
        place     => 'Houston, TX',
    );

    # $result->{country}     eq 'United States'
    # $result->{place}       eq 'Houston, TX, USA'
    # $result->{warnings}[0] eq 'TX: assuming country is United States'
    # $result->{unknown}     is 0

=cut

sub resolve {
	my $self = shift;

	# Accept both hashref and flat list
	my $args = Params::Get::get_params(undef, @_);

	# Validate input arguments
	validate_strict({
		description => 'Geo::Address::Parser::Country::resolve',
		input       => $args,
		schema      => $RESOLVE_SCHEMA,
	});

	my $place = $args->{place};

	# Extract the component from the place string when the caller has not
	# supplied it explicitly.  The component is the last comma-separated
	# token, trimmed of surrounding whitespace.  When the place string
	# contains no comma at all, the entire string is the component.
	my $component = $args->{component}
		// do {
			my ($c) = $place =~ /(?:^|,)\s*([^,]+?)\s*$/;
			$c // $place;
		};

	my $lc = lc($component);

	# Accumulate warnings to return to caller rather than emitting them
	my @warnings;
	my $country;

	# Step 1: check the direct lookup table first, handles historical
	# names, common abbreviations and malformed but real-world input
	if(my $match = $DIRECT{$lc}) {
		if(ref($match) eq 'HASH') {
			$country = $match->{country};
			push @warnings, $match->{warning} if $match->{warning};
		} else {
			$country = $match;
		}
	}

	# Step 2: two-letter US state code, e.g. "TX"
	elsif($component =~ /^[A-Z]{2}$/i
		&& $self->{us}{code2state}{uc($component)}) {
		$country = 'United States';
		push @warnings, "$component: assuming country is United States";
		$place = $self->_append_country($place, 'USA');
	}

	# Step 3: US state full name, e.g. "Texas"
	elsif($self->{us}{state2code}{uc($component)}) {
		$country = 'United States';
		push @warnings, "$component: assuming country is United States";
		$place = $self->_append_country($place, 'USA');
	}

	# Step 4: Canadian province code in English or French
	elsif($component =~ /^[A-Z]{2}$/i
		&& ($self->{ca_en}{code2province}{uc($component)}
		|| $self->{ca_fr}{code2province}{uc($component)})) {
		$country = 'Canada';
		push @warnings, "$component: assuming country is Canada";
		$place = $self->_append_country($place, 'Canada');
	}

	# Step 5: Canadian province full name in English or French
	elsif($self->{ca_en}{province2code}{uc($component)}
		|| $self->{ca_fr}{province2code}{uc($component)}) {
		$country = 'Canada';
		push @warnings, "$component: assuming country is Canada";
		$place = $self->_append_country($place, 'Canada');
	}

	# Step 6: Australian state code, e.g. "NSW", "VIC"
	elsif($component =~ /^[A-Z]{2,3}$/i
		&& $self->{au}{code2state}{$component}) {
		$country = 'Australia';
		push @warnings, "$component: assuming country is Australia";
		$place = $self->_append_country($place, 'Australia');
	}

	# Step 7: Australian state full name
	elsif($self->{au}{state2code}{uc($component)}) {
		$country = 'Australia';
		push @warnings, "$component: assuming country is Australia";
		$place = $self->_append_country($place, 'Australia');
	}

	# Step 8: fall back to Locale::Object::Country by name
	elsif(my $loc = Locale::Object::Country->new(name => $component)) {
		$country = $loc->name();
	}

	# Step 9: optional GeoNames fallback for anything still unresolved
	elsif($self->{geonames}) {
		$country = $self->_geonames_lookup(
			$place, $component, \@warnings
		);
	}

	# Build and validate the return structure before handing back
	my $result = {
		country  => $country,
		place    => $place,
		warnings => \@warnings,
		unknown  => defined($country) ? 0 : 1,
	};

	return set_return($result, $RESOLVE_RETURN_SCHEMA);
}

=head2 normalise_place

=head3 Purpose

Inserts missing commas into a raw, uncleaned place string so that
C<resolve()> can reliably extract the last component. Raw input from
poor-quality data imports frequently omits the commas that separate
city, state, and country tokens.

=head3 API Specification

=head4 Input

    {
        place => { type => 'string', min => 1 },
    }

=head4 Output

    {
        type   => 'hashref',
        schema => {
            place    => { type => 'string', min => 1 },
            warnings => { type => 'arrayref' },
        },
    }

=head3 Arguments

=over 4

=item * C<place> - The raw place string to normalise, e.g.
C<"Houston TX USA"> or C<"Some Place England">. Required.

=back

=head3 Returns

A hashref containing:

=over 4

=item * C<place> - The normalised place string with commas inserted
where they were missing, e.g. C<"Houston, TX, USA">. Always returned
even if no changes were made.

=item * C<warnings> - An arrayref of warning strings generated during
normalisation, e.g. noting where commas were inserted. May be empty.

=back

=head3 Side Effects

None.

=head3 Notes

This method is not yet fully implemented. It currently returns the
place string unchanged. Implementation requires scanning the token
sequence against the locale tables (US states, Canadian provinces,
Australian states, and the %DIRECT country table) to identify where
comma boundaries belong.

Call this method before C<resolve()> when working with raw input that
may lack commas:

    my $norm   = $resolver->normalise_place(place => 'Houston TX USA');
    my $result = $resolver->resolve(place => $norm->{place});

=head3 Example

    my $norm = $resolver->normalise_place(place => 'Some Place England');
    # $norm->{place}    eq 'Some Place, England'   (once implemented)
    # $norm->{warnings} contains a note about comma insertion

=cut

sub normalise_place {
	my $self = shift;

	# Accept both hashref and flat list
	my $args = Params::Get::get_params(undef, @_);

	# Validate input arguments
	validate_strict({
		description => 'Geo::Address::Parser::Country::normalise_place',
		input       => $args,
		schema      => $NORMALISE_SCHEMA,
	});

	my $place    = $args->{place};
	my @warnings;

	# TODO: scan tokens against locale tables and %DIRECT, inserting
	# commas where boundaries are identified.  For example:
	#   'Houston TX USA'   -> 'Houston, TX, USA'
	#   'Some Place England' -> 'Some Place, England'
	# This requires iterating right-to-left through whitespace-separated
	# tokens, matching each against known country/state/province names,
	# and inserting a comma immediately before the first match found.

	my $result = {
		place    => $place,
		warnings => \@warnings,
	};

	return set_return($result, $NORMALISE_RETURN_SCHEMA);
}

# _append_country
#
# Purpose:
#   Appends a country suffix to a place string if not already present.
#
# Entry criteria:
#   $self   - blessed object
#   $place  - non-empty place string
#   $suffix - country string to append, e.g. 'USA'
#
# Exit status:
#   Returns the (possibly modified) place string.
#
# Side effects:
#   None.
#
# Notes:
#   Uses a case-insensitive check to avoid double-appending.
#   E.g. 'Houston, TX' becomes 'Houston, TX, USA'.
#   'Houston, TX, USA' is returned unchanged.

sub _append_country {
	my ($self, $place, $suffix) = @_;

	# Return unchanged if suffix already present at end of string
	return $place if $place =~ /,\s*\Q$suffix\E\s*$/i;

	return "$place, $suffix";
}

# _geonames_lookup
#
# Purpose:
#   Uses the optional Geo::GeoNames object to search for a country
#   name when all other resolution methods have failed.
#
# Entry criteria:
#   $self      - blessed object with {geonames} set
#   $place     - full place string, used as the search query for
#                maximum context
#   $component - original component string, used in warning text
#   $warnings  - arrayref to push warnings onto
#
# Exit status:
#   Returns the country name string on success, undef on failure.
#
# Side effects:
#   Pushes a warning onto $warnings if a country is found via GeoNames.
#
# Notes:
#   We search on the full place string rather than just the component
#   to give GeoNames maximum context and improve result accuracy.
#   The first result is used.

sub _geonames_lookup {
	my ($self, $place, $component, $warnings) = @_;

	my $result = $self->{geonames}->search(
		q     => $place,
		style => 'FULL',
	);

	# Normalise to the first element if an arrayref was returned.
	# Guard against a bare scalar (e.g. an error string) being returned.
	if(ref($result) eq 'ARRAY') {
		$result = $result->[0];
	} elsif(!ref($result)) {
		return;		# scalar return is not a hashref — bail out cleanly
	}

	# Must be a plain hashref at this point
	return unless ref($result) eq 'HASH';

	# Extract country name; must be a defined, non-ref, non-empty string
	my $country = $result->{countryName};
	return unless defined($country)
			   && !ref($country)
			   && length($country);

	push @{$warnings}, "$component: assuming country is $country";
	return $country;
}

=head1 AUTHOR

Nigel Horne C<< <njh@nigelhorne.com> >>

=head1 REPOSITORY

L<https://github.com/nigelhorne/Geo-Address-Parser-Country>

=head1 SUPPORT

This module is provided as-is without any warranty.

Please report any bugs or feature requests to C<bug-geo-address-parser at rt.cpan.org>,
or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Geo-Address-Parser-Country>.
I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 BUGS

=over 4

=item * C<normalise_place()> is not yet implemented. It currently
returns the place string unchanged. See L</normalise_place> for
details of the planned behaviour.

=item * The step 6 Australian state code lookup uses the raw,
un-normalised component as the hash key, making it case-sensitive
unlike steps 2-5. Lowercase codes such as C<nsw> will not match.
A fix to apply C<uc($component)> consistently is pending.

=item * C<Geo::GeoNames> generates its query methods via C<AUTOLOAD>,
so C<can('search')> returns false at the Perl level even though
C<$geonames-E<gt>search(...)> works correctly at runtime. The
C<can =E<gt> 'search'> schema check has been commented out as a
temporary workaround pending a fix to C<Geo::GeoNames> itself.

=back

Please report additional bugs via the GitHub issue tracker:
L<https://github.com/nigelhorne/Geo-Address-Parser-Country/issues>

=head1 SEE ALSO

=over 4

=item * L<Test Dashboard|https://nigelhorne.github.io/Geo-Address-Parser-Country/coverage/>

=item * L<Geo::Address::Parser>

=item * L<Locale::US>

=item * L<Locale::CA>

=item * L<Locale::AU>

=item * L<Locale::Object::Country>

=item * L<Geo::GeoNames>

=item * L<Object::Configure>

=item * L<Params::Get>

=item * L<Params::Validate::Strict>

=item * L<Return::Set>

=back

=head1 LICENCE AND COPYRIGHT

Copyright 2026 Nigel Horne.

Usage is subject to GPL2 licence terms.
If you use it, please let me know.

=cut

1;
