BEGIN {
  $tests = 32;
  if ($ENV{'WITH_CRC64'}) {
    $tests=$tests+2;
  }
  $| = 1;

  eval "use Test::More tests => $tests";

  $@ and eval <<'ENDEV';
$ok = 1;

print "1..$tests\n";

sub ok {
  my($res,$comment) = @_;
  defined $comment and print "# $comment\n";
  $res or print "not ";
  print "ok ", $ok++, "\n";
}
ENDEV
}

use Digest::CRC qw(crc64 crc32 crc16 crcccitt crc8 crcopenpgparmor
                   crc64_hex crc32_hex crc16_hex crcsaej1850 crcccitt_hex crc8_hex crcopenpgparmor_hex);
ok(1, 'use');

my $input = "123456789";
my ($crc32,$crc16,$crcsaej1850,$crcccitt,$crc8) = (crc32($input),crc16($input),crcsaej1850($input),crcccitt($input),crc8($input));

if ($ENV{'WITH_CRC64'}) {
  my $crc64 = crc64($input);
  ok($crc64 == 5090661014116757502, 'crc64 '.$crc64); 
  $ctx = Digest::CRC->new(type=>"crc64"); 
  $ctx->add($input);
  $crc64 = $ctx->digest;
  ok($crc64 == 5090661014116757502, 'OO crc64 '.$crc64); 
}

ok($crc32 == 3421780262, 'crc32'); 
$crc32=$crc32^0xffffffff;
ok(crc32($input.join('', 
                 map {chr(($crc32>>(8*$_))&0xff)} (0,1,2,3))) == 0xffffffff,
   'crc32 Nulltest');
ok($crcsaej1850 == 75, 'crcsaej1850'); 
ok($crcccitt == 10673, 'crcccitt'); 
ok($crc16 == 47933, 'crc16'); 
ok($crc8 == 244, 'crc8'); 
ok(($crc8=crc8($input.chr($crc8))) == 0, 'crc8 Nulltest');
my $ctx; $ctx = Digest::CRC->new(); 
$ctx->add($input);
ok($ctx->digest == 3421780262, 'OO crc32'); 

$crc32=$crc32^0xffffffff;


# addfile
open(F,"<README")||die "Cannot open README";
$ctx->addfile(F);
close(F);
my $y = $ctx->digest;
ok($y == 2682625271, 'OO crc32 with addfile '.$y); 

# start at offset >0 with previous checksum result
$ctx = Digest::CRC->new(type=>"crc32",cont=>1,init=>460478609); 
open(F,"<README")||die "Cannot open README";
use Fcntl qw(:seek);
seek(F,989,Fcntl::SEEK_SET);
$ctx->addfile(F);
close(F);
$y = $ctx->digest;
ok($y == 2316035660, 'OO crc32 with init and addfile '.$y); 

$ctx = Digest::CRC->new(type=>"crcccitt"); 
$ctx->add($input);
ok($ctx->digest == 10673, 'OO crcccitt'); 

$ctx = Digest::CRC->new(type=>"crc16"); 
$ctx->add($input);
ok($ctx->digest == 47933, 'OO crc16'); 

$ctx = Digest::CRC->new(width=>16,init=>0,xorout=>0,refout=>1,poly=>0x3456,
                        refin=>1,cont=>0);
$ctx->add($input);
ok($ctx->digest == 12803, 'OO crc16 poly 3456'); 

$ctx = Digest::CRC->new(type=>"crc8");
$ctx->add($input);
ok($ctx->digest == 244, 'OO crc8');

# crc8 test from Mathis Moder <mathis@pixelconcepts.de>
$ctx = Digest::CRC->new(width=>8, init=>0xab, xorout=>0x00, refout=>0, poly=>0x07,
                        refin=>0, cont=>0);
$ctx->add($input);
ok($ctx->digest == 135, 'OO crc8 init=ab');

$ctx = Digest::CRC->new(width=>8, init=>0xab, xorout=>0xff, refout=>1, poly=>0x07,
                        refin=>1, cont=>0);
$ctx->add("f1");
ok($ctx->digest == 106, 'OO crc8 init=ab, refout');

$input = join '', 'aa'..'zz';
($crc32,$crc16,$crcccitt,$crc8) = (crc32($input),crc16($input),crcccitt($input),crc8($input));

# some more large messages
ok($crc32 == 0xCDA63E54, 'crc32'); 
ok($crcccitt == 0x9702, 'crcccitt'); 
ok($crc16 == 0x0220, 'crc16'); 
ok($crc8 == 0x82, 'crc8'); 

# hex digest
my $hexinput = "ae";
($crc32,$crc16,$crcccitt,$crc8,$crcopenpgparmor) = (crc32_hex($hexinput),crc16_hex($hexinput),crcccitt_hex($hexinput),crc8_hex($hexinput),crcopenpgparmor_hex($hexinput));
ok($crc32 == "00e7ddce", 'crc32_hex');  # width padding to 4 bytes
ok($crcccitt == "1917", 'crcccitt_hex'); 
ok($crc16 == "bbe9", 'crc16_hex'); 
ok($crc8 == "dc", 'crc8_hex'); 
ok($crcopenpgparmor == "3e653a", 'crcopenpgparmor_hex'); 

$ctx = Digest::CRC->new(type=>"crc8"); 
$ctx->add($hexinput);
ok($ctx->hexdigest == "dc", 'OO crc8 hex'); 
$ctx = Digest::CRC->new(type=>"crc16"); 
$ctx->add($hexinput);
ok($ctx->hexdigest == "bbe9", 'OO crc16 hex'); 
$ctx = Digest::CRC->new(type=>"crc32"); 
$ctx->add($hexinput);
ok($ctx->hexdigest == "00e7ddce", 'OO crc32 hex'); 
$ctx = Digest::CRC->new(type=>"crcccitt"); 
$ctx->add($hexinput);
ok($ctx->hexdigest == "1917", 'OO crcccitt hex'); 
$ctx = Digest::CRC->new(type=>"crcopenpgparmor"); 
$ctx->add($hexinput);
ok($ctx->hexdigest == "3e653a", 'OO crcopenpgparmor hex'); 

# openpgparmor
my $openpgparmor = crcopenpgparmor($input);
ok($openpgparmor == 4874579, 'openpgparmor '.$openpgparmor); 
