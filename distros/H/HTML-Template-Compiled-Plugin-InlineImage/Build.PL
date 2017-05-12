use strict;
use warnings;
use Module::Build;

my $build = Module::Build->new(
    create_makefile_pl => 'traditional',
    license            => 'perl',
    module_name        => 'HTML::Template::Compiled::Plugin::InlineImage',
    requires => {
        'HTML::Template::Compiled' => '0.73',
        'MIME::Base64'             => 0,
    },
    recommends => {
        'HTML::Template::Compiled' => '0.74',
        'File::MMagic'             => 0,
        'GD'                       => 0,
    },
    create_readme      => 0,
    sign               => 0,
);
$build->create_build_script;
