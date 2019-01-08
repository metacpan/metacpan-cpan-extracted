#!/usr/bin/perl -w
use strict;

#!/usr/bin/perl -w
use strict;
use FindBin;

use Test::More tests => 1;

use Finance::Bank::Postbank_de::APIv1;


# Check that we have SSL installed :
SKIP: {
    skip "Need SSL capability to access the website",2
        unless LWP::Protocol::implementor('https');
  
    # See also development/diagnose-connection.pl
    my $api = Finance::Bank::Postbank_de::APIv1->new();
    $api->configure_ua();
    my $postbank = $api->login( 'Petra.Pfiffig', '12345678' );
    
    # This tets is mainly to log errors
    ok 1, "We can log in";  
}