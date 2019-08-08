######################################################################
#
# 1001_length.t
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
    sub { $_='';           IOas::CP932NEC::length($_) == 0  },
    sub { $_='1';          IOas::CP932NEC::length($_) == 1  },
    sub { $_='12';         IOas::CP932NEC::length($_) == 2  },
    sub { $_='123';        IOas::CP932NEC::length($_) == 3  },
    sub { $_='ABCD';       IOas::CP932NEC::length($_) == 4  },
    sub { $_='ｱｲｳｴｵ';      IOas::CP932NEC::length($_) == 5  },
    sub { $_='あいうえお'; IOas::CP932NEC::length($_) == 10 },
    sub {1},
    sub {1},
    sub {1},
# 11
    sub { $_='';           IOas::CP932NEC::length() == 0    },
    sub { $_='1';          IOas::CP932NEC::length() == 1    },
    sub { $_='12';         IOas::CP932NEC::length() == 2    },
    sub { $_='123';        IOas::CP932NEC::length() == 3    },
    sub { $_='ABCD';       IOas::CP932NEC::length() == 4    },
    sub { $_='ｱｲｳｴｵ';      IOas::CP932NEC::length() == 5    },
    sub { $_='あいうえお'; IOas::CP932NEC::length() == 10   },
    sub {1},
    sub {1},
    sub {1},
# 21
    sub { ('CP932NEC' eq ('CP'.'932'.'X')) == do { $_='彁';   IOas::CP932NEC::length($_) == 4} },
    sub { ('CP932NEC' eq ('CP'.'932'.'X')) == do { $_='彁彁'; IOas::CP932NEC::length($_) == 8} },
    sub { ('CP932NEC' eq ('CP'.'932'.'X')) == do { $_='彁';   IOas::CP932NEC::length()   == 4} },
    sub { ('CP932NEC' eq ('CP'.'932'.'X')) == do { $_='彁彁'; IOas::CP932NEC::length()   == 8} },
    sub {1},
    sub {1},
    sub {1},
    sub {1},
    sub {1},
    sub {1},
#
);

$|=1; print "1..",scalar(@test),"\n"; my $testno=1; sub ok { print $_[0]?'ok ':'not ok ',$testno++,$_[1]?" - $_[1]\n":"\n" } ok($_->()) for @test;

__END__
