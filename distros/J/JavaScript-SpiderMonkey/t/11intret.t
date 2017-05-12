######################################################################
# Testcase:     Returning integer values from perl 
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
$js->function_set('get_int',sub {return(1000);});
$js->function_set('get_float',sub {return(10.21);});
$js->function_set('booltest',sub {return 1==$_[0];});
#$js->function_set('write',sub {print STDERR $_[0] . "\n"});
$js->function_set("write",sub { $buffer .= join('', @_) });
$js->eval("write(get_int()+1);");
$js->destroy;
# Check buffer from document.write()
print "not " unless $buffer == 1001;
print "ok 1\n";
