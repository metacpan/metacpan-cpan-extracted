package HTTP::Any::Curl;

use strict;
use warnings;

use Net::Curl::Easy qw(/^CURLOPT_/ CURLE_OK CURLINFO_EFFECTIVE_URL CURLE_WRITE_ERROR CURLE_OPERATION_TIMEDOUT CURLE_RECV_ERROR);


BEGIN {
	Net::Curl::Easy->can('CURLOPT_ACCEPT_ENCODING') or die "Rebuild Net::Curl with libcurl 7.21.6 or newer\n";
	Net::Curl::Easy->can('CURLOPT_COOKIEFILE')      or die "Rebuild curl with Cookies support\n";
}

sub _prepare {
	my ($easy, $url, $opt) = @_;

	$easy->setopt(CURLOPT_URL, $url);

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

	$easy->setopt(CURLOPT_WRITEHEADER, \ my $headers);

	my $body = "";
	$easy->setopt(CURLOPT_FILE, \$body) unless $on_body;

	$easy->setopt(CURLOPT_USERAGENT, $$opt{agent}) if $$opt{agent};
	$easy->setopt(CURLOPT_REFERER, $$opt{referer}) if $$opt{referer};
	$easy->setopt(CURLOPT_TIMEOUT, $$opt{timeout}) if $$opt{timeout};

	if (my $proxy = $$opt{proxy}) {
		$proxy =~ s!^socks://!socks5://!;
		$easy->setopt(CURLOPT_PROXY, $proxy);
	}

	$easy->setopt(CURLOPT_ACCEPT_ENCODING, "") if $$opt{compressed} or $$opt{gzip};

	$easy->setopt(CURLOPT_FORBID_REUSE, $$opt{persistent} ? 0 : 1) if exists $$opt{persistent};

	my $max_size = $$opt{max_size};
	my $aborted_by_max_size = 0;

	my $body_size = 0;

	if ($max_size or $on_header or $on_body) {
		my $cb_write = sub {
			my ($easy, $data, $uservar) = @_;
			my $size = length $data;
			$body_size += $size;
			if ($on_header) {
				my ($is_success, $headers, $redirects) = _headers($easy, $url, $headers);
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

		if ($headers) {
			my ($is_success, $headers, $redirects) = _headers($easy, $url, $headers);
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
				$$headers{"Status"} = 599;
				$$headers{"Reason"} = "$result";
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
			$multi_ev->($easy, sub { $cb->($finish->(@_)) }, 4 * 60);
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
		return $h, __headers($$h{location}, @h);
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
