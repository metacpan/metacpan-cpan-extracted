use strict;
use warnings;

use Test::More;
use Test::Moose::More;

use aliased 'Dist::Zilla::Plugin::ContributorsFromGit' => 'CFG';

# Validate the public interface of our class -- aka "make sure no methods
# disappear"

validate_class CFG() => (
    does => [
        'Dist::Zilla::Role::BeforeBuild',
        'Dist::Zilla::Role::MetaProvider',
    ],
    methods => [ qw{ metadata before_build } ],
);

done_testing;
