use Test;
BEGIN { plan tests => 1 }

use Mac::AppleSingleDouble;

my $adfile = new Mac::AppleSingleDouble('./t/.AppleDouble/Perl.com_The_Source_for_Perl');
ok($adfile->get_file_format(), 'AppleDouble');
$adfile->close();
