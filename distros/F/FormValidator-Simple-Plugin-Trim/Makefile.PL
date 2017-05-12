use inc::Module::Install 0.67;

name     'FormValidator-Simple-Plugin-Trim';
all_from 'lib/FormValidator/Simple/Plugin/Trim.pm';

requires 'FormValidator::Simple';

WriteAll;
