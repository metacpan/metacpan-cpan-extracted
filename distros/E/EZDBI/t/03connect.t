use EZDBI;

my $response;
if( -t STDIN ){
    print STDERR q(

    ************************************************************
    This test is optional and requires a functional DBI setup
    You will need a username, password, and databasename on hand.

    You may skip this test with confidence if 02connect.t was OK
    ************************************************************

    Do you wish to proceed? [yN] );
    chomp($response = lc(<STDIN>));
}
unless( -t STDIN && grep { $response eq $_ } ('1', 'y', 'yes') ){
  print "1..0 # Skip live test\n";
  exit 0;
}


print "1..3\n";
eval{
  use POSIX qw(:termios_h);
  my ($term, $oterm, $echo, $noecho, $fd_stdin);
  
  $fd_stdin = fileno(STDIN);
  $term     = POSIX::Termios->new();
  $term->getattr($fd_stdin);
  $oterm     = $term->getlflag();
  $echo     = ECHO | ECHOK | ICANON;
  $noecho   = $oterm & ~$echo;
  
  sub cbreak {
    $term->setlflag($noecho);
    $term->setcc(VTIME, 1);
    $term->setattr($fd_stdin, TCSANOW);
  }
  sub cooked {
    $term->setlflag($oterm);
    $term->setcc(VTIME, 0);
    $term->setattr($fd_stdin, TCSANOW);
  }
  sub getone {
    my $key = '';
    cbreak();
    sysread(STDIN, $key, 1);
    cooked();
    return $key;
  }
} or my $ECHO = 'on';


my($pass, $dbh);
print STDERR "    Enter a DSN e.g. mysql:database1: ";   chomp(my $dsn =  <>);
print STDERR "    Enter a table within this database: "; chomp(my $table= <>);
print STDERR "    Enter a valid username with access: "; chomp(my $user = <>);
until( $dbh ){
  printf STDERR "    Enter the user's password (echo is %s): ", $ECHO || 'off';
  if( $ECHO ){
    chomp($pass =  <>);
  }
  else{
    my $got = '';
    until( $got eq $/ ){
      $pass .= $got;
      $got   = getone();
    }
    cooked();
  }
  unless( $dbh = eval { Connect($dsn, $user, $pass) } ){
    print STDERR q(
    The password may have been mistyped, try again? [Yn] );
    chomp(my $response = lc(<>));
    if( grep { $response eq $_ } ('0', 'n', 'no') ){
      print "not ok 1\n";
      print "ok $_ # Skip\n" for 2 .. 3;
      goto END;
    }
  }
}
print "ok 1\n";


eval {
  my $s = Select("COUNT(*) FROM $table");
  print "ok 2\n";
  printf STDERR qq(
    There appear to be %i rows in $dsn:$table.
    Is this reasonable/correct? [yN] ),
      $s->([])->[0];
  chomp(my $response = lc(<>));
  print 'not ' unless grep { $response eq $_ } ('1', 'y', 'yes');
  
} or print 'not ';
print "ok 3\n";
print STDERR "\n";
1;
