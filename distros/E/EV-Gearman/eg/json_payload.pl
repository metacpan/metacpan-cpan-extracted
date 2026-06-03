#!/usr/bin/env perl
# Structured payloads via JSON. Gearman is byte-oriented; pick any
# serialization you like (JSON, MessagePack, Storable, Sereal).
#
# Conventions:
#   - Workload is a JSON object with at least { args => [...] }
#   - Result is a JSON object with { ok => 1, data => ... }
#     or { ok => 0, error => "..." }
use strict;
use warnings;
use EV;
use EV::Gearman;
use JSON::PP;

my $cli = EV::Gearman->new(host => '127.0.0.1', port => 4730);
my $wkr = EV::Gearman->new(host => '127.0.0.1', port => 4730);

my $j = JSON::PP->new->utf8(1);

# Worker: parses JSON in, returns JSON out
$wkr->register_function('image::resize' => sub {
    my $job = shift;
    my $req;
    eval { $req = $j->decode($job->workload); 1 } or do {
        return $j->encode({ ok => \0, error => "bad json: $@" });
    };
    my $w = $req->{width}  || 0;
    my $h = $req->{height} || 0;
    return $j->encode({
        ok     => \1,
        data   => { dims => [$w, $h], size => $w * $h },
    });
});
$wkr->work;

# Client: encodes/decodes for the user
sub call {
    my ($func, $req, $cb) = @_;
    my $payload = $j->encode($req);
    $cli->submit_job($func, $payload, sub {
        my ($result, $err) = @_;
        return $cb->(undef, $err) if $err;
        my $obj;
        eval { $obj = $j->decode($result); 1 } or return $cb->(undef, "bad json: $@");
        $cb->($obj);
    });
}

call('image::resize', { width => 1920, height => 1080 }, sub {
    my ($obj, $err) = @_;
    if ($err) { warn "fail: $err\n" }
    else      { use Data::Dumper; warn Dumper $obj }
    EV::break;
});

EV::run;
