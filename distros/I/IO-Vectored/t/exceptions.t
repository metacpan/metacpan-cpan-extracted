use strict;
use Test::More tests => 6;
use POSIX;

use IO::Vectored;


{
  eval {
    syswritev(STDOUT);
  };

  my $err = $@;
  like($err, qr/need more arguments/, "too few arguments detected");
}


{
  my @vector = ('Q') x (IO::Vectored::IOV_MAX + 1);

  eval {
    syswritev(STDOUT, @vector);
  };

  my $err = $@;
  like($err, qr/too many arguments/, "too many arguments detected");
}


{
  eval {
    syswritev(STDOUT, {});
  };

  my $err = $@;
  like($err, qr/non-string/, "non-string object detected");
}

{
  eval {
    sysreadv(STDIN, "this is a constant/read-only string");
  };

  my $err = $@;
  like($err, qr/Can't modify/, "constant/read-only string detected");
}


{
  pipe(my $r, my $w) || die "pipe: $!";
  close($w);

  eval {
    syswritev($w, "hello");
  };

  my $err = $@;
  like($err, qr/closed or invalid/, "closed file handle detected");
}


{
  pipe(my $r, my $w) || die "pipe: $!";
  POSIX::close(fileno($w));

  is(syswritev($w, "hello"), undef, "undef from closed file descriptor");
}
