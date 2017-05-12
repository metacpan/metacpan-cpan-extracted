use 5.005;
use inc::Module::Install;

name            'HTML-Tabulate';
all_from        'Tabulate.pm';

requires        'URI::Escape'       => 0;
requires        'Carp'              => 0;
requires        'Scalar::Util'      => 0;
requires        'HTML::Entities'    => 0;
test_requires   'Test::More'        => 0.88;    # done_testing

WriteAll;

