

use inc::Module::Install 0.76;

all_from      'lib/File/ShareDir/PAR.pm';
requires      'Carp'             => 0;
requires      'File::ShareDir'   => '1.02';
requires      'File::Path'       => 0;
requires      'Class::Inspector' => '1.12';
requires      'File::Spec'       => '0.80';
requires      'PAR'              => '0.989';
test_requires 'Test::More'       => '0.47';

# Default version
install_share;

# Full version
install_share(
        module => 'File::ShareDir::PAR' => 'foo',
);

WriteAll;

