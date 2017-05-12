use Test;
BEGIN { plan tests => 1 }

use Mac::AppleSingleDouble;
my $adfile = new Mac::AppleSingleDouble('./t/.AppleDouble/Perl.com_The_Source_for_Perl');
#print "\nChanging label colors...\n";
$adfile->set_labelcolors({0 => 'None',
			  1 => 'ColorOne',
			  2 => 'ColorTwo',
			  3 => 'ColorThree',
			  4 => 'ColorFour',
			  5 => 'ColorFive',
			  6 => 'ColorSix',
			  7 => 'ColorSeven'});
$finfo = $adfile->get_finder_info();
ok($finfo->{'LabelColor'}, 'ColorFour');
$adfile->close();
