use strict;
use warnings;

use Test::More;
use Test::Moose::More;

use Dist::Zilla::Role::ContributorSource;

validate_role 'Dist::Zilla::Role::ContributorSource' => (
    required_methods => [ 'contributors' ],
);

done_testing;
