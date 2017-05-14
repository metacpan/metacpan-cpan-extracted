#!/usr/local/bin/perl -w

use Utils::TrulyRandom;
use Crypt::SHA;
use MIME::Base64;

my $md = new SHA;

my $i;

for ($i=0; $i < 20; $i++)
{
	my $val = truly_random_value();
	print "Adding $val \n";
	$md->add($val);
}
my $result = $md->digest();

$result = encode_base64($result);

# $result =~ s/=+//;
chop $result;
print "Result = $result.\n";
