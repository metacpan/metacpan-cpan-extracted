use Test::More tests => 4;
use strict;

use_ok 'Ganglia::Gmetric';
require_ok( 'Class::Accessor' );
require_ok( 'IO::CaptureOutput' );
my $got=`which gmetric`;
like ($got, '//gmetric/', 'looks like gmetric is located at '.$got );

