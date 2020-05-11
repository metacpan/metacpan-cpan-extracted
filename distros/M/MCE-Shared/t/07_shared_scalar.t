#!/usr/bin/env perl

use strict;
use warnings;
use utf8;

use Test::More;

BEGIN {
   use_ok 'MCE::Flow';
   use_ok 'MCE::Shared';
   use_ok 'MCE::Shared::Scalar';
}

MCE::Flow::init {
   max_workers => 1
};

tie my $s1, 'MCE::Shared', 10;
tie my $s2, 'MCE::Shared', '';

is( tied($s1)->blessed(), 'MCE::Shared::Scalar', 'shared scalar, tied ref' );

my $s5 = MCE::Shared->scalar( 0 );

## --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- ---

MCE::Flow::run( sub {
   $s1 +=  5;
   $s2 .= '';
   $s5->set(20);
});

MCE::Flow::finish;

is( $s1, 15, 'shared scalar, check fetch, store' );
is( $s2, '', 'shared scalar, check blank value' );
is( $s5->get(), 20, 'shared scalar, check value' );

## --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- ---

is( $s5->len(), 2, 'shared scalar, check length' );
is( $s5->incr(), 21, 'shared scalar, check incr' );
is( $s5->decr(), 20, 'shared scalar, check decr' );
is( $s5->incrby(4), 24, 'shared scalar, check incrby' );
is( $s5->decrby(4), 20, 'shared scalar, check decrby' );
is( $s5->getincr(), 20, 'shared scalar, check getincr' );
is( $s5->get(), 21, 'shared scalar, check value after getincr' );
is( $s5->getdecr(), 21, 'shared scalar, check getdecr' );
is( $s5->get(), 20, 'shared scalar, check value after getdecr' );
is( $s5->append('ba'), 4, 'shared scalar, check append' );
is( $s5->get(), '20ba', 'shared scalar, check value after append' );
is( $s5->getset('foo'), '20ba', 'shared scalar, check getset' );
is( $s5->get(), 'foo', 'shared scalar, check value after getset' );

## --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- ---

## https://sacred-texts.com/cla/usappho/sph02.htm (VII)

my $sappho_text =
  "ἔλθε μοι καὶ νῦν, χαλεπᾶν δὲ λῦσον
   ἐκ μερίμναν ὄσσα δέ μοι τέλεσσαι
   θῦμοσ ἰμμέρρει τέλεσον, σὐ δ᾽ αὔτα
   σύμμαχοσ ἔσσο.";

my $translation =
  "Come then, I pray, grant me surcease from sorrow,
   Drive away care, I beseech thee, O goddess
   Fulfil for me what I yearn to accomplish,
   Be thou my ally.";

$s5->set( $sappho_text );
is( $s5->get(), $sappho_text, 'shared scalar, check unicode set' );
is( $s5->len(), length($sappho_text), 'shared scalar, check unicode len' );

my $length = $s5->append("Ǣ");
is( $s5->get(), $sappho_text . "Ǣ", 'shared scalar, check unicode append' );
is( $length, length($sappho_text) + 1, 'shared scalar, check unicode length' );

done_testing;

