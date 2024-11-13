package Genealogy::ChroniclingAmerica;

# https://chroniclingamerica.loc.gov/search/pages/results/?state=Indiana&andtext=james=serjeant&date1=1894&date2=1896&format=json
use warnings;
use strict;

use LWP::UserAgent;
use JSON::MaybeXS;
use Scalar::Util;
use URI;
use Carp;

=head1 NAME

Genealogy::ChroniclingAmerica - Find URLs for a given person on the Library of Congress Newspaper Records

=head1 VERSION

Version 0.04

=cut

our $VERSION = '0.04';

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

=head1 SUBROUTINES/METHODS

=head2 new

Creates a Genealogy::ChroniclingAmerica object.

It takes three mandatory arguments state, firstname and lastname.
State must be the full name, not an abbreviation.

There are four optional arguments: middlename, date_of_birth, date_of_death, ua and host:
host is the domain of the site to search, the default is chroniclingamerica.loc.gov.
ua is a pointer to an object that understands get and env_proxy messages, such
as L<LWP::UserAgent::Throttled>.

=cut

sub new {
	my $class = shift;

	return unless(defined($class));

	# Handle hash or hashref arguments
	my %args;
	if(ref($_[0]) eq 'HASH') {
		%args = %{$_[0]};
	} elsif(ref($_[0]) || !defined($_[0])) {
		Carp::croak('Usage: ', __PACKAGE__, '->new(%args)');
	} elsif(@_ % 2 == 0) {
		%args = @_;
	}

	if(!defined($class)) {
		# Using Genealogy::ChroniclingAmerica->new(), not Genealogy::ChroniclingAmerica::new()
		# carp(__PACKAGE__, ' use ->new() not ::new() to instantiate');
		# return;

		# FIXME: this only works when no arguments are given
		$class = __PACKAGE__;
	} elsif(Scalar::Util::blessed($class)) {
		# If $class is an object, clone it with new arguments
		return bless { %{$class}, %args }, ref($class);
	}

	unless($args{'firstname'}) {
		Carp::croak('First name is not optional');
		return;	# Don't know why this is needed, but it is
	}
	unless(defined($args{'lastname'})) {
		Carp::croak('Last name is not optional');
		return;
	}
	unless($args{'state'}) {
		Carp::croak('State is not optional');
		return;
	}

	if(length($args{'state'}) == 2) {
		Carp::croak('State needs to be the full name');
		return;
	}

	my $ua = $args{'ua'} || LWP::UserAgent->new(agent => __PACKAGE__ . "/$VERSION");
	$ua->env_proxy(1) unless($args{'ua'});

	my $rc = {
		ua => $ua,
		host => $args{'host'} || 'chroniclingamerica.loc.gov'
	};

	my %query_parameters = ( 'format' => 'json', 'state' => ucfirst(lc($args{'state'})) );
	if($query_parameters{'state'} eq 'District of columbia') {
		$query_parameters{'state'} = 'District of Columbia';
	}
	my $name = $args{'firstname'};
	if($args{'middlename'}) {
		$rc->{'name'} = "$name $args{middlename} $args{lastname}";
		$name .= "=$args{middlename}";
	} else {
		$rc->{'name'} = "$name $args{lastname}";
	}
	$name .= "=$args{lastname}";

	$query_parameters{'andtext'} = $name;
	if($args{'date_of_birth'}) {
		$query_parameters{'date1'} = $args{'date_of_birth'};
	}
	if($args{'date_of_death'}) {
		$query_parameters{'date2'} = $args{'date_of_death'};
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

	$rc->{'json'} = JSON::MaybeXS->new();
	my $data = $rc->{'json'}->decode($resp->content());

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

	# Make the API request
	my $resp = $self->{'ua'}->get($entry->{'url'});

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
	return $self->{'json'}->decode($resp->content())->{'pdf'};
}

=head1 AUTHOR

Nigel Horne, C<< <njh at bandsman.co.uk> >>

=head1 BUGS

If a middle name is given and no match is found,
it should search again without the middle name.

Please report any bugs or feature requests to C<bug-genealogy-chroniclingamerica at rt.cpan.org>,
or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Genealogy-ChroniclingAmerica>.
I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SEE ALSO

L<https://github.com/nigelhorne/gedcom>
L<https://chroniclingamerica.loc.gov>

=head1 SUPPORT

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

Copyright 2018-2024 Nigel Horne.

This program is released under the following licence: GPL2

=cut

1; # End of Genealogy::ChroniclingAmerica
