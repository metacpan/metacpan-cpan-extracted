#!perl -T

use Test::More;
use Memcached::Server;

use AnyEvent;
use AE;
use AnyEvent::Handle;
use AnyEvent::Socket;
use Hash::Identity qw(e);

eval {
    my $data;
    Memcached::Server->new(
	open => [[0, 8888]],
	cmd => {
	    _begin => sub {
		my($cb, $client) = @_;
		$data->{$client} = {};
		$cb->();
	    },
	    _end => sub {
		my($cb, $client) = @_;
		delete $data->{$client};
		$cb->();
	    },
	    set => sub {
		my($cb, $key, $flag, $expire, $value, $client) = @_;
		$data->{$client}{$key} = $value;
		$cb->(1);
	    },
	    get => sub {
		my($cb, $key, $client) = @_;
		if( exists $data->{$client}{$key} ) {
		    $cb->(1, $data->{$client}{$key});
		}
		else {
		    $cb->(0);
		}
	    },
	    _find => sub {
		my($cb, $key, $client) = @_;
		$cb->( exists $data->{$client}{$key} );
	    },
	    delete => sub {
		my($cb, $key, $client) = @_;
		if( exists $data->{$client}{$key} ) {
		    delete $data->{$client}{$key};
		    $cb->(1);
		}
		else {
		    $cb->(0);
		}
	    },
	    flush_all => sub {
		my($cb, $client) = @_;
		$data->{$client} = {};
		$cb->();
	    },
	},
    );
};
plan skip_all => 'Cannot bind address on 0:8888' if $@;
plan tests => 12;

my($memd1, $memd2);

{
    my $cv = AE::cv;

    $cv->begin;
    tcp_connect( 0, 8888, sub {
	my($fh) = @_;
	$memd1 = AnyEvent::Handle->new( fh => $fh, on_error => sub { undef $memd1 } );
	$cv->end;
    } );

    $cv->begin;
    tcp_connect( 0, 8888, sub {
	my($fh) = @_;
	$memd2 = AnyEvent::Handle->new( fh => $fh, on_error => sub { undef $memd2 } );
	$cv->end;
    } );

    $cv->recv;
}

{
    my $cv = AE::cv;

    $cv->begin;
    $memd1->push_read( line => sub {
	is($_[1], "STORED", "set data");
	$cv->end;
    } );
    $memd1->push_write("set CindyLinz 3 0 4\r\nGood\r\n");

    $cv->begin;
    $memd1->push_read( line => sub {
	is($_[1], "VALUE CindyLinz 3 4", "get data");
	$cv->end;
    } );
    $cv->begin;
    $memd1->push_read( line => sub {
	is($_[1], "Good", "get data");
	$cv->end;
    } );
    $cv->begin;
    $memd1->push_read( line => sub {
	is($_[1], "END", "get data");
	$cv->end;
    } );
    $memd1->push_write("get CindyLinz\r\n");
    $cv->recv;
}

{
    my $cv = AE::cv;

    $memd2->push_read( line => sub {
	is($_[1], "END", "get no data");
	$cv->send;
    } );
    $memd2->push_write("get CindyLinz\r\n");

    $cv->recv;
}

{
    my $cv = AE::cv;

    $cv->begin;
    $memd2->push_read( line => sub {
	is($_[1], "STORED", "set data");
	$cv->end;
    } );
    $memd2->push_write("set CindyLinz 3 0 9\r\nVery Good\r\n");

    $cv->begin;
    $memd2->push_read( line => sub {
	is($_[1], "VALUE CindyLinz 3 9", "get data");
	$cv->end;
    } );
    $cv->begin;
    $memd2->push_read( line => sub {
	is($_[1], "Very Good", "get data");
	$cv->end;
    } );
    $cv->begin;
    $memd2->push_read( line => sub {
	is($_[1], "END", "get data");
	$cv->end;
    } );
    $memd2->push_write("get CindyLinz\r\n");
    $cv->recv;
}

{
    my $cv = AE::cv;

    $cv->begin;
    $memd1->push_read( line => sub {
	is($_[1], "VALUE CindyLinz 3 4", "get data");
	$cv->end;
    } );
    $cv->begin;
    $memd1->push_read( line => sub {
	is($_[1], "Good", "get data");
	$cv->end;
    } );
    $cv->begin;
    $memd1->push_read( line => sub {
	is($_[1], "END", "get data");
	$cv->end;
    } );
    $memd1->push_write("get CindyLinz\r\n");
    $cv->recv;
}
