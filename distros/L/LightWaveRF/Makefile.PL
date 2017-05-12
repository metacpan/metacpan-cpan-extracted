use inc::Module::Install;

# Define metadata
name           'LightWaveRF';
license        'perl';
perl_version   '5.006';
all_from       'lib/LightWaveRF.pm';


# Specific dependencies
requires 'Moose';
requires 'IO::Socket::INET';
test_requires  'Test::More';

WriteAll;