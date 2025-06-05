package Locale::Places;

# TODO:	Investigate https://github.com/x88/i18nGeoNamesDB
# TODO:	US State names

use strict;
use warnings;

use Carp;
use CHI;
use Class::Debug 0.07;
use Database::Abstraction;
use File::Spec;
use Locale::Places::GB;
use Locale::Places::US;
use Module::Info;
use Params::Get;
use Scalar::Util;

=encoding utf8

=head1 NAME

Locale::Places - Translate places between different languages using http://download.geonames.org/

=head1 VERSION

Version 0.15

=cut

our $VERSION = '0.15';

=head1 SYNOPSIS

Provides the functionality for translating place names between different languages using data from GeoNames.
It currently supports places in Great Britain (GB) and the United States (US) and relies on localized databases.
For example, London is Londres in French.

=head1 METHODS

=head2 new

Create a Locale::Places object.

Arguments:

Takes different argument formats (hash or positional)

=over 4

=item * C<cache>

Place to store results.
If none is given, the results will be stored in a temporary internal cache.

=item * C<config_file>

Points to a configuration file which contains the parameters to C<new()>.
The file can be in any common format,
including C<YAML>, C<XML>, and C<INI>.
This allows the parameters to be set at run time.

=item * C<directory>

Tells the object where to find a directory called 'data' containing GB.sql and US.sql
If that parameter isn't given,
the module will attempt to find the databases,
but that can't be guaranteed.

=back

Any other options are passed to the underlying database driver.

=cut

sub new {
	my $class = shift;

	# Handle hash or hashref arguments
	my $params = Params::Get::get_params(undef, @_);

	if(!defined($class)) {
		if((scalar keys %{$params}) > 0) {
			# Locale::Places::new() used rather than Locale::Places->new()
			carp(__PACKAGE__, ' use ->new() not ::new() to instantiate');
			return;
		}

		# FIXME: this only works when no arguments are given
		$class = __PACKAGE__;
	} elsif(Scalar::Util::blessed($class)) {
		# If $class is an object, clone it with new arguments
		if($params) {
			return bless { %{$class}, %{$params} }, ref($class);
		}
		return bless $class, ref($class);
	}

	# Load the configuration from a config file, if provided

	$params = Class::Debug::setup($class, $params);

	my $directory = delete $params->{'directory'};
	if(!defined($directory)) {
		$directory = Module::Info->new_from_loaded(__PACKAGE__)->file();
		$directory =~ s/\.pm$//;
	}
	$directory = File::Spec->catfile($directory, 'data');

	if(!-d $directory) {
		unless($ENV{'AUTOMATED_TESTING'}) {	# Allow some sanity tests to be run
			Carp::carp("$class: can't find the data directory $directory: $!");
			return;
		}
	}

	$params->{'cache'} ||= CHI->new(driver => 'Memory', datastore => {}, expires_in => $params->{'cache_duration'} || $params->{'expires_in'} || '1 hour');

	Database::Abstraction::init({
		no_entry => 1,
		cache => $params->{cache},
		cache_duration => $params->{'cache_duration'} || '1 week',
		%{$params},
		directory => $directory
	});

	# Return the blessed object
	return bless {
		%{$params},
		directory => $directory
	}, $class;
}

=head2 translate

Translate a city into a different language.

Parameters:
- place (mandatory): The name of the place to translate.
- from: The source language (optional; defaults to environment language).
- to: The target language (mandatory).
- country: The country where the place is located (optional; defaults to 'GB').

Returns:
- Translated name if found, or undef if no translation exists.

Example:
    use Locale::Places;

    # Prints "Douvres"
    print Locale::Places->new()->translate({ place => 'Dover', country => 'GB', from => 'en', to => 'fr' });


=cut

sub translate
{
	my $self = shift;

	# Ensure $self is valid
	Carp::croak('translate() must be called on an object') unless(Scalar::Util::blessed($self));

	# Handle hash or hashref arguments
	my $params = Params::Get::get_params('place', @_);
	if(scalar(@_) == 1) {
		$params->{'from'} ||= 'en';
	}

	my $place = $params->{place};
	unless(defined $place) {
		Carp::carp(__PACKAGE__, ': usage: translate(place => $place, from => $language1, to => $language2 [ , country => $country ])');
		return;
	}

	# Validate 'from' and 'to' languages
	my $from = $params->{from} || $self->_get_language();
	my $to = $params->{to} || $self->_get_language();
	if(!defined($from)) {
		if(!defined($to)) {
			Carp::carp(__PACKAGE__, ': usage: translate(place => $place, from => $language1, to => $language2 [ , country => $country ])');
			return;
		}
		Carp::carp(__PACKAGE__, ": can't work out which language to translate from");
		return;
	}
	if(!defined($to)) {
		Carp::carp(__PACKAGE__, ": can't work out which language to translate to");
		return;
	}

	# Return early if 'from' and 'to' languages are the same
	return $place if($to eq $from);

	# Select database based on country, defaulting to GB
	my $country = $params->{country} || 'GB';

	my $cache_key = join('|', $place, $from, $to, $country);
	if(my $cached_result = $self->{cache}->get($cache_key)) {
		return $cached_result;
	}

	my $db = $self->{$country} ||= do {
		my $class = "Locale::Places::$country";
		$class->new(directory => $self->{directory});
	};

	# my @places = @{$db->selectall_hashref({ type => $from, data => $place, ispreferredname => 1 })};
	# ::diag("$place: $from => $to");
	my @places = $db->code2({ type => $from, data => $place, ispreferredname => 1 });
	# ::diag(__LINE__, ': Number of matches = ', scalar(@places));
	if(scalar(@places) == 0) {
		# @places = @{$db->selectall_hashref({ type => $from, data => $place })};
		@places = $db->code2({ type => $from, data => $place });
		# ::diag(__LINE__, ': Number of matches = ', scalar(@places));
	}

	if(scalar(@places) == 1) {
		if(my $data = $db->data({ type => $to, code2 => $places[0] })) {
		# if(my $data = $db->data({ type => $to, code2 => $places[0]->{'code2'} })) {
			# ::diag(__LINE__, ": $places[0]: $data");
			$self->{cache}->set($cache_key, $data);
			return $data;
		}
	} elsif(scalar(@places) > 1) {
		# Handle the case when there are more than one preferred value
		# but either not all translate or they all translate to the same
		# value, in which case the duplicate can be ignored

		# If none of them matches then assume there are no translations
		# available and return that

		my $candidate;
		my $found_something;
		foreach my $place(@places) {
			if(my $data = $db->data({ type => $to, code2 => $place })) {
				$found_something = 1;
				if(defined($candidate)) {
					if($data ne $candidate) {
						$candidate = undef;
					}
				} else {
					$candidate = $data;
				}
			}
		}
		return $candidate if(defined($candidate));
		return $place if(!defined($found_something));

		@places = $db->code2({ type => $from, data => $place, ispreferredname => 1, isshortname => undef });
		if(scalar(@places) == 1) {
			if(my $data = $db->data({ type => $to, code2 => $places[0] })) {
				$self->{cache}->set($cache_key, $data);
				return $data;
			}
			@places = $db->code2({ type => $from, data => $place, ispreferredname => 1, isshortname => 1 });
			if(scalar(@places) == 1) {
				if(my $data = $db->data({ type => $to, code2 => $places[0] })) {
					$self->{cache}->set($cache_key, $data);
					return $data;
				}
				# Can't find anything
				$self->{cache}->set($cache_key, $place);
				return $place;
			}
		} elsif(scalar(@places) == 0) {
			@places = $db->code2({ type => $from, data => $place, isshortname => undef });
			if((scalar(@places) == 1) &&
			   (my $data = $db->data({ type => $to, code2 => $places[0] }))) {
				$self->{cache}->set($cache_key, $data);
				return $data;
			}
			@places = $db->code2({ type => $from, data => $place });
			if((scalar(@places) == 1) &&
			   (my $data = $db->data({ type => $to, code2 => $places[0] }))) {
				$self->{cache}->set($cache_key, $data);
				return $data;
			}
		} else {
			# Handle multiple translations - see if they happen to be the same
			my %translations;
			foreach my $entry (@places) {
				my $data = $db->data({ type => $to, code2 => $entry });
				$translations{$data}++ if(defined $data);
			}
			if(keys(%translations) == 1) {
				return (keys %translations)[0];
			}
		}
		# foreach (@places) {
			# if(my $data = $db->data({ type => $to, code2 => $_ })) {
				# ::diag(">>>>>$data");
			# }
		# }
		Carp::croak(__PACKAGE__, ': database has ', scalar(@places), " entries for $place in language $to: ", join(', ', @places));
		# foreach my $p(@places) {
			# if(my $line = $db->fetchrow_hashref({ type => $to, code2 => $p->{'code2'} })) {
				# return $line->{'data'};
			# }
		# }
	}
	return; # Return undef if no translation is found
}

#Determines the system's default language using environment variables:
# 'LANGUAGE', 'LC_ALL', 'LC_MESSAGES', $ENV{'LANG'}.
# Defaults to English ('en') if no valid language is found.

# https://www.gnu.org/software/gettext/manual/html_node/Locale-Environment-Variables.html
# https://www.gnu.org/software/gettext/manual/html_node/The-LANGUAGE-variable.html
sub _get_language
{
	if(($ENV{'LANGUAGE'}) && ($ENV{'LANGUAGE'} =~ /^([a-z]{2})/i)) {
		return lc($1);
	}

	foreach my $variable('LC_ALL', 'LC_MESSAGES', 'LANG') {
		my $val = $ENV{$variable};
		next unless(defined($val));

		if($val =~ /^([a-z]{2})/i) {
			return lc($1);
		}
	}

	# if(defined($ENV{'LANG'}) && (($ENV{'LANG'} =~ /^C\./) || ($ENV{'LANG'} eq 'C'))) {
		# return 'en';
	# }
	return 'en' if (defined $ENV{'LANG'}) && $ENV{'LANG'} =~ /^C(\.|$)/;
	return;	# undef
}

=head2 AUTOLOAD

Translate to the given language, where the routine's name will be the target language.

    # Prints 'Virginie', since that's Virginia in French
    print $places->fr({ place => 'Virginia', from => 'en', country => 'US' });

Extracts the target language from the method name and calls C<translate()> internally.

=cut

sub AUTOLOAD
{
	our $AUTOLOAD;
	my $self = shift or return;

	# Extract the target language from the AUTOLOAD variable
	my ($to) = $AUTOLOAD =~ /::(\w+)$/;

	return if($to eq 'DESTROY');

	my %params;
        if(ref($_[0]) eq 'HASH') {
                %params = %{$_[0]};
        } elsif((scalar(@_) % 2) == 0) {
                %params = @_;
        } elsif(scalar(@_) == 1) {
                $params{'place'} = shift;
        }

	return $self->translate(to => $to, %params);
}

=head1 AUTHOR

Nigel Horne, C<< <njh at bandsman.co.uk> >>

=head1 BUGS

Only supports places in GB and US at the moment.

Canterbury no longer translates to Cantorbéry in French.
This is a problem with the data, which has this line:

    16324587	2653877	fr	Canterbury	1

which overrides the translation by setting the 'isPreferredName' flag

Can't specify below the country level.
For example, is Virginia a state, a town in Illinois or one in Minnesota?

=head1 SEE ALSO

L<Locale::Country::Multilingual> to translate country names.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Locale::Places

You can also look for information at:

=over 4

=item * MetaCPAN

L<https://metacpan.org/release/Locale-Places>

=item * GitHub

L<https://github.com/nigelhorne/Locale-Places>

=item * CPANTS

L<http://cpants.cpanauthors.org/dist/Locale-Places>

=item * CPAN Testers' Matrix

L<http://matrix.cpantesters.org/?dist=Locale-Places>

=item * CPAN Testers Dependencies

L<http://deps.cpantesters.org/?module=Locale::Places>

=item * Geonames Discussion Group

L<https://groups.google.com/g/geonames>

=back

=head1 LICENCE AND COPYRIGHT

Copyright 2020-2025 Nigel Horne.

This program is released under the following licence: GPL2

This product uses data from geonames, L<http://download.geonames.org>.

=cut

1;
