use 5.005;
use inc::Module::Install;

name            'HTML-Formulate';
all_from        'Formulate.pm';

requires        'HTML::Tabulate'    => 0.39;
requires        'HTML::Entities'    => 0;
requires        'Carp'              => 0;
test_requires   'Test::More'        => 0;
test_requires   'Test::Differences' => 0;

WriteAll;

