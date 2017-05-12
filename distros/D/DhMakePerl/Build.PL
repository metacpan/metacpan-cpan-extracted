use strict;
use warnings;
use lib qw(privinc);
use My::Builder;

my $builder = My::Builder->new(
    module_name         => 'DhMakePerl',
    license             => 'gpl',
    recommends          => {
        'DPKG::Parse' => 0.02,
        'Git'         => 0,
        'IO::Dir'     => 0,
    },
    configure_requires => { 'Module::Build' => 0.38 },
    requires            => {
        perl    => '5.010',

        'AptPkg::Cache'             => 0,
        'AptPkg::Config'            => 0,
        'Array::Unique'             => 0,
        'Carp'                      => 0,
        'Config::INI::Reader'       => 0,
        'CPAN'                      => 0,
        'CPAN::Meta'                => 0,
        'Cwd'                       => 0,
        'Dpkg'                      => 0,
        'Dpkg::Source::Package'     => 0,
        'Email::Address'            => 0,
        'Email::Date::Format'       => 0,
        'File::Basename'            => 0,
        'File::Copy'                => 0,
        'File::Find::Rule'          => 0,
        'File::Spec'                => 0,
        'File::Spec::Functions'     => 0,
        'File::Which'               => 0,
        'FindBin'                   => 0,
        'Getopt::Long'              => 0,
        'IO::File'                  => 0,
        'IO::Uncompress::Gunzip'    => 0,
        'List::MoreUtils'           => 0,
        'Module::Build'             => 0,
        'Module::CoreList'          => 0,
        'Module::Depends'           => 0,
        'Module::Depends::Intrusive'=> 0,
        'Parse::DebControl'         => 0,
        'Parse::DebianChangelog'    => 0,
        'Software::License::Artistic_2_0' => 0,
        'Storable'                  => 0,
        'Text::Diff'                => 0,
        'Text::Wrap'                => 0,
        'Tie::File'                 => 0,
        'Tie::IxHash'               => 0,
        'User::pwent'               => 0,
        'version'                   => 0,
        'WWW::Mechanize'            => 0,
        'YAML'                      => 0,
    },
    build_requires      => {
        'IPC::Run'          => 0,
        'File::DirCompare'  => 0,
        'File::Touch'       => 0,
        'Test::Compile'     => 0,
        'Test::Deep'        => 0,
        'Test::Differences' => 0,
        'Test::Exception'   => 0,
        'Test::More'        => 0,
    },
    no_index => { directory => [qw(privinc t xt share)] },
    add_to_cleanup      => [ 'DhMakePerl-*', 'Build', '_build' ],
    script_files        => [ 'dh-make-perl' ],
    install_path        => {
        share   => '/usr/share/dh-make-perl',
    },
    share_files         => { map( ( $_ => $_ ), glob 'share/*' ) },
    meta_merge => {
        resources => {
            repository => 'https://anonscm.debian.org/cgit/pkg-perl/packages/dh-make-perl.git',
        },
        keywords => [ qw(debian package helper) ],
    },
);

$builder->add_build_element('share');
$builder->create_build_script();
