#!perl
#
# Documentation, copyright and license is at the end of this file.
#
package  module1;

use 5.001;
use strict;
use warnings;
use warnings::register;

use vars qw($VERSION $DATE $FILE);
$VERSION = '0.02';
$DATE = '2003/08/04';
$FILE = __FILE__;

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
# Test method
#
sub hello 
{
   "hello world"
   
}

1

__END__


=head1 NAME

module1 - SVDmaker test module

=cut




### end of file ###