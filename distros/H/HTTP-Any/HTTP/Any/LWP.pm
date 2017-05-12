package HTTP::Any::LWP;

use strict;
use warnings;



sub do_http {
	my ($ua, $url, $opt, $cb) = @_;

	$ua->agent($$opt{agent})       if $$opt{agent};
	$ua->timeout($$opt{timeout})   if $$opt{timeout};
	$ua->max_size($$opt{max_size}) if $$opt{max_size};

	$ua->parse_head(0);

	if ($$opt{cookie}) {
		$ua->cookie_jar($$opt{cookie});
	} elsif (defined $$opt{cookie}) {
		$ua->cookie_jar({});
	}

	if (my $proxy = $$opt{proxy}) {
		unless ($proxy =~ m!^\w+://!) {
			$proxy = "http://$proxy"
		} else {
			$proxy =~ s!^socks5://!socks://!;
		}
		$ua->proxy(['http', 'https'] => $proxy);
	}

	my $method = $$opt{method} || "GET";

	my $req = HTTP::Request->new($method => $url);

	if ($$opt{headers}) {
		foreach (keys %{$$opt{headers}}) {
			$req->header($_ => $$opt{headers}{$_});
		}
	}

	$req->referer($$opt{referer}) if $$opt{referer};

	if ($$opt{gzip}) {
		$req->header('Accept-Encoding', 'gzip');
		require Compress::Raw::Zlib;
	}

	if ($method eq "POST") {
		unless ($$opt{headers}{"Content-Type"}) {
			$req->content_type("application/x-www-form-urlencoded");
		}
		$req->content($$opt{body});
	}


	my $on_header = $$opt{on_header};
	my $on_body   = $$opt{on_body};

	if ($on_header or $on_body) {
		my $headers_got = 0;
		my $content_encoding;
		my $inflate;

		my @hrs = ();
		$ua->set_my_handler( response_header => sub {
			my($res, $ua, undef) = @_;
			my ($h) = _headers($res);
			push @hrs, $h;
			unless ($$h{Status} == 301) {
				my ($h, @hr) = reverse @hrs;
				$headers_got = 1;
				$content_encoding = $$h{'content-encoding'};
				if ($$opt{gzip} and $content_encoding and $content_encoding eq 'gzip') {
					$inflate = Compress::Raw::Zlib::Inflate->new(-WindowBits => Compress::Raw::Zlib::WANT_GZIP());
				}
				if ($on_header) {
					$on_header->($res->is_success || 0, $h, \@hr) or return;
				}
			}
			return 1;
		});
		
		if ($on_body) {
			$ua->set_my_handler( response_data => sub {
				my($res, $ua, undef, $data) = @_;
				if ($headers_got) {
					if ($inflate) {
						my $status = $inflate->inflate($data, my $output);
						$status == Compress::Raw::Zlib::Z_OK() or $status == Compress::Raw::Zlib::Z_STREAM_END() or warn "inflation failed: $status\n";
						if ($output) {
							$on_body->($output) or return;
						}
					} else {
						$on_body->($data) or return;
					}
					$res->content("");
				}
				return 1;
			});
		}
		
	}



	my $res = $ua->request($req);

	my ($h, @hr) = _headers($res);

	my $is_success = $res->is_success || 0;

	if ($$h{'client-aborted'}) {
		if ($$h{'client-aborted'} eq 'max_size') {
			$$h{Reason} = 'MaxSize';
		} elsif ($$h{'client-aborted'} eq 'die') {
			if ($$h{'x-died'} =~ m/timeout/) {
				$$h{Reason} = 'Timeout';
			}
		}
		$$h{Status} = 599;
		$cb->(0, "", $h, \@hr);
		return;
	}

	if ($on_body) {
			$cb->($is_success, undef, $h, \@hr);
	} else {
		my $content_encoding = $$h{'content-encoding'};
		if ($res->content and $$opt{gzip} and $content_encoding and $content_encoding eq 'gzip') {
			my $inflate = Compress::Raw::Zlib::Inflate->new(-WindowBits => Compress::Raw::Zlib::WANT_GZIP());
			my $status = $inflate->inflate($res->content, my $output);
			$status == Compress::Raw::Zlib::Z_OK() or $status == Compress::Raw::Zlib::Z_STREAM_END() or warn "inflation failed: $status\n";
			$cb->($is_success, $output, $h, \@hr);
		} else {
			$cb->($is_success, $res->content, $h, \@hr);
		}
	}
}


sub _headers {
	my ($res) = @_;
	my %h = %{$res->headers};
	my %r = map { my $v = $h{$_}; $_ => ref $v eq "ARRAY" ? join(",", @$v) : $v } keys %h;
	$r{Status} = $res->code;
	$r{Reason} = $res->message;
	$r{URL}    = $res->base->as_string;
	if (my $prev = $res->previous) {
		return \%r, _headers($prev);
	} else {
		return \%r;
	}
}


1;
