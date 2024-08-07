#!/usr/bin/env perl

use strict;
use warnings;
use Test::Most tests => 4;
use constant SITE =>'https://api.github.com/repos/nigelhorne/Geo-Coder-GooglePlaces/issues';
use constant URL =>'api.github.com';

RT: {
	# RT system, deprecated
	SKIP: {
		if($ENV{AUTHOR_TESTING}) {
			eval 'use WWW::RT::CPAN';	# FIXME: use a REST client
			if($@) {
				diag('WWW::RT::CPAN required to check for open tickets');
				skip('WWW::RT::CPAN required to check for open tickets', 3);
			} elsif(my @rc = @{WWW::RT::CPAN::list_dist_active_tickets(dist => 'Geo-Coder-GooglePlaces')}) {
				ok($rc[0] == 200);
				ok($rc[1] eq 'OK');
				my @tickets = $rc[2] ? @{$rc[2]} : ();

				foreach my $ticket(@tickets) {
					diag($ticket->{id}, ': ', $ticket->{title}, ', broken since ', $ticket->{'broken_in'}[0]);
				}
				ok(scalar(@tickets) == 0);
			} else {
				diag("Can't connect to rt.cpan.org");
				skip("Can't connect to rt.cpan.org", 3);
			}
		} else {
			diag('Author tests not required for installation');
			skip('Author tests not required for installation', 3);
		}
	}
}

GITHUB: {
	# https://docs.github.com/en/rest/reference/issues#list-repository-issues
	SKIP: {
		if($ENV{'AUTHOR_TESTING'}) {
			eval 'use JSON';
			if($@) {
				diag('JSON required to check for open tickets');
				skip('JSON required to check for open tickets', 1);
			} else {
				eval 'use IO::Socket::INET';
				if($@) {
					diag('IO::Socket::INET required to check for open tickets');
					skip('IO::Socket::INET required to check for open tickets', 1);
				} else {
					my $s = IO::Socket::INET->new(
						PeerAddr => SITE,
						Timeout => 5
					);
					if($s) {
						eval 'use LWP::Simple';

						if($@) {
							diag('LWP::Simple required to check for open tickets');
							skip('LWP::Simple required to check for open tickets', 1);
						} elsif(my $data = LWP::Simple::get(URL)) {
							my $json = JSON->new()->utf8();
							my @issues = @{$json->decode($data)};
							# diag(Data::Dumper->new([\@issues])->Dump());
							if($ENV{'TEST_VERBOSE'}) {
								foreach my $issue(@issues) {
									# diag($issues[0]->{'user'}->{'login'});
									diag($issue->{'html_url'});
								}
							}
							cmp_ok(scalar(@issues), '==', 0, 'There are no opentickets');
						} else {
							diag(URL, ': failed to get data');
							fail('Failed to get data');
						}
					} else {
						diag("Can't connect to ", SITE);
						skip("Can't connect to " . SITE, 1);
					}
				}
			}
		} else {
			diag('Author tests not required for installation');
			skip('Author tests not required for installation', 1);
		}
	}
}
