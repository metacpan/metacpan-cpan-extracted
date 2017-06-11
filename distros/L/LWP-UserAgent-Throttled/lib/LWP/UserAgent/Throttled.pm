package LWP::UserAgent::Throttled;

use LWP;
use Time::HiRes;

our @ISA = ('LWP::UserAgent');

=head1 NAME

LWP::UserAgent::Throttled - Throttle requests to a site

=head1 VERSION

Version 0.05

=cut

our $VERSION = '0.05';

=head1 SYNOPSIS

Some sites with REST APIs, such as openstreetmap.org, will blacklist you if you do too many requests.
LWP::UserAgent::Throttled is a sub-class of LWP::UserAgent.

    use LWP::UserAgent::Throttled;
    my $ua = LWP::UserAgent::Throttled->new();
    $ua->throttle({ 'www.example.com' => 5 });
    print $ua->get('http://www.example.com');
    sleep (2);
    print $ua->get('http://www.example.com');	# Will wait at least 3 seconds before the GET is sent

=cut

=head1 SUBROUTINES/METHODS

=head2 send_request

See L<LWP::UserAgent>.

=cut

sub send_request {
	my $self = shift;
	my ($request, $arg, $size) = @_;
	my $host = $request->uri()->host();

	if((defined($self->{'throttle'})) && $self->{'throttle'}{$host}) {
		if($self->{'lastcallended'}{$host}) {
			my $now = Time::HiRes::time();
			my $waittime = $self->{'throttle'}{$host} - (Time::HiRes::time() - $self->{'lastcallended'}{$host});

			if($waittime > 0) {
				Time::HiRes::usleep($waittime * 1e6);
			}
		}
	}
	my $rc = $self->SUPER::send_request(@_);
	$self->{'lastcallended'}{$host} = Time::HiRes::time();
	return $rc;
}

=head2 throttle

Get/set the number of seconds between each request for sites.

    my $ua = LWP::UserAgent::Throttled->new();
    $ua->throttle({ 'search.cpan.org' => 0.1, 'www.example.com' => 1 });
    print $ua->throttle('search.cpan.org'), "\n";    # prints 0.1
    print $ua->throttle('perl.org'), "\n";    # prints 0

=cut

sub throttle {
	my $self = shift;

	return if(!defined($_[0]));

	if(ref($_[0]) eq 'HASH') {
		my %throttles = %{$_[0]};

		foreach my $host(keys %throttles) {
			$self->{'throttle'}{$host} = $throttles{$host};
		}
		return;
	}

	my $host = shift;
	return $self->{'throttle'}{$host} ? $self->{'throttle'}{$host} : 0;
}

=head1 AUTHOR

Nigel Horne, C<< <njh at bandsman.co.uk> >>

=head1 BUGS

There is one global throttle level, so you can't have different levels for different sites.

=head1 SEE ALSO

L<LWP::UserAgent>

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc LWP::Throttle

You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=LWP-Throttle>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/LWP-Throttle>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/LWP-Throttle>

=item * Search CPAN

L<http://search.cpan.org/dist/LWP-Throttle/>

=back

=head1 LICENSE AND COPYRIGHT

Copyright 2017 Nigel Horne.

This program is released under the following licence: GPL2

=cut

1; # End of LWP::Throttle
