use strict;
use warnings;

use Test::More;
use Test::Moose::More;

use aliased 'Dist::Zilla::Stash::GitHub' => 'GitHub';

validate_class GitHub() => (
    does       => [ 'Dist::Zilla::Role::Stash::Login' ],
    attributes => [ qw{ username password } ],
);

done_testing;
