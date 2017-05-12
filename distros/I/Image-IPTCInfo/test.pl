# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

######################### We start with some black magic to print on failure.

# Change 1..1 below to 1..last_test_to_print .
# (It may become useful if the test is moved to ./t subdirectory.)

BEGIN { $| = 1; print "1..6\n"; }
END {print "package load...        not ok 1\n" unless $loaded;}
use Image::IPTCInfo;
$loaded = 1;
print "package load....        ok 1\n";

######################### End of black magic.

#
# Make sure debug mode is turned off for release
#

if ($Image::IPTCInfo::debugMode == 0)
{
    print "debug mode off....      ok 2\n";
}
else
{
    print "debug mode off....      not ok 2\n";
}


#
# Test loading IPTC info
#

my $info = new Image::IPTCInfo('demo_images/burger_van.jpg');

if (defined($info) && $info->Attribute('caption/abstract') eq
    'A van full of burgers awaits mysterious buyers in a dark parking lot.')
{
    print "get caption....         ok 3\n";
}
else
{
    print "get caption....         not ok 3\n";
    print "error: " . Image::IPTCInfo::Error() . "\n";
}

#
# Test saving IPTC info
#

$info->SetAttribute('caption/abstract', 'modified caption');
$info->SaveAs('demo_images/burger_van_save1.jpg') ||
    print "error: " . Image::IPTCInfo::Error() . "\n";

undef $info;

$info = new Image::IPTCInfo('demo_images/burger_van_save1.jpg');

if (defined($info) && $info->Attribute('caption/abstract') eq 'modified caption')
{
    print "save and load....       ok 4\n";
}
else
{
    print "save and load....       not ok 4\n";
    print "error: " . Image::IPTCInfo::Error() . "\n";
}

#
# Re-load modified image and use Save() to save, then check it
#
undef $info;

$info = new Image::IPTCInfo('demo_images/burger_van_save1.jpg');

if (!defined($info))
{
    print "re-save and re-load.... not ok 5\n";
    print "error: " . Image::IPTCInfo::Error() . "\n";
    exit;
}

$info->SetAttribute('caption/abstract', 'modified caption 2');
$info->Save();

undef $info;

$info = new Image::IPTCInfo('demo_images/burger_van_save1.jpg');

if (defined($info) && $info->Attribute('caption/abstract') 
    eq 'modified caption 2')
{
    print "re-save and re-load.... ok 5\n";
}
else
{
    print "re-save and re-load.... not ok 5\n";
    print "error: " . Image::IPTCInfo::Error() . "\n";
}

use IO::File;
my $handle = IO::File->new('demo_images/burger_van_save1.jpg');
$info = Image::IPTCInfo->new($handle);
if (defined($info) && $info->Attribute('caption/abstract') 
    eq 'modified caption 2')
{
    print "re-load with handle.... ok 6\n";
}
else
{
    print "re-load with handle.... not ok 6\n";
    print "error: " . Image::IPTCInfo::Error() . "\n";
}
