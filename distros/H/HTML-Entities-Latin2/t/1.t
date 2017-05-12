# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl 1.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use Test::More tests => 4;
BEGIN { use_ok('HTML::Entities::Latin2') };

#########################

# Insert your test code below, the Test::More module is use()ed here so read
# its man page ( perldoc Test::More ) for help writing this test script.
use HTML::Entities::Latin2;

$lat2_string = "\"k\xF6zponti\" <b>sz\xE1m\xEDt\xF3g\xE9p</b>";
	
is(HTML::Entities::Latin2::encode($lat2_string), q("k&#246;zponti" <b>sz&#225;m&#237;t&#243;g&#233;p</b>));
	
is(HTML::Entities::Latin2::encode($lat2_string, 'name', '<"'), q(&quot;k&ouml;zponti&quot; &lt;b>sz&aacute;m&iacute;t&oacute;g&eacute;p&lt;/b>));
	
is(HTML::Entities::Latin2::encode($lat2_string, 'hex'), q("k&#x00F6;zponti" <b>sz&#x00E1;m&#x00ED;t&#x00F3;g&#x00E9;p</b>));
