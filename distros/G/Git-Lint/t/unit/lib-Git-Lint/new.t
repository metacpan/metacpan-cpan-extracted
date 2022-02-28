use strict;
use warnings;

use FindBin;
use lib "$FindBin::RealBin/../../../lib", "$FindBin::RealBin/../../lib";

use Git::Lint::Test;

my $class = 'Git::Lint';
use_ok( $class );

my $object = $class->new();
isa_ok( $object, $class );

done_testing;
