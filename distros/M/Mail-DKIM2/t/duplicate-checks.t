#!/usr/bin/perl -w
use 5.020;
use strict;
use warnings;
use Test::More;
use lib 'lib', 't/lib';
use Mail::DKIM2::Signature;
use Mail::DKIM2::MessageInstance;

# --- -07 §10.9: DKIM2-Signature s= duplicate/limit checks ---

my $clean = Mail::DKIM2::Signature->parse(
    'i=1; m=1; t=1740000000; d=a.example; nd=b.example; '
  . 's=sel1:rsa-sha256:AAA,sel2:ed25519-sha256:BBB');
is_deeply([Mail::DKIM2::Signature::check_duplicates($clean)], [],
          'clean signature list has no errors');

my $dup_sel = Mail::DKIM2::Signature->parse(
    'i=3; m=1; t=1740000000; d=a.example; nd=b.example; '
  . 's=sel1:rsa-sha256:AAA,sel1:ed25519-sha256:BBB');
my @errs = Mail::DKIM2::Signature::check_duplicates($dup_sel);
is_deeply(\@errs, ['PERMERROR: DKIM2-Signature i=3 has a duplicate selector'],
          '-07 §10.9: a Selector MUST NOT repeat');

my $dup_sel_ci = Mail::DKIM2::Signature->parse(
    'i=1; m=1; t=1740000000; d=a.example; nd=b.example; '
  . 's=Sel1:rsa-sha256:AAA,sel1:ed25519-sha256:BBB');
like((Mail::DKIM2::Signature::check_duplicates($dup_sel_ci))[0],
     qr/has a duplicate selector/,
     '-07 §3.6: Selector matching is case-insensitive (Selector is a Domain)');

my $twice = Mail::DKIM2::Signature->parse(
    'i=1; m=1; t=1740000000; d=a.example; nd=b.example; '
  . 's=sel1:rsa-sha256:AAA,sel2:rsa-sha256:BBB');
is_deeply([Mail::DKIM2::Signature::check_duplicates($twice)], [],
          '-07 §10.9: same algorithm twice with distinct Selectors is allowed');

my $thrice = Mail::DKIM2::Signature->parse(
    'i=2; m=1; t=1740000000; d=a.example; nd=b.example; '
  . 's=sel1:rsa-sha256:AAA,sel2:rsa-sha256:BBB,sel3:rsa-sha256:CCC');
is_deeply([Mail::DKIM2::Signature::check_duplicates($thrice)],
          ['PERMERROR: DKIM2-Signature i=2 has more selectors than allowed'],
          '-07 §10.9: three same-algorithm signatures exceed the selector limit');

my $dup_sel_and_alg = Mail::DKIM2::Signature->parse(
    'i=1; m=1; t=1740000000; d=a.example; nd=b.example; '
  . 's=sel1:rsa-sha256:AAA,sel1:rsa-sha256:BBB');
my @combo_errs = Mail::DKIM2::Signature::check_duplicates($dup_sel_and_alg);
ok((grep { /duplicate selector/ } @combo_errs), 'duplicate selector detected');
ok(!(grep { /more selectors than allowed/ } @combo_errs),
   '-07 §10.9: duplicate-selector and excess-selector checks are independent '
 . '(count is 2, not 3+)');

# --- -07 §9.3: Message-Instance h= duplicate hash algorithm ---

my $mi_sets = Mail::DKIM2::MessageInstance::parse_hash_sets('sha256:AAA:BBB,SHA256:CCC:DDD');
my %seen;
my $dup = grep { $seen{$_->[0]}++ } @$mi_sets;
ok($dup, 'duplicate hash algorithm detected case-insensitively in parse_hash_sets list');

eval {
    Mail::DKIM2::MessageInstance->parse('m=7; h=sha256:AAA:BBB,sha256:CCC:DDD;');
};
like($@, qr/^PERMERROR: Message-Instance m=7 has a duplicate hash algorithm/,
     '-07 §9.3: MessageInstance::parse dies with the exact PERMERROR string on a duplicate');

eval {
    Mail::DKIM2::MessageInstance->parse('m=7; h=sha256:AAA:BBB,SHA256:CCC:DDD;');
};
like($@, qr/^PERMERROR: Message-Instance m=7 has a duplicate hash algorithm/,
     '-07 §9.3: duplicate hash algorithm detected case-insensitively via parse()');

my $ok_mi = Mail::DKIM2::MessageInstance->parse('m=7; h=sha256:AAA:BBB,sha512:CCC:DDD;');
ok($ok_mi, 'two distinct hash algorithms parse cleanly');
is_deeply($ok_mi->get_tag('hashes'),
          { sha256 => ['AAA', 'BBB'], sha512 => ['CCC', 'DDD'] },
          'both hash-sets are retained when algorithms differ');

done_testing();
