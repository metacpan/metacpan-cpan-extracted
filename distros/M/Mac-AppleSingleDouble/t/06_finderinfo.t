use Test;
BEGIN { plan tests => 8 }

use Mac::AppleSingleDouble;
my $adfile = new Mac::AppleSingleDouble('./t/.AppleDouble/Perl.com_The_Source_for_Perl');
#print "\nChecking Finder info...\n";
my $finfo = $adfile->get_finder_info();
ok($finfo);
ok($finfo->{'Type'}, 'URL ');
ok($finfo->{'Creator'}, 'MOSS');
ok($finfo->{'Flags'}, 264);
ok($finfo->{'HasBeenInited'}, 1);
ok($finfo->{'Label'}, 4);
ok($finfo->{'LabelColor'}, 'Cyan');
ok($finfo->{'LabelName'}, 'Cool');
$adfile->close();
