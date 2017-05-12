use lib '../..';
use Java;

#
# See SelfRunning.java for what's going on on the Java side
#
$java = new Java(event_port=>-1);
my($perlobj)=$java->get_callback_object();
my($obj)=$java->create_object("SelfRunning",$perlobj);
$obj->call('go');

