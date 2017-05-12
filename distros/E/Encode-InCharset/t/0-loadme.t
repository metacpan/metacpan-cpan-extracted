#
# $Id: 0-loadme.t,v 0.1 2002/05/03 05:28:21 dankogai Exp $
#
use 5.007003;
use strict;
use Test::More tests => 111;

use_ok("Encode::InCharset");
no warnings;
for my $sub (keys %Encode::InCharset::Config::InPM){
    can_ok('main', $sub);
}
