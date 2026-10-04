#!/usr/bin/perl -w

use 5.020;
use Path::Tiny;
use Email::MIME;
use lib 'lib';
use Mail::DKIM2::Common qw(extract_mi_version parse_dkim_pubkey);
use Mail::DKIM2::MessageInstance;
use Mail::DKIM2::Verifier;
use List::Util qw(max);
use JSON;
use Getopt::Long qw(GetOptions);

my $ignore_ts = 0;
GetOptions('ignore-timestamps' => \$ignore_ts)
  or die "usage: $0 [--ignore-timestamps] <file>\n";

my $f1 = shift;
my $data = path($f1)->slurp;
$data =~ s/\r//gs;
$data =~ s/\n/\r\n/gs;
my $msg1 = Email::MIME->new($data);

my $dns = decode_json(path('../dns.json')->slurp);

my %map = map { _geti($_) => $_ } $msg1->header('DKIM2-Signature');
my $num = %map ? max(keys %map) : 0;
my %mimap = map { extract_mi_version($_) => $_ } $msg1->header('Message-Instance');
my $instance = %mimap ? max(keys %mimap) : 0;

# The true top of the chain, remembered before the walk below starts stripping
# signatures off $msg1. Every step after the first verifies a PARTIAL view, in
# which the locally-highest i= is not the real top -- see mid_process below.
my $top_i = $num;

# spec-06 §11: "there MUST NOT be a Message-Instance field with a higher m=
# value than occurs in any DKIM2-Signature field" -- reported as "PERMERROR
# Message-Instance m=<x> is not signed". Checked up front because the walk
# below happily verifies and reports "OK Message-Instance" for an instance
# above every signature, which is precisely the unaccountable instance the
# rule exists to reject. This tool is a conformance checker, so it is strict
# even though our own inbound path stamps an unsigned MI internally.
if ($instance) {
  my $top_signed = %map ? max(map { _getv($_) } values %map) : 0;
  die "PERMERROR Message-Instance m=$instance is not signed\n"
    if $instance > $top_signed;
}

while (1) {
  my $hi = $num ? _getv($map{$num}) : 0;
  while ($instance > $hi) {
    my ($check, $error) = Mail::DKIM2::MessageInstance->verify($msg1);
    die "ERROR: failed to verify instance $instance: $error\n" unless $check;
    die "DIDN'T FIND TOP $instance <> $check" unless $instance == $check;
    say "OK Message-Instance: m=$check";
    die "Failed to undo" unless Mail::DKIM2::MessageInstance->undo($msg1);
    # Email::MIME keeps internal caches which get broken by replacing the body
    $instance--;
    last unless $instance;
    $msg1 = Email::MIME->new($msg1->as_string);
    %mimap = map { extract_mi_version($_) => $_ } $msg1->header('Message-Instance');
    %map = map { _geti($_) => $_ } $msg1->header('DKIM2-Signature');
    my $newnum = %map ? max(keys %map) : 0;
    my $newinstance = %mimap ? max(keys %mimap) : 0;
    die "MISMATCH TOP DKIM" unless $num == $newnum;
    die "MISMATCH TOP VERSION $instance <> $newinstance" unless $instance == $newinstance;
    die "NO SUCH Message-Instance m=$instance" unless $mimap{$instance};
  }
  last unless $num;
  my $h = $map{$num};
  die "NO SUCH DKIM2-Header i=$num" unless $h;

  # Create a verifier for this specific signature
  my $verifier = Mail::DKIM2::Verifier->new();
  $verifier->skip_timestamp_check(1) if $ignore_ts;
  # After the first step this is a partial view (higher DKIM2-Signature
  # headers have been stripped), so its locally-highest i= is not the real
  # top of the chain and Verifier.pm's top-nd= rejection must not fire: a
  # legitimate §9.3 nd= bridge below the top looks locally topmost here.
  # The first step still sees the whole chain, so a true top nd= is caught.
  $verifier->mid_process(1) if $num < $top_i;
  $verifier->set_pubkey_callback(sub { find_key(@_) });
  $verifier->PRINT($msg1->as_string());
  $verifier->CLOSE;

  if ($verifier->result eq 'pass') {
    say "OK DKIM2-Signature: i=$num; m=$instance";
  } else {
    die "DKIM2-Signature i=$num: " . $verifier->result_detail();
  }
  $msg1->header_raw_set('DKIM2-Signature', grep { _geti($_) < $num } $msg1->header('DKIM2-Signature'));
  $num--;
}

sub _geti {
  my $arg = shift;
  return 0 unless $arg =~ m/\bi=(\d+)/;
  return 0 + $1;
}

sub _getv {
  my $arg = shift;
  return 0 unless $arg =~ m/\bm=(\d+)/;
  return 0 + $1;
}

sub find_key {
  my ($signature, $idx) = @_;
  $idx //= 0;
  my $sel = $signature->selector($idx);
  my $dom = $signature->domain;
  my $key_txt = $dns->{$dom}{"$sel._domainkey"}[0][1];
  return parse_dkim_pubkey($key_txt);
}
