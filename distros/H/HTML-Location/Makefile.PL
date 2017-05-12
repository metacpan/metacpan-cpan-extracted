use inc::Module::Install 0.75;

all_from      'lib/HTML/Location.pm';
requires      'File::Spec' => '0.80';
requires      'Clone'      => '0.31';
requires      'List::Util' => '1.11';
requires      'URI'        => 0;
test_requires 'Test::More' => '0.47';

WriteAll;
