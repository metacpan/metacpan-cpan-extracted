#!/usr/bin/env perl
#
# RT #60457, add custom headers to HTTP::DAV::put()
#

use strict;
use warnings;
use Cwd ();
use Data::Dumper;
use Test::More tests => 8;

use_ok('HTTP::DAV');
use_ok('HTTP::DAV::Comms');

#HTTP::DAV::DebugLevel(3);

#
# Test the set of headers in HTTP::DAV::Comms
#
my $comms = HTTP::DAV::Comms->new(
    -headers => {"X-HTTP-DAV-1" => "abc123"}
);
ok($comms);

my $headers = $comms->{_headers};
ok($headers, "Got a HTTP::DAV::Headers object");

is(
    $headers->header("X-HTTP-DAV-1") => "abc123",
    "Header passed at construction time"
);

#
# Test setting of headers from HTTP::DAV to Comms
#
my $dav = HTTP::DAV->new(
    -headers => { "X-HTTP-DAV-2" => "def456" }
);

# XXX This currently does not work without test details,
# so it's not tested
my $result = $dav->put(
    -local => $0,
    -url => "$0.copy.$$",
    -headers => {"X-HTTP-DAV-3" => "ghi789"}
);

# Inspect the internals to check if everything looks fine
$comms = $dav->{_comms};
ok($comms, 'HTTP::DAV::Comms object is there');

$headers = $comms->{_headers};
ok($headers, "Got a HTTP::DAV::Headers object");

is(
    $headers->header("X-HTTP-DAV-2") => "def456",
    "Header passed in the HTTP::DAV constructor is passed along",
);

__END__

SKIP: {

    use lib 't';
    use TestDetails qw($test_user $test_pass $test_url do_test fail_tests test_callback);

#    if ($test_url !~ m{http}) {
#        skip("no test server", 4);
#    }

    use_ok('HTTP::DAV');
    use_ok('HTTP::DAV::Comms');

    my $dav = HTTP::DAV->new();
    HTTP::DAV::DebugLevel(3);

    $dav->credentials($test_user,$test_pass,$test_url);

    my $collection = $test_url;
    $collection =~ s{/$}{}g;
    my $new_file = "$collection/dav_test_file.txt";
    diag("File: $new_file");

    my $resource = $dav->new_resource( -uri => $new_file );
    my $response = $resource->put("DAV.pm test content ", {"X-DAV-Test" => "12345"});

    if (! ok($response->is_success)) {
       diag($response->message());
    }

    $response = $resource->get();
    if (! ok($response->is_success) ) {
       diag($response->message());
    }

}

