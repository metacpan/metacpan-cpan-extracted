use lib 't/lib';
use ThreadsCheck;
use threads;
use strict;
use warnings;
BEGIN {
  $ENV{DEVEL_CONFESS_OPTIONS} = '';
}

use MiniTest;

use Devel::Confess qw(nowarnings);

my $gone = 0;
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
  sub DESTROY {
    $gone++;
  }
}

sub foo {
  eval { die MyException->new("yarp") };
  $@;
}

sub bar {
  foo();
}

my $ex = bar();

my $stringy_ex = "$ex";

my $stringy_from_thread = threads->create(sub {
  "$ex";
})->join;

is $stringy_from_thread, $stringy_ex,
  'stack trace maintained across threads';

my $thread_gone = threads->create(sub {
  undef $ex;
  $gone;
})->join;

is $thread_gone, $gone + 1,
  'DESTROY called in threads for cloned exception';

my $cleared = threads->create(sub {
  my $class = ref $ex;
  undef $ex;
  UNIVERSAL::can($class, 'DESTROY') ? 0 : 1;
})->join;

ok $cleared,
  'cloned exception cleans up namespace when destroyed';

done_testing;
