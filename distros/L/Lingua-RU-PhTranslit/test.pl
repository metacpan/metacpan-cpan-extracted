#!/usr/bin/perl -w
# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use Test;
BEGIN { plan tests => 7 };
use Lingua::RU::PhTranslit qw( koi2phtr phtr2koi koi2win win2koi koi2alt alt2koi );
ok(1); # If we made it this far, we're ok.
$phtr="ABVGDEJo";
$alt="ÄÅÇÉÑÖŸ";
$koi="·‚˜Á‰Â≥";
$win="¿¡¬√ƒ≈®";
ok(koi2phtr($koi), $phtr);
ok(phtr2koi($phtr), $koi);
ok(koi2win($koi), $win);
ok(win2koi($win), $koi);
ok(koi2alt($koi), $alt);
ok(alt2koi($alt), $koi);



#########################

# Insert your test code below, the Test module is use()ed here so read
# its man page ( perldoc Test ) for help writing this test script.

__END__
