
use strict;
use warnings;

use Test::More tests => 2;
use Test::NoWarnings;

use lib './lib';
use File::Util;

my $ftl = File::Util->new();

# check to see if File::Util ISA [foo, etc.]
ok
(
   UNIVERSAL::isa( $ftl, 'File::Util' ),
   'ISA File::Util bless matches namespace'
);

exit;
