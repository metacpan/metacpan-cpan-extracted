use Test::Most;

use Font::Fontconfig;



plan( skip_all => "'fontconfig' most likely not installed on MS platforms")
    if $^O eq 'MSWin32';



ok( `which fc-list`, "'fontconfig' is available on this platform [$^O]" );



done_testing;
