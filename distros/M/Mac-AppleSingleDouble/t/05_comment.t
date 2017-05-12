use Test;
BEGIN { plan tests => 1 }

use Mac::AppleSingleDouble;
my $adfile = new Mac::AppleSingleDouble('./t/.AppleDouble/Perl.com_The_Source_for_Perl');
#print "\nReading comment from entry ID #4...\n";
my $comment = $adfile->get_entry(4);
#print "comment is '$comment'\n";
ok($comment, 'This is a Netscape bookmark to the Perl.com home page.');
$adfile->close();
