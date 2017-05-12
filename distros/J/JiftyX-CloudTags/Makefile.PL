use inc::Module::Install;

name     'JiftyX-CloudTags';
all_from 'lib/JiftyX/CloudTags.pm';
author   'Cornelius <cornelius.howl@gmail.com>';
license  'GPL';

requires 'Jifty'                => 0;
requires 'JiftyX::ModelHelpers' => 0;
requires 'Mouse'                => 0;

build_requires 'Test::More';

tests 't/*.t t/*/t/*.t';

auto_install;

WriteAll;

