package Genealogy::ChroniclingAmerica;

# OLD API
# https://chroniclingamerica.loc.gov/search/pages/results/?date1=1912&state=Indiana&format=json&andtext=ralph%3Dbixler

# TODO: NEW API
# https://libraryofcongress.github.io/data-exploration/loc.gov%20JSON%20API/Chronicling_America/README.html
# https://libraryofcongress.github.io/data-exploration/loc.gov%20JSON%20API/Chronicling_America/ChronAm-download_results.html
# https://www.loc.gov/collections/chronicling-america/?dl=page&end_date=1912-12-31&ops=PHRASE&qs=ralph+bixler&searchType=advanced&start_date=1912-01-01&fo=json

use warnings;
use strict;

use Carp;
use CHI;
use LWP::UserAgent;
use JSON::MaybeXS;
use Object::Configure;
use Params::Get 0.13;
use Scalar::Util;
use Return::Set 0.02;
use URI;

=head1 NAME

Genealogy::ChroniclingAmerica - Find URLs for a given person on the Library of Congress Newspaper Records

=head1 VERSION

Version 0.07

=cut

our $VERSION = '0.07';

=head1 SYNOPSIS

    use HTTP::Cache::Transparent;  # be nice
    use Genealogy::ChroniclingAmerica;

    HTTP::Cache::Transparent::init({
	BasePath => '/tmp/cache'
    });
    my $loc = Genealogy::ChroniclingAmerica->new({
	firstname => 'John',
	lastname => 'Smith',
	state => 'Indiana',
	date_of_death => 1862
    });

    while(my $url = $loc->get_next_entry()) {
	print "$url\n";
    }

=head1 DESCRIPTION

The B<Genealogy::ChroniclingAmerica> module allows users to search for historical newspaper records from the B<Chronicling America> archive,
maintained by the Library of Congress.
By providing a person's first name,
last name,
and state,
the module constructs and executes search queries,
retrieving URLs to relevant newspaper pages in JSON format.
It supports additional filters like date of birth and date of death,
enforces B<rate-limiting> to comply with API request limits,
local caching,
and includes robust error handling and validation.
Ideal for genealogy research,
this module streamlines access to historical newspaper archives with an easy-to-use interface.

=over 4

=item * Rate-Limiting

A minimum interval between successive API calls can be enforced to ensure that the API is not overwhelmed and to comply with any request throttling requirements.

Rate-limiting is implemented using L<Time::HiRes>.
A minimum interval between API
calls can be specified via the C<min_interval> parameter in the constructor.
Before making an API call,
the module checks how much time has elapsed since the
last request and,
if necessary,
sleeps for the remaining time.

=back

=head1 SUBROUTINES/METHODS

=head2 new

Creates a Genealogy::ChroniclingAmerica object.

It takes three mandatory arguments:

=over 4

=item * C<firstname>

=item * C<lastname>

=item * C<state> - Must be the full name,
not an abbreviation.

=back

Accepts the following optional arguments:

=over 4

=item * C<cache>

A caching object.
If not provided,
an in-memory cache is created with a default expiration of one hour.

=item * C<middlename>

=item * C<date_of_birth>

=item * C<date_of_death>

=item * C<host> - The domain of the site to search, the default is L<https://chroniclingamerica.loc.gov>.

=item * C<ua> - An object that understands get and env_proxy messages,
such as L<LWP::UserAgent::Throttled>.

=item * C<min_interval> - Amount to rate limit.
Defaults to 3 seconds,
inline with L<https://libraryofcongress.github.io/data-exploration/loc.gov%20JSON%20API/Chronicling_America/README.html#rate-limits>

=back

=cut

sub new {
	my $class = shift;

	return unless(defined($class));

	# Handle hash or hashref arguments
	my $params = Params::Get::get_params(undef, \@_) || {};

	if(Scalar::Util::blessed($class)) {
		# If $class is an object, clone it with new arguments
		return bless { %{$class}, %{$params} }, ref($class);
	}

	unless($params->{'firstname'}) {
		Carp::croak('Firstname is not optional');
		return;	# Don't know why this is needed, but it is
	}

	# Fail when the input is just a set of numbers
	if($params->{'firstname'} !~ /\D/) {
		Carp::croak('Usage: ', __PACKAGE__, ": invalid input to new(), $params->{firstname}");
		return;
	}

	unless(defined($params->{'lastname'})) {
		Carp::croak('Lastname is not optional');
		return;
	}

	# Fail when the input is just a set of numbers
	if($params->{'lastname'} !~ /\D/) {
		Carp::croak('Usage: ', __PACKAGE__, ": invalid input to new(), $params->{lastname}");
		return;
	}

	unless($params->{'state'}) {
		Carp::croak('State is not optional');
		return;
	}

	if(length($params->{'state'}) == 2) {
		Carp::croak('State needs to be the full name');
		return;
	}

	# Fail when the input contains a number
	if($params->{'state'} =~ /\d/) {
		Carp::croak('Usage: ', __PACKAGE__, ": invalid input to new(), $params->{state}");
		return;
	}

	my $ua = $params->{'ua'};
	if(!defined($ua)) {
		my $ssl_opts;
		if(-r '/etc/ssl/certs/ca-certificates.crt') {	# Linux
			$ssl_opts = {
				'SSL_ca_file' => '/etc/ssl/certs/ca-certificates.crt',
				verify_hostname => 1
			}
		} elsif(-r '/opt/homebrew/etc/ca-certificates/cert.pem') {	# MacOS
			$ssl_opts = {
				'SSL_ca_file' => '/opt/homebrew/etc/ca-certificates/cert.pem',
				verify_hostname => 1
			}
		} else {
			$ssl_opts = { verify_hostname => 0 };
		}
		$ua = LWP::UserAgent->new(
			ssl_opts => $ssl_opts,
			agent => __PACKAGE__ . "/$VERSION"
		);
		$ua->env_proxy(1);
	}

	$params = Object::Configure::configure($class, $params);

	# Set up caching (default to an in-memory cache if none provided)
	my $cache = $params->{cache} || CHI->new(
		driver => 'Memory',
		global => 1,
		expires_in => '1 hour',
	);

	# Set up rate-limiting: minimum interval between requests (in seconds)
	# From https://libraryofcongress.github.io/data-exploration/loc.gov%20JSON%20API/Chronicling_America/README.html#rate-limits
	# Burst Limit: 20 requests per 1 minute, Block for 5 minutes
	my $min_interval = $params->{min_interval} || 4;	# default: four second delay

	my $rc = {
		%{$params},
		min_interval => $min_interval,
		ua => $ua,
		host => $params->{'host'} || 'www.loc.gov',
		path => 'collections/chronicling-america',
		cache => $cache,
	};

	my %query_parameters = ( 'fo' => 'json', 'location_state' => ucfirst(lc($params->{'state'})), 'ops' => 'PHRASE', 'searchType' => 'advanced' );
	if($query_parameters{'location_state'} eq 'District of columbia') {
		$query_parameters{'location_state'} = 'District of Columbia';
	}
	my $name = $params->{'firstname'};
	if($params->{'middlename'}) {
		$rc->{'name'} = "$name $params->{middlename} $params->{lastname}";
		$name .= '+' . $params->{middlename};
	} else {
		$rc->{'name'} = "$name $params->{lastname}";
	}
	$name .= "+$params->{lastname}";

	$name =~ s/\s/+/g;

	$query_parameters{'qs'} = $name;
	if($params->{'date_of_birth'}) {
		$query_parameters{'start_date'} = $params->{'date_of_birth'};
	}
	if($params->{'date_of_death'}) {
		$query_parameters{'end_date'} = $params->{'date_of_death'};
	}

	# Just scanning for one year
	$query_parameters{'start_date'} ||= $params->{'date_of_death'};
	$query_parameters{'end_date'} ||= $params->{'date_of_birth'};

	$query_parameters{'start_date'} .= '-01-01' if($query_parameters{'start_date'});
	$query_parameters{'end_date'} .= '-12-31' if($query_parameters{'end_date'});

	my $uri = URI->new("https://$rc->{host}/$rc->{path}");
	$uri->query_form(%query_parameters);
	my $url = $uri->as_string();
	# ::diag(">>>>$url = ", $rc->{'name'});
	# print ">>>>$url = ", $rc->{'name'}, "\n";

	my $items = _get_items($ua, $url);

	# Update last_request timestamp
	$rc->{'last_request'} = time();

	if(scalar(@{$items})) {
		# Add 'fo=json' to the end of each row
		my @rc;
		for my $item (@{$items}) {
			unless($item->{'id'} =~ /&fo=json$/) {
				$item->{'id'} .= '&fo=json';
			}
			push @rc, $item;
		}
		$rc->{'items'} = \@rc;
		$rc->{'index'} = 0;
		$rc->{'matches'} = scalar(@rc);
	} else {
		$rc->{'matches'} = 0;
	}

	return bless $rc, $class;
}

=head2 get_next_entry

Returns the next match as a URL.

=cut

sub get_next_entry
{
	my $self = shift;

	# Exit if no matches or index out of bounds
	return if($self->{'matches'} == 0) || ($self->{'index'} >= $self->{'matches'});

	# Retrieve the next entry and increment index
	my $entry = $self->{'items'}->[$self->{'index'}++];

	# ::diag(Data::Dumper->new([$entry])->Dump());

	# Create a cache key based on the location, date and time zone (might want to use a stronger hash function if needed)
	my $cache_key = "loc:$entry->{id}";
	if(my $cached = $self->{cache}->get($cache_key)) {
		return $cached;
	}

	# Enforce rate-limiting: ensure at least min_interval seconds between requests.
	my $now = time();
	my $elapsed = $now - $self->{last_request};
	if($elapsed < $self->{min_interval}) {
		Time::HiRes::sleep($self->{min_interval} - $elapsed);
	}

	# Make the API request
	# ::diag(__LINE__);
	# ::diag(Data::Dumper->new([$entry])->Dump());
	# ::diag($entry->{'id'});
	my $resp = $self->{'ua'}->get($entry->{'id'});
	# ::diag(__LINE__);
	# ::diag(Data::Dumper->new([$resp])->Dump());

	# Update last_request timestamp
	$self->{last_request} = time();

	# Handle error responses
	if($resp->is_error()) {
		# print 'got: ', $resp->content(), "\n";
		Carp::carp("get_next_entry: API returned error on $entry->{id}: ", $resp->status_line()) unless($resp->code() == 404);
		return;
	}

	unless($resp->is_success()) {
		Carp::croak($resp->status_line());
	}

	my $data = decode_json($resp->decoded_content());

	my $full_text = $data->{'full_text'};
	if(!defined($full_text)) {
		return $self->get_next_entry();
	}

	$full_text =~ s/[\r\n]/ /g;
        if($full_text !~ /$self->{'name'}/ims) {
                return $self->get_next_entry();
        }

	# ::diag(__LINE__);
	# ::diag($data->{full_text});
	foreach my $page(@{$data->{'page'}}) {
		if($page->{'mimetype'} eq 'application/pdf') {
			# Cache the result before returning it
			$self->{'cache'}->set($cache_key, $page->{'url'});
			return Return::Set::set_return($page->{'url'}, { type => 'string', 'min' => 5, matches => qr/\.pdf$/ });
		}
	}
}

# This is the sample code at https://libraryofcongress.github.io/data-exploration/loc.gov%20JSON%20API/Chronicling_America/ChronAm-download_results.html
#	translated into Perl

# Run P1 search and get a list of results
sub _get_items
{
	my ($ua, $url, $items_ref, $conditional, $depth) = @_;

	$items_ref ||= [];
	$conditional ||= 'True';
	$depth ||= 0;

	# Check that the query URL is not an item or resource link
	my @exclude = ('loc.gov/item', 'loc.gov/resource');
	for my $string (@exclude) {
		if (index($url, $string) != -1) {
			Carp::croak('Your URL points directly to an item or ',
			  'resource page (you can tell because "item" ',
			  'or "resource" is in the URL). Please use ',
			  'a search URL instead. For example, instead ',
			  'of "https://www.loc.gov/item/2009581123/", ',
			  'try "https://www.loc.gov/maps/?q=2009581123".');
		}
	}

	# Create URI object and add parameters
	my $uri = URI->new($url);
	$uri->query_form(
		$uri->query_form(),
		fo => 'json',
		c => 100,
		at => 'results,pagination'
	);

	# Make HTTP request
	# ::diag(__LINE__);
	# ::diag($uri);
	my $response = $ua->get($uri);

	# Check that the API request was successful
	if($response->is_success() && $response->header('Content-Type') && ($response->header('Content-Type') =~ /json/)) {
		my $data = decode_json($response->decoded_content());
		my $results = $data->{results};

		for my $result(@{$results}) {
			# Filter out anything that's a collection or web page
			my $original_format = $result->{original_format} || [];
			my $filter_out = 0;

			# Check if original_format contains "collection" or "web page"
			for my $format (@$original_format) {
				if ($format =~ /collection/i || $format =~ /web page/i) {
					$filter_out = 1;
					last;
				}
			}

			# Evaluate conditional (simplified - assumes 'True' means true)
			if ($conditional ne 'True') {
				$filter_out = 1;
			}

			unless ($filter_out) {
				# Get the link to the item record
				if (my $item = $result->{id}) {
					# Filter out links to Catalog or other platforms
					if ($item =~ /^http:\/\/www\.loc\.gov\/resource/) {
						# my $resource = $item; # Assign item to resource
						# push @$items_ref, $resource;
						push @$items_ref, $result;
					}
					if ($item =~ /^http:\/\/www\.loc\.gov\/item/) {
						push @$items_ref, $result;
					}
				}
			}
		}

		# Repeat the loop on the next page, unless we're on the last page
		# Put the $depth in case the end of list code doesn't work
		if(($depth <= 10) && defined(my $next_url = $data->{pagination}->{next})) {
			_get_items($ua, $next_url, $items_ref, $conditional, $depth + 1);
		}

		return $items_ref;
	}
	Carp::carp($url, ': ', $response->status_line());
	return $items_ref;
}

=head1 AUTHOR

Nigel Horne, C<< <njh at nigelhorne.com> >>

=head1 BUGS

If a middle name is given and no match is found,
it should search again without the middle name.

=head1 SEE ALSO

=item * L<https://github.com/nigelhorne/gedcom>

=item * L<https://chroniclingamerica.loc.gov>

=item * L<https://github.com/LibraryOfCongress/data-exploration>

=head1 SUPPORT

This module is provided as-is without any warranty.

Please report any bugs or feature requests to C<bug-genealogy-chroniclingamerica at rt.cpan.org>,
or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Genealogy-ChroniclingAmerica>.
I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

You can find documentation for this module with the perldoc command.

    perldoc Genealogy::ChroniclingAmerica

You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Genealogy-ChroniclingAmerica>

=item * Search CPAN

L<https://metacpan.org/release/Genealogy-ChroniclingAmerica>

=back

=head1 LICENSE AND COPYRIGHT

Copyright 2018-2025 Nigel Horne.

This program is released under the following licence: GPL2

=cut

1; # End of Genealogy::ChroniclingAmerica
