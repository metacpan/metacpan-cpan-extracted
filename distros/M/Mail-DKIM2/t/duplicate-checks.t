#!/usr/bin/perl -w
use 5.020;
use strict;
use warnings;
use Test::More;
use lib 'lib', 't/lib';
use Mail::DKIM2::Signature;
use Mail::DKIM2::MessageInstance;

# --- -08 §10.9: DKIM2-Signature s= duplicate/limit checks ---

my $clean = Mail::DKIM2::Signature->parse(
    'i=1; m=1; t=1740000000; d=a.example; nd=b.example; '
  . 's=sel1:rsa-sha256:AAAA,sel2:ed25519-sha256:BBBB');
is_deeply([Mail::DKIM2::Signature::check_duplicates($clean)], [],
          'clean signature list has no errors');

my $dup_sel = Mail::DKIM2::Signature->parse(
    'i=3; m=1; t=1740000000; d=a.example; nd=b.example; '
  . 's=sel1:rsa-sha256:AAAA,sel1:ed25519-sha256:BBBB');
my @errs = Mail::DKIM2::Signature::check_duplicates($dup_sel);
is_deeply(\@errs, ['PERMERROR: DKIM2-Signature i=3 has a duplicate selector'],
          '-08 §10.9: a Selector MUST NOT repeat');

my $dup_sel_ci = Mail::DKIM2::Signature->parse(
    'i=1; m=1; t=1740000000; d=a.example; nd=b.example; '
  . 's=Sel1:rsa-sha256:AAAA,sel1:ed25519-sha256:BBBB');
like((Mail::DKIM2::Signature::check_duplicates($dup_sel_ci))[0],
     qr/has a duplicate selector/,
     '-08 §3.6: Selector matching is case-insensitive (Selector is a Domain)');

my $twice = Mail::DKIM2::Signature->parse(
    'i=1; m=1; t=1740000000; d=a.example; nd=b.example; '
  . 's=sel1:rsa-sha256:AAAA,sel2:rsa-sha256:BBBB');
is_deeply([Mail::DKIM2::Signature::check_duplicates($twice)], [],
          '-08 §10.9: same algorithm twice with distinct Selectors is allowed');

my $thrice = Mail::DKIM2::Signature->parse(
    'i=2; m=1; t=1740000000; d=a.example; nd=b.example; '
  . 's=sel1:rsa-sha256:AAAA,sel2:rsa-sha256:BBBB,sel3:rsa-sha256:CCCC');
is_deeply([Mail::DKIM2::Signature::check_duplicates($thrice)], [],
          '-08 §10.9: any number of same-algorithm signatures with distinct Selectors');

my $dup_sel_and_alg = Mail::DKIM2::Signature->parse(
    'i=1; m=1; t=1740000000; d=a.example; nd=b.example; '
  . 's=sel1:rsa-sha256:AAAA,sel1:rsa-sha256:BBBB');
my @combo_errs = Mail::DKIM2::Signature::check_duplicates($dup_sel_and_alg);
is_deeply(\@combo_errs, ['PERMERROR: DKIM2-Signature i=1 has a duplicate selector'],
          'duplicate selector detected');

my $across = Mail::DKIM2::Signature->parse(
    'i=1; m=1; t=1740000000; d=a.example; nd=b.example; '
  . 's=sel1:rsa-sha256:AAAA|SEL1:ed25519-sha256:BBBB');
is_deeply([Mail::DKIM2::Signature::check_duplicates($across)],
          ['PERMERROR: DKIM2-Signature i=1 has a duplicate selector'],
          '-08 §10.9: a Selector twice across "|" groups, in any case');

# --- -08 §9.3: Message-Instance h= duplicate hash algorithm ---

my $mi_sets = Mail::DKIM2::MessageInstance::parse_hash_sets('sha256:AAAA:BBBB|sha256:CCCC:DDDD');
my %seen;
my $dup = grep { $seen{$_->[0]}++ } @$mi_sets;
ok($dup, 'duplicate hash algorithm across "|" groups is in the parse_hash_sets list');

eval {
    Mail::DKIM2::MessageInstance->parse('m=7; h=sha256:AAAA:BBBB,sha256:CCCC:DDDD;');
};
like($@, qr/^PERMERROR: Message-Instance m=7 has a duplicate hash algorithm/,
     '-08 §9.3: MessageInstance::parse dies with the exact PERMERROR string on a duplicate');

eval {
    Mail::DKIM2::MessageInstance->parse('m=7; h=sha256:AAAA:BBBB|sha256:CCCC:DDDD;');
};
like($@, qr/^PERMERROR: Message-Instance m=7 has a duplicate hash algorithm/,
     '-08 §9.3: duplicate hash algorithm across "|" groups via parse()');

my $two_names = Mail::DKIM2::MessageInstance->parse('m=7; h=sha256:AAAA:BBBB,SHA256:CCCC:DDDD;');
ok($two_names, '-08 §2.14: SHA256 is not sha256 (names are case-sensitive)');

my $ok_mi = Mail::DKIM2::MessageInstance->parse('m=7; h=sha256:AAAA:BBBB,sha512:CCCC:DDDD;');
ok($ok_mi, 'two distinct hash algorithms parse cleanly');
is_deeply($ok_mi->get_tag('hashes'),
          { sha256 => ['AAAA', 'BBBB'], sha512 => ['CCCC', 'DDDD'] },
          'both hash-sets are retained when algorithms differ');

done_testing();
