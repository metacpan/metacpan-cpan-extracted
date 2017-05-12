use strict;
use Test::More tests => 3;
use IO::Capture::Stdout;

my $class = 'Language::MinCaml';

use_ok($class);

### test _interpret
# skip

### test interpret_string
{
    my $capture = IO::Capture::Stdout->new;
    my $string;

    $string = << 'INPUT';
let rec gcd m n =
  if m = 0 then n else
  if m <= n then gcd m (n - m) else
  gcd n (m - n) in
print_int (gcd 78 117)
INPUT

    $capture->start();
    $class->interpret_string($string);
    $capture->stop();
    is($capture->read, '39');
}

### test interpret_file
{
    my $capture = IO::Capture::Stdout->new;

    $capture->start();
    $class->interpret_file('t/assets/gcd.ml');
    $capture->stop();

    is($capture->read, '39');
}

