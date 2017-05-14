# $Id: Debug.pm,v 1.1 2001/08/18 16:37:09 joern Exp $

package JaM::Debug;

use strict;
use Data::Dumper;

#---------------------------------------------------------------------
# Debugging stuff
# 
# Setzen/Abfragen des Debugging Levels. Wenn als Klassenmethode
# aufgerufen, wird das Debugging klassenweit eingeschaltet. Als
# Objektmethode aufgerufen, wird Debugging nur für das entsprechende
# Objekt eingeschaltet.
#
# Level:	0	Debugging deaktiviert
#		1	nur aktive Debugging Ausgaben
#		2	Call Trace, Subroutinen Namen
#		3	Call Trace, Subroutinen Namen + Argumente
#
# Debuggingausgaben erfolgen im Klartext auf STDERR.
#---------------------------------------------------------------------

sub debug_level {
	my $thing = shift;
	my $debug;
	if ( ref $thing ) {
		$thing->{debug} = shift if @_;
		$debug = $thing->{debug};
	} else {
		$JaM::DEBUG = shift if @_;
		$debug = $JaM::DEBUG;
	}
	
	if ( $debug ) {
		$JaM::DEBUG::TIME = scalar(localtime(time));
		print STDERR
			"--- START ------------------------------------\n",
			"$$: $JaM::DEBUG::TIME - DEBUG LEVEL $debug\n";
	}
	
	return $debug;
}

#---------------------------------------------------------------------
# Klassen/Objekt Methode
# 
# Gibt je nach Debugginglevel entsprechende Call Trace Informationen
# aus bzw. tut gar nichts, wenn Debugging abgeschaltet ist.
#---------------------------------------------------------------------

sub trace_in {
	my $thing = shift;
	my $debug = $JaM::DEBUG;
	$debug = $thing->{debug} if ref $thing and $thing->{debug};
	return if $debug < 2;

	# Level 1: Methodenaufrufe
	if ( $debug == 2 ) {
		my @c1 = caller (1);
		my @c2 = caller (2);
		print STDERR "$$: TRACE IN : $c1[3] (-> $c2[3])\n";
	}
	
	# Level 2: Methodenaufrufe mit Parametern
	if ( $debug == 3 ) {
		package DB;
		my @c = caller (1);
		my $args = '"'.(join('","',@DB::args)).'"';
		my @c2 = caller (2);
		print STDERR "$$: TRACE IN : $c[3] (-> $c2[3])\n\t($args)\n";
	}
	
	1;
}

sub trace_out {
	my $thing = shift;
	my $debug = $JaM::DEBUG;
	$debug = $thing->{debug} if ref $thing and $thing->{debug};
	return if $debug < 2;

	my @c1 = caller (1);
	my @c2 = caller (2);
	print STDERR "$$: TRACE OUT: $c1[3] (-> $c2[3])";

	if ( $debug == 2 ) {
		print STDERR " DATA: ", Dumper(@_);
	} else {
		print STDERR "\n";
	}
	
	1;
}

sub dump {
	my $thing = shift;
	my $debug = $JaM::DEBUG;
	$debug = $thing->{debug} if ref $thing and $thing->{debug};
	return if not $debug;	

	if ( @_ ) {
		print STDERR Dumper(@_);
	} else {
		print STDERR Dumper($thing);
	}
}

sub debug {
	my $thing = shift;
	my $debug = $JaM::DEBUG;
	$debug = $thing->{debug} if ref $thing and $thing->{debug};
	return if not $debug;	

	my @c1 = caller (1);
	print STDERR "$$: DEBUG    : $c1[3]: ", join (",", @_), "\n";
	1;
}

1;
