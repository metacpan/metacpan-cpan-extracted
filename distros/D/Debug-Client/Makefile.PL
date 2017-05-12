use inc::Module::Install 1.06;

name 'Debug-Client';
all_from 'lib/Debug/Client.pm';
requires_from 'lib/Debug/Client.pm';

perl_version '5.010001';

requires 'Carp'           => '1.20';
requires 'IO::Socket::IP' => '0.21';
requires 'PadWalker'      => '1.96';

if ($^O =~ /Win32/i) {
  requires 'Term::ReadLine'       => '1.1';
}

else {
  requires 'Term::ReadLine'       => '1.1';
  requires 'Term::ReadLine::Gnu'  => '1.2';
}

requires 'constant' => '1.21';

test_requires 'Exporter'        => '5.64';
test_requires 'File::HomeDir'   => '1';
test_requires 'File::Spec'      => '3.4';
test_requires 'File::Temp'      => '0.2301';
test_requires 'Test::CheckDeps' => '0.006';
test_requires 'Test::Class'     => '0.39';
test_requires 'Test::Deep'      => '0.11';
test_requires 'Test::More'      => '0.98';
test_requires 'Test::Requires'  => '0.07';

if ($^O =~ /Win32/i) {
  test_requires 'Win32'          => '0.47';
  test_requires 'Win32::Process' => '0.14';
}

test_requires 'parent'  => '0.225';
test_requires 'version' => '0.9902';

recommends 'ExtUtils::MakeMaker'   => '6.66';
recommends 'File::Spec::Functions' => '3.4';
recommends 'List::Util '           => '1.27';
recommends 'Test::Pod'             => '1.48';
recommends 'Test::Pod::Coverage'   => '1.08';


homepage 'http://padre.perlide.org/trac/wiki/Features/Perl5Debugger';
bugtracker 'http://padre.perlide.org/trac/wiki/Tickets';
repository 'http://svn.perlide.org/padre/trunk/Debug-Client/';

no_index 'directory' => qw{ eg inc t xt };

WriteAll

