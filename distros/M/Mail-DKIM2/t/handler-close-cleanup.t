#!/usr/bin/perl
use strict;
use warnings;
use Test::More;
use Path::Tiny;

# authentication_milter kills the child when a handler leaves a per-message
# key behind after close_callback ("did not clean up data for key ..."), so
# every key a callback sets must be gone once close_callback has run.
# Keys starting with "_" belong to the mocked framework (t/lib/MockAuthMilter.pm).
use lib 'lib', 't/lib';
use MockAuthMilter qw(run_sign);
use Mail::Milter::Authentication::Handler::DKIM2Verify;
use DKIM2TestKeys;

sub leftover_keys {
    my ($handler) = @_;
    return sort grep { !/^_/ } keys %$handler;
}

sub feed {
    my ($handler, $raw) = @_;
    $raw =~ s/\r//gs;
    $raw =~ s/\n/\r\n/gs;
    my ($header_block, $body) = split /\r\n\r\n/, $raw, 2;
    my @lines;
    for my $line (split /\r\n/, $header_block) {
        if ($line =~ /^\s/ && @lines) { $lines[-1] .= "\r\n$line" }
        else                          { push @lines, $line }
    }
    $handler->envfrom_callback('<sender@test1.dkim2.com>');
    for my $hline (@lines) {
        my ($name, $value) = $hline =~ /^([^\s:]+)\s*:\s*(.*)/s;
        $handler->header_callback($name, $value, $hline);
    }
    $handler->eoh_callback();
    my $verifier = $handler->get_object('dkim2_verifier');
    $verifier->set_pubkey_callback(DKIM2TestKeys::pubkey_callback()) if $verifier;
    $handler->body_callback($body) if defined $body && length $body;
    $handler->eom_callback();
}

my $unsigned = path('tests/emails/brong-orig.eml')->slurp_raw;
my $signed   = path('tests/expected/chain-hop1-originator.eml')->slurp_raw;

for my $case ([ 'unsigned message', $unsigned ],
              [ 'signed message',   $signed   ]) {
    my ($label, $raw) = @$case;
    my $handler = Mail::Milter::Authentication::Handler::DKIM2Verify->new(
        config => { hide_none => 0, add_message_instance => 1,
                    snapshot_directory => undef },
    );
    feed($handler, $raw);
    $handler->close_callback();
    is_deeply([ leftover_keys($handler) ], [],
        "DKIM2Verify: close_callback leaves no per-message keys ($label)");
}

{
    my ($handler) = run_sign($unsigned);
    $handler->close_callback();
    is_deeply([ leftover_keys($handler) ], [],
        'DKIM2Sign: close_callback leaves no per-message keys');
}

done_testing;
