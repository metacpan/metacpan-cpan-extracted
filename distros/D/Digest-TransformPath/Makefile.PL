use inc::Module::Install;

name           'Digest-TransformPath';
all_from       'lib/Digest/TransformPath.pm';
requires       'Digest::MD5'     => '2.00';
build_requires 'Test::More'      => '0.47';

WriteAll;
