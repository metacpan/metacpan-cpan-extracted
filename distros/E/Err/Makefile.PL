use inc::Module::Install;

name           'Err';
all_from       'lib/Err.pm';

requires       'Exception::Class'          => 0;

license 'perl';
githubmeta;
author_tests('xt');
readme_from 'lib/Err.pm';

WriteAll;
