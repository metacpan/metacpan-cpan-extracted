#!/usr/bin/perl -w
#
# t/data/ carries the test keys and dns.json the suite needs, so the
# distribution tests itself without the interop repository around it. In the
# repository those files are copies of ../keys/ and ../dns.json, which the
# other implementations' tests share; this keeps the copies honest. Outside
# the repository (an unpacked CPAN tarball) there is nothing to compare
# against and the test skips.

use 5.020;
use strict;
use warnings;
use Test::More;
use FindBin;
use Path::Tiny;

my $data = path("$FindBin::Bin/data");
my $root = path("$FindBin::Bin/../..");
plan skip_all => 'not in the interop repository (no ../keys); nothing to compare'
    unless $root->child('keys')->is_dir && $root->child('dns.json')->exists;

my @pem = sort map { $_->basename } $root->child('keys')->children(qr/\.pem\z/);
ok(scalar @pem, 'the repository has test keys');
for my $name (@pem) {
    my $ours = $data->child('keys', $name);
    ok($ours->exists, "t/data/keys/$name exists") or next;
    is($ours->slurp_raw, $root->child('keys', $name)->slurp_raw, "t/data/keys/$name matches ../keys/$name");
}
my @extra = grep { my $n = $_; !grep { $_ eq $n } @pem } map { $_->basename } $data->child('keys')->children(qr/\.pem\z/);
is_deeply(\@extra, [], 't/data/keys has no key the repository lacks');
is($data->child('dns.json')->slurp_raw, $root->child('dns.json')->slurp_raw, 't/data/dns.json matches ../dns.json');

done_testing;
