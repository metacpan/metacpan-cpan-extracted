#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;
use File::Basename qw(dirname);
use IPC::Open3;
use MVC::Neaf::Util qw(JSON encode_json decode_json);

my $lib = dirname(__FILE__)."/../lib";

my $pid = open3( \*SKIP_IN, \*CGI_OUT, \*CGI_ERR,
        "perl", "-I$lib", "-MMVC::Neaf=:sugar", "-e",
        q{get '/'=>sub {die "Foobared"}; neaf->run}
    )
    or die "Failed to spawn process: $!";

END{ kill 9, $pid if $pid };
close SKIP_IN;

$SIG{CHLD} = sub {
    waitpid $pid,
    note "Clild return $?";
    undef $pid;
};
$SIG{ALRM} = sub { die "Timeout!" };
alarm 10;

local $/;
my $result = <CGI_OUT>;
close CGI_OUT;
my $log    = <CGI_ERR>;
close CGI_ERR;

my ($head, $body) = split /\n\s*\n/s, $result, 2;

note "STDERR = \n".$log;

my $data = eval {
    decode_json($body);
};
ok $data, "Got valid JSON, error=$@";
is $data->{error}, 500, "Error 500 inside";
ok $data->{req_id}, "req_id present";

like $log, qr/req_id=$data->{req_id}/, "Req id round trip";
like $log, qr/Foobared at/, "Exception as expected";

done_testing;
