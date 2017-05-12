use strict;
use warnings;
use Module::Build;

Module::Build->new(
    module_name => 'Log::Dispatch::TestDiag',
    dist_author => 'Graham TerMarsch (cpan@howlingfrog.com)',
    license     => 'artistic_2',
    requires    => {
        'Log::Dispatch::Output' => 0,
        'Test::More'            => 0,
    },
)->create_build_script;
