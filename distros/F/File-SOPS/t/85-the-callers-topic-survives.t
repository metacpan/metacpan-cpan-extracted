#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use File::Temp qw(tempdir);
use File::SOPS;
use Crypt::Age;

# k203: Crypt::Age before 0.005 read the age header with a bare while (<$fh>)
# and overwrote the caller's global $_. File::SOPS calls Crypt::Age->decrypt
# directly, so every decrypting entry point inherited it: a loop like
# for (@files) { File::SOPS->decrypt_file(input => $_, ...) } rewrote the list.
# The cpanfile now requires 0.005; this test holds the guarantee on this side.

my ($public, $secret) = Crypt::Age->generate_keypair;
my $data = { db => { password => 'topic-test' } };
my $encrypted = File::SOPS->encrypt(
    data => $data, recipients => [$public], format => 'yaml',
);

my $dir = tempdir(CLEANUP => 1);
my $enc_file = "$dir/in.yaml";
{
    open my $fh, '>:raw', $enc_file or die "open $enc_file: $!";
    print {$fh} $encrypted;
    close $fh or die "close $enc_file: $!";
}

my @entry_points = (
    [ decrypt => sub {
        my $out = File::SOPS->decrypt(
            encrypted => $encrypted, identities => [$secret],
        );
        die "wrong data\n" unless $out->{db}{password} eq 'topic-test';
    } ],
    [ decrypt_file => sub {
        File::SOPS->decrypt_file(
            input => $enc_file, output => "$dir/out.yaml",
            identities => [$secret],
        );
    } ],
    [ extract => sub {
        my $v = File::SOPS->extract(
            file => $enc_file, path => 'db.password', identities => [$secret],
        );
        die "wrong value\n" unless $v eq 'topic-test';
    } ],
);

for my $ep (@entry_points) {
    my ($name, $call) = @$ep;

    local $_ = 'caller topic';
    $call->();
    is $_, 'caller topic', "$name leaves the global \$_ alone";

    my @list = ('one', 'two');
    for (@list) { $call->() }
    is_deeply \@list, ['one', 'two'], "$name inside for (\@list) leaves the elements alone";

    my $ok = eval { for ('read-only') { $call->() } 1 };
    ok $ok, "$name inside a loop over a literal does not die"
        or diag $@;
}

done_testing;
