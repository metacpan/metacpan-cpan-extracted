use inc::Module::Install;
  
name           'Lingua-EN-Alphabet-Deseret';
all_from       'lib/Lingua/EN/Alphabet/Deseret.pm';

requires       'Lingua::EN::Phoneme';

WriteAll;
