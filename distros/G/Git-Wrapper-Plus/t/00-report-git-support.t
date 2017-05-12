use strict;
use warnings;

use Test::More tests => 3;

# ABSTRACT: Report supported features of your git

use Git::Wrapper::Plus::Tester;
use Git::Wrapper::Plus::Support;

my $t = Git::Wrapper::Plus::Tester->new();
my $s = Git::Wrapper::Plus::Support->new( git => $t->git );

my $data = {
  commands  => {},
  behaviors => {},
  arguments => {},
};

$t->run_env(
  sub {
    note "\nCommands:";
    for my $command ( $s->commands->entries ) {
      my $msg = '- ' . $command . ' ';
      if ( $s->supports_command($command) ) {
        $msg .= "supported";
        push @{ $data->{commands}->{supported} }, $command;
      }
      else {
        push @{ $data->{commands}->{unsupported} }, $command;
        $msg .= "UNSUPPORTED";
      }
      note $msg;

    }
    pass("Commands reporting ok");
    note "\nBehaviours:";

    for my $behavior ( $s->behaviors->entries ) {
      my $msg = '- ' . $behavior . ' ';
      if ( $s->supports_behavior($behavior) ) {
        $msg .= "supported";
        push @{ $data->{behaviors}->{supported} }, $behavior;
      }
      else {
        push @{ $data->{behaviors}->{unsupported} }, $behavior;
        $msg .= "UNSUPPORTED";
      }
      note $msg;
    }
    pass("Behaviours reporting ok");

    note "\nArguments:";

    for my $cmd ( $s->arguments->commands ) {
      for my $arg ( $s->arguments->arguments($cmd) ) {
        my $msg = '- ' . $cmd . ' ' . $arg . ' ';
        if ( $s->supports_argument( $cmd, $arg ) ) {
          $msg .= "supported";
          push @{ $data->{arguments}->{supported} }, $cmd . ' ' . $arg;
        }
        else {
          push @{ $data->{arguments}->{unsupported} }, $cmd . ' ' . $arg;
          $msg .= "UNSUPPORTED";
        }
        note $msg;
      }
    }
    pass("Arguments reporting ok");
  }
);

diag "\n";
for my $level ( sort keys %{$data} ) {
  for my $grade ( sort keys %{ $data->{$level} } ) {
    my $prefix = sprintf "%14s %-11s", $level, $grade;
    my @all = @{ $data->{$level}->{$grade} };
    my @this;
    while (@all) {
      push @this, shift @all;
      my $mesg = "$prefix | " . ( join q[, ], @this );
      if ( length $mesg > 110 ) {
        diag $mesg;
        $prefix = sprintf "%14s %-11s", q[], q[];
        @this = ();
      }
      if ( not @all ) {
        diag $mesg if @this;
        last;
      }
    }

    #diag "$prefix | " . join q[, ], @{ $data->{$level}->{$grade} };
  }
}

done_testing;

