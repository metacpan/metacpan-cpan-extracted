use strict;
use FileHandle::Unget;
use Test::More tests => 2;

#-------------------------------------------------------------------------------

{
  my $out = new FileHandle::Unget;
  my $in = new FileHandle::Unget;

  pipe $out, $in or die;

  my $pid = fork();

  unless(defined $pid)
  {
    # 1
    ok(0, "Couldn't fork");

    # 2
    ok(0, "Couldn't get info from child");

    exit;
  }

  # In parent
  if ($pid)
  {
    close $in;

    # 1
    ok(1, 'Fork succeeded');

    local $/ = undef;
    my $results = <$out>;

    # 2
    is($results,"Some info from the child\nSome more\n", 'Child output');

    exit;
  }
  # In child
  else
  {
    print $in "Some info from the child\nSome more\n";
    exit;
  }
}
