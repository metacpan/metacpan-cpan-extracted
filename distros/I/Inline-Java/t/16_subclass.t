use Test::More;

use strict;
use warnings;
{
package Hi3;
use strict;
use warnings;

BEGIN {
  $ENV{CLASSPATH} .= "t/t16subclass.jar";
}

use Inline Java => 'STUDY', STUDY => ['t16subclass'];

sub new {
	my $class = shift;
#	print "class name is $class \n";
	my $a = shift;
	my $b = shift;
	return Hi3::t16subclass->t16subclass($a, $b);
}
}

my $Higher1 = Hi3->new(5,10);
is $Higher1->printValues(), "a = 5\nb = 10";

done_testing;
