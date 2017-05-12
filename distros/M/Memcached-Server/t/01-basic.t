#!perl -T

use Test::More;
use Memcached::Server::Default;

use AnyEvent;
use AE;
use AnyEvent::Handle;
use AnyEvent::Socket;
use Hash::Identity qw(e);

eval {
    Memcached::Server::Default->new(
	open => [[0, 8888]]
    );
    Memcached::Server::Default->new(
	open => [[0, 8889]],
	no_extra => 1
    );
};
plan skip_all => 'Cannot bind address on 0:8888 and 0:8889' if $@;
plan tests => 64;

my $cv = AE::cv;
my $cv2 = AE::cv;

tcp_connect( 0, 8888, sub {
    my($fh) = @_;
    my $memd;
    $memd = AnyEvent::Handle->new( fh => $fh, on_error => sub { undef $memd } );

    $cv->begin;
    $memd->push_read( line => sub {
	is($_[1], "END", "get no data");
	$cv->end;
    } );
    $memd->push_write("get CindyLinz\r\n");

    $cv->begin;
    $memd->push_read( line => sub {
	is($_[1], "STORED", "set data");
	$cv->end;
    } );
    $memd->push_write("set CindyLinz 3 0 4\r\nGood\r\n");

    $cv->begin;
    $memd->push_read( line => sub {
	is($_[1], "VALUE CindyLinz 3 4", "get data");
	$cv->end;
    } );
    $cv->begin;
    $memd->push_read( line => sub {
	is($_[1], "Good", "get data");
	$cv->end;
    } );
    $cv->begin;
    $memd->push_read( line => sub {
	is($_[1], "END", "get data");
	$cv->end;
    } );
    $memd->push_write("get CindyLinz\r\n");

    $cv->begin;
    $memd->push_read( line => sub {
	is($_[1], "VALUE CindyLinz 3 4", "get multiple data");
	$cv->end;
    } );
    $cv->begin;
    $memd->push_read( line => sub {
	is($_[1], "Good", "get multiple data");
	$cv->end;
    } );
    $cv->begin;
    $memd->push_read( line => sub {
	is($_[1], "VALUE CindyLinz 3 4", "get multiple data");
	$cv->end;
    } );
    $cv->begin;
    $memd->push_read( line => sub {
	is($_[1], "Good", "get multiple data");
	$cv->end;
    } );
    $cv->begin;
    $memd->push_read( line => sub {
	is($_[1], "END", "get multiple data");
	$cv->end;
    } );
    $memd->push_write("get CindyLinz cindy CindyLinz\r\n");

    $cv->begin;
    $memd->push_read( line => sub {
	is($_[1], "STORED", "append data");
	$cv->end;
    } );
    $memd->push_write("append CindyLinz 2 0 7\r\n enough\r\n");

    $cv->begin;
    $memd->push_read( line => sub {
	is($_[1], "VALUE CindyLinz 3 11", "check append");
	$cv->end;
    } );
    $cv->begin;
    $memd->push_read( line => sub {
	is($_[1], "Good enough", "check append");
	$cv->end;
    } );
    $cv->begin;
    $memd->push_read( line => sub {
	is($_[1], "END", "check append");
	$cv->end;
    } );
    $memd->push_write("get CindyLinz\r\n");

    $cv->begin;
    $memd->push_read( line => sub {
	is($_[1], "STORED", "prepend data");
	$cv->end;
    } );
    $memd->push_write("prepend CindyLinz 1 0 6\r\nYeah! \r\n");

    $cv->begin;
    $memd->push_read( line => sub {
	is($_[1], "VALUE CindyLinz 3 17", "check prepend");
	$cv->end;
    } );
    $cv->begin;
    $memd->push_read( line => sub {
	is($_[1], "Yeah! Good enough", "check prepend");
	$cv->end;
    } );
    $cv->begin;
    $memd->push_read( line => sub {
	is($_[1], "END", "check prepend");
	$cv->end;
    } );
    $memd->push_write("get CindyLinz\r\n");

    $cv->begin;
    $memd->push_read( line => sub {
	is($_[1], "NOT_STORED", "append data fail");
	$cv->end;
    } );
    $memd->push_write("append CindyLinz2 2 0 7\r\n enough\r\n");

    $cv->begin;
    $memd->push_read( line => sub {
	is($_[1], "NOT_STORED", "prepend data fail");
	$cv->end;
    } );
    $memd->push_write("prepend CindyLinz2 1 0 6\r\nYeah! \r\n");

    $cv->begin;
    $memd->push_read( line => sub {
	is($_[1], "NOT_STORED", "add data fail");
	$cv->end;
    } );
    $memd->push_write("add CindyLinz 1 0 6\r\nYeah! \r\n");

    $cv->begin;
    $memd->push_read( line => sub {
	is($_[1], "NOT_STORED", "replace data fail");
	$cv->end;
    } );
    $memd->push_write("replace CindyLinz2 1 0 6\r\nYeah! \r\n");

    $cv->begin;
    $memd->push_read( line => sub {
	is($_[1], "STORED", "replace data");
	$cv->end;
    } );
    $memd->push_write("replace CindyLinz 1 0 6\r\nYeah! \r\n");

    $cv->begin;
    $memd->push_read( line => sub {
	is($_[1], "VALUE CindyLinz 1 6", "check replace");
	$cv->end;
    } );
    $cv->begin;
    $memd->push_read( line => sub {
	is($_[1], "Yeah! ", "check replace");
	$cv->end;
    } );
    $cv->begin;
    $memd->push_read( line => sub {
	is($_[1], "END", "check replace");
	$cv->end;
    } );
    $memd->push_write("get CindyLinz\r\n");

    $cv->begin;
    $memd->push_read( line => sub {
	is($_[1], "5", "incr data");
	$cv->end;
    } );
    $memd->push_write("incr CindyLinz 5\r\n");

    $cv->begin;
    $memd->push_read( line => sub {
	is($_[1], "2", "decr data");
	$cv->end;
    } );
    $memd->push_write("decr CindyLinz 3\r\n");

    $cv->begin;
    $memd->push_read( line => sub {
	is($_[1], "0", "decr data over");
	$cv->end;
    } );
    $memd->push_write("decr CindyLinz 3\r\n");

    $cv->begin;
    $memd->push_read( line => sub {
	is($_[1], "NOT_FOUND", "incr data fail");
	$cv->end;
    } );
    $memd->push_write("incr CindyLinz2 3\r\n");

    $cv->begin;
    $memd->push_read( line => sub {
	is($_[1], "NOT_FOUND", "decr data fail");
	$cv->end;
    } );
    $memd->push_write("decr CindyLinz2 3\r\n");

    $cv->begin;
    $memd->push_read( line => sub {
	is($_[1], "NOT_FOUND", "delete fail");
	$cv->end;
    } );
    $memd->push_write("delete CindyLinz2\r\n");

    $cv->begin;
    $memd->push_read( line => sub {
	is($_[1], "STORED", "add data");
	$cv->end;
    } );
    $memd->push_write("add CindyLinz2 0 0 3\r\nabc\r\n");

    $cv->begin;
    $memd->push_read( line => sub {
	is($_[1], "VALUE CindyLinz2 0 3", "check add");
	$cv->end;
    } );
    $cv->begin;
    $memd->push_read( line => sub {
	is($_[1], "abc", "check add");
	$cv->end;
    } );
    $cv->begin;
    $memd->push_read( line => sub {
	is($_[1], "END", "check add");
	$cv->end;
    } );
    $memd->push_write("get CindyLinz2\r\n");

    $cv->begin;
    $memd->push_read( line => sub {
	is($_[1], "DELETED", "delete data");
	$cv->end;
    } );
    $memd->push_write("delete CindyLinz2\r\n");

    $cv->begin;
    $memd->push_read( line => sub {
	is($_[1], "END", "check delete");
	$cv->end;
    } );
    $memd->push_write("get CindyLinz2\r\n");

    my $cas;

    $cv->begin;
    $memd->push_read( line => sub {
	like($_[1], qr/^VALUE CindyLinz 1 1 \d+$/, "gets data");
	($cas) = $_[1] =~ /(\d+)$/;
	$cv->end;
    } );
    $cv->begin;
    $memd->push_read( line => sub {
	is($_[1], "0", "gets data");
	$cv->end;
    } );
    $cv->begin;
    $memd->push_read( line => sub {
	is($_[1], "END", "gets data");

	$cv->begin;
	$memd->push_read( line => sub {
	    is($_[1], "NOT_FOUND", "cas not found");
	    $cv->end;
	} );
	$memd->push_write("cas CindyLinz2 0 0 3 5\r\nabc\r\n");

	$cv->begin;
	$memd->push_read( line => sub {
	    is($_[1], "EXISTS", "cas exists");
	    $cv->end;
	} );
	$memd->push_write("cas CindyLinz 0 0 3 $e{$cas+1}\r\nabc\r\n");

	$cv->begin;
	$memd->push_read( line => sub {
	    is($_[1], "STORED", "cas data");
	    $cv->end;
	} );
	$memd->push_write("cas CindyLinz 0 0 3 $cas\r\nabc\r\n");

	$cv->begin;
	$memd->push_read( line => sub {
	    like($_[1], qr/VALUE CindyLinz 0 3 \d+/, "cas check");
	    $cv->end;
	} );
	$cv->begin;
	$memd->push_read( line => sub {
	    is($_[1], "abc", "cas check");
	    $cv->end;
	} );
	$cv->begin;
	$memd->push_read( line => sub {
	    is($_[1], "END", "cas check");
	    $cv->end;
	} );
	$memd->push_write("gets CindyLinz\r\n");

	$cv->begin;
	$memd->push_read( line => sub {
	    is($_[1], "OK", "flush_all");
	    $cv->end;
	} );
	$memd->push_write("flush_all\r\n");

	$cv->begin;
	$memd->push_read( line => sub {
	    is($_[1], "END", "check flush_all");
	    $cv->end;
	} );
	$memd->push_write("gets CindyLinz\r\n");

	$cv->end;
    } );
    $memd->push_write("gets CindyLinz\r\n");
} );

tcp_connect( 0, 8889, sub {
    my($fh) = @_;
    my $memd;
    $memd = AnyEvent::Handle->new( fh => $fh, on_error => sub { undef $memd } );

    $cv2->begin;
    $memd->push_read( line => sub {
	is($_[1], "STORED", "set data");
	$cv2->end;
    } );
    $memd->push_write("set CindyLinz 3 0 4\r\nGood\r\n");

    $cv2->begin;
    $memd->push_read( line => sub {
	is($_[1], "VALUE CindyLinz 0 4", "get data");
	$cv2->end;
    } );
    $cv2->begin;
    $memd->push_read( line => sub {
	is($_[1], "Good", "get data");
	$cv2->end;
    } );
    $cv2->begin;
    $memd->push_read( line => sub {
	is($_[1], "END", "get data");
	$cv2->end;
    } );
    $memd->push_write("get CindyLinz\r\n");

    my $cas;

    $cv2->begin;
    $memd->push_read( line => sub {
	like($_[1], qr/^VALUE CindyLinz 0 4 \d+$/, "gets data");
	($cas) = $_[1] =~ /(\d+)$/;
	$cv2->end;
    } );
    $cv2->begin;
    $memd->push_read( line => sub {
	is($_[1], "Good", "gets data");
	$cv2->end;
    } );
    $cv2->begin;
    $memd->push_read( line => sub {
	is($_[1], "END", "gets data");

	$cv2->begin;
	$memd->push_read( line => sub {
	    is($_[1], "NOT_FOUND", "cas not found");
	    $cv2->end;
	} );
	$memd->push_write("cas CindyLinz2 0 0 3 5\r\nabc\r\n");

	$cv2->begin;
	$memd->push_read( line => sub {
	    is($_[1], "STORED", "cas exists no extra");
	    $cv2->end;
	} );
	$memd->push_write("cas CindyLinz 0 0 3 $e{$cas+1}\r\nabc\r\n");

	$cv2->begin;
	$memd->push_read( line => sub {
	    is($_[1], "STORED", "cas data");
	    $cv2->end;
	} );
	$memd->push_write("cas CindyLinz 0 0 3 $cas\r\nabc\r\n");

	$cv2->begin;
	$memd->push_read( line => sub {
	    like($_[1], qr/VALUE CindyLinz 0 3 \d+/, "cas check");
	    $cv2->end;
	} );
	$cv2->begin;
	$memd->push_read( line => sub {
	    is($_[1], "abc", "cas check");
	    $cv2->end;
	} );
	$cv2->begin;
	$memd->push_read( line => sub {
	    is($_[1], "END", "cas check");
	    $cv2->end;
	} );
	$memd->push_write("gets CindyLinz\r\n");

	$cv2->begin;
	$memd->push_read( line => sub {
	    is($_[1], "OK", "flush_all");
	    $cv2->end;
	} );
	$memd->push_write("flush_all\r\n");

	$cv2->begin;
	$memd->push_read( line => sub {
	    is($_[1], "END", "check flush_all");
	    $cv2->end;
	} );
	$memd->push_write("gets CindyLinz\r\n");

	$cv2->end;
    } );
    $memd->push_write("gets CindyLinz\r\n");
} );

$cv->recv;
$cv2->recv;
