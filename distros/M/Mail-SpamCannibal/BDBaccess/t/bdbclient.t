# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

######################### We start with some black magic to print on failure.
# Change 1..1 below to 1..last_test_to_print .
# (It may become useful if the test is moved to ./t subdirectory.)

BEGIN { $| = 1; print "1..12\n"; }
END {print "not ok 1\n" unless $loaded;}

#use diagnostics;
use Cwd;
use Mail::SpamCannibal::BDBclient;
use IO::Socket::UNIX;

print "ok 1\n";
######################### End of black magic.

$loaded = 1;
# Insert your test code below (better if it prints "ok 13"
# (correspondingly "not ok 13") depending on the success of chunk 13
# of the test code):

$test = 2;

umask 007;
foreach my $dir (qw(tmp tmp.dbhome tmp.bogus)) {
  if (-d $dir) {         # clean up previous test runs
    opendir(T,$dir);
    @_ = grep(!/^\./, readdir(T));
    closedir T;
    foreach(@_) {
      unlink "$dir/$_";
    }
    rmdir $dir or die "COULD NOT REMOVE $dir DIRECTORY\n";
  }
  unlink $dir if -e $dir;	# remove files of this name as well
}

sub ok {
  print "ok $test\n";
  ++$test;
}

my $dir = cwd() .'/tmp';
mkdir $dir,0755;

## test 2	open listen socket
my $listen = IO::Socket::UNIX->new(
	Type	=> SOCK_STREAM,
	Local	=> $dir .'/bdbclient',
	Listen	=> 5,
) or print "could not open listen socket\nnot ";
&ok;

## test 3 	open talk socket
my $talk = Mail::SpamCannibal::BDBclient::_unsock($dir .'/bdbclient')
	or print "could not open talk socket\nnot ";
&ok;

## test 4	talk
my $n = syswrite $talk, "hello";
print "sent: $n characters, exp: 5 characters\nnot "
	unless $n == 5;
&ok;

## test 5	accept talker
local *Client;
accept(Client,$listen) or print "could not accept connection\nnot ";
&ok;

## test 6	read from talker
my $buffer;
$n = sysread(Client, $buffer, 1000);

print "read error $!\nnot "
	if $!;
&ok;

## test 7	verify read data
print "got: $n characters, exp: 5 characters\nnot "
	unless $n == 5;
&ok;

## test 8	verify read data content
print "got: $buffer, exp: hello\nnot "
	unless $buffer eq 'hello';
&ok;

## test 9	speak to talker
$n = syswrite(Client,"goodbye");
print "sent: $n, exp: 7\nnot "
	unless $n == 7;
&ok;

## test 10	read from talker
$n = sysread $talk, $buffer, 1000;

print "talker read error $!\nnot "
	if $!;
&ok;

## test 11	check talker data
print "got: $n, exp: 7\nnot "
	unless $n == 7;
&ok;

## test 12	check data content
print "got: $buffer, exp: goodbye\nnot "
	unless $buffer eq 'goodbye';
&ok;

close Client;
close $listen;
close $talk;
