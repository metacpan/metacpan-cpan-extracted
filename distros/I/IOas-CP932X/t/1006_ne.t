######################################################################
#
# 1006_ne.t
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
    sub {     IOas::CP932X::ne('Ｂ','Ａ')       },
    sub { not IOas::CP932X::ne('Ｂ','Ｂ')       },
    sub {     IOas::CP932X::ne('Ｂ','Ｃ')       },
    sub {     IOas::CP932X::ne('２２','２')     },
    sub { not IOas::CP932X::ne('２２','２２')   },
    sub {     IOas::CP932X::ne('２２','２２２') },
    sub {     IOas::CP932X::ne('２２','１１０') },
    sub {     IOas::CP932X::ne('２２','３３０') },
    sub {     IOas::CP932X::ne('２２','１')     },
    sub {     IOas::CP932X::ne('２２','３')     },
#
);

$|=1; print "1..",scalar(@test),"\n"; my $testno=1; sub ok { print $_[0]?'ok ':'not ok ',$testno++,$_[1]?" - $_[1]\n":"\n" } ok($_->()) for @test;

__END__
