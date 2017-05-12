#!/usr/bin/perl

use strict;
use warnings;
use FindBin;

use Test::More;

BEGIN {
    {
        local $@;
        eval "use Plack 0.9910; use FCGI::Client 0.04; use MooseX::NonMoose 0.07; use IO::String;";
        plan skip_all => "Plack 0.9910, FCGI::Client and MooseX::NonMoose are required for this test" if $@;
    }
}

use Test::TCP;
use Plack::Handler::FCGI::Engine;
use Plack::Test::Suite;
use t::lib::FCGIUtils;

my $lighty_port;
my $fcgi_port;

test_lighty_external(
   sub {
       ($lighty_port, $fcgi_port, my $needs_fix) = @_;
       Plack::Test::Suite->run_server_tests(run_server_cb($needs_fix), $fcgi_port, $lighty_port);
       done_testing();
    }
);

sub run_server_cb {
    my $needs_fix = shift;

    require Plack::Middleware::LighttpdScriptNameFix;
    return sub {
        my($port, $app) = @_;

        note "Applying LighttpdScriptNameFix" if $needs_fix;
        $app = Plack::Middleware::LighttpdScriptNameFix->wrap($app) if $needs_fix;

        $| = 0; # Test::Builder autoflushes this. reset!

        my $server = Plack::Handler::FCGI::Engine->new(
            host        => '127.0.0.1',
            port        => $port,
            pidfile     => '/tmp/100_plack_server_fcgi_engine.pid',
            keep_stderr => 1,
        );
        $server->run($app);
    };
}



