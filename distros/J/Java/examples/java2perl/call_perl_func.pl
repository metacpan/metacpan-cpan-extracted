use lib '../..';
use Java;

#
# See CallPerlFunc.java for what's going on on the Java side
#
$java = new Java(event_port=>-1);
my($perlobj)=$java->get_callback_object();
my($obj)=$java->create_object("CallPerlFunc",$perlobj);

print($obj->makeUpperCase("hola")->get_value()."\n");


sub make_upper_case
{
	uc shift;
}
	
