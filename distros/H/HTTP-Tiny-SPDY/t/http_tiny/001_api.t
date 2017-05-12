#!perl

use strict;
use warnings;

use Test::More tests => 2;
use HTTP::Tiny::SPDY;

my @accessors = qw(
  agent default_headers http_proxy https_proxy keep_alive local_address
  max_redirect max_size proxy no_proxy timeout SSL_options verify_SSL cookie_jar
  enable_SPDY
);
my @methods   = qw(
  new get head put post delete post_form request mirror www_form_urlencode
);

my %api;
@api{@accessors} = (1) x @accessors;
@api{@methods} = (1) x @methods;

can_ok('HTTP::Tiny::SPDY', @methods, @accessors);

my @extra =
  grep {! $api{$_} }
  grep { $_ !~ /\A_/ }
  grep {; no strict 'refs'; *{"HTTP::Tiny::SPDY::$_"}{CODE} }
  sort keys %HTTP::Tiny::SPDY::;

ok( ! scalar @extra, "No unexpected subroutines defined" )
  or diag "Found: @extra";
