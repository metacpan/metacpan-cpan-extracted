package Apache::ADS::EventServer;


use 5.006;
use strict;
use warnings;
use HTTPD::ADS;
use IO::Socket::UNIX;
use User::pwent;

#do not run this as root, I specifically split root-privileged code into another module.
#you MUST run this as your Postgresql database username
#this username has to be a member of the primary group for the webserver because UNIX doesn't support proper access lists.
BEGIN {
use CGI::Carp qw(cluck  carpout);
my $logfile="/tmp/EventServer.log";
die "cannot open log file $logfile for write" if (-e $logfile && ! (-w $logfile));
open(LOG, ">>$logfile") or die "carp could not open log";
carpout(\*LOG);
}


our $VERSION = '0.01';

#daemon process waits for events to come in, then puts them in database and analyzes and takes action

my $ADSDatabase="wwwads";
my $ADSDataUser="";
my $ADSDataPassword="";
my $webserverusername="wwwrun";
my $webpw = getpwnam($webserverusername);
my $fifo = "/tmp/AttackWatch";
die "socket file present and I can't delete it" if(-e $fifo and (unlink $fifo) !=1);
my $default_filepermissions = umask 07 ;#INVERSE: bit set is deny access this denys Other, allows user and group rwx
my $listen = IO::Socket::UNIX->new(Local=>$fifo, Listen=>0) || die "$!"; #per io_unix.t of IO::Socket::UNIX
#the above line creates the socket file but we 
my $rv = chown (-1,$webpw->gid,$fifo);#-1 is supposed to mean leave it alone
carp "Could not change group of socket file $fifo, LiveWatch may not be able to use socket" unless $rv==1;
my $message;
my $oldtimeout = $listen->timeout(3600);
print "timeout set, was ".(defined $oldtimeout? $oldtimeout:  "not defined\n");
print "blocking mode set, was ".$listen->blocking(0);
my  $sock = $listen->accept();
my %args;
my $apacheids = HTTPD::ADS->new (
			       ADSDataUser => $ADSDataUser,
			       ADSDataPassword   => $ADSDataPassword,
			       ADSDatabase => $ADSDatabase);
while (1) {
  $message= $sock->getline;
  undef %args;			#clean it out
  if (!defined $message) {
    my $time = scalar localtime;
    carp "$time: socket problem  $! - no message rec'd.\n";
    next;
  }
  %args = split /\^/,$message;


#1st is to put the event in the  database.
# then can decide what to do  about it.
# One may think access to protected page w/o specifying username is innocent. Maybe. but it could
# be that someone trys and then failing to get in launches a brute force attack. So while blank
# username on its own might be innocent it could be counted with failed login attempts 
# as grounds for killing some asshole
# or blackholing his ip anyway. But you need data on which to make a decision.
    $apacheids->event_recorder(%args);

}


1;
__END__



=head1 AUTHOR

Dana Hudes, E<lt>dhudes@networkengineer.bizE<gt>

=head1 SEE ALSO

L<perl>.

=cut
