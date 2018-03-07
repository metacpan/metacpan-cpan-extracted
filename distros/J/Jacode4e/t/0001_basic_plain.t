######################################################################
#
# 0001_basic_test_plain.t
#
# Copyright (c) 2018 INABA Hitoshi <ina@cpan.org> in a CPAN
######################################################################

use strict;
use FindBin;
use lib "$FindBin::Bin/../lib";

BEGIN { $|=1; print "1..11\n"; my $testno=1; sub ok { print $_[0]?'ok ':'not ok ',$testno++,$_[1]?" - $_[1]\n":"\n" }}

use Jacode4e;

my $return = 0;
my $line = '';

$line = "\x81\x40";
$return = Jacode4e::convert(\$line,'jef','cp932');
ok($line eq "\xA1\xA1", qq{cp932(8140) to jef(A1A1) => return=$return,got=(@{[uc unpack('H*',$line)]})});

$line = "\x81\x40";
$return = Jacode4e::convert(\$line,'jef','cp932',{});
ok($line eq "\xA1\xA1", qq{cp932(8140) to jef(A1A1), {} => return=$return,got=(@{[uc unpack('H*',$line)]})});

$line = "\x81\x40";
$return = Jacode4e::convert(\$line,'jef','cp932',{'SPACE'=>"\x40\x40"});
ok($line eq "\x40\x40", qq{cp932(8140) to jef(4040), {SPACE=>4040} => return=$return,got=(@{[uc unpack('H*',$line)]})});

$line = "\xFC\xFC";
$return = Jacode4e::convert(\$line,'jef','cp932',{});
ok($line eq "\xA2\xAE", qq{cp932(FCFC) to jef(A2AE), {} => return=$return,got=(@{[uc unpack('H*',$line)]})});

$line = "\xFC\xFC";
$return = Jacode4e::convert(\$line,'jef','cp932',{'GETA'=>"\xFE\xFE"});
ok($line eq "\xFE\xFE", qq{cp932(FCFC) to jef(FEFE), {GETA=>FEFE} => return=$return,got=(@{[uc unpack('H*',$line)]})});

$line = "\x28\xA1\xA1";
$return = Jacode4e::convert(\$line,'cp932','jef');
ok($line eq "\x81\x40", qq{jef(28A1A1) to cp932(8140) => return=$return,got=(@{[uc unpack('H*',$line)]})});

$line = "\x28\xA1\xA1\x29\xF1";
$return = Jacode4e::convert(\$line,'cp932','jef');
ok($line eq "\x81\x40\x31", qq{jef(28A1A129F1) to cp932(814031) => return=$return,got=(@{[uc unpack('H*',$line)]})});

$line = "\xA1\xA1\xF1";
$return = Jacode4e::convert(\$line,'cp932','jef',{'INPUT_LAYOUT'=>'DS'});
ok($line eq "\x81\x40\x31", qq{jef(A1A1F1) to cp932(814031), {INPUT_LAYOUT=>DS} => return=$return,got=(@{[uc unpack('H*',$line)]})});

$line = "\x81\x40\x31";
$return = Jacode4e::convert(\$line,'jef','cp932');
ok($line eq "\xA1\xA1\xF1", qq{cp932(814031) to jef(A1A1F1) => return=$return,got=(@{[uc unpack('H*',$line)]})});

$line = "\x81\x40\x31";
$return = Jacode4e::convert(\$line,'jef','cp932',{'OUTPUT_SHIFTING'=>1});
ok($line eq "\x28\xA1\xA1\x29\xF1", qq{cp932(814031) to jef(28A1A129F1), {OUTPUT_SHIFTING=>1} => return=$return,got=(@{[uc unpack('H*',$line)]})});

$line = "\xA1\xA1\xFE\xFE\xF1";
$return = Jacode4e::convert(\$line,'jipsj','jef',{'INPUT_LAYOUT'=>'DDS','OUTPUT_SHIFTING'=>1,'SPACE'=>"\x20\x20",'GETA'=>"\x7E\x7E"});
ok($line eq "\x1A\x70\x20\x20\x7E\x7E\x1A\x71\x31", qq{jef(A1A1F1) to jipsj(1A7020207E7E1A7131), {INPUT_LAYOUT=>DS,OUTPUT_SHIFTING=>1,SPACE=>2020,GETA=>7E7E} => return=$return,got=(@{[uc unpack('H*',$line)]})});

__END__
