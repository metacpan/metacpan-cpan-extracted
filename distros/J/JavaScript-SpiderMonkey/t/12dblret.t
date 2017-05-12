######################################################################
# Testcase:     Returning double values from perl 
# Revision:     $Revision: 1.1 $
# Last Checkin: $Date: 2006/06/13 13:43:51 $
# By:           $Author: thomas_busch $
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
