package HTTP::Any::AnyEvent;

use strict;
use warnings;


sub do_http {
	my ($http_request, $url, $opt, $cb) = @_;

	my $method = $$opt{method} || "GET";

	my %headers = ();
	%headers = %{$$opt{headers}} if $$opt{headers};

	$headers{"user-agent"} = $$opt{agent}   if $$opt{agent};
	$headers{"referer"}    = $$opt{referer} if $$opt{referer};

	if ($$opt{gzip}) {
		$headers{'Accept-Encoding'} = 'gzip';
		require Compress::Raw::Zlib;
	}

	my %args = ();
	$args{headers} = \%headers      if keys %headers;
	$args{timeout} = $$opt{timeout} if $$opt{timeout};

	if (defined $$opt{max_redirect}) {
		$args{recurse} = $$opt{max_redirect};
	} else {
		$args{recurse} = 7;
	}

	if (my $proxy = $$opt{proxy}) {
		if ($proxy =~ m/^socks/) {
			$proxy =~ s!^socks://!socks5://!;
			$args{socks} = $proxy;
		} elsif ($proxy =~ m!^(\w+://)?(.+):(\d+)$!) {
			if ($1) {
				$args{proxy} = [$2, $3, $1];
			} else {
				$args{proxy} = [$2, $3];
			}
		}
	}

	if ($$opt{cookie}) {
		$args{cookie_jar} = $$opt{cookie};
	} elsif (defined $$opt{cookie}) {
		$args{cookie_jar} = {};
	}

	$args{persistent} = $$opt{persistent} if exists $$opt{persistent};

	my $max_size  = $$opt{max_size};
	my $on_header = $$opt{on_header};
	my $on_body   = $$opt{on_body};

	my $body_from_on_body_length = 0;
	my @body_from_on_body        = ();

	if ($max_size or $on_header or $on_body) {
		my $headers_got = 0;
		my $content_encoding;
		my $inflate;

		$args{on_header} = sub {
			my ($headers) = @_;
			$body_from_on_body_length = 0;
			@body_from_on_body        = ();
			$headers_got              = 1;
			my ($is_success, $status, $h, $redirects) = headers($headers);
			$content_encoding = $$h{'content-encoding'};
			if ($$opt{gzip} and $content_encoding and $content_encoding eq 'gzip') {
				$inflate = Compress::Raw::Zlib::Inflate->new(-WindowBits => Compress::Raw::Zlib::WANT_GZIP());
			}

			if ($on_header) {
				$on_header->($is_success, $h, $redirects) or return;
			}
			return 1;
		};
		
		$args{on_body} = sub {
			my ($partial_body, $headers) = @_;
			$body_from_on_body_length += length $partial_body;
			push @body_from_on_body, $partial_body unless $on_body;
			if ($headers_got and $max_size and $body_from_on_body_length > $max_size) {
				return;
			}
			if ($headers_got and $on_body) {
				if ($inflate) {
					my $status = $inflate->inflate($partial_body, my $output);
					$status == Compress::Raw::Zlib::Z_OK() or $status == Compress::Raw::Zlib::Z_STREAM_END() or warn "inflation failed: $status\n";
					if ($output) {
						$on_body->($output) or return;
					}
				} else {
					$on_body->($partial_body) or return;
				}
			}
			return 1;
		};
	}

	if ($method eq "POST") {
		$args{headers}{"Content-Type"} ||= "application/x-www-form-urlencoded";
		$args{body} = $$opt{body};
	}

	$http_request->(
		$method => $url,
		%args,
		sub {
			my ($body, $headers) = @_;
			my ($is_success, $status, $h, $redirects) = headers($headers);

			if (not $body) {
				if ($status >= 590) {
					$is_success   = 0;
					$body         = "";
					if ($status == 598) {
						$$h{"Reason"} = "MaxSize";
					}
					$$h{"Status"} = $status = 599;
					delete $$h{"Orig$_"} foreach qw(Status Reason);
				} elsif (@body_from_on_body) {
					$body = join "", @body_from_on_body;
				}
			}

			$$h{Protocol} = "HTTP/" . $$h{HTTPVersion};

			my $content_encoding = $$h{'content-encoding'};
			if ($body and $$opt{gzip} and $content_encoding and $content_encoding eq 'gzip') {
				require Compress::Raw::Zlib;
				my $inflate = Compress::Raw::Zlib::Inflate->new(-WindowBits => Compress::Raw::Zlib::WANT_GZIP());
				my $status = $inflate->inflate($body, my $output);
				$status == Compress::Raw::Zlib::Z_OK() or $status == Compress::Raw::Zlib::Z_STREAM_END() or warn "inflation failed: $status\n";
				$cb->($is_success, $output, $h, $redirects);
			} else {
				$cb->($is_success, $body, $h, $redirects);
			}

		}
	);
}



sub headers {
	my ($headers) = @_;

	my $status = $$headers{Status};
	my $is_success = ($status >= 200 and $status < 300) ? 1 : 0;
	my ($h, @hr) = _headers($headers);

	return $is_success, $status, $h, \@hr;
}



sub _headers {
	my ($h) = @_;
	my %h = map { $_ => $$h{$_} } grep { $_ ne 'Redirect' } keys %$h;
	if (my $r = $$h{'Redirect'}) {
		return \%h, _headers($$r[1]);
	} else {
		return \%h;
	}
}


1;
