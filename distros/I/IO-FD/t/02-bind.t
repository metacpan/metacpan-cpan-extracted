use Test::More;
use IO::FD;
use POSIX qw<errno_h>;

{
  local $SIG{__WARN__}=sub {
    ok $_[0]=~/IO::FD::bind called with something other than a file descriptor/, "bad fd";
  };
  my $ret=IO::FD::bind "",undef;
  ok !defined($ret), "bad fd in bind";
  ok $!== EBADF;

}
{
  eval {
    my $ret=IO::FD::socketpair "",undef, 0, 0, 0;
  };
  ok $@, "socket pair sv no readonly";

}

{
  local $SIG{__WARN__}=sub {
    ok $_[0]=~/IO::FD::dup called with something other than a file descriptor/, "bad fd";
  };
  my $ret=IO::FD::dup "asdf";
  ok !defined($ret), "bad fd in dup";
  ok $!== EBADF;

}
{
  local $SIG{__WARN__}=sub {
    ok $_[0]=~/IO::FD::dup2 called with something other than a file descriptor/, "bad fd";
  };
  my $ret=IO::FD::dup2 "asdf",0;
  ok !defined($ret), "bad fd in dup2";
  ok $!== EBADF;

  $ret=IO::FD::dup2 0,"df";
  ok !defined($ret), "bad fd in dup2";
  ok $!== EBADF;

}
{
  eval {
    my $ret=IO::FD::socket "",undef, 0, 0;
  };
  ok $@, "socket sv no readonly";

}
done_testing;
