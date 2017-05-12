use inc::Module::Install;
name     'JS-Foo-Bar';
abstract 'Sample JavaScript Module Distribution';
version  '0.01';
license  'lgpl';
all_from 'lib/JS/Foo/Bar.pm';
WriteAll;
