######################################################################
#
# 1007_ge.t
#
# Copyright (c) 2019 INABA Hitoshi <ina@cpan.org> in a CPAN
######################################################################

# This file is encoded in UTF-8.
die "This file is not encoded in UTF-8.\n" if 'あ' ne "\xe3\x81\x82";
die "This script is for perl only. You are using $^X.\n" if $^X =~ /jperl/i;

use strict;
use FindBin;
use lib "$FindBin::Bin/../lib";
use IOas::CP932X;
use vars qw(@test);

@test = (
# 1
    sub {     IOas::CP932X::ge('Ｂ','Ａ')       },
    sub {     IOas::CP932X::ge('Ｂ','Ｂ')       },
    sub { not IOas::CP932X::ge('Ｂ','Ｃ')       },
    sub {     IOas::CP932X::ge('２２','２')     },
    sub {     IOas::CP932X::ge('２２','２２')   },
    sub { not IOas::CP932X::ge('２２','２２２') },
    sub {     IOas::CP932X::ge('２２','１１０') },
    sub { not IOas::CP932X::ge('２２','３３０') },
    sub {     IOas::CP932X::ge('２２','１')     },
    sub { not IOas::CP932X::ge('２２','３')     },
#
);

$|=1; print "1..",scalar(@test),"\n"; my $testno=1; sub ok { print $_[0]?'ok ':'not ok ',$testno++,$_[1]?" - $_[1]\n":"\n" } ok($_->()) for @test;

__END__
