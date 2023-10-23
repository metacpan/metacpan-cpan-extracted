#!perl
use 5.020;
use feature 'signatures';
no warnings 'experimental::signatures';
use File::Temp 'tempfile';
use Capture::Tiny 'capture';
use HTTP::Request::FromFetch;

use Test2::V0 '-no_srand';

my $have_mojolicious;
BEGIN {
    if( eval { require Mojo::UserAgent; 1 }) {
        $have_mojolicious = 1;
    }
}

my @tests = (
    { js => <<'JS', name => 'empty fetch'},
        fetch("https://example.com/")
JS

    { js => <<'JS', name => 'semicolon at end'},
        fetch("https://example.com/");
JS

    { js => <<'JS', name => 'empty options'},
        fetch("https://example.com/",{})
JS

    { js => <<'JS', name => 'empty options'},
        fetch("https://example.com/",{ "method":"GET" })
JS

    { js => <<'JS', name => 'full options'},
        fetch("https://example.com/foo",{
        "credentials": "include",
        "headers": {
            "User-Agent": "Mozilla/5.0 (X11; Linux x86_64; rv:74.0) Gecko/20100101 Firefox/74.0",
            "Accept": "text/javascript, text/html, application/xml, text/xml, */*",
            "Accept-Language": "de,en-US;q=0.7,en;q=0.3",
            "X-Requested-With": "XMLHttpRequest"
        },
        "referrer": "https://www.example.com/",
        "method": "GET",
        "mode": "cors"
    })
JS

# This is unsupported so far
#    { js => <<'JS', name => 'single quotes'},
#        fetch("https://example.com/foo",{
#        'credentials': 'include'
#    })
#JS
);

sub compiles_ok( $code, $name ) {
    my( $fh, $tempname ) = tempfile( UNLINK => 1 );
    binmode $fh, ':raw';
    print $fh $code;
    close $fh;

    my ($stdout, $stderr, $exit) = capture(sub {
        system( $^X, '-Mblib', '-wc', $tempname );
    });

    if( $exit ) {
        diag $stderr;
        diag "Exit code: ", $exit;
        fail($name);
    } elsif( $stderr !~ /(^|\n)\Q$tempname\E syntax OK\s*$/) {
        diag $stderr;
        diag $code;
        fail($name);
    } else {
        pass($name);
    };
};

plan tests => 3*@tests;

for my $test (@tests) {
    my $name = $test->{name};
    my $code = $test->{js};

    my $r = HTTP::Request::FromFetch->new(
        $code,
    );

    $code = $r->as_snippet(type => 'LWP',
        preamble => ['use strict;','use LWP::UserAgent;']
    );
    compiles_ok( $code, "$name as LWP snippet compiles OK")
        or diag $code;

    $code = $r->as_snippet(type => 'Tiny',
        preamble => ['use strict;','use HTTP::Tiny;']
    );
    compiles_ok( $code, "$name as HTTP::Tiny snippet compiles OK")
        or diag $code;

    $code = $r->as_snippet(type => 'Mojolicious',
        preamble => ['use strict;','use Mojo::UserAgent;']
    );

    if( $have_mojolicious) {
        compiles_ok( $code, "$name as Mojolicious snippet compiles OK")
            or diag $code;
    } else {
        SKIP: {
            skip( "Mojolicious not installed", 1 );
        };
    }
};

done_testing;
