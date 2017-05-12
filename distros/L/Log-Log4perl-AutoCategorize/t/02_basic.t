# -*- perl -*-

BEGIN {
    # it seems unholy to do this, but perl Core does..
    chdir 't' if -d 't';
    use lib '../lib';
    $ENV{PERL5LIB} = '../lib';    # so children will see it too
    unlink <out.basic*>, <out.02*>, <out.dflt_stdout*>;
}

use Test::More (tests => 25);

# These both get 'Illegal seek' errs
#$stdout = `perl dflt_stdout.pl 2> junk`;
#$stdout = `perl dflt_stdout.pl`;

# use default logging setup again
use Log::Log4perl::AutoCategorize;

$!=0;
system 'perl dflt_stdout.pl > out.basic.stdout 2> out.basic.stderr';

ok (!$@, 'no $@ error');
ok (!$!, "no \$! error: $!");
ok (!$?, 'exited with 0');

my ($stdout,$stderr);
{
    local $/ = undef;
    my $fh;
    open ($fh, "out.basic.stdout");
    $stdout = <$fh>;
    open ($fh, "out.basic.stderr");
    $stderr = <$fh>;
}

ok ($stdout, "got something on stdout");

like ($stdout, qr/in Foo->bar\(\)/ms, 'found Foo->bar() unmunged');
like ($stdout, qr/in Foo->bar\(1\)/ms, 'found Foo->bar(1) unmunged');

ok ($stderr, "got something on stderr");

##########
diag ("following tests look for expected line number reporting");

like ($stderr, qr/main.main.debug.36: 1/, 'found debug.36, 1st call');
like ($stderr, qr/main.main.debug.36: 2/, 'found debug.36, 2nd call');
like ($stderr, qr/main.main.info.37: one arg, /, 'found info.37, 1 arg ok');
like ($stderr, qr/main.main.warn.38: 2 args, /, 'found info.38, 2 args ok');

##########
diag ("following tests check output of Data::Dumper");

like ($stderr, qr/\Qmain.main.debug.39: [
  'arrayref'
]
/, 'found debug.39 arrayref dump');


like ($stderr, qr/\Qmain.main.info.40: {
  'hash' => 'ref'
}
/,
      'found info.40 hashref dump');


like ($stderr, qr/\Qmain.main.info.41: [
  [
    'nested',
    'arrayref',
    'and'
  ],
  {
    'hash' => 'also'
  }
]/,
      'found info.41 complex ref dump');

##########
diag("following test nested use of logger - dunno why anyone would..");

like ($stderr, qr/\Qmain.main.info.44: {
  'inner' => 'call to same fn'
}/,
      'found inner info() invocation');


like ($stderr, qr/\Qmain.main.info.44a: logged, /,
      'found outer info() invocation on same line');

like ($stderr, qr/\Qmain.main.debug.47: {
  'inner' => 'call to diff fn'
}/,
      'found inner debug() invocation');

like ($stderr, qr/\Qmain.main.info.47: logged nested, {
  'hash' => 'ref'
}/,
      'found outer info() invocation');

##########
diag ("now check logging from user functions and packages");

like ($stderr, qr/\Qmain.usersub.info.54: logging from main function, [
  1
]/,
      'call from usersub, with arrayref arg');

like ($stderr, qr/\Qmain.usersub.info.55: logging from main function 1, /,
      'call from usersub, with array of 1 arg');

like ($stderr, qr/\QFoo.uselogger.debug.22: logging from Foo Foo 2, /,
      'call from user package, with 1 arg');

like ($stderr, qr/\QFoo.uselogger.debug.23: logging from Foo Foo 2 extra, /,
      'call from user package, with 2 args');

like ($stderr, qr/\QFoo.uselogger.debug.24: logging from Foo, [
  'Foo',
  2
]/,
      'call from user package, with arrayref of 2 args');

##########
diag ("now test contents of coverage report");

like ($stderr, qr/(\QLog.Log4perl.AutoCategorize.END.info.\E\d+\Q: Seen Log Events:, {
  'Log.Log4perl.AutoCategorize.END.info.\E\d+\Q' => 1,
  'log4perl.category.Foo.uselogger.debug.22' => 2,
  'log4perl.category.Foo.uselogger.debug.23' => 2,
  'log4perl.category.Foo.uselogger.debug.24' => 2,
  'log4perl.category.main.main.debug.36' => 2,
  'log4perl.category.main.main.debug.39' => 2,
  'log4perl.category.main.main.debug.47' => 2,
  'log4perl.category.main.main.info.37' => 2,
  'log4perl.category.main.main.info.40' => 2,
  'log4perl.category.main.main.info.41' => 2,
  'log4perl.category.main.main.info.44' => 2,
  'log4perl.category.main.main.info.44a' => 2,
  'log4perl.category.main.main.info.47' => 2,
  'log4perl.category.main.main.warn.38' => 2,
  'log4perl.category.main.usersub.info.54' => 2,
  'log4perl.category.main.usersub.info.55' => 2,
  'log4perl.category.main.usersub.info.56' => 2
}\E)/,
      "OK - Seen report looks good - look at t/out.basic.stderr");

like ($stderr, qr/(\QLog.Log4perl.AutoCategorize.END.info.\E\d+\Q: UnSeen Log Events:, {
  'debug_00018' => 'main,dflt_stdout.pl,63',
  'info_00017' => 'main,dflt_stdout.pl,62'
}\E)/,
      "OK - Un-Seen report looks good - look at t/out.basic.stderr");

##########
diag ("\nall done. now the Loggers (see test 1) END block reports ...\n\n");

__END__

