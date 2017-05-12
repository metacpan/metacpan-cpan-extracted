
our $perl_path;
sub find_perl_path {

  use Config;
  if ($^X =~ m|^/|) {
    $perl_path = $^X;
  }
  elsif ($config{PERL_PATH}) {
    $perl_path = $config{PERL_PATH};
  }
  else {
    $perl_path = $Config{perlpath};
    $perl_path =~ s|/[^/]*$|/$^X|;
  }
}


sub start_indexd {
  my $indexd_port = int (20000 + rand(10000));
  $indexd_uri = "dq://127.0.0.1:${indexd_port}";

  find_perl_path();

  if (($indexd_pid = fork) == 0) {
    print "running: $perl_path ../dq-indexd --port $indexd_port\n";
    exec ("$perl_path ../dq-indexd --port $indexd_port");
    die;
  } else {
    sleep 1;
    print "started indexd $indexd_pid at $indexd_uri\n";
  }
}

sub stop_indexd {
  # use POSIX ":sys_wait_h";

  # need to set this explicitly, otherwise t/15_enq_indexd.t screws up
  $SIG{CHLD} = 'DEFAULT';

  ok kill (15, $indexd_pid);
  print "stopped indexd $indexd_pid at $indexd_uri\n";

  $kid = waitpid($indexd_pid, 0);
  ok ($kid == $indexd_pid) or warn "kid=$kid ipid=$indexd_pid ex=$! q=$?";

  ok (($? >> 8) == 0);
}

1;
