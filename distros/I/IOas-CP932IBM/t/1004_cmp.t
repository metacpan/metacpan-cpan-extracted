######################################################################
#
# 1004_cmp.t
#
# Copyright (c) 2019 INABA Hitoshi <ina@cpan.org> in a CPAN
######################################################################

# This file is encoded in UTF-8.
die "This file is not encoded in UTF-8.\n" if 'あ' ne "\xe3\x81\x82";
die "This script is for perl only. You are using $^X.\n" if $^X =~ /jperl/i;

use strict;
use FindBin;
use lib "$FindBin::Bin/../lib";
use IOas::CP932IBM;
use vars qw(@test);

@test = (
# 1
    sub { IOas::CP932IBM::cmp('B','A')    == 1  },
    sub { IOas::CP932IBM::cmp('B','B')    == 0  },
    sub { IOas::CP932IBM::cmp('B','C')    == -1 },
    sub { IOas::CP932IBM::cmp('22','2')   == 1  },
    sub { IOas::CP932IBM::cmp('22','22')  == 0  },
    sub { IOas::CP932IBM::cmp('22','222') == -1 },
    sub { IOas::CP932IBM::cmp('22','110') == 1  },
    sub { IOas::CP932IBM::cmp('22','330') == -1 },
    sub { IOas::CP932IBM::cmp('22','1')   == 1  },
    sub { IOas::CP932IBM::cmp('22','3')   == -1 },
#
# 11
    sub { IOas::CP932IBM::cmp('Ｂ','Ａ')       == 1  },
    sub { IOas::CP932IBM::cmp('Ｂ','Ｂ')       == 0  },
    sub { IOas::CP932IBM::cmp('Ｂ','Ｃ')       == -1 },
    sub { IOas::CP932IBM::cmp('２２','２')     == 1  },
    sub { IOas::CP932IBM::cmp('２２','２２')   == 0  },
    sub { IOas::CP932IBM::cmp('２２','２２２') == -1 },
    sub { IOas::CP932IBM::cmp('２２','１１０') == 1  },
    sub { IOas::CP932IBM::cmp('２２','３３０') == -1 },
    sub { IOas::CP932IBM::cmp('２２','１')     == 1  },
    sub { IOas::CP932IBM::cmp('２２','３')     == -1 },
#
);

$|=1; print "1..",scalar(@test),"\n"; my $testno=1; sub ok { print $_[0]?'ok ':'not ok ',$testno++,$_[1]?" - $_[1]\n":"\n" } ok($_->()) for @test;

__END__
