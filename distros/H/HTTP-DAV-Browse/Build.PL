use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    module_name         => 'HTTP::DAV::Browse',
    license             => 'perl',
    dist_author         => 'Jozef Kutej <jkutej@cpan.org>',
    dist_version_from   => 'lib/HTTP/DAV/Browse.pm',
    requires => {
        'Moose'     => 0,
        'Moose::Util::TypeConstraints'
                    => 0,
        'MooseX::StrictConstructor'
                    => 0,
        'HTTP::DAV' => 0.38,
        'URI'       => 0,
    },
    recommends => {
        'Proc::PID::File' => 0,
        'File::Which' => 0,
        'Build::Daily' => 0,
        'CPAN::Mini::Inject' => 0,
        'IPC::Run' => 0,
        'File::Find::Rule' => 0,
        'Getopt::Long' => 0,
        'Pod::Usage' => 0,
        'File::Spec' => 0,
        'JSON::XS' => 0,
        'File::Slurp' => 0,
        'File::Temp' => 0.21,
        'File::Basename' => 0,
    },
    build_requires => {
        'Test::More'      => 0,
        'Test::Exception' => 0,
        'LWP::UserAgent'  => 0,
    },
    script_files => [
        'script/hdb-build-tarballs',
    ],
    add_to_cleanup      => [ 'HTTP-DAV-Browse-*' ],
    create_readme       => 1,
    sign                => 1,
    meta_merge => {
        resources => {
            repository => 'git://github.com/jozef/HTTP-DAV-Browse.git',
            bugtracker =>
            'http://rt.cpan.org/NoAuth/Bugs.html?Dist=HTTP-DAV-Browse',
        },
        keywords => [ qw/ http dav webdav ls folders files / ],
    },
);

$builder->create_build_script();
