use strict;
use warnings;

use Test::More;
use Test::Moose::More;

use Dist::Zilla::Role::Store;

validate_role 'Dist::Zilla::Role::Store' => (
    attributes => [
        zilla => { init_arg => '_zilla', is => 'ro' },
    ],
    does       => [ 'Dist::Zilla::Role::Stash' ],
);

done_testing;
