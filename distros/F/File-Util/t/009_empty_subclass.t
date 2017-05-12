
use strict;
use warnings;

use Test::More;
use Test::NoWarnings;

use lib './lib';
use File::Util;

plan tests => ( scalar @File::Util::EXPORT_OK ) + 1;

# automated empty subclass test

# subclass File::Util in package _Foo
package _Foo;
use strict;
use warnings;
use File::Util qw( :all );
$Foo::VERSION = 0.00_0;
@_Foo::ISA = qw( File::Util );
1;

# switch back to main package
package main;

# see if _Foo can do everything that File::Util can do
map {

   ok ref UNIVERSAL::can('_Foo', $_) eq 'CODE',
      "Empty subclass can $_"

} @File::Util::EXPORT_OK;

exit;
