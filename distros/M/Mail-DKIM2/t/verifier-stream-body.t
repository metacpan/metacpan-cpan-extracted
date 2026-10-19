#!/usr/bin/perl
use strict;
use warnings;
use Test::More;
use FindBin;
use lib "$FindBin::Bin/../lib", "$FindBin::Bin/lib";
use Path::Tiny;
use JSON qw(decode_json);
use Mail::DKIM2::Verifier;
use Mail::DKIM2::Common qw(parse_dkim_pubkey);
use DKIM2TestKeys;

# StreamBody (the default): the Verifier hashes every instance's body as the body arrives
# (Mail::DKIM2::BodyPlan) instead of keeping it and undoing each instance.
# Same verdicts, same words, as the undo walk; and the body is not kept.

my %dns = %{ decode_json(path(DKIM2TestKeys::dns_json())->slurp) };
my $capture = path("$FindBin::Bin/../../corpus/results/capture");
my $live = $capture->parent->child('dns-live.json');
%dns = (%dns, %{ decode_json($live->slurp) }) if $live->is_file;

my $pubkey = sub {
    my ($sig, $idx) = @_;
    my $e = $dns{$sig->domain}{$sig->selector($idx // 0) . '._domainkey'};
    return $e && $e->[0] ? parse_dkim_pubkey($e->[0][1]) : undef;
};

sub verify {
    my ($raw, %opts) = @_;
    my $v = Mail::DKIM2::Verifier->new(SkipTimestampCheck => 1,
                                       PubkeyCallback => $pubkey, %opts);
    my $kept = 0;
    for my $chunk (unpack('(a4093)*', $raw)) {
        $v->PRINT($chunk);
        next if $v->{_in_header};    # the headers wait in _buf for their end
        $kept = length $v->{_buf} if length $v->{_buf} > $kept;
    }
    $v->CLOSE;
    return ($v->result . ': ' . $v->result_detail, $kept);
}

# A Subject changed.
sub tamper_header {
    my ($raw) = @_;
    return $raw =~ s/^(Subject:[ \t]*)/${1}x/mi ? $raw : undef;
}

# A body byte changed: the first letter after the header block.
sub tamper {
    my ($raw) = @_;
    my $at = index($raw, "\r\n\r\n");
    return undef if $at < 0;
    pos($raw) = $at + 4;
    return undef unless $raw =~ /\G[^a-z]*([a-z])/gi;
    substr($raw, $-[1], 1) = $1 eq 'x' ? 'y' : 'x';
    return $raw;
}

my @files = sort(path("$FindBin::Bin/../tests/expected")->children(qr/\.eml\z/));
push @files, sort($capture->children(qr/\.eml\z/)) if $capture->is_dir;

my $kept_max;
for my $file (@files) {
    (my $raw = $file->slurp_raw) =~ s/\r?\n/\r\n/g;
    for my $case ([$file->basename, $raw],
                  ['tampered body ' . $file->basename, tamper($raw)],
                  ['tampered header ' . $file->basename, tamper_header($raw)]) {
        my ($name, $msg) = @$case;
        next unless defined $msg;
        my ($want)        = verify($msg, StreamBody => 0);
        my ($have, $kept) = verify($msg);
        is($have, $want, $name);
        $kept_max = $kept if !defined $kept_max || $kept > $kept_max;
    }
}
is($kept_max, 0, 'StreamBody keeps no body');

done_testing;
