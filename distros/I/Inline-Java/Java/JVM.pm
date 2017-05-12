package Inline::Java::JVM ;


use strict ;
use Carp ;
use IO::File ;
use IPC::Open3 ;
use IO::Socket ;
use Text::ParseWords ;
use Inline::Java::Portable ;

$Inline::Java::JVM::VERSION = '0.53' ;

my %SIGS = () ;

my @SIG_LIST = ('HUP', 'INT', 'PIPE', 'TERM') ;

sub new {
	my $class = shift ;
	my $o = shift ;

	my $this = {} ;
	bless($this, $class) ;

	foreach my $sig (@SIG_LIST){
		local $SIG{__WARN__} = sub {} ;
		if (exists($SIG{$sig})){
			$SIGS{$sig} = $SIG{$sig} ;
		}
	}

	$this->{socket} = undef ;
	$this->{JNI} = undef ;
	$this->{embedded} = $o->get_java_config('EMBEDDED_JNI') ;
	$this->{owner} = 1 ;
	$this->{destroyed} = 0 ;
	$this->{private} = $o->get_java_config('PRIVATE') ;
	$this->{debugger} = $o->get_java_config('DEBUGGER') ;

	if ($this->{embedded}){
		Inline::Java::debug(1, "using embedded JVM...") ;
	}
	else{
		Inline::Java::debug(1, "starting JVM...") ;
	}

	my $args = $o->get_java_config('EXTRA_JAVA_ARGS') ;
	if ($o->get_java_config('JNI')){
		Inline::Java::debug(1, "JNI mode") ;

		# Split args and remove quotes
		my @args = map {s/(['"])(.*)\1/$2/ ; $_}
			parse_line('\s+', 1, $args) ;
		my $jni = new Inline::Java::JNI(
			$ENV{CLASSPATH} || '',
			\@args,
			$this->{embedded},
			Inline::Java::get_DEBUG(),
			$o->get_java_config('NATIVE_DOUBLES'),
		) ;
		$jni->create_ijs() ;

		$this->{JNI} = $jni ;
	}
	else {
		Inline::Java::debug(1, "client/server mode") ;

		my $debug = Inline::Java::get_DEBUG() ;

		$this->{shared} = $o->get_java_config('SHARED_JVM') ;
		$this->{start_jvm} = $o->get_java_config('START_JVM') ;
		$this->{port} = $o->get_java_config('PORT') ;
		$this->{host} = $o->get_java_config('HOST') ;

		# Used to limit the bind of the JVM server
		$this->{'bind'} = $o->get_java_config('BIND') ;

		# Grab the next free port number and release it.
		if ((! $this->{shared})&&($this->{port} < 0)){
			if (Inline::Java::Portable::portable("GOT_NEXT_FREE_PORT")){
				my $sock = IO::Socket::INET->new(
					Listen => 0, Proto => 'tcp',
					LocalAddr => 'localhost', LocalPort => 0) ;
				if ($sock){
					$this->{port} = $sock->sockport() ;
					Inline::Java::debug(2, "next available port number is $this->{port}") ;
					close($sock) ;
				}
				else{
					# Revert to the default.
					$this->{port} = - $this->{port} ;
					carp(
						"Could not get next available port number, using port " .
						"$this->{port} instead. Use the PORT configuration " .
						"option to suppress this warning.\n Error: $!\n") ;
				}
			}
			else{
				# Revert to the default.
				# Try this maybe: 9000 + $$ ?
				$this->{port} = - $this->{port} ;
			}
		}

		# Check if JVM is already running
		if ($this->{shared}){
			eval {
				$this->reconnect() ;
			} ;
			if (! $@){
				Inline::Java::debug(1, "connected to already running JVM!") ;
				return $this ;
			}

			if (! $this->{start_jvm}){
				croak("Can't find running JVM and START_JVM = 0") ;
			}
		}

		my $java = File::Spec->catfile($o->get_java_config('J2SDK'), 
			Inline::Java::Portable::portable("J2SDK_BIN"),
			($this->{debugger} ? "jdb" : "java") . 
			Inline::Java::Portable::portable("EXE_EXTENSION")) ;

		my $shared = ($this->{shared} ? "true" : "false") ;
		my $priv = ($this->{private} ? "true" : "false") ;
		my $native_doubles = ($o->get_java_config('NATIVE_DOUBLES') ? "true" : "false") ;
		my $cmd = Inline::Java::Portable::portable("SUB_FIX_CMD_QUOTES", "\"$java\" $args org.perl.inline.java.InlineJavaServer $debug $this->{bind} $this->{port} $shared $priv $native_doubles") ;
		Inline::Java::debug(2, $cmd) ;
		if ($o->get_config('UNTAINT')){
			($cmd) = $cmd =~ /(.*)/ ;
		}

		my $pid = 0 ;
		eval {
			$pid = $this->launch($o, $cmd) ;
		} ;
		croak "Can't exec JVM: $@" if $@ ;

		if ($this->{shared}){
			# As of 0.40, we release by default.
			$this->release() ;
		}
		else{
			$this->capture() ;
		}

		$this->{pid} = $pid ;
		$this->{socket}	= setup_socket(
			$this->{host}, 
			$this->{port}, 
			# Give the user an extra hour's time set breakpoints and the like...
			($this->{debugger} ? 3600 : 0) + int($o->get_java_config('STARTUP_DELAY')),
			0
		) ;
	}

	return $this ;
}


sub launch {
	my $this = shift ;
	my $o = shift ;
	my $cmd = shift ;

	local $SIG{__WARN__} = sub {} ;

	my $dn = Inline::Java::Portable::portable("DEV_NULL") ;
	my $in = ($this->{debugger} ? ">&STDIN" : new IO::File("<$dn")) ;
	if (! defined($in)){
		croak "Can't open $dn for reading" ;
	}

	my $out = ">&STDOUT" ;
	if ($this->{shared}){
		$out = new IO::File(">$dn") ;
		if (! defined($out)){
			croak "Can't open $dn for writing" ;
		}
	}

	my $err = ">&STDERR" ;

	my $pid = open3($in, $out, $err, $cmd) ;

	if (! $this->{debugger}){
		close($in) ;
	}
	if ($this->{shared}){
		close($out) ;
	}

	return $pid ;
}


sub DESTROY {
	my $this = shift ;

	$this->shutdown() ;	
}


sub shutdown {
	my $this = shift ;

	if ($this->{embedded}){
		Inline::Java::debug(1, "embedded JVM, skipping shutdown.") ;
		return ;
	}

	if (! $this->{destroyed}){
		if ($this->am_owner()){
			Inline::Java::debug(1, "JVM owner exiting...") ;

			if ($this->{socket}){
				# This asks the Java server to stop and die.
				my $sock = $this->{socket} ;
				if ($sock->peername()){
					Inline::Java::debug(1, "Sending 'die' message to JVM...") ;
					print $sock "die\n" ;
				}
				else{
					carp "Lost connection with Java virtual machine" ;
				}
				close($sock) ;
		
				if ($this->{pid}){
					# Here we go ahead and send the signals anyway to be very 
					# sure it's dead...
					# Always be polite first, and then insist.
					if (Inline::Java::Portable::portable('GOT_SAFE_SIGNALS')){
						Inline::Java::debug(1, "Sending 15 signal to JVM...") ;
						kill(15, $this->{pid}) ;
						Inline::Java::debug(1, "Sending 9 signal to JVM...") ;
						kill(9, $this->{pid}) ;
					}
		
					# Reap the child...
					waitpid($this->{pid}, 0) ;
				}
			}
			if ($this->{JNI}){
				$this->{JNI}->shutdown() ;
			}
		}
		else{
			# We are not the JVM owner, so we simply politely disconnect
			if ($this->{socket}){
				Inline::Java::debug(1, "JVM non-owner exiting...") ;
				close($this->{socket}) ;
				$this->{socket} = undef ;
			}

			# This should never happen in JNI mode
		}

        $this->{destroyed} = 1 ;
	}
}


# This cannot be a member function because it can be used
# elsewhere to connect to the JVM.
sub setup_socket {
	my $host = shift ;
	my $port = shift ;
	my $timeout = shift ;
	my $one_shot = shift ;

	my $socket = undef ;

	my $last_words = "timeout\n" ;
	my $got_alarm = Inline::Java::Portable::portable("GOT_ALARM") ;

	eval {
		local $SIG{ALRM} = sub { die($last_words) ; } ;

		if ($got_alarm){
			alarm($timeout) ;
		}

		# ignore expected "connection refused" warnings
		# Thanks binkley!
		local $SIG{__WARN__} = sub { 
			warn($@) unless ($@ =~ /Connection refused/i) ; 
		} ;

		while (1){
			$socket = new IO::Socket::INET(
				PeerAddr => $host,
				PeerPort => $port,
				Proto => 'tcp') ;
			if (($socket)||($one_shot)){
				last ;
			}
			select(undef, undef, undef, 0.1) ;
		}

		if ($got_alarm){
			alarm(0) ;
		}
	} ;
	if ($@){
		if ($@ eq $last_words){
			croak "JVM taking more than $timeout seconds to start, or died before Perl could connect. Increase config STARTUP_DELAY if necessary." ;
		}
		else{
			if ($got_alarm){
				alarm(0) ;
			}
			croak $@ ;
		}
	}

	if (! $socket){
		croak "Can't connect to JVM at ($host:$port): $!" ;
	}

	$socket->autoflush(1) ;
	
	return $socket ;
}


sub reconnect {
	my $this = shift ;

	if (($this->{JNI})||(! $this->{shared})){
		return ;
	}

	if ($this->{socket}){
		# Close the previous socket
		close($this->{socket}) ;
		$this->{socket} = undef ;
	}

	my $socket = setup_socket(
		$this->{host}, 
		$this->{port}, 
		0,
		1
	) ;
	$this->{socket} = $socket ;

	# Now that we have reconnected, we release the JVM
	$this->release() ;
}


sub capture {
	my $this = shift ;

	if (($this->{JNI})||(! $this->{shared})){
		return ;
	}

	foreach my $sig (@SIG_LIST){
		if (exists($SIG{$sig})){
			$SIG{$sig} = \&Inline::Java::done ;
		}
	}

	$this->{owner} = 1 ;
}


sub am_owner {
	my $this = shift ;

	return $this->{owner} ;
}


sub release {
	my $this = shift ;

	if (($this->{JNI})||(! $this->{shared})){
		return ;
	}

	foreach my $sig (@SIG_LIST){
		local $SIG{__WARN__} = sub {} ;
		if (exists($SIG{$sig})){
			$SIG{$sig} = $SIGS{$sig} ;
		}
	}

	$this->{owner} = 0 ;
}


sub process_command {
	my $this = shift ;
	my $inline = shift ;
	my $data = shift ;

	my $resp = undef ;

	# Patch by Simon Cozens for perl -wle 'use Our::Module; do_stuff()'
	local $/ = "\n" ;
	local $\ = "" ;
	# End Patch

	while (1){
		Inline::Java::debug(3, "packet sent is $data") ;

		if ($this->{socket}){

			my $sock = $this->{socket} ;
			print $sock $data . "\n" or
				croak "Can't send packet to JVM: $!" ;

			$resp = <$sock> ;
			if (! $resp){
				croak "Can't receive packet from JVM: $!" ;
			}

			# Release the reference since the object has been sent back
			# to Java.
			$Inline::Java::Callback::OBJECT_HOOK = undef ;
		}
		if ($this->{JNI}){
			$Inline::Java::JNI::INLINE_HOOK = $inline ;
			$resp = $this->{JNI}->process_command($data) ;
		}
		chomp($resp) ;

		Inline::Java::debug(3, "packet recv is $resp") ;

		# We got an answer from the server. Is it a callback?
		if ($resp =~ /^callback/o){
			($data, $Inline::Java::Callback::OBJECT_HOOK) = Inline::Java::Callback::InterceptCallback($inline, $resp) ;
			next ;
		}
		else{
			last ;
		}
	}

	return $resp ;
}



1 ;

