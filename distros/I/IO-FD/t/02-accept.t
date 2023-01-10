# This is a complicated file to test the status flags of a accepted socket using the
# different type of accept functions  in IO::FD
# The listening sockets is placed in nonblocking mode which should result in non blocking accepted sockets 
# bsd type operating systems and but blocking on linux
#
#The normal accept will result in this behaviour
#The accept4 test  test the flags applied
#The accept_multiple forces non blocking on  all
#
use feature ":all";
use strict;
use warnings;
use Test::More;
use IO::FD;

use Fcntl qw<FD_CLOEXEC O_NONBLOCK F_SETFL F_GETFD F_GETFL>;
use POSIX qw<EAGAIN EINPROGRESS>;
use Errno ":POSIX";

use Socket ":all";

my $error;
my @res;
my $port;

my $tests_performed;

local $^F=2;  #disable automatic close on exec for higher fds

#create a passive socket
my ($accept_fd, $client1, $accept4_fd, $client2, $accept_multiple_fd, $client3)=map {
  die  "Could not create socket " unless defined IO::FD::socket my $socket, AF_INET, SOCK_STREAM, 0;
  ($error, @res)= getaddrinfo("0.0.0.0",0, {
    flags=>AI_NUMERICHOST|AI_PASSIVE,
    family=>AF_INET,
    type=>SOCK_STREAM}
  );

  die $error if $error;

  die $! unless defined IO::FD::fcntl $socket, F_SETFL, O_NONBLOCK;
  die "Could not bind " unless defined IO::FD::bind $socket, $res[0]{addr};

  my $addr=IO::FD::getsockname($socket);

  ($error, undef, $port)=getnameinfo($addr, NI_NUMERICHOST);


  die "Could not listen" unless defined IO::FD::listen $socket, 1;


  #Connect with client
  #
  die "Could not create client socket" unless defined IO::FD::socket my $client, AF_INET, SOCK_STREAM, 0;

  die $! unless defined IO::FD::fcntl $client, F_SETFL, O_NONBLOCK;

  ($error, @res)=getaddrinfo("127.0.0.1", $port, {flags=>AI_NUMERICHOST, family=>AF_INET, type=>SOCK_STREAM});

  die $error if $error;

  my $error=IO::FD::connect $client, $res[0]{addr};
  die "Coud not connect $!" if not defined ($error) and $! != EINPROGRESS;
  ($socket,$client);

} 1..3;

#Event loop to progresss in a non blocking fashion

my $rv="";
my $wv="";
my @read_fd;#=($client);
my @read_cb;

my @write_fd;
my @write_cb;

my @connect_fd=($client1, $client2, $client3);
my $connect_cb= sub {
  &IO::FD::close;
};

my @listen_fd=($accept_fd, $accept4_fd, $accept_multiple_fd);
my $listen_cb=sub {
    my $fd=shift;
    my $peer;

    if($fd == $accept_fd){
      if(defined ($peer =IO::FD::accept my $con, $fd)){
        #Test that blocking status is correct per operating system
        my $non_block=IO::FD::fcntl $con, F_GETFL, 0;
        $non_block&=O_NONBLOCK;
        if($^O eq 'darwin' or $^O =~ /bsd/i){
          ok $non_block, "Non blocking expecteded";
        }
        elsif($^O eq 'linux'){
          ok !$non_block, "Blocking expected";
        }
        else {
          #Who knows...
        }
        $tests_performed++;
      }
    }
    elsif($fd == $accept4_fd){
	my $flags=0;
	if($^O=~/darwin/){
		$flags=IO::FD::SOCK_NONBLOCK|IO::FD::SOCK_CLOEXEC;
	}
	else{
		$flags=SOCK_NONBLOCK|SOCK_CLOEXEC;
	}
      if(defined ($peer =IO::FD::accept4 my $con, $fd, $flags)){
        #Test that flags are applied
        my $non_block=IO::FD::fcntl $con, F_GETFL, 0;
        $non_block&=O_NONBLOCK;
        ok $non_block, "Nonblocking applied";

        my $cloexec=IO::FD::fcntl $con, F_GETFD, 0;
        ok $cloexec, "Close of exec ok";
        $tests_performed++;
      }
    }
    elsif($fd == $accept_multiple_fd){
      my @peer;
      my @new;
      my $count=IO::FD::accept_multiple @new, @peer, $fd;
      ok $count == @new, "Expected number of accepted fds";

      if(defined $count){
        $tests_performed++;
        for(0..$count-1){
          #Check the  new fd is non blocking and has closexec flags
          my $value=IO::FD::fcntl $new[$_], F_GETFD, FD_CLOEXEC;
          ok defined($value), "Retrieved FD_CLOEXEC flag ok";
          ok $value == 1,  "FD_CLOEXEC flags set";

          $value=IO::FD::fcntl $new[$_], F_GETFL, 0;
          ok defined($value), "Retrieved O_NONBLOCK status ok";
          ok O_NONBLOCK==($value&O_NONBLOCK),  "O_NONBLOCK status set";
        }
      }
    }
  };



for(@read_fd){
  vec($rv, $_, 1)=1;   #We always want to know if we can read
}

for(@listen_fd){
  vec($rv, $_, 1)=1;   #We always want to know if we can read
}

for(@connect_fd){
  vec($wv, $_, 1)=1;   #We always want to know if we can read
}

my $run=1;
my $timeout=1;
while($run){
  my $count= select my $rrv=$rv, my $wwv=$wv, undef, $timeout;
  unless(defined $count){
    die "Error in select";
  }
  if($count){
    for my $i (0..$#listen_fd){
      if(vec $rrv, $listen_fd[$i], 1){
          $listen_cb->($listen_fd[$i]);
      }
    }

    if(@connect_fd){
      my $i=0;
      my @splice;
      for my $connect_fd (@connect_fd){
        if(vec $wwv, $connect_fd, 1){
          push @splice, $i;
          $connect_cb->($connect_fd);
        }
        $i++;
      }
      for(@splice){
        vec($wv, $connect_fd[$_], 1)=0; 
      }
      splice @connect_fd, $_, 1 for(reverse @splice);
    }
    
    if(@read_fd){
      for my $i (0..$#read_fd){
        if(vec $rrv, $read_fd[$i], 1){
          $read_cb[$i]->($read_fd[$i]);
        }
      }
    }

    if(@write_fd){
      for my $i (0.. $#write_fd){
        if(vec $wwv, $write_fd[$i], 1){
          $write_cb[$i]->($write_fd[$i]);
        }

      }
    }
  }
  else {
    #Timeout
    $run=$tests_performed <3;
  }
}

{
  #Die on readonly socket
  eval {
    my $ret=IO::FD::socket "",0,0,0;
  };
  ok $@=~ "Modification of a read-only value attempted", "Die on readonly socket var";
}

{
  # non fd on listen
  local $SIG{__WARN__}=sub {
    ok $_[0] =~ /IO::FD::listen called with something other than a file descriptor/, "Got warning";
  };
  my $ret=IO::FD::listen "", 3;
  ok !defined($ret), "Undef for bad fd";
  ok $! == EBADF,"bad fd";
}

{
  #Die on readonly accept
  eval {
    my $ret=IO::FD::accept "",0;
  };
  ok $@=~ "Modification of a read-only value attempted", "Die on readonly socket var";

  # non fd for accept
  local $SIG{__WARN__}=sub {
    ok $_[0] =~ /IO::FD::accept called with something other than a file descriptor/, "Got warning";
  };
  my $ret=IO::FD::accept my $new, "asdf";
  ok !defined($ret), "Undef for bad fd";
  ok $! == EBADF,"bad fd";
}
{
  #Die on readonly accept
  eval {
    my $ret=IO::FD::accept4 "",0,0;
  };
  ok $@=~ "Modification of a read-only value attempted", "Die on readonly socket var";

  # non fd for accept
  local $SIG{__WARN__}=sub {
    ok $_[0] =~ /IO::FD::accept4 called with something other than a file descriptor/, "Got warning";
  };
  my $ret=IO::FD::accept4 my $new, "asdf",0;
  ok !defined($ret), "Undef for bad fd";
  ok $! == EBADF,"bad fd";
}
{

  # non fd for connect
  local $SIG{__WARN__}=sub {
    ok $_[0] =~ /IO::FD::connect called with something other than a file descriptor/, "Got warning";
  };
  my $ret=IO::FD::connect my $new, ""; 
  ok !defined($ret), "Undef for bad fd";
  ok $! == EBADF,"bad fd";
}

done_testing;
