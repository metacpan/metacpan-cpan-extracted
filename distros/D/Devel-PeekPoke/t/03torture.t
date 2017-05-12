use strict;
use warnings;

# T::M appears to leak, emit the TAP by hand
#use Test::More 'no_plan';

sub is {
  my $str = $_[0] eq $_[1] ? 'ok' : 'not ok';

  {
    lock($::TEST_COUNT);
    $::TEST_COUNT++;
    printf STDOUT ("%s %u - %s\n",
      $str,
      $::TEST_COUNT,
      $_[2] || '',
    );
  }
  threads->yield if $INC{'threads.pm'};
}

use Devel::PeekPoke qw/peek poke peek_address poke_address/;
use Devel::PeekPoke::Constants qw/PTR_SIZE PTR_PACK_TYPE/;

my $str = 'for mutilation and mayhem';
my $len = length($str);
my $str_pv_addr = unpack(PTR_PACK_TYPE, pack('p', $str) );

is( peek($str_pv_addr, $len + 1), $str . "\0", 'peek as expected (with NUL termination)' );

for (1 .. ($ENV{AUTOMATED_TESTING} ? 200 : 5 ) ) {
  for my $poke_size (2 .. $len) {
    my $replace_chunk = 'a' . ( '0' x ($poke_size-1) );
    for my $poke_start ( 0 .. ($len - $poke_size) ) {
      $replace_chunk++;

      my $expecting = $str;
      substr($expecting, $poke_start, $poke_size, $replace_chunk);

      poke($str_pv_addr+$poke_start, $replace_chunk);
      is($str, $expecting, 'String matches expectation after poke');
    }
  }
}

if ($ENV{AUTOMATED_TESTING} and ! $INC{'threads.pm'}) {
  my $vsz;
  if (-f "/proc/$$/stat") {
    my $proc_stat = do { local (@ARGV, $/) = "/proc/$$/stat"; <> };
    ($vsz) = map { $_ / 1024 }
      (split (/\s+/, $proc_stat))[-22];  # go backwards because the %s of the procname can contain anything
  }

  printf STDERR "#\n# VSIZE:%dKiB\n", $vsz
    if $vsz;
}

print "1..$::TEST_COUNT\n" unless $INC{'threads.pm'};
