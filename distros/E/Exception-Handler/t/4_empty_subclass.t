
use strict;
use Test;

# use a BEGIN block so we print our plan before module is loaded
BEGIN { use Exception::Handler }
BEGIN { plan tests => scalar(@Exception::Handler::EXPORT_OK), todo => [] }
BEGIN { $| = 1 }

# load your module...
use lib './';

# automated empty subclass test

# subclass Exception::Handler in package _Foo
package _Foo;
use strict;
use warnings;
use Exception::Handler qw( :all );
$Foo::VERSION = 0.00_0;
@_Foo::ISA = qw( Exception::Handler );
1;

# switch back to main package
package main;

# see if _Foo can do everything that Exception::Handler can do
map {

   ok ref(UNIVERSAL::can('_Foo', $_)) eq 'CODE'

} @Exception::Handler::EXPORT_OK;


exit;
