#!perl
use strict;
use warnings;
use lib 'lib';
use Devel::ebug;
use File::Temp qw(tempfile);
use Test::More tests => 5;

# Under PERL_DEBUG_DONT_RELAY_IO (ebug_server -keepio) the program keeps
# its own STDOUT and STDERR instead of having them captured.  Point ours
# at a file while the program starts, so it inherits that.
my($fh, $file) = tempfile(UNLINK => 1);
my $ebug = Devel::ebug->new;
$ebug->program('corpus/carp.pl');
{
  local $ENV{PERL_DEBUG_DONT_RELAY_IO} = 1;
  open my $stdout, '>&', \*STDOUT or die "dup STDOUT: $!";
  open my $stderr, '>&', \*STDERR or die "dup STDERR: $!";
  open STDOUT, '>&', $fh or die "redirect STDOUT: $!";
  open STDERR, '>&', $fh or die "redirect STDERR: $!";
  $ebug->load;
  open STDOUT, '>&', $stdout or die "restore STDOUT: $!";
  open STDERR, '>&', $stderr or die "restore STDERR: $!";
}
$ebug->step for 1 .. 4;

my($stdout, $stderr) = $ebug->output;
is($stdout, '', 'nothing is captured from STDOUT');
is($stderr, '', 'nothing is captured from STDERR');

# a file is block buffered, so have the program write out what it has
$ebug->eval('require IO::Handle; STDOUT->flush');
my $written = do { local(@ARGV, $/) = $file; <> };
like($written, qr/(?:\A|\n)Hi!\n/, 'STDOUT goes where it was going');
like($written, qr/\$x is -4 at corpus\/carp\.pl line 8/, 'and so does STDERR');

# the plugin used to open a bareword NULL handle here for no reason
is($ebug->eval(q{
  my $io = *Devel::ebug::Backend::Plugin::Output::NULL{IO};
  $io && tell($io) >= 0 ? 'open' : 'none';
}), 'none', 'no stray NULL filehandle is left open');
