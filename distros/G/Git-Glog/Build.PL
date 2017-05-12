use 5.008;
use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    module_name         => 'Git::Glog',
    license             => 'perl',
    dist_author         => q{Colin Kennedy <moshen@cpan.org>},
    dist_version_from   => 'lib/Git/Glog.pm',
    script_files        => 'bin/git-glog',
    build_requires => {
        'Test::More' => 0,
    },
    requires => {
        'Pod::Usage' => 0,
        'Getopt::Long' => 0,
        'Digest::MD5' => 0,
        'Compress::Zlib' => 0,
        'LWP::UserAgent' => 0,
        'Image::Term256Color' => 0.03,
        'perl' => 5.008,
    },
    add_to_cleanup      => [ 'Git-Glog-*' ],
    create_makefile_pl => 'traditional',
);

$builder->create_build_script();
