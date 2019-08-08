######################################################################
#
# 1002_sprintf.t
#
# Copyright (c) 2019 INABA Hitoshi <ina@cpan.org> in a CPAN
######################################################################

# This file is encoded in UTF-8.
die "This file is not encoded in UTF-8.\n" if 'あ' ne "\xe3\x81\x82";
die "This script is for perl only. You are using $^X.\n" if $^X =~ /jperl/i;

use strict;
use FindBin;
use lib "$FindBin::Bin/../lib";
use IOas::CP932;
use vars qw(@test);

@test = (
# 1
    sub { IOas::CP932::sprintf('あ')               eq 'あ'        },
    sub { IOas::CP932::sprintf('あ%04d', 1)        eq 'あ0001'    },
    sub { IOas::CP932::sprintf('あ%sう', 'い')     eq 'あいう'    },
    sub { IOas::CP932::sprintf('あ%1sう', 'い')    eq 'あいう'    },
    sub { IOas::CP932::sprintf('あ%2sう', 'い')    eq 'あいう'    },
    sub { IOas::CP932::sprintf('あ%3sう', 'い')    eq 'あ いう'   },
    sub { IOas::CP932::sprintf('あ%-3sう', 'い')   eq 'あい う'   },
    sub { IOas::CP932::sprintf('あ%-3sえ', 'いう') eq 'あいうえ'  },
    sub { IOas::CP932::sprintf('あ%-4sえ', 'いう') eq 'あいうえ'  },
    sub { IOas::CP932::sprintf('あ%-5sえ', 'いう') eq 'あいう え' },
#
);

$|=1; print "1..",scalar(@test),"\n"; my $testno=1; sub ok { print $_[0]?'ok ':'not ok ',$testno++,$_[1]?" - $_[1]\n":"\n" } ok($_->()) for @test;

__END__
