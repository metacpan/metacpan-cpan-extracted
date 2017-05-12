#
# Getopt::Awesome::Examples::ImportAllFoos
#
# Created: 10/07/2009 09:18:20 AM
package Getopt::Awesome::Examples::ImportAllFoos;

use strict;
use warnings;

use Getopt::Awesome::Examples::Foo;
use Getopt::Awesome::Examples::Foo::ChildFoo;
use Getopt::Awesome::Examples::Foo::ChildFoo::GrandchildFoo;
use Getopt::Awesome qw(:common);

sub test_this_foo {
    print "Calling ChildFoo::test:\n";
    Getopt::Awesome::Examples::Foo::ChildFoo->test;
    print "Gettings the example value of ChildFoo frm ImportAllFoos:\n";
    print get_opt('Getopt::Awesome::Examples::Foo::ChildFoo::example') . "\n";
    print "Now setting the value from ImportallFoos:\n";
    set_opt('Getopt::Awesome::Examples::Foo::ChildFoo::example', 'new value');
    print "Getting the value we just set...\n";
    print get_opt('getopt::Awesome::Examples::Foo::ChildFoo::example') . "\n";
}
1;



