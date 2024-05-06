use Test2::V0; 

sub capture_stderr :prototype(&) {
  my ($sub) = @_;
  # We redirect STDERR to be read from a custom READ_STDERR handle.
  pipe READ_STDERR, NEW_STDERR;
  open REAL_STDERR, '>&', STDERR;
  close STDERR;
  open STDERR, '>&', NEW_STDERR;
  close NEW_STDERR;
  $sub->();
  # We restore STDERR to the saved REAL_STDERR handle.
  close STDERR;
  open STDERR, '>&', REAL_STDERR;
  close REAL_STDERR;
  # We slupr our READ_STDERR handle.
  my @data = <READ_STDERR>;
  close READ_STDERR;
  return @data;
}

subtest '--log debug' => sub {
  my @logs = capture_stderr {
    package MyTest1;
    @ARGV = qw(foo --log debug bar);
    # We are using eval statement everywhere to force the calls to
    # Log::Any::Adapter->set (and ->remove) to happen at runtime, once our test
    # setup is correctly in place.
    # Because of this, we have to pre-declare the test methods.
    sub info; sub debug; sub trace;
    eval "use Log::Any::Simple qw(:default :from_argv)";
    info 'foo';
    debug 'bar';
    trace 'baz';
    eval "no Log::Any::Simple ':logging'";
  };
  is(\@ARGV, ['foo', 'bar'], 'parsed arguments are removed from argv');
  is(\@logs, ["INFO - foo\n", "DEBUG(MyTest1) - bar\n"], 'Logged as required');
};

subtest '--log=info' => sub {
  my @logs = capture_stderr {
    package MyTest2;
    @ARGV = qw(foo --log=info bar);
    sub info; sub debug;
    eval "use Log::Any::Simple qw(:default :from_argv)";
    info 'foo';
    debug 'bar';
    eval "no Log::Any::Simple ':logging'";
  };
  is(\@ARGV, ['foo', 'bar'], 'parsed arguments are removed from argv');
  is(\@logs, ["INFO - foo\n"], 'Logged as required ');
};

subtest '--log' => sub {
  my @logs = capture_stderr {
    package MyTest3;
    @ARGV = qw(foo --log);
    sub error; sub trace;
    eval "use Log::Any::Simple qw(:default :from_argv)";
    error 'foo';
    trace 'baz';
    eval "no Log::Any::Simple ':logging'";
  };
  is(\@ARGV, ['foo', '--log'], 'nothing removed from @ARGV');
  is(\@logs, [], 'nothing logged');
};

done_testing;
