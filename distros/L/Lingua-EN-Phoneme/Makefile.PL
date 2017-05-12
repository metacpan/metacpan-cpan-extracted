use inc::Module::Install;
  
name           'Lingua-EN-Phoneme';
all_from       'lib/Lingua/EN/Phoneme.pm';

requires       'DB_File';
requires       'File::ShareDir';

install_share;

WriteAll;
