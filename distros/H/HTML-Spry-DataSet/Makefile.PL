use inc::Module::Install 0.79;

all_from      'lib/HTML/Spry/DataSet.pm';
requires      'IO'               => '1.23';
requires      'CGI'              => '0.38';
requires      'Params::Util'     => '0.32';
test_requires 'Test::More'       => '0.42';
test_requires 'Test::LongString' => '0.11';
test_requires 'File::Remove'     => '1.42';

WriteAll;
