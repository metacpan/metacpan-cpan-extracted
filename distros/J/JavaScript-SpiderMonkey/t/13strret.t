######################################################################
# Testcase:     Returning string values from perl 
# Revision:     $Revision$
# Last Checkin: $Date$
# By:           $Author$
#
# Author:       Marc Relation marc@igneousconsulting.com
######################################################################

use warnings;
use strict;
use Test::More tests => 1;

use JavaScript::SpiderMonkey;

my $js = new JavaScript::SpiderMonkey;
my $buffer;
$js->init;
$js->function_set('get_string',sub { return "John Doe";});
#$js->function_set('write',sub {print STDERR $_[0] . "\n"});
$js->function_set("write",sub { $buffer .= join('', @_) });
$js->eval("write(get_string()+' who');");
$js->destroy;
# Check buffer from document.write()
is $buffer, 'John Doe who';
