use strict;
use FileHandle::Unget;
use File::Spec::Functions qw(:ALL);
use Test::More tests => 3;
use Config;
use File::Temp;
use File::Slurp ();

# -------------------------------------------------------------------------------

use vars qw( %PROGRAMS $single_quote $command_separator $set_env );

if ($^O eq 'MSWin32')
{
  $set_env = 'set';
  $single_quote = '"';
  $command_separator = '&';
}
else
{
  $set_env = '';
  $single_quote = "'";
  $command_separator = '';
}

# -------------------------------------------------------------------------------

my $path_to_perl = $Config{perlpath};

my $test_program;
{
  my $fh;
  ($fh, $test_program) = File::Temp::tempfile(UNLINK => 1);
  print $fh File::Slurp::read_file(\*DATA);
  close $fh;
}

# Note: No space before the pipe because on Windows it is passed to the test
# program
my $test = "echo hello| $path_to_perl $test_program";
my $expected_stdout = qr/Starting at position (-1|0)\ngot: hello\ngot: world\n/;
my $expected_stderr = '';

{
  my @standard_inc = split /###/, `$path_to_perl -e "\$\\" = '###';print \\"\@INC\\""`;
  my @extra_inc;
  foreach my $inc (@INC)
  {
    push @extra_inc, "$single_quote$inc$single_quote"
      unless grep { /^\Q$inc\E$/ } @standard_inc;
  }

  my $test_program_pattern = $test_program;
  $test_program_pattern =~ s/\\/\\\\/g;
  if (@extra_inc)
  {
    local $" = ' -I';
    $test =~ s#\b\Q$path_to_perl\E\b#$path_to_perl -I@extra_inc#g;
  }
}

my ($test_stdout, $test_stderr);
{
  my $fh;
  ($fh, $test_stdout) = File::Temp::tempfile(UNLINK => 1);
  close $fh;
  ($fh, $test_stderr) = File::Temp::tempfile(UNLINK => 1);
  close $fh;
}

system "$test 1>$test_stdout 2>$test_stderr";

#1
ok(!$?,'Executing external program');

my $actual_stdout = File::Slurp::read_file($test_stdout);
my $actual_stderr = File::Slurp::read_file($test_stderr);

#2
like($actual_stdout,$expected_stdout,'Output matches');

#3
is($actual_stderr,$expected_stderr,'Stderr matches');

exit;

# -------------------------------------------------------------------------------

__DATA__
use strict;
use FileHandle::Unget;

my $fh = new FileHandle::Unget(\*STDIN);

print 'Starting at position ', tell($fh), "\n";

# 1
print "got: ", scalar <$fh>;

$fh->ungets("world\n");

# 2
print "got: ", scalar <$fh>;
