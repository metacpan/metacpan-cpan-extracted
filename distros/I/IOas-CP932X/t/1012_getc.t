######################################################################
#
# 1012_getc.t
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
    sub { open(FH,'>a'); print FH "\x82\xA0\x82\xA2"; close(FH); open(FH,'a');    my $got = IOas::CP932X::getc(FH); close(FH);    unlink('a'); $got eq 'あ' },
    sub { open(FH,'>a'); print FH "\x82\xA0\x82\xA2"; close(FH); open(STDIN,'a'); my $got = IOas::CP932X::getc();   close(STDIN); unlink('a'); $got eq 'あ' },
    sub {1},
    sub {1},
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
