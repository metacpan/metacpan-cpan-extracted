use Test;
BEGIN { plan tests => 1 }

use Mac::AppleSingleDouble;
my $adfile = new Mac::AppleSingleDouble('./t/.AppleDouble/Perl.com_The_Source_for_Perl');
#print "\nChanging label names...\n";
$adfile->set_labelnames({0 => 'None',
			 1 => 'LabelOne',
			 2 => 'LabelTwo',
			 3 => 'LabelThree',
			 4 => 'LabelFour',
			 5 => 'LabelFive',
			 6 => 'LabelSix',
			 7 => 'LabelSeven'});
$finfo = $adfile->get_finder_info();
ok($finfo->{'LabelName'}, 'LabelFour');
$adfile->close();
