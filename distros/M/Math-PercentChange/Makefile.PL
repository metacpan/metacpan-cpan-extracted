use inc::Module::Install;
#use Module::Install::ExtraTests;

# Define metadata
name           'Math-PercentChange';
perl_version   '5.006';
license        'perl';
all_from       'lib/Math/PercentChange.pm';

# Specific dependencies
requires       'Scalar::Util'  => '1.23';
test_requires  'Test::More'  => '0.42';

# Testing
#extra_tests;

WriteAll;
