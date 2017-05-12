use inc::Module::Install;
name     'JS-jQuery';
abstract 'The Write Less, Do More JavaScript Library';
version  '1.2.6.001';
license  ['mit', 'gpl'];
all_from 'lib/JS/jQuery.pm';

requires    'JS' => '0.17';

WriteAll;
