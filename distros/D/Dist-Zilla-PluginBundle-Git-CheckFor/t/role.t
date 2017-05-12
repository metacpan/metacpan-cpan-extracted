use strict;
use warnings;

use Test::More;
use Test::Moose::More 0.008;

use Dist::Zilla::Role::Git::Repo::More;

validate_role 'Dist::Zilla::Role::Git::Repo::More' => (
    does       => [ qw{ Dist::Zilla::Role::Git::Repo } ],
    attributes => [ qw{ _repo                        } ],
);

done_testing;

