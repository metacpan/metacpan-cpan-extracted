# Copyright (C) 1998 Tuomas J. Lukka
# DISTRIBUTED WITH NO WARRANTY, EXPRESS OR IMPLIED.
# See the GNU Library General Public License (file COPYING in the distribution)
# for conditions of use and redistribution.

# The following is POD documentation for the VRML::Browser module
# It will be automatically installed in a manual page upon make install.
# See the perlpod manpage for the I<>, C<> &c explanation

=head1 NAME

VRML::Browser -- perl module to implement a VRML97 browser

=head1 SYNOPSIS

Use the command-line interface (L<freewrl>), or
inside Perl:

	use VRML::Browser;

	$b = VRML::Browser->new();

	$b->load_file($url);
	$b->load_file($url,$base_url);
	$b->load_string("Shape { geometry ....", $base_url);

	$b->eventloop();

	# VRML Browser API
	$name = 	$b->getName();
	$version = 	$b->getVersion();
	$speed =	$b->getCurrentSpeed();
	...

	# The rest of the API may still change and is not documented
	# here. If you need to know, check the file Browser.pm

=head1 DESCRIPTION

This module implements a VRML browser. The actual module
is of interest only if you are planning to use the code from Perl.

For information on the user interface, see L<VRML::Viewer>.

=head1 AUTHOR

See L<freewrl>.

=cut

require 'VRML/GLBackEnd.pm';
require 'VRML/Parser.pm';
require 'VRML/Scene.pm';
require 'VRML/Events.pm';
require 'VRML/Config.pm';
require 'VRML/URL.pm';

package VRML::Browser;
use strict vars;
use POSIX;

###############################################
#
# Public functions

sub new {
	my($type,$pars) = @_;
	my $this = bless {
		Verbose => delete $pars->{Verbose},
		BE => new VRML::GLBackEnd(@{$pars->{BackEnd} or []}),
		EV => new VRML::EventMachine(),
	}, $type;
	return $this;
}

sub clear_scene {
	my($this) = @_;
	delete $this->{Scene};
}

# Discards previous scene
sub load_file {
	my($this,$file,$url) = @_;
	$url = ($url || $file);
	$this->{URL} = $url ; 
	print "File: $file URL: $url\n" if $VRML::verbose::scene;
	my $t = VRML::URL::get_absolute($file);
	unless($t =~ /^#VRML V2.0/s) {
		if($t =~ /^#VRML V1.0/s) {
			die("Sorry, this file is according to VRML V1.0, I only know V2.0");
		}
		warn("WARNING: file '$file' doesn't start with the '#VRML V2.0' header line");
	}
	$this->load_string($t,$url);
}

sub load_string {
	my($this,$string,$file) = @_;
	$this->clear_scene();
	$this->{Scene} = VRML::Scene->new($this->{EV},$file);
	$this->{Scene}->set_browser($this);
	VRML::Parser::parse($this->{Scene},$string);
#	$this->{Scene}->make_executable();
#	$this->{Scene}->make_backend($this->{BE});
#	$this->{Scene}->setup_routing($this->{EV},$this->{BE});
#	$this->{EV}->print;
}

sub get_scene {
	my($this) = @_;
	$this->{Scene} or ($this->{Scene} = VRML::Scene->new(
		$this->{EV}, "USER"));
}
sub get_eventmodel { return $_[0]->{EV} }

sub get_backend { return $_[0]{BE} }

sub eventloop {
	my($this) = @_;
	$this->prepare();
	while(!$this->{BE}->quitpressed) {
		$this->tick();
	}
}

sub prepare {
	my($this) = @_;
	$this->{Scene}->make_executable();
	$this->{Scene}->make_backend($this->{BE});
	$this->{Scene}->setup_routing($this->{EV}, $this->{BE});
	$this->{Scene}->init_routing($this->{EV},$this->{BE});
	$this->{EV}->print;
}

sub tick {
	my($this) = @_;
	my $time = get_timestamp();
	$this->{BE}->update_scene($time);
	$this->{EV}->propagate_events($time,$this->{BE},
		$this->{Scene});
	for(@{$this->{Periodic}}) {
		&$_();
	}
}

my $FPS = 0;

# The routines below implement the browser object interface.

sub getName { return "FreeWRL by Tuomas J. Lukka" }
sub getVersion { return $VRML::Config{VERSION} } 
sub getCurrentSpeed { return 0.0 } # legal
sub getCurrentFrameRate { return $FPS }
sub getWorldURL { return $_[0]{URL} }
sub replaceWorld { die("Can't do replaceworld yet") }
sub loadURL { die("Can't do loadURL yet") }
sub setDescription { print "Set description: ",
	(join '',reverse split '',$_[1]),"\n" } # Read the spec: 4.12.10.8 ;)

# Warning: due to the lack of soft references, all unreferenced nodes
# leak horribly. Perl 5.005 (to be out soon) will probably
# provide soft references. If not, we are going to make a temporary
# solution. For now, we leak.
sub createVrmlFromString { 
	my ($this,$string) = @_;
	my $scene = VRML::Scene->new($this->{EV},"FROM A STRING, DUH");
	$scene->set_browser($this);
	VRML::Parser::parse($scene, $string);
	$scene->make_executable();
	$scene->setup_routing($this->{EV}, $this->{BE});
	return $scene->get_as_mfnode();
}


sub createVrmlFromURL { die "Can't do createvrmlfromurl yet" }


sub addRoute { die "No addroute yet" }
sub deleteRoute { die "No deleteroute yet" }

# EAI
sub api_beginUpdate { die "XXX" }
sub api_endUpdate { die "XXX" }
sub api_getNode { 
	$_[0]->{Scene}->getNode($_[1]);
}
sub api__sendEvent { 
	my($this,$node,$field,$val) = @_;
	$this->{EV}->send_event_to($node,$field,$val);
}
sub api__registerListener { 
	my($this, $node, $field, $sub) = @_;
	$this->{EV}->register_listener($node, $field, $sub);
}

sub api__getFieldInfo {
	my($this,$node,$field) = @_;
	my($k,$t) = ($node->{Type}{FieldKinds}{$field},$node->{Type}{FieldTypes}{$field});
	return($k,$t);
}

sub add_periodic { push @{$_[0]{Periodic}}, $_[1]; }

#########################################################3
#
# Private stuff

{
my $ind = 0; 
my $start = (POSIX::times())[0] / &POSIX::CLK_TCK;
my $add = time() - $start; $start += $add;
sub get_timestamp {
	my $ticks = (POSIX::times())[0] / &POSIX::CLK_TCK; # Get clock ticks
	$ticks += $add;
	print "TICK: $ticks\n"
		if $VRML::verbose;
	if(!$_[0]) {
		$ind++;;
		if($ind == 25) {
			$ind = 0;
			$FPS = 25/($ticks-$start);
			print "Fps: ",$FPS,"\n";
			pmeasures();
			$start = $ticks;
		}
	}
	return $ticks;
}

{
my %h; my $cur; my $curt;
sub tmeasure_single {
	my($name) = @_;
	my $t = get_timestamp(1);
	if(defined $cur) {
		$h{$cur} += $t - $curt;
	}
	$cur = $name;
	$curt = $t;
}
sub pmeasures {
	return;
	my $s = 0;
	for(values %h) {$s += $_}
	print "TIMES NOW:\n";
	for(sort keys %h) {printf "$_\t%3.3f\n",$h{$_}/$s}
}
}
}


# No other nice place to put this so it's here...
# For explanation, see the file ARCHITECTURE
package VRML::Handles;

{
my %S = ();

sub reserve {
	my($object) = @_;
	my $str = "$object";
	if(!defined $S{$str}) {
		$S{$str} = [$object, 0];
	}
	$S{$str}[1] ++;
	return $str;
}

sub release {
	my($object) = @_;
	if(--$S{"$object"}[1] <= 0) {
		delete $S{"$object"};
	}
}

sub get {
	my($handle) = @_;
	return NULL if $handle eq "NULL";
	if(!exists $S{$handle}) {
		die("Nonexistent VRML Node Handle!");
	}
	return $S{$handle}[0];
}
}


1;
