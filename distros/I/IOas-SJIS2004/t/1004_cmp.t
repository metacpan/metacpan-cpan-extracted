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
use IOas::SJIS2004;
use vars qw(@test);

@test = (
# 1
    sub { IOas::SJIS2004::cmp('B','A')    == 1  },
    sub { IOas::SJIS2004::cmp('B','B')    == 0  },
    sub { IOas::SJIS2004::cmp('B','C')    == -1 },
    sub { IOas::SJIS2004::cmp('22','2')   == 1  },
    sub { IOas::SJIS2004::cmp('22','22')  == 0  },
    sub { IOas::SJIS2004::cmp('22','222') == -1 },
    sub { IOas::SJIS2004::cmp('22','110') == 1  },
    sub { IOas::SJIS2004::cmp('22','330') == -1 },
    sub { IOas::SJIS2004::cmp('22','1')   == 1  },
    sub { IOas::SJIS2004::cmp('22','3')   == -1 },
#
# 11
    sub { IOas::SJIS2004::cmp('Ｂ','Ａ')       == 1  },
    sub { IOas::SJIS2004::cmp('Ｂ','Ｂ')       == 0  },
    sub { IOas::SJIS2004::cmp('Ｂ','Ｃ')       == -1 },
    sub { IOas::SJIS2004::cmp('２２','２')     == 1  },
    sub { IOas::SJIS2004::cmp('２２','２２')   == 0  },
    sub { IOas::SJIS2004::cmp('２２','２２２') == -1 },
    sub { IOas::SJIS2004::cmp('２２','１１０') == 1  },
    sub { IOas::SJIS2004::cmp('２２','３３０') == -1 },
    sub { IOas::SJIS2004::cmp('２２','１')     == 1  },
    sub { IOas::SJIS2004::cmp('２２','３')     == -1 },
#
);

$|=1; print "1..",scalar(@test),"\n"; my $testno=1; sub ok { print $_[0]?'ok ':'not ok ',$testno++,$_[1]?" - $_[1]\n":"\n" } ok($_->()) for @test;

__END__
