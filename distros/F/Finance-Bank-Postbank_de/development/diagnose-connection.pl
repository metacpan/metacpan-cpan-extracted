#!/usr/bin/perl -w
use strict;

#!/usr/bin/perl -w
use strict;
use FindBin;

use Finance::Bank::Postbank_de::APIv1;

# A simple verbose output to detect common errors

my $api = Finance::Bank::Postbank_de::APIv1->new( diagnostics => 1);
$api->configure_ua();
my $postbank = $api->login( 'Petra.Pfiffig', '12345678' );
    
