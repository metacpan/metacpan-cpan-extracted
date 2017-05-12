use inc::Module::Install 0.91;

if ( -e 'MANIFEST.SKIP' ) {
    system('pod2text lib/Log/Handler/Output/Gearman.pm > README');
}

perl_version '5.006001';

name 'Log-Handler-Output-Gearman';
all_from 'lib/Log/Handler/Output/Gearman.pm';

requires(
    'Log::Handler' => '0.62',
    'Gearman::XS'  => '0.6',
    'Carp::Clan'   => 0,
);

test_requires(
    'Test::More' => 0,
    'File::Temp' => 0,
);

auto_install;
WriteAll;
