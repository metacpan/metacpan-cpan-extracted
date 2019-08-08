######################################################################
#
# 1008_gt.t
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
    sub {     IOas::CP932NEC::gt('Ｂ','Ａ')       },
    sub { not IOas::CP932NEC::gt('Ｂ','Ｂ')       },
    sub { not IOas::CP932NEC::gt('Ｂ','Ｃ')       },
    sub {     IOas::CP932NEC::gt('２２','２')     },
    sub { not IOas::CP932NEC::gt('２２','２２')   },
    sub { not IOas::CP932NEC::gt('２２','２２２') },
    sub {     IOas::CP932NEC::gt('２２','１１０') },
    sub { not IOas::CP932NEC::gt('２２','３３０') },
    sub {     IOas::CP932NEC::gt('２２','１')     },
    sub { not IOas::CP932NEC::gt('２２','３')     },
#
);

$|=1; print "1..",scalar(@test),"\n"; my $testno=1; sub ok { print $_[0]?'ok ':'not ok ',$testno++,$_[1]?" - $_[1]\n":"\n" } ok($_->()) for @test;

__END__
