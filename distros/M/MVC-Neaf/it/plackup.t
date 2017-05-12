#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;
use IPC::Open3;
use LWP::UserAgent;
use IO::Socket::INET;

use FindBin qw($Bin);
use File::Basename qw(dirname basename);
use lib dirname($Bin)."/lib";

my $root = dirname( $Bin );

my $port_attempts = 100;
my $run_attempts  = 10;

# use 09-request example which calls most getters
my ($example) = glob ("$root/example/01*");
if (!$example or !-f $example) {
    die "No example found in $root/example";
};
my $cginame = basename($example);

# make sure example compiles at all
my $sub = eval { do $example };

is (ref $sub, 'CODE', "$example lives and returns coderef")
    or die "Example failed to load: ".($@ || $! || "unexpected return");

# TODO find a free port
my $pid;
my $port;
while ($port_attempts --> 0) {
    $port = 65535 - int(40000 * rand);

    my $sock = IO::Socket::INET->new(
        Proto => "tcp",
        PeerHost => "localhost",
        PeerHost => $port,
    );
    if ($sock) {
        # port occupied...
        close $sock;
        next;
    };

    # start plack
    $pid = open3( \*SKIP, \*ALSO_SKIP, \*LOG,
        "plackup", "--listen", ":$port", "-I$root/lib", $example );

    last if $pid;
    last unless $run_attempts --> 0;
};

if (!$pid) {
    diag "Couldn't find a free port, but $example compiles";
    done_testing;
    exit 0;
};

# Keep in line with the server
END { kill 9, $pid if $pid }; # TODO check we're still Luke's father
$SIG{CHLD} = sub {
    undef $pid;
    die "plack server shut down unexpectedly ($?)";
};

# don't let this test hang!
$SIG{ALRM} = sub {
    die "Script timed out, bailing out";
};
alarm 10;

my $invite = <LOG>;
if (!defined $invite) {
    die "Failed to get any prompt from plackup: $!";
};

my $url = "http://localhost:$port/cgi/$cginame/some/foobar";

my $agent = LWP::UserAgent->new;

my $resp = $agent->get( $url );
ok ($resp->is_success, "$example returned a 200" );
note $resp->decoded_content;

# avoid warnings
close (SKIP);
close (ALSO_SKIP);

delete $SIG{CHLD};
kill 'INT', $pid;

while (<LOG>) {
    note "From server: $_";
};
close LOG;

done_testing; # plack will be killed anyway


