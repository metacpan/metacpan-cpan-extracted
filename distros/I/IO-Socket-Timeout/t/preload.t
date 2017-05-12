use strict;
use warnings;

use FindBin qw($Bin);
use Test::More;

use IO::Socket::Timeout qw(IO::Socket::INET IO::Socket::Unix);

ok exists($INC{'IO/Socket/Unix__with__IO/Socket/Timeout/Role/SetSockOpt.pm'}),
  'INC contains composed class IO::Socket::Unix with SetSockOpt role"';

like($INC{'IO/Socket/Unix__with__IO/Socket/Timeout/Role/SetSockOpt.pm'},
     qr|lib/IO/Socket/Timeout\.pm$|, 'file name is ok');

ok exists($INC{'IO/Socket/Unix__with__IO/Socket/Timeout/Role/PerlIO.pm'}),
  'INC contains composed class IO::Socket::Unix with PerlIO role"';

like($INC{'IO/Socket/Unix__with__IO/Socket/Timeout/Role/PerlIO.pm'},
     qr|lib/IO/Socket/Timeout\.pm$|, 'file name is ok');

ok exists($INC{'IO/Socket/INET__with__IO/Socket/Timeout/Role/SetSockOpt.pm'}),
  'INC contains composed class IO::Socket::INET with SetSockOpt role"';

like($INC{'IO/Socket/INET__with__IO/Socket/Timeout/Role/SetSockOpt.pm'},
     qr|lib/IO/Socket/Timeout\.pm$|, 'file name is ok');

ok exists ($INC{'IO/Socket/INET__with__IO/Socket/Timeout/Role/PerlIO.pm'}),
  'INC contains composed class IO::Socket::INET with PerlIO role"';

like($INC{'IO/Socket/INET__with__IO/Socket/Timeout/Role/PerlIO.pm'},
     qr|lib/IO/Socket/Timeout\.pm$|, 'file name is ok');




done_testing;

