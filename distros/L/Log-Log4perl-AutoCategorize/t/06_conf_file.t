# -*- perl -*-

BEGIN {
    # it seems unholy to do this, but perl Core does..
    chdir 't' if -d 't';
    use lib '../lib';
    $ENV{PERL5LIB} = '../lib';    # so children will see it too
    unlink <out.06*>, <out.tconf_file*>;
}

use Test::More (tests => 9);

diag ("test with a loaded config-file");

$!=0;
# hide stderr, not helpful
system 'perl -w tconf_file.pl 2> out.tconf_file.stderr';

ok (!$@, 'no $@ error');
ok (!$!, "no \$! error: $!");
ok (!$?, 'exited with 0');

my ($logout,$logcover);
my ($fout,$fcover) = ("out.tconf_file","out.tconf_file.cover");
{
    local $/ = undef;
    my $fh;
    open ($fh, $fout);
    $logout = <$fh>;
    open ($fh, $fcover);
    
    $logcover = <$fh>;
}

ok ($logout, "got something on stdout");
ok ($logcover, "got something in coverage log");

##########
diag ("following tests look for expected logging output, with line numbers");

#like ($logout, qr/main.main.warn.32: 1/, 'found warn.31, 1st call');
#like ($logout, qr/main.main.info.33: 2/, 'found info.32, 2nd call');
#like ($logout, qr/main.foo.warn.41: 1, /, 'found warn.40, 1 arg ok');
like ($logout, qr/\QA.truck.debug.63: trucks are noisy 2, [
  1,
  2
]/ms, 'found warn.50, with arrayref Dump');

##########

diag ("now test contents of coverage report: t/$fcover");

like ($logcover, qr/(\QLog.Log4perl.AutoCategorize.END.info.\E\d+\Q: Seen Log Events:, {
  'Log.Log4perl.AutoCategorize.END.info.\E\d+\Q' => 1,
  'log4perl.category.A.truck.debug.63' => 20,
  'log4perl.category.A.truck.debug.65' => 20,
  'log4perl.category.A.truck.debug.66' => 20,
  'log4perl.category.A.truck.warn.62' => 20,
  'log4perl.category.main.car.warn.46' => 10,
  'log4perl.category.main.main.info.28' => 5,
  'log4perl.category.main.main.warn.27' => 5,
  'log4perl.category.main.suv.warn.51' => '-10',
  'log4perl.category.main.suv.warn.52' => '-10'
}\E)/,
      "OK - Seen report");

like ($logcover, qr/(\QLog.Log4perl.AutoCategorize.END.info.\E\d+\Q: UnSeen Log Events:, {
  'info_00011' => 'main,tconf_file.pl,36',
  'warn_00008' => 'B::C,tconf_file.pl,76'
}\E)/,
      "OK - Un-Seen report");

like ($logcover, qr/(\QLog.Log4perl.AutoCategorize.END.info.\E\d+\Q: cat2data:, {
  'A.truck.debug.63' => 'debug_00005',
  'A.truck.debug.65' => 'debug_00006',
  'A.truck.debug.66' => 'debug_1_00007',
  'A.truck.warn.62' => 'warn_00004',
  'main.car.warn.46' => 'warn_00001',
  'main.main.info.28' => 'info_00010',
  'main.main.warn.27' => 'warn_00009',
  'main.suv.warn.51' => 'warn_00002',
  'main.suv.warn.52' => 'warn_00003'
}\E)/,
      "OK - cat-2-munged data");

__END__

