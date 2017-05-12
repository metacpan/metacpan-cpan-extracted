use strict;
use warnings;

use Config;
BEGIN {
  unless ($Config{useithreads}) {
    print "1..0 # SKIP your perl does not support ithreads\n";
    exit 0;
  }
}

BEGIN {
  unless (eval { require threads }) {
    print "1..0 # SKIP threads.pm not installed\n";
    exit 0;
  }
}

BEGIN {
  if ($ENV{DEVEL_GLOBALDESTRUCTION_PP_TEST}) {
    unshift @INC, sub {
      die 'no XS' if $_[1] eq 'Devel/GlobalDestruction/XS.pm';
    };
  }
}

BEGIN {
  package Test::Scope::Guard;
  sub new { my ($class, $code) = @_; bless [$code], $class; }
  sub DESTROY { my $self = shift; $self->[0]->() }
}
BEGIN {
  package Test::Thread::Clone;
  my @code;
  sub new { my ($class, $code) = @_; push @code, $code; bless [$code], $class; }
  sub CLONE { $_->() for @code }
}

use threads;
use threads::shared;

print "1..4\n";

our $had_error :shared;
END { $? = $had_error||0 }

sub ok ($$) {
  $had_error++, print "not " if !$_[0];
  print "ok";
  print " - $_[1]" if defined $_[1];
  print "\n";
}

# load it before spawning a thread, that's the whole point
use Devel::GlobalDestruction;

our $cloner = Test::Thread::Clone->new(sub {
    ok( ! in_global_destruction(), "CLONE is not GD" );
    my $guard = Test::Scope::Guard->new(sub {
        ok( ! in_global_destruction(), "DESTROY during CLONE is not GD");
    });
});
our $global = Test::Scope::Guard->new(sub {
    ok( in_global_destruction(), "Final cleanup object destruction properly in GD in " . (threads->tid ? 'thread' : 'main program') );
});

sub do_test {
  # just die so we don't need to deal with testcount skew
  unless ( ($_[0]||'') eq 'arg' ) {
    $had_error++;
    die "Argument passing failed!";
  }
  # nothing really to do in here
  1;
}

threads->create('do_test', 'arg')->join
  or $had_error++;
