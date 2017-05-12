use Test;
BEGIN { plan tests => 1 }

use Mac::AppleSingleDouble;
my $adfile = new Mac::AppleSingleDouble('./t/.AppleDouble/Perl.com_The_Source_for_Perl');
#print "\nReading real filename from entry ID #3...\n";
my $realname = $adfile->get_entry(3);
#print "Realname is '$realname'\n";
ok($realname, 'Perl.com/ The Source for Perl');
$adfile->close();
