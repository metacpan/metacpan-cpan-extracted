use inc::Module::Install;

name 'Loompa';
all_from 'lib/Loompa.pm';
author 'Hans Dieter Pearcey <hdp@cpan.org>';
test_requires 'Test::More' => 0;
test_requires 'Test::Exception' => 0;
repository 'https://svn.opensourcery.com/public/projects/loompa/trunk';
WriteAll;
