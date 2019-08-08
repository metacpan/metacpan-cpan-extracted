######################################################################
#
# 1009_le.t
#
# Copyright (c) 2019 INABA Hitoshi <ina@cpan.org> in a CPAN
######################################################################

# This file is encoded in UTF-8.
die "This file is not encoded in UTF-8.\n" if 'あ' ne "\xe3\x81\x82";
die "This script is for perl only. You are using $^X.\n" if $^X =~ /jperl/i;

use strict;
use FindBin;
use lib "$FindBin::Bin/../lib";
use IOas::CP932NEC;
use vars qw(@test);

@test = (
# 1
    sub { not IOas::CP932NEC::le('Ｂ','Ａ')       },
    sub {     IOas::CP932NEC::le('Ｂ','Ｂ')       },
    sub {     IOas::CP932NEC::le('Ｂ','Ｃ')       },
    sub { not IOas::CP932NEC::le('２２','２')     },
    sub {     IOas::CP932NEC::le('２２','２２')   },
    sub {     IOas::CP932NEC::le('２２','２２２') },
    sub { not IOas::CP932NEC::le('２２','１１０') },
    sub {     IOas::CP932NEC::le('２２','３３０') },
    sub { not IOas::CP932NEC::le('２２','１')     },
    sub {     IOas::CP932NEC::le('２２','３')     },
#
);

$|=1; print "1..",scalar(@test),"\n"; my $testno=1; sub ok { print $_[0]?'ok ':'not ok ',$testno++,$_[1]?" - $_[1]\n":"\n" } ok($_->()) for @test;

__END__
