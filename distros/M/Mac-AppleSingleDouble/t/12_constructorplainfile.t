use Test;
BEGIN { plan tests => 1 }

use Mac::AppleSingleDouble;
$adfile = new Mac::AppleSingleDouble('./t/Perl.com_The_Source_for_Perl');
ok($adfile->get_file_format(), 'Plain');
