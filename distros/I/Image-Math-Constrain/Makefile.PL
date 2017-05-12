use inc::Module::Install 0.76;

all_from      'lib/Image/Math/Constrain.pm';
test_requires 'Test::More' => '0.47';
test_requires 'File::Spec' => '0.82';

WriteAll;
