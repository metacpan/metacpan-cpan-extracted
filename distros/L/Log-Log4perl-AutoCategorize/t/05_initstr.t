# -*- perl -*-

BEGIN {
    # it seems unholy to do this, but perl Core does..
    chdir 't' if -d 't';
    use lib '../lib';
    $ENV{PERL5LIB} = '../lib';    # so children will see it too
}

use Test::More (tests => 12);

diag ("test a non-default initstr");

$!=0;
# hide stderr, not helpful
system 'perl -w tinitstr.pl 2> out.tinitstr.stderr';

ok (!$@, 'no $@ error');
ok (!$!, "no \$! error: $!");
ok (!$?, 'exited with 0');

my ($logout,$logcover);
my ($flogout,$flogcover) = ("out.tinitstr","out.tinitstr.cover");
{
    local $/ = undef;
    my $fh;
    open ($fh, $flogout);
    $logout = <$fh>;
    open ($fh, $flogcover);
    $logcover = <$fh>;
}

ok ($logout, "got something on stdout");
ok ($logcover, "got something on logcover");

##########
diag ("following tests look for expected logging output, with line numbers");

like ($logout, qr/main.main.warn.32: 1/, 'found warn.31, 1st call');
like ($logout, qr/main.main.info.33: 2/, 'found info.32, 2nd call');
like ($logout, qr/main.foo.warn.41: 1, /, 'found warn.40, 1 arg ok');
like ($logout, qr/\QA.bar.warn.51: 5, [
  1,
  2,
  3,
  4,
  5
]/ms, 'found warn.50, with arrayref Dump');

##########

diag ("now test contents of coverage report");

like ($logcover, qr/(\QLog.Log4perl.AutoCategorize.END.info.\E\d+\Q: Seen Log Events:, {
  'Log.Log4perl.AutoCategorize.END.info.\E\d+\Q' => 1,
  'log4perl.category.A.bar.debug.52' => '-50',
  'log4perl.category.A.bar.warn.51' => 50,
  'log4perl.category.main.foo.warn.41' => 25,
  'log4perl.category.main.main.info.33' => 5,
  'log4perl.category.main.main.warn.32' => 5
}\E)/,
      "OK - Seen report in t/$flogcover");

like ($logcover, qr/(\QLog.Log4perl.AutoCategorize.END.info.\E\d+\Q: UnSeen Log Events:, {}\E)/,
      "OK - Un-Seen report in t/$flogcover");

like ($logcover, qr/(\QLog.Log4perl.AutoCategorize.END.info.\E\d+\Q: cat2data:, {
  'A.bar.debug.52' => 'debug_00003',
  'A.bar.warn.51' => 'warn_00002',
  'main.foo.warn.41' => 'warn_00001',
  'main.main.info.33' => 'info_00005',
  'main.main.warn.32' => 'warn_00004'
}\E)/,
      "OK - cat-2-munged data in t/$flogcover");

__END__

