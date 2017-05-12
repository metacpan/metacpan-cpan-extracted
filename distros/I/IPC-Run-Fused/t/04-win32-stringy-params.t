
use strict;
use warnings;

use Test::More;

if ( $^O ne 'MSWin32' ) {
  plan skip_all => 'Win32 Only Checks';
}

use FindBin;

use IPC::Run::Fused qw( run_fused );

my $test = 0;

sub test_string {
  my ($cmd) = shift;
  $test++;
  my $pid = run_fused( my $reader, \$cmd );
  while ( my $line = <$reader> ) {
    pass("Got line $. for $test");
    note($line);
  }
  waitpid $pid, 0;
}

sub test_list {
  my (@list) = @_;
  $test++;
  my $pid = run_fused( my $reader, @list );
  while ( my $line = <$reader> ) {
    pass("Got line $. for $test");
    note($line);
  }
  waitpid $pid, 0;
}

test_string(q{ perl -e "print 'hello'" });
test_list( 'perl', '-e', q{print 'hello'} );

# test_list('perl ', '-e', q{print "hello world"});

done_testing;
