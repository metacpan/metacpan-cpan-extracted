package HTTP::Curl;

use strict;
use warnings;
our $VERSION = '1.07';

use Net::Curl::Easy qw(/^CURLOPT_/ CURLE_OK CURLINFO_EFFECTIVE_URL /^CURLE_/ CURLAUTH_ANY);


BEGIN {
	Net::Curl::Easy->can('CURLOPT_ACCEPT_ENCODING') or die "Rebuild Net::Curl with libcurl 7.21.6 or newer\n";
	Net::Curl::Easy->can('CURLOPT_COOKIEFILE')      or die "Rebuild curl with Cookies support\n";
}

sub _prepare {
	my ($easy, $url, $opt) = @_;

	$easy->setopt(CURLOPT_URL, $url);
	$easy->setopt(CURLOPT_VERBOSE, 1) if $$opt{verbose};

	my @headers = ();
	@headers = map { $_ . ": " . $$opt{headers}{$_} } keys %{$$opt{headers}} if $$opt{headers};

	if ($$opt{method} and $$opt{method} eq "POST" ) {
		$easy->setopt(CURLOPT_POST, 1);
		unless ($$opt{headers}{"Content-Type"}) {
			push @headers, "Content-Type: application/x-www-form-urlencoded";
		}
		if (ref $$opt{body} eq "CODE") {
			$easy->setopt(CURLOPT_POST, 1);
			$easy->setopt(CURLOPT_UPLOAD, 1);
			$easy->setopt(CURLOPT_CUSTOMREQUEST, "POST");

			my $buf = "";
			my $body_sub = $$opt{body};
			$easy->setopt(CURLOPT_READFUNCTION, sub {
				my ( $easy, $maxlen, $uservar ) = @_;
				$buf ||= $body_sub->();
				if ($buf) {
					return \ substr $buf, 0, $maxlen, "";
				} else {
					return CURLE_OK;
				}
			} );
		} else {
			$easy->setopt(CURLOPT_POSTFIELDS, $$opt{body});
		}
	}

	$easy->setopt(CURLOPT_HTTPHEADER, \@headers) if @headers;

	my $max_redirect = defined $$opt{max_redirect} ? $$opt{max_redirect} : 7;
	if ($max_redirect) {
		$easy->setopt(CURLOPT_FOLLOWLOCATION, 1);
		$easy->setopt(CURLOPT_MAXREDIRS, $max_redirect);
	}


	if ($$opt{cookie}) {
		$easy->setopt(CURLOPT_COOKIEFILE, $$opt{cookie});
		$easy->setopt(CURLOPT_COOKIEJAR,  $$opt{cookie});
	} elsif (defined $$opt{cookie}) {
		$easy->setopt(CURLOPT_COOKIEFILE, "");
	}

	my $on_header = $$opt{on_header};
	my $on_body   = $$opt{on_body};

	$easy->setopt(CURLOPT_WRITEHEADER, \ my $_headers);

	my $body = "";
	$easy->setopt(CURLOPT_FILE, \$body) unless $on_body;

	$easy->setopt(CURLOPT_USERAGENT, $$opt{agent}) if $$opt{agent};
	$easy->setopt(CURLOPT_REFERER, $$opt{referer}) if $$opt{referer};
	$easy->setopt(CURLOPT_TIMEOUT, $$opt{timeout}) if $$opt{timeout};

	if (my $proxy = $$opt{proxy}) {
		$proxy =~ s!^socks://!socks5://!;
		$easy->setopt(CURLOPT_PROXY, $proxy);
		if (my $proxy_auth = $$opt{proxy_auth}) {
			$easy->setopt(CURLOPT_PROXYAUTH, CURLAUTH_ANY);
			$easy->setopt(CURLOPT_PROXYUSERPWD, join ":", @$proxy_auth);
		}
	}

	$easy->setopt(CURLOPT_ACCEPT_ENCODING, "") if $$opt{compressed} or $$opt{gzip};

	$easy->setopt(CURLOPT_FORBID_REUSE, $$opt{persistent} ? 0 : 1) if exists $$opt{persistent};

	my ($is_success, $headers, $redirects);

	my $max_size = $$opt{max_size};
	my $aborted_by_max_size = 0;

	my $body_size = 0;

	if ($max_size or $on_header or $on_body) {
		my $cb_write = sub {
			my ($easy, $data, $uservar) = @_;
			my $size = length $data;
			$body_size += $size;
			if ($on_header) {
				($is_success, $headers, $redirects) = _headers($easy, $url, $_headers);
				my $r = $on_header->($is_success, $headers, $redirects);
				$on_header = undef;
				$r or return 0;
			}
			if ($on_body) {
				$on_body->($data) or return 0;
			} else {
				$body .= $data;
			}
			if ($max_size and $body_size > $max_size) {
				$aborted_by_max_size = 1;
				return 0;
			}
			return $size;
		};
		$easy->setopt(CURLOPT_WRITEFUNCTION, $cb_write);
	} else {
		$easy->setopt(CURLOPT_WRITEFUNCTION, undef);
	}

	my $finish = sub {
		my ($easy, $result) = @_;

		if ($_headers) {
			($is_success, $headers, $redirects) = _headers($easy, $url, $_headers) unless $headers;
			if ($result == CURLE_WRITE_ERROR and $aborted_by_max_size) {
				$is_success = 0;
				$$headers{"Status"} = 599;
				$$headers{"Reason"} = "MaxSize";
			} elsif ($result == CURLE_OPERATION_TIMEDOUT) {
				$is_success = 0;
				$$headers{"Status"} = 599;
				$$headers{"Reason"} = "Timeout";
			} elsif ($result == CURLE_RECV_ERROR) {
				$is_success = 0;
				unless ($$headers{"Status"} == 407) {
					$$headers{"Status"} = 599;
					$$headers{"Reason"} = "$result";
				}
			}
			$easy = undef;
			return ($is_success, $body, $headers, $redirects);
		} else {
			$easy = undef;
			return (0, undef, { Status => 500, Reason => "$result", URL => $url }, []);
		}

	};

	return $finish;
}


sub _do_http {
	my ($easy, $url, $opt) = @_;

	my $finish = _prepare($easy, $url, $opt);

	eval { $easy->perform() };
	if ($@) {
		if (ref $@ eq "Net::Curl::Easy::Code" ) {
			return $finish->($easy, $@);
		} else {
			die $@;
		}
	} else {
		return $finish->($easy, CURLE_OK);
	}
}


sub do_http {
	if (@_ == 5) {
		my ($multi_ev, $easy, $url, $opt, $cb) = @_;
		my $finish = _prepare($easy, $url, $opt);
		if ($multi_ev) {
			my $timeout = $$opt{timeout} || 300;
			$multi_ev->($easy, sub { $cb->($finish->(@_)) }, $timeout);
		} else {
			$cb->(_do_http($easy, $url, $opt));
		}
	} else {
		goto &_do_http;
	}
}



sub _parse_headers {
	my ($url, $h) = @_;

	if ($h =~ m/^\r?\n$/) {
		$h = "HTTP/0.9 200 Assumed OK\r\n";
	}

	$h =~ s/(,\r*\n)\s+/, /g; # fix for old standard, multyline header

	my ($status_line, @h) = split /\r?\n/, $h;
	my ($protocol, $status, $reason) = $status_line =~ m/(HTTP\/\d(?:\.\d)?)\s+(\d+)(?:\s+(.+))?/;

	my %h = ();
	foreach (@h) {
		my ($k, $v) = split /:\s*/, $_, 2;
		my $h = lc $k;
		push @{$h{$h}}, $v if $v;
	}

	return {
		Protocol => $protocol,
		Status   => $status,
		Reason   => ($reason || ""),
		URL      => $url,
		map { $_ => join ",", @{$h{$_}} } keys %h
	};
}


sub __headers {
	my ($url, $htext, @h) = @_;
	my $h = _parse_headers($url, $htext);
	if (@h) {
		return $h, __headers($$h{location} || $url, @h);
	} else {
		return $h;
	}
}


sub _headers {
	my ($easy, $url, $headers) = @_;

	my ($h, @hr) = reverse __headers($url, split /\r?\n\r?\n/, $headers);

	my $status = $$h{Status};
	my $is_success = ($status >= 200 and $status < 300) ? 1 : 0;

	$$h{URL} = $easy->getinfo(CURLINFO_EFFECTIVE_URL);

	return $is_success, $h, \@hr;
}



1;

__END__


=head1 NAME

HTTP::Curl - HTTP interface for Net::Curl (clone of HTTP::Any::Curl)

=head1 SYNOPSIS

 use HTTP::Curl;
 my ($is_success, $body, $headers, $redirects) = HTTP::Curl::do_http($easy, $url, $opt);

=head1 DESCRIPTION

=head2 Curl

 use Net::Curl::Easy;
 use HTTP::Curl;

 my $easy = Net::Curl::Easy->new();

 my ($is_success, $body, $headers, $redirects) = HTTP::Curl::do_http($easy, $url, $opt);

 or

 my $cb = sub {
 	my ($is_success, $body, $headers, $redirects) = @_;
 	...
 };
 HTTP::Curl::do_http(undef, $easy, $url, $opt, $cb);


=head2 Curl with Multi

 use Net::Curl::Easy;
 use Net::Curl::Multi;
 use Net::Curl::Multi::EV;
 use HTTP::Curl;

 my $multi = Net::Curl::Multi->new();
 my $curl_ev = Net::Curl::Multi::EV::curl_ev($multi);
 my $easy = Net::Curl::Easy->new();

 my $cb = sub {
 	my ($is_success, $body, $headers, $redirects) = @_;
 	...
 };
 HTTP::Curl::do_http($curl_ev, $easy, $url, $opt, $cb);
 ...


=head2 Parameters

=over

=item url

URL as string

=item opt

options and headers

=item cb

callback function to get result

=back

=head3 options

=over

=item referer

Referer url

=item agent

User agent name

=item timeout

Timeout, seconds

=item compressed

This option adds 'Accept-Encoding' header to the HTTP query and tells that the response must be decoded.
If you don't want to decode the response, please add 'Accept-Encoding' header into the 'headers' parameter.

=item headers

Ref on HASH of HTTP headers:

 {
   'Accept' => '*/*',
    ...
 }

=item cookie

It enables cookies support. The "" values enables the session cookies support without saving them.

=item persistent

1 or 0. Try to create/reuse a persistent connection.
When not specified, see the default behavior of Curl (reverse of CURLOPT_FORBID_REUSE).

=item proxy

http and socks proxy

 proxy => "$host:$port"
 or
 proxy => "$scheme://$host:$port"
 where scheme can be one of the: http, socks (socks5), socks5, socks4.

 proxy_auth => [user, password]

=item max_size

The size limit for response content, bytes.

HTTP::Curl - will return the result partially.

When max_size options will be triggered, 'client-aborted' header will added with 'max_size' value.

=item max_redirect

The limit of how many times it will obey redirection responses in a given request cycle.

By default, the value is 7.

=item body

Data for POST method.

String or CODE ref to return strings (return undef is end of body data).

=item method

When method parameter is "POST", the POST request is used with body parameter on data and 'Content-Type' header is added with 'application/x-www-form-urlencoded' value.

=item verbose

 verbose => 1

=back

=head3 finish callback function

 my $cb = sub {
 	my ($is_success, $body, $headers, $redirects) = @_;
 	...
 };

where:

=over

=item is_success

It is true, when HTTP code is 2XX.

=item body

HTML body. When on_header callback function is defined, then body is undef.

=item headers

Ref on HASH of HTTP headers (lowercase) and others info: Status, Reason, URL

=item redirects

Previous headers from last to first

=back

=head3 on_header callback function

When specified, this callback will be called after getting all headers.

 $opt{on_header} = sub {
 	my ($is_success, $headers, $redirects) = @_;
 	...
 };

=head3 on_body callback function

When specified, this callback will be called on each chunk.

 $opt{on_body} = sub {
 	my ($body) = @_; # body chunk
 	...
 };


=head1 NOTES

Turn off the persistent options to download pages of many sites.

Use libcurl with "Asynchronous DNS resolution via c-ares".

=head1 AUTHOR

Nick Kostyria <kni@cpan.org>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2013 by Nick Kostyria

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.14.2 or,
at your option, any later version of Perl 5 you may have available.

=head1 SEE ALSO

L<Net::Curl>
L<Net::Curl::Multi::EV>
L<Net::Any>

=cut
