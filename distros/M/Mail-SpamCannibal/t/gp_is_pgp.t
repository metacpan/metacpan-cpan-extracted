# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

######################### We start with some black magic to print on failure.
# Change 1..1 below to 1..last_test_to_print .
# (It may become useful if the test is moved to ./t subdirectory.)

BEGIN { $| = 1; print "1..24\n"; }
END {print "not ok 1\n" unless $loaded;}

use Mail::SpamCannibal::ParseMessage qw(
	string2array
	array2string
);
use Mail::SpamCannibal::GoodPrivacy qw(
	is_pgp
);

$loaded = 1;
print "ok 1\n";
######################### End of black magic.

# Insert your test code below (better if it prints "ok 13"
# (correspondingly "not ok 13") depending on the success of chunk 13
# of the test code):

$test = 2;

sub ok {
  print "ok $test\n";
  ++$test;
}

my $TOPMSG = '-----BEGIN PGP';
my $END = '-----END';
my $msgtop = q|

This test message is from the web page I found via Tom McCune's
page for Pretty Good Privacy: http://www.mccune.cc/PGP.htm
the link says: PGP Format "Oddities" and points to:
http://www.angelfire.com/pr/pgpf/pgpoddities.html
message: example,  TeE1.txt 
found at: http://www.angelfire.com/pr/pgpf/TeE1.html

-----BEGIN PGP MESSAGE-----|;

my $msgcmt = q|
Version: 6.5.8ckt http://www.ipgpp.com/
Comment: { Acts of Kindness better the World, and protect the Soul }
comment: lines and spaces between comment line and message block
comment:2
comment:3
comment:4
comment:5
comment:6
version:7.5 ;-)
comment:
version:|;

# odd characters, not radix64 are allowed by some pgp
# implementations, but we will not allow them
my $invalid1 = q|
~!@#$%^&*()_+`={}|. '|' .q|[]\;':"<>?,./-
|;

# only one blank line is allowed by some pgp implementations
# so multiple blank lines will fail our verification
my $invalid2 = q|



|;

my $msgblank = "\n";
my $msgbot = q|
hQEMA/FWZIj3ev97AQf/f7bIeHDbMdtogl66vhiac0+1rRFJQcez6bQn246ePb7+
DDvWUI68TBKlXgY191l22UcyblfFC1TGNqZSj7JdMIDlozuAg20KuMGelxMjJ/dW
int5bN5PO5RQ+NFHZh6Io7rY6+vjwL/AcXachHfUBDQ6kDroKCoz3DRWkOY5pIrj
mp9ENOg8As+cm3mna6HwMnD8VYJ4j69jowV5fVtxhk/yH7Dqq32sokq84ZCCDumm
06CLS9z+TUNaySbfbkAsZmBbuKgbURDBLpjG7Hu7Uq5+mTnElfTDjA5lkKUo4MQt
zUuWlrcl525BJcNv5K8SJ7J4PA91D6wctutt8qpxsaQYVyz2Bl/at+VpK340UJkf
YC/aFMn/PtxT
=H1si
|;

my $msgend = q|-----END ESP MESSAGE-----

|;

my $signed = q|
-----BEGIN PGP SIGNED MESSAGE-----
Hash: RIPEMD160

this line ends in a'TAB'

-----BEGIN PGP SIGNATURE-----
Version: 6.5.8ckt http://www.ipgpp.com/
Comment: { Acts of Kindness better the World, and protect the Soul }
Comment: KeyID: 0xF246E1FA7B534E2D
Comment: Fingerprint: BFBF 905E DBF7 E388 3340  FD02 F246 E1FA 7B53 4E2D

iQA/AwUBPiq/y/JG4fp7U04tEQNk0wCfVx3aAKiEnnjzHv0KTl75GVCDb5gAniZK
xXqrq4ohNAxHOq11eQ1bckzE
=kvxA
-----END PGP SIGNATURE-----
|;

#        not an array ref
#        signed cleartext
#        no BEGIN PGP
#        no blank line
#        no armor text  
#        non-armor text
#        no END
        

my $tstmes = [];
my($count,$begin,$end,$err);

## two test cycles
sub fail {
  my($inTxt,$exp) = @_;
  string2array($inTxt,$tstmes);
  print "failed to find: $exp\nnot "
	if is_pgp($tstmes,\$err);
  &ok;

  ## next test;
  print "error says: |$err|\nnot "
	unless $err eq $exp;
  &ok;
}

## test 2-3 -- fail on signed cleartext
fail($signed,'signed cleartext');

## test 4-5 -- fail on missing BEGIN
fail($msgbot.$msgblank.$msgend,'no BEGIN');

## test 6-7 -- fail on missing 'blank line'
fail($msgtop.$msgbot.$msgend,'no blank line');

## test 8-9 -- fail on missing / bad armor
fail($msgtop.$msgblank.$msgblank.$msgbot.$msgend,'no armor text');

## test 10-11 -- fail on bad chars in armor (blank line)
fail($msgtop.$msgblank.$msgbot.$msgblank.$msgend,'invalid armor');

## test 12-13 -- fail on bad chars in armor (random text containing space)
fail($msgtop.$msgblank.$msgbot."random text\n".$msgend,'invalid armor');

## test 14-15 -- fail on missing -----END
fail($msgtop.$msgblank.$msgbot,'no END');

## test 16 -- pass good message
string2array($msgtop.$msgblank.$msgbot.$msgend,$tstmes);
if ($count = @_ = is_pgp($tstmes,\$err)) {
  ($begin,$end) = @_;
} else {
  print "valid PGP message failed with error $err\nnot "
	if $err;
}
&ok;

## test 17 -- verify begin, end
my $xb = 9;
my $xe = 19;
print "exp: begin=$xb, end=$xe; got: begin=$begin, end=$end\nnot "
	unless $begin == $xb && $end == $xe;
&ok;

## test 18 -- check content of begin
print "BEGIN = $tstmes->[$begin]\nnot "
	unless  $tstmes->[$begin] =~ /$TOPMSG/o;
&ok;

## test 19 -- check content of end
print "END = $tstmes->[$end]\nnot "
	unless $tstmes->[$end] =~ /^$END/o;
&ok;

## test 20 -- pass good message with comments
string2array($msgtop.$msgcmt.$msgblank.$msgbot.$msgend,$tstmes);
if ($count = @_ = is_pgp($tstmes,\$err)) {
  ($begin,$end) = @_;
} else {
  print "valid PGP message failed with error $err\nnot "
        if $err;
}
&ok;

## test 21 -- verify begin, end
$xb = 9;
$xe = 30;
print "exp: begin=$xb, end=$xe; got: begin=$begin, end=$end\nnot "
        unless $begin == $xb && $end == $xe;
&ok;

## test 22 -- convert to array with discreet begin, end
my $result = array2string($tstmes,$begin,$end);
$count = string2array($result,$tstmes);
my $expc = 22;
print "exp: $expc, got: $count lines\nnot "
	unless $expc == $count;
&ok;

## test 23 -- check for begin
print "BEGIN = $tstmes->[0]\nnot "
	unless $tstmes->[0] =~ /$TOPMSG/o;
&ok;

## test 24 -- check for end
print "END = $tstmes->[$expc - 1]\nnot "
	 unless $tstmes->[$expc - 1] =~ /^$END/o;
&ok;
