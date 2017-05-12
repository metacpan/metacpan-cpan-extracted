use inc::Module::Install;
  
name           'Lingua-EN-Alphabet-Shaw';
all_from       'lib/Lingua/EN/Alphabet/Shaw.pm';

requires       'DBI';
requires       'DBD::SQLite';
requires       'File::ShareDir';
requires       'HTML::Parser';

install_share;

WriteAll;
