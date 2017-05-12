use lib '../..';
use Java;

#
# See perljava.java for what's going on on the Java side
#
$java = new Java;
$global_hash={'name'=>"Mr. President"};
my($perlobj)=$java->get_callback_object();
my($obj)=$java->create_object("com.zzo.javaserver.perljava",$perlobj);
print($obj->doSomeJavaCode()->get_value());

