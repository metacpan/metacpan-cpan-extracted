use lib '.';
use inc::Module::Install 1.08;

name 'Debug-Client';
all_from 'lib/Debug/Client.pm';
requires_from 'lib/Debug/Client.pm';

perl_version '5.010001';

requires 'Carp'           => '1.3301';
requires 'Exporter'       => '5.70';
requires 'IO::Socket::IP' => '0.29';
requires 'PadWalker'      => '1.98';
requires 'Term::ReadLine' => '1.14';
requires 'constant'       => '1.27';

requires 'Term::ReadLine'       => '1.14';
requires 'Term::ReadLine::Gnu'  => '1.24' if !win32;

test_requires 'File::HomeDir'   => '1';
test_requires 'File::Temp'      => '0.2304';
test_requires 'List::Util'      => '1.38';
test_requires 'Test::CheckDeps' => '0.01';
test_requires 'Test::Class'     => '0.42';
test_requires 'Test::Deep'      => '0.112';
test_requires 'Test::More'      => '1.001003';
test_requires 'Test::Requires'  => '0.07';
test_requires 'Win32'           => '0.49' if win32;
test_requires 'Win32::Process'  => '0.16' if win32;
test_requires 'parent'          => '0.228';
test_requires 'version'         => '0.9908';


recommends 'ExtUtils::MakeMaker'   => '6.66';
recommends 'File::Spec::Functions' => '3.4';
recommends 'List::Util'            => '1.27';
recommends 'Test::Pod'             => '1.48';
recommends 'Test::Pod::Coverage'   => '1.08';


homepage 'https://github.com/PadreIDE/Debug-Client';
bugtracker 'https://github.com/PadreIDE/Debug-Client/issues';
repository 'git://github.com/PadreIDE/Debug-Client.git';

no_index 'directory' => qw{ eg t };

WriteAll

