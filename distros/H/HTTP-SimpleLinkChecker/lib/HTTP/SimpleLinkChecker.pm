package HTTP::SimpleLinkChecker;
use strict;

use warnings;
no warnings;

use Exporter qw(import);

use vars qw($ERROR $VERSION @EXPORT_OK);

use Mojo::UserAgent;

@EXPORT_OK = qw(check_link);

my $UA = Mojo::UserAgent->new();
$UA->proxy->detect;
$UA->max_redirects(3);

$VERSION = '1.165';

sub check_link {
	my $link = shift;
	unless( defined $link ) {
		$ERROR = 'Received no argument';
		return;
		}

	my $transaction = $UA->head($link);
	my $response = $transaction->res;

	if( ! $response and $response->code >= 400 ) {
		$transaction = $UA->get($link);
		$response = $transaction->res;
		}

	unless( ref $response ) {
		$ERROR = 'Could not get response';
		return;
		}

	return $response->code;
	}

sub user_agent { $UA }

1;

=encoding utf8

=head1 NAME

HTTP::SimpleLinkChecker - Check the HTTP response code for a link

=head1 SYNOPSIS

	use HTTP::SimpleLinkChecker;

	my $code = HTTP::SimpleLinkChecker::check_link($url);

	unless( defined $code ) {
		print "Error: $HTTP::SimpleLinkChecker::ERROR\n";
		}

=head1 DESCRIPTION

You don't have to know anything about objected-oriented Perl, LWP, or
the HTTP module to be able to check your links. This module is
designed for the casual user. It has one function, C<check_link>, that
returns the HTTP response code that it receives when it tries to fetch
the web address passed to it. The undef value is returned for any
non-HTTP failure and the C<$HTTP::SimpleLinkChecker::ERROR> variable
is set.

The HEAD method is tried first, although if anything other than a good
status code (those less than 400) is received, another request is made
with the GET method.

The user-agent will automatically handle redirects. If you don't like
that, you can change the user agent settings before you start:

	HTTP::SimpleLinkChecker::user_agent()->max_redirects(0);

The user agent is L<Mojo::UserAgent>, so anything you do with that
module you can do with the user agent.

Note that even with the best code, no module can control how
servers decide to respond to a check, or control any of the myriad
things that can go wrong with the network between you and the remote
server. Some may filter requests based on origin IP address,
user-agent type, or any other arbitrary factor. Some servers may not
respond correctly at all. Furthermore, some servers might be
temporarily down or overloaded. I recommend that you recheck "broken"
links a couple times over a long period (like a day or two) before you
decide they are really broken.

If you are behind a firewall or proxy, this module picks up those
settings through L<Mojo::UserAgent::Proxy>'s C<detect()> method.  See
L<Mojo::UserAgent::Proxy> for more details.

=head2 Functions

=over 4

=item check_link( URL )

Returns the HTTP response code for URL.

=item user_agent

Returns a reference to the Mojo::UserAgent object.  You
can affect it directly.  See L<Mojo::UserAgent>.

	my $ua = HTTP::SimpleLinkChecker::user_agent();
	$ua->transactor->name( 'Mozilla 19.2' );

=back

=head1 SOURCE AVAILABILITY

This source is in Github:

	http://github.com/briandfoy/http-simplelinkchecker

If, for some reason, I disappear from the world, one of the other
members of the project can shepherd this module appropriately.

=head1 AUTHOR

brian d foy, C<< <bdfoy@cpan.org> >>

=head2 Contributors

=over 4

=item * Sebastian Paaske Tørholm, C<< <Eckankar@gmail.com> >>

=back

=head1 COPYRIGHT AND LICENSE

Copyright © 2004-2016, brian d foy <bdfoy@cpan.org>. All rights reserved.

This program is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
