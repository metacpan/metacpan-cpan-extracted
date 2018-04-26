use strict;
use warnings;

use Test::More 0.88;
use Test::DZil;
use Test::Fatal;

use lib 'corpus/DZ5';

my $tzil = Builder->from_config( { dist_root => 'corpus/DZ5' }, );

like(
    exception { $tzil->build },
    qr/\[=MyBundle\/OSPrereqs\] inferred OS name as =MyBundle\/OSPrereqs, which looks like it came from a bundle!/,
    'build dies with appropriate warning when author forgot to pass an explicit OS name from a bundle plugin',
);

done_testing;
