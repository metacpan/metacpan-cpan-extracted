#
# Getopt::Awesome::Examples::Foo::ChildFoo::GrandchildFoo
#
# Created: 10/07/2009 09:09:06 AM
package Getopt::Awesome::Examples::Foo::ChildFoo::GrandchildFoo;

use strict;
use warnings;
use base qw(Getopt::Awesome::Examples::Foo::ChildFoo);
use Getopt::Awesome qw(:common);

define_option('example', 'an example from grand child foo');


1;



