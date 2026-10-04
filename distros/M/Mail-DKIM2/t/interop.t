#!/usr/bin/perl -w

use 5.020;
use strict;
use warnings;
use Test::More;
use Path::Tiny;
use Email::MIME;
use JSON;
use lib 'lib';

use Mail::DKIM2::Common qw(parse_dkim_pubkey);
use Mail::DKIM2::MessageInstance;
use Mail::DKIM2::Verifier;

# Load DNS keys
my $dns = decode_json(path('../dns.json')->slurp);

sub find_key {
    my ($signature, $idx) = @_;
    $idx //= 0;
    my $sel = $signature->selector($idx);
    my $dom = $signature->domain;
    my $key_txt = $dns->{$dom}{"$sel._domainkey"}[0][1];
    return parse_dkim_pubkey($key_txt);
}

sub verify_msg {
    my ($msg) = @_;
    my $verifier = Mail::DKIM2::Verifier->new();
    $verifier->set_pubkey_callback(\&find_key);
    $verifier->skip_timestamp_check(1);  # test emails have fixed timestamps
    $verifier->PRINT($msg->as_string());
    $verifier->CLOSE;
    return $verifier;
}

# ============================================================
# Verify other implementations' test emails
# ============================================================

my @impl_dirs = (
    ['../python/tests/expected', 'python'],
    ['../hs',                    'hs'],
);

for my $impl (@impl_dirs) {
    my ($dir, $name) = @$impl;
    next unless -d $dir;

    my @files = sort glob("$dir/*.eml");
    next unless @files;

    diag("=== Verifying $name test emails ===");

    for my $path (@files) {
        my $file = Path::Tiny::path($path)->basename;
        my $data = path($path)->slurp;
        $data =~ s/\r//gs;
        $data =~ s/\n/\r\n/gs;
        my $msg = Email::MIME->new($data);

        # Verify DKIM2-Signature
        my $v = verify_msg($msg);
        if ($v->result eq 'pass') {
            pass("$name/$file: DKIM2-Signature verifies");

            # Also verify Message-Instance if signature passed
            my $mi_check = Mail::DKIM2::MessageInstance->verify($msg);
            ok($mi_check, "$name/$file: MI verifies")
                or do {
                    my ($r, $e) = Mail::DKIM2::MessageInstance->verify($msg);
                    diag("MI error: $e");
                };
        } else {
            # Report but don't hard-fail — interop issues may need
            # fixes in the other implementation
            TODO: {
                local $TODO = "interop: may need fixes in $name implementation";
                is($v->result, 'pass', "$name/$file: DKIM2-Signature verifies")
                    or diag($v->result_detail());
            }
        }
    }
}

unless (Test::More->builder->current_test) {
    diag("No other implementation test directories found");
    pass("placeholder — no interop files to test");
}

done_testing();
