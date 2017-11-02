use Test2::Bundle::Extended;
#use Keyword::Declare {debug => 1};
use Filter::Cleanup;

subtest 'simple' => sub {
  my $var1 = 'unset';
  my $var2 = 'unset';
  my $var3 = 'unset';
  my $var4 = 'unset';

  do {
    cleanup { $var2 = 'set' };
    $var1 = 'set';
  };

  do {
    cleanup { $var3 = 'set' }
    $var4 = 'set';
  };

  is $var1, 'set', 'statement is executed';
  is $var2, 'set', 'cleanup is executed';
};

subtest 'error handling' => sub {
  my $var = 'unset';
  my $code = sub {
    cleanup { $var = 'set' };
    die 'dead';
  };

  like dies{ $code->() }, qr/dead/, 'error is rethrown';
  is $var, 'set', 'cleanup is executed';
};

subtest 'nested' => sub {
  subtest 'simple' => sub {
    my @trap;

    do {
      cleanup { push @trap, 'cleanup1' }
      cleanup { push @trap, 'cleanup2' }
      cleanup { push @trap, 'cleanup3' }
    };

    is \@trap, [qw(cleanup3 cleanup2 cleanup1)], 'cleanups called in correct order';
  };

  subtest 'error after final cleanup' => sub {
    my @trap;

    my $code = sub {
      cleanup { push @trap, 'cleanup1' };
      cleanup { push @trap, 'cleanup2' };
      cleanup { push @trap, 'cleanup3' };
      die 'dead';
    };

    like dies{ $code->() }, qr/dead/, 'error is rethrown';
    is \@trap, [qw(cleanup3 cleanup2 cleanup1)], 'cleanups called in correct order';
  };

  subtest 'interstitial error' => sub {
    my @trap;

    my $code = sub {
      cleanup { push @trap, 'cleanup1' };
      cleanup { push @trap, 'cleanup2' };
      die 'dead';
      cleanup { push @trap, 'cleanup3' };
    };

    like dies{ $code->() }, qr/dead/, 'error is rethrown';
    is \@trap, [qw(cleanup2 cleanup1)], 'correct cleanups called and in correct order';
  };
};

subtest 'list context' => sub {
  my $var = 'unset';
  my $code = sub {
    cleanup { $var = 'set' };
    return (8, 4, 2);
  };

  is [$code->()], [8, 4, 2], 'result returned in list context';
  is $var, 'set', 'cleanup is executed';
};

subtest 'early block exit' => sub {
  my @trap;
  foreach my $i (1 .. 10) {
    cleanup { push @trap, $i };
    last if $i == 6;
  }

  is \@trap, [1,2,3,4,5,6], 'expected variables trapped';
};

done_testing;
