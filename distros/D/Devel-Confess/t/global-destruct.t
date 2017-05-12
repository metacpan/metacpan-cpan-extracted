use strict;
use warnings;
BEGIN {
  $ENV{DEVEL_CONFESS_OPTIONS} = '';
}
no warnings 'once';
use Devel::Confess;
use POSIX ();

$| = 1;
print "1..1\n";

{
  package MyException;
  use overload
    fallback => 1,
    '""' => sub {
      $_[0]->{message};
    },
  ;
  sub new {
    my ($class, $message) = @_;
    my $self = bless { message => $message }, $class;
    return $self;
  }
}

sub foo {
  eval { die MyException->new("yarp") };
  $@;
}

sub bar {
  foo();
}


# gd order is unpredictable, try multiple times
our $last01 = bless {}, 'InGD';
our $last02 = bless {}, 'InGD';
our $ex = bar();
our $stringy = "$ex";
our $last03 = bless {}, 'InGD';
our $last04 = bless {}, 'InGD';

sub InGD::DESTROY {
  if (!defined $ex) {
    print "ok 1 # skip got unlucky on GD order, can't test\n";
  }
  else {
    my $gd_stringy = "$ex";
    my $ok = $gd_stringy eq $stringy;
    print ( ($ok ? '' : 'not ') . "ok 1 - stringifies properly in global destruction\n");
    unless ($ok) {
      s/^/#  /mg, s/\n$//
        for $stringy, $gd_stringy;
      print "# Got:\n$gd_stringy\n#\n# Expected:\n$stringy\n";
      POSIX::_exit(1);
    }
  }
  POSIX::_exit(0);
}
