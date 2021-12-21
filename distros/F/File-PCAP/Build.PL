use 5.006;
use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    add_to_cleanup      => [ 'File-PCAP-*' ],
    build_requires      => {
        'Test::More'    => 0,
    },
    configure_requires  => {
        'Module::Build' => 0,
    },
    create_makefile_pl  => 'small',
    dist_abstract       => 'a pure Perl library to read and write PCAP files',
    dist_author         => q{Mathias Weidner <mamawe@cpan.org>},
    dist_version_from   => 'lib/File/PCAP.pm',
    license             => 'artistic_2',
    meta_merge => {
        resources => {
            repository => 'https://github.com/matwei-perl/File-PCAP',
            bugtracker => 'https://rt.cpan.org/Public/Dist/Display.html?Name=File-PCAP',
        }
    },
    module_name         => 'File::PCAP',
    release_status      => 'stable',
    requires => {
        #'ABC'              => 1.6,
        #'Foo::Bar::Module' => 5.0401,
    },
    script_files	=> [
	    'bin/acap2pcap',
    ],
);

$builder->create_build_script();
