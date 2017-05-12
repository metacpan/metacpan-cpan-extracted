use inc::Module::Install;

name           'Kwiki-Markdown';
all_from       'lib/Kwiki/Markdown.pm';
build_requires 'Test::Base';
requires       'Kwiki' => 0.38;

&WriteAll;

