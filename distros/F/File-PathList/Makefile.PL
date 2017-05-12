use inc::Module::Install 0.76;

all_from      'lib/File/PathList.pm';
requires      'File::Spec'      => '0.80';
requires      'Params::Util'    => '0.24';
test_requires 'Test::More'      => '0.47';

WriteAll;
