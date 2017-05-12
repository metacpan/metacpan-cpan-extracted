use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    module_name       => 'Gearman::JobScheduler',
    license           => 'perl',
    dist_abstract     => "Gearman job scheduler",
    dist_author       => 'Linas Valiukas <linas dot valiukas at gmail dot com>',
    dist_version_from => 'lib/Gearman/JobScheduler.pm',
    requires          => {
        'Capture::Tiny' => 0,
        'Carp' => 0,
        'Data::Compare' => 0,
        'Data::Dumper' => 0,
        'Data::UUID' => 0,
        'DateTime' => 0,
        'Email::MIME' => 0,
        'Email::Sender::Simple' => 0,
        'File::Path' => 0,
        'File::ReadBackwards' => 0,
        'File::Slurp' => 0,
        'File::Temp' => 0,
        'Gearman::XS' => 0,
        'IO::File' => 0,
        'IO::Socket::INET' => 0,
        'JSON' => 0,
        'Log::Log4perl' => 0,
        'Modern::Perl' => 0,
        'Moose' => '2.1005',
        'Moose::Role' => '2.1005',
        'MooseX::Singleton' => 0,
        'Net::Telnet' => 0,
        'Proc::Background' => 0,
        'Readonly' => 0,
        'Sys::Hostname' => 0,
        'Test::More' => 0,
        'Test::NoWarnings' => 0,
        'Test::Strict' => 0,
        'Time::HiRes' => 0,
        'perl'       => '5.12.0',
    },
    script_files => [
        "script/gjs_sample_client.pl",
        "script/gjs_update_readme.sh",
        "script/gjs_worker.pl"
    ],
    add_to_cleanup =>
        [ 'Gearman-JobScheduler-*', 'MANIFEST.bak', 'MANIFEST.SKIP.bak', 'Makefile', 'MYMETA.*', '_build' ],
    create_makefile_pl => 'passthrough',
    meta_merge => {
        resources => {
            repository => 'https://github.com/pypt/p5-Gearman-JobScheduler'
        }
    },
);

$builder->create_build_script();
