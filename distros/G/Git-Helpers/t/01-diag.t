use strict;
use warnings;

use Test::More;

use Git::Version;

my $v = Git::Version->new(`git --version`);
ok( $v, "got version $v" );

done_testing();
