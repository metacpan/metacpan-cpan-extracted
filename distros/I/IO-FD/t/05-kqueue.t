use Test::More;
use lib "lib";
use lib "blib/lib";
use lib "blib/arch";

use IO::FD;
use IO::FD::Constants;

use feature ":all";
#say @IO::FD::Constants::names;

use Fcntl;

use strict;
use warnings;

plan skip_all => "kqueue not supported on  $^O" if $^O !~ /darwin|bsd/i;

my $kq=IO::FD::kqueue();
ok defined( $kq), "Create a queue";

#Create a pipe with a read fd and a write fd
ok defined IO::FD::pipe(my $read, my $write);

for($read,$write){
	my $flags=IO::FD::fcntl( $_, F_GETFL,0);
	die "Could not set non blocking" unless defined IO::FD::fcntl($_, F_SETFL, $flags|O_NONBLOCK);
}

     #############################################################################
     # struct kevent {                                                           #
     #         uintptr_t       ident;          /* identifier for this event */   #
     #         int16_t         filter;         /* filter for event */            #
     #         uint16_t        flags;          /* general flags */               #
     #         uint32_t        fflags;         /* filter-specific flags */       #
     #         intptr_t        data;           /* filter-specific data */        #
     #         void            *udata;         /* opaque user data identifier */ #
     #         #extensions
     # };                                                                        #
     #############################################################################

	my $struct=pack(KEVENT_PACKER, $read, EVFILT_READ,EV_ADD|EV_ENABLE,0,0,0); 

     	my $results=IO::FD::SV(length($struct) * 10);
	my $ret=IO::FD::kevent($kq, $struct, $results, 0);
	
	
for(1..5){
	IO::FD::syswrite $write, "Hello";
	my $ret=IO::FD::kevent($kq, $struct, $results, undef);
}


IO::FD::close $kq;
done_testing;
