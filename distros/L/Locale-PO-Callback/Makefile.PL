use inc::Module::Install;
  
name           'Locale-PO-Callback';
all_from       'lib/Locale/PO/Callback.pm';

requires       'POSIX';

WriteAll;
