use inc::Module::Install 0.77;

all_from      'lib/JSAN/Librarian.pm';
requires      'File::Spec'            => '0.80';
requires      'File::Path'            => '1.06';
requires      'Config::Tiny'          => '2.00';
requires      'Params::Util'          => '0.21';
requires      'File::Find::Rule'      => '0.20';
requires      'JSAN::Parse::FileDeps' => '0.02';
requires      'JavaScript::Librarian' => '0.03';
test_requires 'URI'                   => '1.33';
test_requires 'Test::More'            => '0.47';
test_requires 'File::Remove'          => '1.40';

WriteAll;
