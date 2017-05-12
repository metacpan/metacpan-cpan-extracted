package Golger;

use strict;
use warnings;
use 5.008002;

use AnyEvent::WebSocket::Client;
use JSON::Any;

our $VERSION = version->parse('v0.1.0');

sub connect {
	my $connect_info = shift;
	my $format = shift;
 	if (defined $format) {
 		if (ref $format eq "ARRAY") {
 			my @format = @$format;
			$format = sub {
				my $omsg = JSON::Any -> jsonToObj ($_[0]);
				my @fm = @{$omsg}{ @format };
				print join " ", map {defined ($_) ? $_ : "N/A" } @fm, "\n";
			}
 		} elsif (ref $format ne "CODE") {
			die "oh noes! this ain't no coderef";
		}
 	} else {
 		$format = sub {
 			my $omsg = JSON::Any -> jsonToObj ($_[0]);
 			my @fm = @{$omsg}{ qw/time host service description/ };
			print join " ", map {defined ($_) ? $_ : "N/A" } @fm, "\n";
 		}
 	}
	my $client = AnyEvent::WebSocket::Client -> new();
	$client -> connect($connect_info)
        -> cb(
					sub {
						our $connection = eval { shift -> recv };
						if ($@) {
							warn $@;
							return
						}
						$connection->on(each_message => sub {
								my($connection, $message) = @_;
								if ($message -> isa('AnyEvent::WebSocket::Message')) {
									if (exists $message -> {body}) {
										$format->($message -> {body});
									} else {
										warn "oh noes! message has no body";
										return
									}
								} else {
									warn "message is garbled";
									return
								}
							}
						);
					}
				);
	AnyEvent->condvar->recv;
}

1;

