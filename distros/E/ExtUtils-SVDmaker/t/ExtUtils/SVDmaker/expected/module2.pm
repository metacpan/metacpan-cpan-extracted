#!perl
#
# Documentation, copyright and license is at the end of this file.
#
package  SVDtest;

use 5.001;
use strict;
use warnings;
use warnings::register;

use Test;
use Data::Dumper;
use Test::TestUtil;
$Data::Dumper::Terse = 1; 

use vars qw($VERSION $DATE);
$VERSION = '0.01';
$DATE = '2003/08/01';

#####
# Because Test::TestUtil uses SelfLoader, the @ISA
# method of inheriting Test::TestUtil has problems.
#
# Use AUTOLOAD inheritance technique below instead.
#
# use vars qw(@ISA);
# @ISA = qw(Test::TestUtil);

$Test::TestLevel = 1;

####
# Using an object to pass localized object data
# between functions. Makes the functions reentrant
# where out right globals can be clobbered when
# used with different threads (processes??)
#
sub new
{
    my ($class, $test_log) = @_;
    $class = ref($class) if ref($class);
    bless {}, $class;

}

#####
# Done with the test
#
sub hello # end a test
{
   print "hello world\n";
   1
}

1

__END__


### end of file ###