package Genealogy::ChroniclingAmerica;

# https://chroniclingamerica.loc.gov/search/pages/results/?state=Indiana&andtext=james=serjeant&date1=1894&date2=1896&format=json
use warnings;
use strict;
use LWP::UserAgent;
use JSON;
use URI;
use Carp;

=head1 NAME

Genealogy::ChroniclingAmerica - Find URLs for a given person on the Library of Congress Newspaper Records

=head1 VERSION

Version 0.01

=cut

our $VERSION = '0.01';

=head1 SYNOPSIS

    use HTTP::Cache::Transparent;  # be nice
    use Genealogy::ChroniclingAmerica;

    HTTP::Cache::Transparent::init({
	BasePath => '/var/cache/loc'
    });
    my $f = Genealogy::ChroniclingAmerica->new({
	firstname => 'John',
	lastname => 'Smith',
	country => 'Indiana',
	date_of_death => 1862
    });

    while(my $url = $f->get_next_entry()) {
	print "$url\n";
    }
}

=head1 SUBROUTINES/METHODS

=head2 new

=cut

sub new {
	my $proto = shift;
	my $class = ref($proto) || $proto;

	return unless(defined($class));

	my %args;
	if(ref($_[0]) eq 'HASH') {
		%args = %{$_[0]};
	} elsif(ref($_[0])) {
		Carp::croak("Usage: __PACKAGE__->new(%args)");
	} elsif(@_ % 2 == 0) {
		%args = @_;
	}

	die "First name is not optional" unless($args{'firstname'});
	die "Last name is not optional" unless($args{'lastname'});
	die "State is not optional" unless($args{'state'});

	die "State needs to be the full name" if(length($args{'state'}) == 2);

	my $ua = delete $args{ua} || LWP::UserAgent->new(agent => __PACKAGE__ . "/$VERSION");
	$ua->env_proxy(1);

	my $rc = { ua => $ua, };
	$rc->{'host'} = $args{'host'} || 'chroniclingamerica.loc.gov';

	my %query_parameters = ( 'format' => 'json', 'state' => ucfirst(lc($args{'state'})) );
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

	my $resp = $ua->get($url);

	if($resp->is_error()) {
		Carp::carp("API returned error: on $url ", $resp->status_line());
		return {};
	}

	unless($resp->is_success()) {
		die $resp->status_line();
	}

	$rc->{'json'} = JSON->new();
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

	return if($self->{'matches'} == 0);

	if($self->{'index'} >= $self->{'matches'}) {
		return;
	}

	my $entry = @{$self->{'items'}}[$self->{'index'}];
	$self->{'index'}++;

	if(!defined($entry->{'url'})) {
		return $self->get_next_entry();
	}

	my $text = $entry->{'ocr_eng'};

	if($text !~ /$self->{'name'}/i) {
		return $self->get_next_entry();
	}

	# ::diag(Data::Dumper->new([$entry])->Dump());

	my $resp = $self->{'ua'}->get($entry->{'url'});

	if($resp->is_error()) {
		Carp::carp("API returned error: on $entry->{url} ", $resp->status_line());
		return;
	}

	unless($resp->is_success()) {
		die $resp->status_line();
	}

	my $data = $self->{'json'}->decode($resp->content());
	return $data->{'pdf'};
}

=head1 AUTHOR

Nigel Horne, C<< <njh at bandsman.co.uk> >>

=head1 BUGS

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

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Genealogy-ChroniclingAmerica>

=item * Search CPAN

L<https://metacpan.org/release/Genealogy-ChroniclingAmerica>

=back

=head1 LICENSE AND COPYRIGHT

Copyright 2018 Nigel Horne.

This program is released under the following licence: GPL2

=cut

1; # End of Genealogy::ChroniclingAmerica
