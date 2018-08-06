######################################################################
# Testcase:     Returning double values from perl 
# Revision:     $Revision$
# Last Checkin: $Date$
# By:           $Author$
#
# Author:       Marc Relation marc@igneousconsulting.com
######################################################################

use warnings;
use strict;

print "1..1\n";
use JavaScript::SpiderMonkey;

my $js=new JavaScript::SpiderMonkey;
my $buffer;
$js->init;
$js->function_set('get_double',sub {return(10.21);});
$js->function_set("write",sub { $buffer .= join('', @_) });
$js->eval("write(get_double()+1.2);");
$js->destroy;
# Check buffer from document.write()
print "not " unless $buffer == 11.41;
print "ok 1\n";
