package MockFH;

use v5.20;
use warnings;

sub new { bless [], shift }

# void-returning methods
{
   no strict 'refs';

   *$_ = sub { } for qw(
      set_mode
      cfmakeraw
      setflag_clocal

      autoflush
   );
}

0x55AA;
