use inc::Module::Install;

all_from    'lib/Lingua/JA/WordNet.pm';
readme_from 'lib/Lingua/JA/WordNet.pm';

configure_requires 'File::ShareDir';
requires           'Carp';
requires           'DBI';
requires           'DBD::SQLite' => 1.27; # sqlite_unicode
requires           'List::MoreUtils';
test_requires      'Test::More'  => 0.98;
test_requires      'Test::Warn';
test_requires      'Test::Exception';

install_share;

tests 't/*.t';
author_tests 'xt';

no_index directory => 'benchmark';

resources(
    license    => 'http://dev.perl.org/licenses',
    repository => 'https://github.com/pawa-/Lingua-JA-WordNet',
    bugtracker => 'https://github.com/pawa-/Lingua-JA-WordNet/issues',
);

WriteAll;
