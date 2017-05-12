use warnings;
use strict;
use Test::More;
use Test::Exception;

use Log::Fast;


plan tests => 17;


my $LOG = Log::Fast->global();

lives_ok  { Log::Fast->new({})  };
lives_ok  { Log::Fast->new()    };
throws_ok { Log::Fast->new([])  } qr/HASHREF/;

lives_ok  { $LOG->config({})    };
throws_ok { $LOG->config()      } qr/HASHREF/;
throws_ok { $LOG->config([])    } qr/HASHREF/;

lives_ok  { $LOG->config({prefix=>q{}}) };
throws_ok { $LOG->config({preFix=>q{}}) } qr/unknown option/;

throws_ok { $LOG->config({level=>'InFo'})   } qr/{level}/;
lives_ok  { $LOG->config({level=>'INFO'})   };
throws_ok { $LOG->level('InFo')             } qr/{level}/;
lives_ok  { $LOG->level('INFO')             };

SKIP: {
    eval {
        use File::Temp qw( tempfile );
        use Socket;
        (undef, my $tempfile) = tempfile();
        unlink $tempfile;
        socket my $sock, AF_UNIX, SOCK_DGRAM, 0 or die "socket: $!";
        connect $sock, sockaddr_un($tempfile) or die "connect: $!";
        unlink $tempfile;
    };
    skip 'no UNIX sockets available', 2 if $@;
    SKIP: {
        use Sys::Syslog ();
        my $path = Sys::Syslog::_PATH_LOG() || '/dev/log';
        skip 'unable to detect syslog socket', 1 if !-S $path;
        lives_ok  { $LOG->config({type=>'unix',path=>$path})   };
    }
    throws_ok { $LOG->config({type=>'unix',path=>'nosuch'})     } qr/connect:/;
}

throws_ok { $LOG->config({type=>'Fh',fh=>\*NOSUCH}) } qr/{type}/;

lives_ok  { $LOG->config({type=>'fh',fh=>\*NOSUCH}) };
throws_ok { $SIG{__WARN__}=sub{}; $LOG->ERR('test') } qr/print/;

