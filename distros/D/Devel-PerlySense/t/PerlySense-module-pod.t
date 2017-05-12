#!/usr/bin/perl -w
use strict;

use Test::More tests => 4;
use Test::Exception;

use File::Basename;
use File::Spec::Functions;

use lib "../lib";

use_ok("Devel::PerlySense");

BEGIN { -d "t" and chdir("t"); }


ok(my $oPs = Devel::PerlySense->new(), "new ok");



my $dirData = "data/simple-lib";
my $nameModule = "Win32::Word::Writer";

ok(my $fileModule = $oPs->fileFindModule(nameModule => $nameModule, dirOrigin => $dirData), "Found file ok");

like($oPs->podFromFile(file => $fileModule), qr/Win32::Word::Writer - Create Microsoft Word documents/, "Correct POD");





__END__
