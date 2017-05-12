use strict;
use warnings;
use Module::Build::SysPath;

use 5.010;

my $builder = Module::Build::SysPath->new(
    module_name       => 'Debian::Apt::PM',
    license           => 'perl',
    dist_author       => 'Jozef Kutej <jkutej@cpan.org>',
    dist_version_from => 'lib/Debian/Apt/PM.pm',
    
    configure_requires => {
        'Module::Build::SysPath' => 0.13,
        'Module::Build'          => '0.3607',
    },
    build_requires => {
        'Module::Build::SysPath' => 0.13,
        'Test::More'             => 0,
        'Test::Differences'      => 0,
        'Test::Exception'        => 0,
    },
    requires => {
        'Moose'                   => 0,
        'IO::Uncompress::Bunzip2' => 0,
        'IO::Any'                 => 0,
        'Parse::Deb::Control'     => 0.04,   # get_paras()
        'Dpkg::Version'           => 0,
        'AptPkg::Config'          => 0,
        'LWP::Simple'             => 0,
        'Carp'                    => 0,
        'JSON::Util'              => 0.04,   # atomic writes
        'Getopt::Long'            => 0,
        'Pod::Usage'              => 0,
        'List::MoreUtils'         => 0,
        'File::Find::Rule'        => 0,
        'File::Basename'          => 0,
        'Module::Build::ModuleInfo' => 0,
        'File::Temp'              => 0,
        'File::Path'              => 2.01,   # make_path
        'CPAN::Version'           => 0,
        'Storable'                => 0,
        'File::HomeDir'           => 0,
        'File::Copy'              => 0,
        'CPAN'                    => 0,
        'File::is'                => 0,
        'CPAN::Patches'           => 0,
        'CPAN::Patches::Plugin::Debian' => 0.03,    # stackable patch set folders
        'Module::Depends::Intrusive'    => 0,
        'Digest::MD5'             => 0,
        'CPAN::PackageDetails'    => 0,
        'MetaCPAN::API'           => 0,
        'IO::Uncompress::Gunzip'  => 0,
        'CPAN'                    => 0,
        'CPAN::Module'            => 0,
        'DateTime'                => 0,
        'Data::Header::Fields'    => '0.04',       # fix mem leaks
        'Parallel::Iterator'      => 0,
    },
    script_files => [
        'script/apt-pm',
        'script/apt-pm-web',
        'script/apt-cpan',
        'script/dpkg-scanpmpackages',
        'script/dh-make-pm',
    ],
    add_to_cleanup => [ 'Debian-Apt-PM-*' ],
    create_readme  => 1,
    meta_merge => {
        resources => {
            repository => 'git://github.com/jozef/Debian-Apt-PM.git',
            bugtracker => 'http://github.com/jozef/Debian-Apt-PM/issues',
        },
        keywords => [ qw/ debian perl modules / ],
    },
);

$builder->create_build_script();
