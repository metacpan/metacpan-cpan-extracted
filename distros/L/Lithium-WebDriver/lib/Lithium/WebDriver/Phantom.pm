package Lithium::WebDriver::Phantom;

use strict;
use warnings;
use Time::HiRes qw/sleep/;
use LWP::UserAgent;
use Lithium::WebDriver;
use Lithium::WebDriver::Utils;

use base 'Lithium::WebDriver';

sub connect
{
	my ($self, $url) = @_;
	debug "Connecting from phantom driver";
	$self->{ua} ||= "default";
	debug "Testing if Stand Alone ghostdriver";
	$self->{base} =~ s/\/wd\/hub$//;
	my $timer = 0;
	my $connected = 0;
	local $SIG{ALRM} = sub { die 1; };
	alarm $self->{connection_timeout};
	our $res = {};
	eval {
		while (!$connected) {
			$res = $self->{LWP}->get($self->{base});
			dump $res;
			if ($res->is_success) {
				if ($res->content =~ m/selenium/i) {
					$self->{stand_alone} = 0;
					$self->{base}  .= "/wd/hub";
				} else {
					$self->{stand_alone} = 1;
				}
				$self->{host} = $self->{base};
				$connected = 1;
			} elsif ($res->code == 404) {
				debug "404 on standalone detection, attempting alternative path";
				$res = $self->{LWP}->get($self->{base}."/sessions");
				dump $res;
				if ($res->is_success) {
					$self->{stand_alone} = 1;
					debug "Detected standalone setting base is: ".$self->{base};
					$self->{host} = $self->{base};
					$connected = 1;
				} else {
					sleep 0.1;
				}
			} else {
				sleep 0.1;
			}
		}
		alarm 0;
		1;
	} or do {
		alarm 0;
		if (scalar(keys(%$res)) && $res->status_line) {
			error "There was an error connecting to: ".$self->{base}
				.": ".$res->status_line;
			dump $res->content;
		} else {
			error "There was an error connecting to: ".$self->{base};
		}
		die error "Unable to determine standalone or hub, host is [".$self->{host}."]";
	};
	$self->SUPER::connect($url);
}

=head1 NAME

Lithium::WebDriver::Phantom - Driver specific functions for connecting to phantomjs.

=head1 DESCRIPTION

The selenium hub/standalones and the phantomjs webdriver behave slightly different.
The major difference is the base url path, while the hub and standalone have an added
/wd/hub, the phantomjs webdriver has a base path of just /.

=head1 FUNCTIONS

=head2 connect($url)

Overrides Driver->connect, to as to set the phantomjs user-agent string and
to test if the the end point is a selenium hub or a stand alone ghost driver

Notice: it is no longer necessary to call visit after giving a root url, although
this behavior is still supported.

=head1 AUTHOR

Written by Dan Molik C<< <dan at d3fy dot net> >>

=cut

1;
