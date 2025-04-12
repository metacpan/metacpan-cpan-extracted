package LWP::UserAgent::Throttled;

use warnings;
use strict;
use LWP;
use Time::HiRes;
use LWP::UserAgent;

our @ISA = ('LWP::UserAgent');

=head1 NAME

LWP::UserAgent::Throttled - Throttle requests to a site

=head1 VERSION

Version 0.13

=cut

our $VERSION = '0.13';

=head1 SYNOPSIS

Some sites with REST APIs, such as openstreetmap.org, will blacklist you if you do too many requests.
LWP::UserAgent::Throttled is a sub-class of LWP::UserAgent.

    use LWP::UserAgent::Throttled;
    my $ua = LWP::UserAgent::Throttled->new();
    $ua->throttle({ 'www.example.com' => 5 });
    print $ua->get('http://www.example.com/page1.html');
    sleep (2);
    print $ua->get('http://www.example.com/page2.html');	# Will wait at least 3 seconds before the GET is sent

=cut

=head1 SUBROUTINES/METHODS

=head2 send_request

See L<LWP::UserAgent>.

=cut

sub send_request {
	# my ($request, $arg, $size) = @_;

	my $self = shift;
	my $request = $_[0];
	my $host = $request->uri()->host();

	if((defined($self->{'throttle'})) && $self->{'throttle'}{$host} && $self->{'lastcallended'}{$host}) {
		my $waittime = $self->{'throttle'}{$host} - (Time::HiRes::time() - $self->{'lastcallended'}{$host});

		if($waittime > 0) {
			Time::HiRes::usleep($waittime * 1e6);
		}
	}
	my $rc;
	if(defined($self->{'_ua'})) {
		$rc = $self->{'_ua'}->send_request(@_);
	} else {
		$rc = $self->SUPER::send_request(@_);
	}
	$self->{'lastcallended'}{$host} = Time::HiRes::time();
	return $rc;
}

=head2 throttle

Get/set the number of seconds between each request for sites.

    my $ua = LWP::UserAgent::Throttled->new();
    $ua->throttle({ 'search.cpan.org' => 0.1, 'www.example.com' => 1 });
    print $ua->throttle('search.cpan.org'), "\n";	# prints 0.1
    print $ua->throttle('perl.org'), "\n";	# prints 0

When setting a throttle it returns itself,
so you can daisy chain messages.

=cut

sub throttle {
	my ($self, $args) = @_;

	return unless(defined($args));

	if(ref($args) eq 'HASH') {
		# Merge the new throttles in with the previous throttles
		$self->{throttle} = { %{$self->{throttle} || {}}, %{$args} };
		return $self;
	}

	return $self->{throttle}{$args} || 0;
}

=head2 ua

Get/set the user agent if you wish to use that rather than itself

    use LWP::UserAgent::Cached;

    $ua->ua(LWP::UserAgent::Cached->new(cache_dir => '/home/home/.cache/lwp-cache'));
    my $resp = $ua->get('https://www.nigelhorne.com');	# Throttles, then checks cache, then gets

=cut

sub ua {
	my($self, $ua) = @_;

	if($ua) {
		$self->{_ua} = $ua;
	}

	return $self->{_ua};
}

=head1 AUTHOR

Nigel Horne, C<< <njh at bandsman.co.uk> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-lwp-useragent-throttled at rt.cpan.org>,
or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=LWP-UserAgent-Throttled>.
I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

Redirects to other domains can confuse it, so you need to program those manually.

=head1 SEE ALSO

L<LWP::UserAgent>

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc LWP::UserAgent::Throttled

You can also look for information at:

=over 4

=item * MetaCPAN

L<https://metacpan.org/release/LWP-UserAgent-Throttled>

=item * RT: CPAN's request tracker

L<https://rt.cpan.org/NoAuth/Bugs.html?Dist=LWP-UserAgent-Throttled>

=item * CPANTS

L<http://cpants.cpanauthors.org/dist/LWP-UserAgent-Throttled>

=item * CPAN Testers' Matrix

L<http://matrix.cpantesters.org/?dist=LWP-UserAgent-Throttled>

=item * CPAN Testers Dependencies

L<http://deps.cpantesters.org/?module=LWP::UserAgent::Throttled>

=back

=head1 LICENSE AND COPYRIGHT

Copyright 2017-2025 Nigel Horne.

This program is released under the following licence: GPL2

=cut

1; # End of LWP::Throttle
