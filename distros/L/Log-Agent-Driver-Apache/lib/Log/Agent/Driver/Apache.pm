package Log::Agent::Driver::Apache;
use 5.008006;
use strict;
use warnings;
use Apache2::Log;
use Apache2::ServerUtil;
use Log::Agent::Driver;

our(@ISA) = qw(Log::Agent::Driver);
our($VERSION) = 0.002;
use vars qw(%PRI_MAP);

#
# %PRI_MAP is a mapping of priorities to underlying Apache2::Log->log()->$method
#
#  priority => method. Others, not listed, are info and debug.
%PRI_MAP = (
	emergency => 'emerg',
	alert => 'alert',
	critical => 'crit',
	error => 'error',
	warning => 'warn',
	notice => 'notice'
);

# this is the constructor. 
sub make {
	my($this) = shift;
	my(%opt) = @_;
	$this = ref($this) || $this;
	my($self) = bless({},$this);
	$self->{'_apache_log'} = $opt{'-log'} || _default_log();
	return($self);
}

# By default, we use server log.
sub _default_log {
	my $s = Apache2::ServerUtil->server();
	return($s->log);
}
sub channel_eq {
	my($self,$ch1,$ch2) = (shift,shift,shift);
	return(1);
}

sub write {
	my($self,$channel,$priority,$logstring) = @_;
	my($l) = $self->{_apache_log} || 0;
	# Attempt to log something without logging anything?
	$logstring ||= join(",",caller()) . " (something was logged)";
	if(! $l){
		# Since the message may have something to do 
		# with Apache::Log itself, or, misconfiguration
		# or the other things that can go wrong.. we issue
		# a warn here.
		warn "(log config. prob) $priority $logstring";
		return;
	}
	if($channel eq 'debug'){
		$l->debug($logstring);
		return();
	}
	$priority ||= 0;
	my($meth);
	if($l->can($priority)){
		$meth = $priority;
	}else{
		$meth = 'info'; # A reasonable default?
	}
	eval {
		$l->$meth($logstring);
	};
	if($@){
		warn "$@ $logstring"; # Couldn't log for some reason?
	}
	return();
}
# Map priorities to methods.
sub map_pri {
    my ($self,$priority, $level) = (shift,shift,shift);
	my($l) = $self->{_apache_log} || 0;
	if($l){
		if($l->can($priority)){
			return($priority);
		}
	}
	return($PRI_MAP{$priority});
}

sub prefix_msg {
	shift; # self,
	return(shift()); # Whatever the message is.
}

1;
__END__

=head1 NAME

Log::Agent::Driver::Apache - Use mod_perl with standard logger.

=head1 SYNOPSIS

	use Log::Agent;
	use Log::Agent::Driver::Apache;
  	
	.. 

	# Make the driver.
	my $driver = Log::Agent::Driver::Apache->make();
	# Tell Log::Agent to use it.
	logconfig(-driver => $driver);
	
	# later on, in the vastness name-space, far far away..
	logerr("Use the source, Luke");

=head1 DESCRIPTION

A L<Log::Agent::Driver> module for Apache.

Since L<Log::Agent> is the standard way for modules to log output,
or rather it's supposed to be, but Apache with mod_perl has different
ideas about logging, this module attempts to translate Log::Agent
calls over to Apache::Log.

Part of a bigger project to port some older mod_perl stuff to the newer
mod_perl 2.0, I thought CPAN might have a use for this.

One of the advantages of this style is that you can use a different driver
for Log::Agent for out-of-apache testing, use this driver while running
under mod_perl. Any modules you may have that are not tied to mod_perl can
continue to run in both environments. Later on, if your mod_perl application
grows or you feel some need to switch to a syslog style logger, just 
use one of the other Log::Agent drivers.

=head2 EXPORT

None, this is a driver for Log::Agent.

=head2 METHODS

=over 4

=item make(%options)

This is the constructor for this driver, using the Log::Agent convention
of prefixing option keys with a dash.

Options are

=over 4

=item -log

An L<Apache2::Log::Request> or L<Apache2::Log::Server> object. This is
optional and defaults to an L<Apache2::Log::Server> object. I wouldn't
set this to an Apache2::Log::Request if I were you, unless you were prepared
to configure it on each request.

Note that the default is the main server, not a virtual host.

=back


=item channel_eq()

Always returns true. (Even if apache is configured in ways that
involve multiple files/logs)

Log::Agent::Driver requires this method.

=item write($channel,$priority,$logstring)

This is the required Log::Agent::Driver->write() method, after the priority
has been mapped, it calls on a method of Apache::Log::Server.

=back


=head1 SEE ALSO

L<Log::Agent> L<Log::Agent::Driver> mod_perl L<Apache2::Log>

h2xs suggested I have a web site for modules. Here is one:
L<http://www.geniegate.com/other/log_agent/>.

=head1 AUTHOR

Jamie Hoglund http://www.geniegate.com/contact.php

Cough, it sounds like "hoaglund" :-)

(I won't use my email address for fear of overworking my poor
old machine running spam assassin. Sorry!)

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2005 by Jamie Hoglund

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.6 or,
at your option, any later version of Perl 5 you may have available.
(Actually, it'll probably work with earlier versions too.)

=head1 BUGS

I'm not real happy with the way it defaults to using an
Apache::Log::Server object for logging. Using an Apache::Log::Request
would mean reconfiguring the driver in each handler instance (Which 
would make it inconvenient to use.)

There are probably other bugs waiting to be uncovered. 

=cut
