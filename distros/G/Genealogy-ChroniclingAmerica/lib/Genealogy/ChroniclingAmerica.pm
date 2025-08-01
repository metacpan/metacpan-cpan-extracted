package Genealogy::ChroniclingAmerica;

# https://chroniclingamerica.loc.gov/search/pages/results/?state=Indiana&andtext=james=serjeant&date1=1894&date2=1896&format=json
use warnings;
use strict;

use Carp;
use LWP::UserAgent;
use JSON::MaybeXS;
use Object::Configure;
use Params::Get;
use Scalar::Util;
use Return::Set 0.02;
use URI;

=head1 NAME

Genealogy::ChroniclingAmerica - Find URLs for a given person on the Library of Congress Newspaper Records

=head1 VERSION

Version 0.06

=cut

our $VERSION = '0.06';

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

The **Genealogy::ChroniclingAmerica** module allows users to search for historical newspaper records from the **Chronicling America** archive,
maintained by the Library of Congress.
By providing a person's first name,
last name,
and state,
the module constructs and executes search queries,
retrieving URLs to relevant newspaper pages in JSON format.
It supports additional filters like date of birth and date of death,
enforces **rate-limiting** to comply with API request limits,
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

=item * C<middlename>

=item * C<date_of_birth>

=item * C<date_of_death>

=item * C<host> - The domain of the site to search, the default is L<https://chroniclingamerica.loc.gov>.

=item * C<ua> - An object that understands get and env_proxy messages,
such as L<LWP::UserAgent::Throttled>.

=item * C<min_interval> - Amount to rate limit.

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

	my $ua = $params->{'ua'} || LWP::UserAgent->new(agent => __PACKAGE__ . "/$VERSION");
	$ua->env_proxy(1) unless($params->{'ua'});

	$params = Object::Configure::configure($class, $params);

	# Set up rate-limiting: minimum interval between requests (in seconds)
	my $min_interval = $params->{min_interval} || 0;	# default: no delay

	my $rc = {
		%{$params},
		min_interval => $min_interval,
		ua => $ua,
		host => $params->{'host'} || 'chroniclingamerica.loc.gov',
	};

	my %query_parameters = ( 'format' => 'json', 'state' => ucfirst(lc($params->{'state'})) );
	if($query_parameters{'state'} eq 'District of columbia') {
		$query_parameters{'state'} = 'District of Columbia';
	}
	my $name = $params->{'firstname'};
	if($params->{'middlename'}) {
		$rc->{'name'} = "$name $params->{middlename} $params->{lastname}";
		$name .= '=' . $params->{middlename};
	} else {
		$rc->{'name'} = "$name $params->{lastname}";
	}
	$name .= "=$params->{lastname}";

	$query_parameters{'andtext'} = $name;
	if($params->{'date_of_birth'}) {
		$query_parameters{'date1'} = $params->{'date_of_birth'};
	}
	if($params->{'date_of_death'}) {
		$query_parameters{'date2'} = $params->{'date_of_death'};
	}

	my $uri = URI->new("https://$rc->{host}/search/pages/results/");
	$uri->query_form(%query_parameters);
	my $url = $uri->as_string();
	# ::diag(">>>>$url = ", $rc->{'name'});
	# print ">>>>$url = ", $rc->{'name'}, "\n";

	my $resp = $ua->get($url);

	if($resp->is_error()) {
		Carp::carp("API returned error on $url: ", $resp->status_line());
		return;
	}

	unless($resp->is_success()) {
		die $resp->status_line();
	}

	# Update last_request timestamp
	$rc->{'last_request'} = time();

	$rc->{'json'} = JSON::MaybeXS->new();
	my $data;

	eval { $data = $rc->{'json'}->decode($resp->content()) };

	if($@) {
		Carp::carp("Failed to parse JSON response: $@");
		return;
	}

	# ::diag(Data::Dumper->new([$data])->Dump());

	my $matches = $data->{'totalItems'};
	if($data->{'itemsPerPage'} < $matches) {
		$matches = $data->{'itemsPerPage'};
	}

	$rc->{'matches'} = $matches;
	if($matches) {
		$rc->{'query_parameters'} = \%query_parameters;
		$rc->{'items'} = $data->{'items'};
		$rc->{'index'} = 0;
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

	if(!defined($entry->{'url'})) {
		return $self->get_next_entry();
	}

	# Clean up OCR text
	my $text = $entry->{'ocr_eng'};

	if(!defined($text)) {
		return $self->get_next_entry();
	}

	$text =~ s/[\r\n]/ /g;
	if($text !~ /$self->{'name'}/ims) {
		return $self->get_next_entry();
	}

	# ::diag(Data::Dumper->new([$entry])->Dump());

	# Enforce rate-limiting: ensure at least min_interval seconds between requests.
	my $now = time();
	my $elapsed = $now - $self->{last_request};
	if($elapsed < $self->{min_interval}) {
		Time::HiRes::sleep($self->{min_interval} - $elapsed);
	}

	# Make the API request
	my $resp = $self->{'ua'}->get($entry->{'url'});

	# Update last_request timestamp
	$self->{last_request} = time();

	# Handle error responses
	if($resp->is_error()) {
		# print 'got: ', $resp->content(), "\n";
		Carp::carp("get_next_entry: API returned error on $entry->{url}: ", $resp->status_line());
		return;
	}

	unless($resp->is_success()) {
		die $resp->status_line();
	}

	# Decode JSON response and return PDF data
	return Return::Set::set_return($self->{'json'}->decode($resp->content())->{'pdf'}, { type => 'string', 'min' => 5, matches => qr/\.pdf$/ });
}

=head1 AUTHOR

Nigel Horne, C<< <njh at nigelhorne.com> >>

=head1 BUGS

If a middle name is given and no match is found,
it should search again without the middle name.

=head1 SEE ALSO

L<https://github.com/nigelhorne/gedcom>
L<https://chroniclingamerica.loc.gov>

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
