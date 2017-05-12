use inc::Module::Install;

all_from 'lib/HTTP/MobileAgent/Flash.pm';

test_requires 'Test::More' => 0.32;
test_requires 'Test::Base';

recommends 'WWW::MobileCarrierJP' => 0.61;
requires 'HTTP::MobileAgent' => 0;
requires 'Class::Accessor' => 0;

my $make_map_script = 'bin/make_map_flash_lite.pl';
install_script $make_map_script;

my $basedir = "lib/HTTP/MobileAgent/Flash";

postamble(<<GENERATE_PM);

update_flash_map: pm_docomo pm_ezweb pm_softbank

pm_docomo:
\t$make_map_script --carrier=docomo --output=pm > $basedir/DoCoMoFlashMap.pm

pm_ezweb:
\t$make_map_script --carrier=ezweb --output=pm > $basedir/EZWebFlashMap.pm

pm_softbank:
\t$make_map_script --carrier=softbank --output=pm > $basedir/SoftBankFlashMap.pm


GENERATE_PM

WriteAll;


