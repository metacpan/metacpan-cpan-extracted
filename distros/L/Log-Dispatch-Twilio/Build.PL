use strict;
use warnings;
use Module::Build;

Module::Build->new(
    module_name => 'Log::Dispatch::Twilio',
    dist_author => 'Graham TerMarsch (cpan@howlingfrog.com)',
    license     => 'artistic_2',
    requires    => {
        'HTTP::Status'     => 0,
        'List::Util'       => 0,
        'Log::Dispatch'    => 0,
        'WWW::Twilio::API' => 0,
    },
    build_requires => {
        'Test::More' => 0,
    },
)->create_build_script;
