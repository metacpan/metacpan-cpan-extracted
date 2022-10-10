use Test::More;
use lib "lib";
use lib "blib/lib";
use lib "blib/arch";

use IO::FD;
use IO::FD::Constants;

use feature ":all";
#say @IO::FD::Constants::EXPORT;

use Fcntl;
use strict;
use warnings;
################################
# use constant {               #
#         POLLIN=>0x0001,      #
#         POLLPRI=>0x0002,     #
#         POLLOUT=>0x0004,     #
#         POLLRDNORM=>0x0040,  #
#         POLLWRNORM=>POLLOUT, #
#         POLLRDBAND=>0x0080,  #
#         POLLWRBAND=>0x0100,  #
#         POLLERR=>0x0008,     #
#         POLLHUP=>0x0010,     #
#         POLLNVAL=>0x0020     #
# };                           #
################################

#Create a pipe with a read fd and a write fd
ok defined IO::FD::pipe(my $read, my $write);

for($read,$write){
	my $flags=IO::FD::fcntl( $_, F_GETFL,0);
	die "Could not set non blocking" unless defined IO::FD::fcntl($_, F_SETFL, $flags|O_NONBLOCK);
}

#Poll
#pack "iss"; #int=> fd short=>flags to watch,  short=>result flags;
my %position;
my $list="";
$list.=pack POLLFD_PACKER, $read, POLLIN, 0, $write, POLLOUT, 0;
for(0..10){
	#Build list to monitor
	#execute poll
	my $res=IO::FD::poll($list,0);
	ok $res==1 , "Write ready";

}
done_testing;
