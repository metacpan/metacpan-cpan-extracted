package Devel::DebugHooks::Server;

use strict;
use warnings;

# We should define utility subs first...
## IO::Async stuff
# global DATA
my $loop;
my $stream;



my $ti =  0;
sub tinfo {
	return " - $$ ($loop) w:" .uwsgi::worker_id();
}


# event handlers
sub handle_write_eof {
	die "Write error: >>@_<<";
}


sub handle_write_error {
	die "Write error: >>@_<<";
}


# TODO: Need to check. Because of eof does not seen until write the event is not
# occour until write handle is closed
sub handle_closed {
	$DB::OUT =  \*STDOUT;
	undef $stream;
	my $time =  localtime();
	`echo "$time Session closed\n" >> /home/feelsafe/loop`;
	warn "$time Session closed";
}


sub read_command {
	my( $self, $buffref, $eof ) =  @_;

	warn 'New Command: ' .$$buffref;


	if( $$buffref =~ s/^(.*?)\r?(\n)// ) {
		warn "\nThis is the thread (RC): " .tinfo() ."\n\n"   if $ti;

		$$buffref = "$1$2$$buffref"   unless defined &readline( "$1$2" );

		return 0;
	}

	warn "Text '$$buffref' is left in buffer"   if $$buffref;

	if( $eof ) {
		warn "TTYIN EOF";
		$self->close_when_empty();
	}

	return 0;
}


sub start_dbg_session {
	if( defined $stream ) {
		$_[0]->write( "Debugging session is attached already\n" );
		$_[0]->close_when_empty();
		return;
	}


	warn "New client connected";
	( $stream ) =  @_;

	$stream->configure(
		close_on_read_eof =>  0
		,on_read          =>  \&read_command
		,on_write_eof     =>  \&handle_write_eof
		,on_write_error   =>  \&handle_write_error
		,on_closed        =>  \&handle_closed
		,autoflush        =>  1
		,write_all        =>  1
	);

	$loop->add( $stream );
	$DB::OUT =  $stream->read_handle();

	if( $ti ) {
		my $str =  "This is the thread (Start): " .tinfo() ."\n";
		$stream->write( $str );
		warn $str;
	}
}


sub listen {
	my( $loop ) =  @_;

	$loop->listen(
		# family =>  'unix',
		# path   =>  'file.sock',
		family   =>  'inet',
		socktype =>  'stream',
		host     =>  '127.0.0.1',
		service  =>  9000,
		on_resolve_error =>  sub { die "Cannot resolve - $_[1] <<< @_\n"; },
		on_listen_error  =>  sub { die "Cannot listen  - $_[1] <<< @_\n"; },
		on_listen        =>  sub {
			my( $s ) =  @_;

			warn "listening on: " .$s->sockhost . ':' .$s->sockport;
			warn "\nThis is the thread(Listen): " .tinfo()   if $ti;
		},

		# This sub is invoked for each new incoming connection
		on_stream =>  \&start_dbg_session,
	);
}





# Setup and process $loop
# We can uncoment this if we want debugger messages were sent to dbg client
# BEGIN {
# 	use IO::Async::Loop;
# 	$loop =  IO::Async::Loop->new;
# 	# As soon as possible
# 	# But, it is better that only worker listens to :9000
# 	# And because of BEGIN block the IO::Async modules are noticed by debugger
# 	&listen( $loop );
# 	sleep 2; # wait dbg client to connect
# 	$loop->loop_once( 0 );
# }
use IO::Async::Loop;
$loop =  IO::Async::Loop->new;


sub uwsgi_signal_handler {
	# warn time() ." Singal" .tinfo() ."\n"   if $ti;
	warn 'Signal arrive';

	# First of all we should process loop queue: connect client, read data...
	$loop->loop_once( 0 );

	# ...now we can do something with that
	DB::interact( 1 );
	warn 'Signal processed';
}



# uwsgi::postfork( sub{
# 	print $DB::OUT time() ." Forked\n";
# 	$DB::commands->{ load }->();
# 	&listen( $loop );
# 	$loop->loop_once( 0 );
# 	# Useless. Signals are sended to worker only after it is forked
# 	# uwsgi::signal( 1 );
# 	# NOTE: if I 'die' here I get assertion
# 	# uwsgi: perl.c:539: perl_destruct: Assertion `(my_perl->Iscopestack_ix) == 1' failed.
# });


# uwsgi::register_signal( 1, 'workers', \&uwsgi_signal_handler );
# uwsgi::add_timer( 1, 1 );



my $dbg_buffer;
sub readline {
	# set
	if( @_ ) {
		return   if defined $dbg_buffer;

		return( $dbg_buffer =  shift )
	}


	# get
	while( !defined $dbg_buffer ) {
		if( $stream ) {
			$stream->invoke_event( 'on_read', \$stream->{ readbuff } );
			last   if defined $dbg_buffer;
		}

		$loop->loop_once();
	}


	my $result =  $dbg_buffer;
	undef $dbg_buffer;
	return $result;
}
# END OF IO::Async stuff



sub bbreak {
	my $self =  shift;

	Devel::DebugHooks::Commands->process( 'l .' );
}


# ... define another utilities that can be called at CT
my $last_input =  's';
sub get_command {
	my $self =  shift;

	my $line =  &readline();
	chomp $line;
	if( $line ne '' ) {
		$last_input =  $line;
	}
	else {
		$line =  $last_input;
	}

	return $line;
}


# ... now we can use DebugHooks
our @ISA;

BEGIN {
	$DB::options{ trace_load }  //=  1;
	$DB::options{ trace_subs }  //=  0;
	$DB::options{ trace_returns }  //=  0;
	$DB::options{ _debug }      //=  0;
	$DB::options{ dbg_frames }  //=  0;
	$DB::options{ NonStop    }  //=  0;
	@DB::options{ qw/ w s / } = ( 1, 1 );
	push @ISA, 'Devel::DebugHooks';
}



sub import {
	my $class =  shift;

	$class->SUPER::import( @_ );
}


use Devel::DebugHooks();

#TODO: Think about this syntax:
# $handler =  DB::reg( 'interact', 'Server', $sub, $context, @other args );
# Here we may pass or silent $context. All will depends on our need
my $handler =  DB::reg( 'interact', 'Server' );
$$handler->{ context } =  $DB::dbg;
##FIX: We may pass context as first argument
# $$handler->{ args } =  [ $DB::dbg ]
$$handler->{ code } =  \&Devel::DebugHooks::Commands::interact;

#FIX: Decide where to complete subscribtion: from &import of from RT of module
$handler =  DB::reg( 'bbreak', 'Server' );
$$handler->{ context } =  $DB::dbg;
$$handler->{ code }    =  \&bbreak;


&listen( $loop );
$loop->loop_once( 0 );

1;
