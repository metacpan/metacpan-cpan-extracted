use strict;
use warnings;

use Test::More 0.96;

eval "use Test::CPAN::Changes";
if ($@) {
    plan skip_all =>
        "install Test::CPAN::Changes to run this test";
}

changes_file_ok('Changes');

done_testing();
