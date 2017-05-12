use inc::Module::Install;

name            'Ganglia-Gmetric-PP';
all_from        'lib/Ganglia/Gmetric/PP.pm';

install_script  'bin/gmetric-aggregator.pl';
install_script  'bin/gmetric.pl';

test_requires   'AnyEvent'                      => 0;

WriteAll;
