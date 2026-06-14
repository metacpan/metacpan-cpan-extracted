use v5.36;
use strict;
use warnings;

use Test::More;

my @checks = (
  [ 'lib/Linux/Event/Wakeup.pm', 'Linux::FD::Event is required for waker() support' ],
  [ 'lib/Linux/Event/Signal.pm', 'Linux::FD::Signal is required for signal() support' ],
  [ 'lib/Linux/Event/Pid.pm',    'Linux::FD::Pid is required for pid() support' ],
);

for my $check (@checks) {
  my ($file, $needle) = @$check;
  open my $fh, '<', $file or die "open $file: $!";
  local $/;
  my $src = <$fh>;
  like($src, qr/\Q$needle\E/, "$file has clear optional dependency error");
}

done_testing;
