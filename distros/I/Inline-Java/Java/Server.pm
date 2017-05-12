package Inline::Java::Server ;
@Inline::Java::Server::ISA = qw(Exporter) ;

# Export the cast function if wanted
@EXPORT_OK = qw(start stop status) ;


use strict ;
use Exporter ;
use Carp ;
require Inline ;
require Inline::Java ;
use File::Spec ;


$Inline::Java::Server::VERSION = '0.53' ;


# Create a dummy Inline::Java object in order to 
# get the default options.
my $IJ = bless({}, "Inline::Java") ;
$IJ->validate(
	SHARED_JVM => 1
) ;



sub import {
	my $class = shift ;
	my $a = shift ;

	my @actions = () ;
	if ($a eq 'restart'){
		push @actions, 'stop', 'sleep', 'start' ;
	}
	else{
		push @actions, $a ;
	}

	my $host = $IJ->get_java_config("HOST") ;
	my $bind = $IJ->get_java_config("BIND") ;
	my $port = $IJ->get_java_config("PORT") ;
	foreach $a (@actions){
		if ($a eq 'sleep'){
			sleep(5) ;
			next ;
		}

		my $status = Inline::Java::Server::status() ;

		if ($a eq 'start'){
			if ($status){
				print "SHARED_JVM server on port $bind:$port is already running\n" ;
			}
			else{
				Inline::Java::Server::start() ;
				my $pid = Inline::Java::__get_JVM()->{pid} ;
				print "SHARED_JVM server on port $bind:$port started with pid $pid\n" ;
			}
		}
		elsif ($a eq 'stop'){
			if (! $status){
				print "SHARED_JVM server on port $host:$port is not running\n" ;
			}
			else {
				Inline::Java::Server::stop() ;
				print "SHARED_JVM server on port $host:$port stopped\n" ;
			}
		}
		elsif ($a eq 'status'){
			if ($status){
				print "SHARED_JVM on port $host:$port is running\n" ;
			}
			else {
				print "SHARED_JVM on port $host:$port is not running\n" ;
			}
		}
		else{
			croak("Usage: perl -MInline::Java::Server=(start|stop|restart|status)\n") ;
		}
	}

	exit() ;
}



sub status {
	my $socket = undef ;

	eval {
	    $socket = Inline::Java::JVM::setup_socket(
			$IJ->get_java_config("HOST"),
			$IJ->get_java_config("PORT"),
			0,
			1
	    ) ;
	} ;
	if ($@){
		return 0 ;
	}
	else {
		close($socket) ;
		return 1 ;
	}
}


sub start {
	my $dir = $ENV{PERL_INLINE_JAVA_DIRECTORY} ;

	Inline->bind(
		Java => 'STUDY',
		SHARED_JVM => 1,
		($dir ? (DIRECTORY => $dir) : ()),
	) ;
}


sub stop {
	# This will connect us to the running JVM
	Inline::Java::Server::start() ; 
	Inline::Java::capture_JVM() ; 
	Inline::Java::shutdown_JVM() ; 
}



1 ;

