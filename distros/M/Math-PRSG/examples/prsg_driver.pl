#!/usr/local/bin/perl -w

use Utils::TrulyRandom;
use Crypt::SHA;
use Crypt::PRSG;
use MIME::Base64;

my $md = new SHA;

my $i;

for ($i=0; $i < 3; $i++)
{
	my $val = truly_random_value();
	print "Adding $val \n";
	$md->add($val);
}
my $result = $md->digest();

$res = encode_base64($result);

# $res =~ s/=+//;
chop $res;
print "Result = $res.\n";



$rng = new PRSG $result;
my $r;

for ($i=0; $i < 20000; $i++)
{
	$r = $rng->clock();
	$md->add($r);
	$r = $md->digest();
	$_ = unpack("B160", $r);
	s/0/\ /g;
	print $_, "\n";

	$r = $md->digest;
	$md->reset();
	$md->add($r);
}
