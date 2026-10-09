#!/usr/bin/perl -w

use 5.020;
use Path::Tiny;
use Email::MIME;
use lib 'lib';
use Mail::DKIM2::Common qw(extract_mi_version parse_dkim_pubkey parse_mime
                           valid_sequence chain_number_error mi_version_tag UNKEYABLE_SIGNATURE_ERROR);
use Mail::DKIM2::Signature;
use Mail::DKIM2::MessageInstance;
use Mail::DKIM2::Verifier;
use List::Util qw(max);
use JSON;
use Getopt::Long qw(GetOptions);

my $ignore_ts = 0;
my $dns_json;
GetOptions('ignore-timestamps' => \$ignore_ts, 'dns-json=s' => \$dns_json)
  or die "usage: $0 [--ignore-timestamps] [--dns-json FILE] <file>\n";
# Keys come from a dns.json (interop test fixture), never live DNS: this is the
# cross-implementation checker, not the production verifier. Default to the
# copy shipped with the tests, then the interop repository's shared file.
$dns_json //= $ENV{DKIM2_DNS_JSON}
         // (-e 't/data/dns.json' ? 't/data/dns.json' : '../dns.json');

my $f1 = shift;
my $data = path($f1)->slurp;
$data =~ s/\r//gs;
$data =~ s/\n/\r\n/gs;
my $msg1 = parse_mime($data);

my $dns = decode_json(path($dns_json)->slurp);

# Header-level PERMERRORs first, as the Verifier reports them. The walk below
# is driven by the i= and m= values it can read, so without this a junk
# DKIM2-Signature with no usable i= -- even the only one -- would simply never
# be visited, and an i= or m= above MAX_CHAIN_LENGTH would be a loop bound.
for my $h ($msg1->header_raw('DKIM2-Signature')) {
  my $sig = eval { Mail::DKIM2::Signature->parse($h) };
  my $i = $sig ? $sig->sequence : undef;
  die UNKEYABLE_SIGNATURE_ERROR . "\n" unless valid_sequence($i);
  my $e = chain_number_error('DKIM2-Signature', 'i', $i)
       // chain_number_error('DKIM2-Signature', 'm', $sig->version);
  die "$e\n" if $e;
}
for my $h ($msg1->header_raw('Message-Instance')) {
  my $e = chain_number_error('Message-Instance', 'm', mi_version_tag($h));
  die "$e\n" if $e;
}

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

# Set once past an instance with a null body Recipe: the body below it is
# lost, so lower levels check header hashes only, undoing header Recipes only.
my $hdr_only = 0;

while (1) {
  my $hi = $num ? _getv($map{$num}) : 0;
  while ($instance > $hi) {
    my ($check, $error) = Mail::DKIM2::MessageInstance->verify($msg1, HeadersOnly => $hdr_only);
    die "ERROR: failed to verify instance $instance: $error\n" unless $check;
    die "DIDN'T FIND TOP $instance <> $check" unless $instance == $check;
    say "OK Message-Instance: m=$check";
    my $mi = Mail::DKIM2::MessageInstance->parse($mimap{$instance});
    $hdr_only = 1 if $mi && $mi->unrecoverable;
    die "Failed to undo" unless Mail::DKIM2::MessageInstance->undo($msg1, HeadersOnly => $hdr_only);
    # Email::MIME keeps internal caches which get broken by replacing the body
    $instance--;
    last unless $instance;
    $msg1 = parse_mime($msg1->as_string);
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
  $verifier->headers_only(1) if $hdr_only;
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

# i= and m= of a DKIM2-Signature, read with the tag-list parser so FWS around
# "=" (which the syntax allows) is no obstacle. Both are already known to be
# in range (checked above).
sub _geti { return _sigtag(shift, 'sequence') }
sub _getv { return _sigtag(shift, 'version') }

sub _sigtag {
  my ($arg, $tag) = @_;
  my $sig = eval { Mail::DKIM2::Signature->parse($arg) } or return 0;
  my $v = $sig->$tag;
  return (defined $v && $v =~ /\A[0-9]+\z/) ? 0 + $v : 0;
}

sub find_key {
  my ($signature, $idx) = @_;
  $idx //= 0;
  my $sel = $signature->selector($idx);
  my $dom = $signature->domain;
  my $key_txt = $dns->{$dom}{"$sel._domainkey"}[0][1];
  return parse_dkim_pubkey($key_txt);
}
