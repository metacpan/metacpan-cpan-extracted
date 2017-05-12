use inc::Module::Install 0.91;

name 'Gearman-Driver';
all_from 'lib/Gearman/Driver.pm';

requires(
    'DateTime'                   => '0.4304',
    'Gearman::Client'            => '1.10',
    'Module::Find'               => '0.08',
    'Module::Runtime'            => '0.013',
    'Moose'                      => '0.90',
    'MooseX::SimpleConfig'       => '0.05',
    'MooseX::Getopt'             => '0.24',
    'MooseX::Log::Log4perl'      => '0.40',
    'MooseX::MethodAttributes'   => '0.18',
    'MooseX::Types::Path::Class' => '0.05',
    'Net::Telnet::Gearman'       => '0.01000',
    'POE'                        => '1.280',
    'Term::ReadKey'              => '2.30',
    'Time::HiRes'                => '1.9715',
    'Try::Tiny'                  => '0.02',
);

test_requires(
    'File::Slurp'       => 0,
    'File::Temp'        => 0,
    'Gearman::Server'   => '1.10',
    'Net::Telnet'       => 0,
    'Test::Differences' => 0,
    'Test::Exception'   => 0,
    'Test::More'        => 0,
    'YAML'              => 0,
);

feature 'Gearman::XS',
  -default      => 0,
  'Gearman::XS' => 0;

my @tests = ( 't/*.t', 't/*/*.t' );

if ( -e 'MANIFEST.SKIP' ) {
    system('pod2text lib/Gearman/Driver.pm > README');
    unshift @tests, 'xt/*.t';
}

tests join ' ', @tests;

install_script( glob('script/*.pl') );

auto_install;
WriteAll;
