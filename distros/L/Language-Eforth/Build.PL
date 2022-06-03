#!perl
#
# build script for Language::Eforth, see the README file for details

use strict;
use warnings;
use Module::Build;
Module::Build->VERSION('0.4004');

# TODO figure out Alien::Build and write an Alien::Eforth to (try to)
# install that? in the meantime see the README for what to copy from
# the embed repository into the src directory. I guess you could
# randomly pull down stuff from github, which is a less horrible
# version of `curl ... | sh`
for my $file (qw[embed.c embed.h image.c]) {
    if ( !-f "src/$file" ) {
        print "  src/$file is missing\n";
        print "No automated install, see the README for details\n";
        exit 0;
    }
}

my $builder = Module::Build->new(
    module_name       => 'Language::Eforth',
    dist_author       => 'Jeremy Mates <jeremy.mates@gmail.com>',
    dist_version_from => 'lib/Language/Eforth.pm',
    c_source          => 'src',
    create_license    => 0,
    create_readme     => 0,
    dynamic_config    => 0,
    include_dirs      => [qw(. src)],
    license           => 'bsd',
    needs_compiler    => 1,
    release_status    => 'stable',
    requires          => {
        'perl'   => '5.6.0',
        'strict' => 0,
    },
    test_requires      => { 'Test2::V0' => 0, },
    configure_requires => {
        'CPAN::Meta'    => '2.142060',
        'Module::Build' => '0.4004',     # test_requires
    },
    add_to_cleanup => ['Language-Eforth-*'],
    auto_features  => {
        dist_authoring => {
            description => "Create new distributions",
            requires    => { 'Archive::Tar' => 1.09, },
        },
    },
);

$builder->create_build_script();
