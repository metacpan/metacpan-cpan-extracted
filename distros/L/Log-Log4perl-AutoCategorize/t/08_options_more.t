# -*- perl -*-
# tests various options that can be passed into Logger

my ($stdfile, $errfile);
BEGIN {
    # it seems unholy to do this, but perl Core does..
    chdir 't' if -d 't';
    use lib '../lib';
    $ENV{PERL5LIB} = '../lib';    # so children will see it too

    ($stdfile, $errfile) = qw( out.options_more.std out.options_more.err );
    unlink 'out.08*', $stdfile, $errfile;
}

use Test::More (tests => 5);	# 1 un-conditional skip
local $" = "\n\t";

#################
diag "test -z options";
$!=0;
system "perl dflt_stdout.pl -d zZ > $stdfile 2> $errfile";

ok (!$@, 'no $@ errors');
ok (!$!, "no \$! error: $!");
ok (!$?, "exited with $?");

diag " now examine output";

my ($stdout,$stderr);
{
    local $/ = undef;
    my $fh;
    open ($fh, "$stdfile");
    $stdout = <$fh>;
    open ($fh, "$errfile");
    $stderr = <$fh>;
}

ok ($stdout, "got something on stdout");

SKIP: {
    # dont test size output now, its too dependent upon perl itself
    skip ": CV size testing is too dependent upon perl itself", 1;
    skip ": you dont have Devel::Size installed", 1
	if ! eval {require Devel::Size};

    like ($stdout, qr/CV isn\'t complete/, 'CV isnt complete');
    like ($stdout, qr/(\Qsize breakdown: {
  'debug_00001' => 92,
  'debug_00002' => 92,
  'debug_00003' => 92,
  'debug_00007' => 92,
  'debug_00010' => 92,
  'debug_00016' => 92,
  'info_00004' => 92,
  'info_00005' => 92,
  'info_00006' => 92,
  'info_00008' => 92,
  'info_00011' => 92,
  'info_00012' => 92,
  'info_00013' => 92,
  'info_00014' => 92,
  'info_00015' => 92,
  'warn_00009' => 92
}\E)/, "got expected size breakdown of vivified functions");

    # this was in the output, b4 cat2munged
    # 'info' => 88,

}


