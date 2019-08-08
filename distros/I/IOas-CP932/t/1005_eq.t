######################################################################
#
# 1005_eq.t
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
    sub { not IOas::CP932::eq('Ｂ','Ａ')       },
    sub {     IOas::CP932::eq('Ｂ','Ｂ')       },
    sub { not IOas::CP932::eq('Ｂ','Ｃ')       },
    sub { not IOas::CP932::eq('２２','２')     },
    sub {     IOas::CP932::eq('２２','２２')   },
    sub { not IOas::CP932::eq('２２','２２２') },
    sub { not IOas::CP932::eq('２２','１１０') },
    sub { not IOas::CP932::eq('２２','３３０') },
    sub { not IOas::CP932::eq('２２','１')     },
    sub { not IOas::CP932::eq('２２','３')     },
#
);

$|=1; print "1..",scalar(@test),"\n"; my $testno=1; sub ok { print $_[0]?'ok ':'not ok ',$testno++,$_[1]?" - $_[1]\n":"\n" } ok($_->()) for @test;

__END__
