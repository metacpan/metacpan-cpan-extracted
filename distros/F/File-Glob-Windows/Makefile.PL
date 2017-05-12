use inc::Module::Install;

name 'File-Glob-Windows';
author 'tateisu <tateisu@gmail.com>';
license 'perl';
all_from 'lib/File/Glob/Windows.pm';

perl_version '5.8.3';
test_requires 'Test::More';
test_requires 'Test::Base';

auto_include_deps;
check_nmake;
author_tests('xt'); # with Module::Install::AuthorTests 
WriteAll;
