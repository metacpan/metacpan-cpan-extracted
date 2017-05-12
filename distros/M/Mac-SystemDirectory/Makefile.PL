use inc::Module::Install;
use Config;

($^O eq 'darwin')
  || die("OS unsupported\n");

all_from        'lib/Mac/SystemDirectory.pm';
perl_version    '5.006';
repository      'http://svn.ali.as/cpan/trunk/Mac-SystemDirectory/';
bugtracker      'http://rt.cpan.org/Public/Dist/Display.html?Name=Mac-SystemDirectory';
test_requires   'Test::More' => '0.86';
makemaker_args  LDDLFLAGS => $Config{lddlflags} . ' -lobjc -framework CoreFoundation -framework Foundation';
makemaker_args  DEFINE => '-ObjC -DHAS_BOOL';

requires_external_cc;

WriteAll;

