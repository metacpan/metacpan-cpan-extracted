use Test::More;
use Socket;
use strict;
use warnings;


#plan tests => 1;

#simulate a webgui_cmd.pl
our $APPNAME = "Maplat memh test";
our $VERSION = 1.0;

BEGIN { 
    require("t/testhelpers.pm");
    my $daemon_status = connect_memcached();
    if($daemon_status ne "OK") {
        plan skip_all => "Skipping - no memchached running - OTHER TEST RESULTS MAY BE WRONG (USING A MEMCACHE SIMULATION)";
	exit(0);
    } else {
        plan tests => 2;
        use_ok('Maplat::Web::MemCache')
    }
};


eval {
    my $memh = new Maplat::Web::MemCache(service => "localhost:11211",
                                        namespace => "MaplatInstallTest::",
                                    );
}; 
if ($@) {
    fail("Useable perl memcached module $@");
} else {
    pass("Useable perl memcached module");
}    


done_testing();

