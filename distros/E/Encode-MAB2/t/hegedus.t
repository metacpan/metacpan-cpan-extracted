# -*- coding: utf-8; mode: cperl -*-

# at the time of this writing (2002-09), the Hegedus record in the PND
# file was incorrect. Encode::MAB2 makes this a special case that
# should go away in the future.

# The enclose hegedus.mab contains the wrong record and the corrected
# record. The result should be different records but currently the
# records are identical. We have a TODO test there that considers them
# different.


use strict;
# Adjust the number here!
use Test::More tests => 4;

use_ok('Encode');
use_ok('Encode::MAB2');
# Add more test here!

open F, "t/hegedus.mab" or die "Couldn't open t/hegedus.mab: $!";
my $wrongrec = <F>;
my $correctrec = <F>;
close F;

use Encode::MAB2;
my $unicode = Encode::decode("MAB2",$wrongrec);
use MAB2::Record::Base;
my $mab2wr = MAB2::Record::Base->new($wrongrec);
my $mab2co = MAB2::Record::Base->new($correctrec);

ok($wrongrec eq $mab2wr->as_string, "decoding has no side-effect");

use Encode;

TODO: {
  our $TODO;
  local $TODO = "Waiting till official PND record is fixed";
  ok($mab2wr->readable ne $mab2co->readable, "fooble");
  #sprintf "wr[%s]co[%s]", Encode::encode("ascii",$mab2wr->readable,Encode::FB_PERLQQ),
  #Encode::encode("ascii",$mab2co->readable,Encode::FB_PERLQQ));
}
