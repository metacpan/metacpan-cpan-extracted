use strict;
use FindBin;
use Test::More;
use Plack::Test;

use HTML::Mason::PSGIHandler::Streamy;

my %DESTRUCTED;
BEGIN {
    my $orig = CGI::PSGI->can('DESTROY');
    no warnings 'redefine';
    *CGI::PSGI::DESTROY = sub {
        $orig->(@_) if $orig;
        $DESTRUCTED{'CGI::PSGI'}++;
    };
}

my $h = HTML::Mason::PSGIHandler::Streamy->new(
    comp_root => $FindBin::Bin,
);

my $handler = sub { $h->handle_psgi(@_) };
%DESTRUCTED = ();
test_psgi app => $handler, client => sub {
    my $cb = shift;
    for (1..5) {
        my $res = $cb->(HTTP::Request->new(GET => "http://localhost/hello.mhtml?foo=bar"));
        is $res->code, 200, 'got 200 response';
    }
    is $DESTRUCTED{'CGI::PSGI'}, 4, "destroyed 2 CGI::PSGI";
};

$handler = sub { Plack::Util::response_cb( $h->handle_psgi(@_), sub { my $res = shift; return sub { $_[0]||'' } } ) };
%DESTRUCTED = ();
test_psgi app => $handler, client => sub {
    my $cb = shift;
    for (1..5) {
        my $res = $cb->(HTTP::Request->new(GET => "http://localhost/hello.mhtml?foo=bar"));
        is $res->code, 200, 'got 200 response';
    }
    is $DESTRUCTED{'CGI::PSGI'}, 5, "destroyed 2 CGI::PSGI";
};


done_testing;
