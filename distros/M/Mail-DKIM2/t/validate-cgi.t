#!/usr/bin/perl -w
use 5.020; use strict; use warnings;
use Test::More;
use Path::Tiny;
use JSON ();

my $cgi = path('bin/validate.cgi');
ok($cgi->exists, 'cgi exists');

# Compiles.
my $c = qx{perl -c -Ilib bin/validate.cgi 2>&1};
like($c, qr/syntax OK/, 'cgi compiles');

# Pipe a no-DKIM2 message as a POST body; expect valid JSON with overall=none.
my $body = "From: x\@a.test\r\nSubject: hi\r\n\r\nhello\r\n";
my $outfile = "/tmp/vcgi.$$.out";
{
    local $ENV{CONTENT_LENGTH} = length($body);
    local $ENV{DKIM2_DNS_JSON} = '../dns.json';
    open my $fh, '|-', "perl -Ilib bin/validate.cgi > $outfile" or die "spawn: $!";
    print $fh $body;
    close $fh;
}
my $out = path($outfile)->slurp;
unlink $outfile;

like($out, qr{Content-Type: application/json}, 'emits json content-type');
my ($json) = $out =~ /\r?\n\r?\n(.*)/s;
my $data = eval { JSON::decode_json($json // '') };
ok($data, 'body is valid JSON') or diag($out);
is($data->{overall}, 'none', 'no-DKIM2 body -> overall none');

done_testing;
