package Helios::Logger;

use 5.008;
use strict;
use warnings;

use Helios::Job;
use Helios::Error::LoggingError;
use Helios::ObjectDriver::DBI;

our $VERSION = '2.81';

=head1 NAME

Helios::Logger - Base class for sending Helios logging information to external loggers

=head1 SYNOPSIS

 # in your logging system shim class
 use strict;
 use warnings;
 use base qw(Helios::Logger);
 # optional, but probably useful
 use Helios::LogEntry::Levels qw(:all);
 use Helios::Error::LoggingError;
  
 sub init {
 	my $self = shift;

 	...initialization code for your logging system...
 }
 
 sub logMsg {
 	my $self = shift;
 	my $job = shift;
 	my $priority_level = shift;
 	my $log_message = shift;
 	...code to log the message to your logging system...
 }


=head1 DESCRIPTION

Helios::Logger is the base class to extend to provide interfaces to external 
logging systems for Helios services.  It provides a basic set of accessor 
methods to get and store information about the Helios environment, and defines 
interface methods for you to override in your class to actually implement the 
logging code. 

It should be noted that all methods are actually class methods, not instance 
(object) methods, because Helios::Logger subclasses are not instantiated.  If 
you need to implement other methods outside of the interface methods defined 
below, make sure you implement them as class methods.

=head1 ACCESSOR METHODS

Helios::Logger provides 4 set/get accessor pairs to provide access to 
information from the Helios collective environment:

 set/getConfig();   # config hashref from Helios::Service->getConfig()
 set/getJobType();  # job type/service name string from Helios::Service->getJobType()
 set/getHostname(); # host job is running on from Helios::Service->getHostname()
 set/getDriver();   # Data::ObjectDriver object connected to Helios collective 
                      database from Helios::Service->getDriver()
 
Normally, Helios::Service->logMsg() calls the set* methods before the init() 
method to properly initialize the logging class.  If these values can be 
adjusted in the init() method if necessary.

=cut

my $Config;
my $JobType;
my $Hostname;
my $Driver;
my $Debug;

sub debug { my $self = shift; @_ ? $Debug = shift : $Debug; }

sub setConfig {
	my $var = $_[0]."::Config";
	no strict 'refs';
	$$var = $_[1]; 
}
sub getConfig { 
    my $var = $_[0]."::Config";
    no strict 'refs';
    return $$var;	
}

sub setJobType {
    my $var = $_[0]."::JobType";
    no strict 'refs';
    $$var = $_[1]; 
}
sub getJobType { 
    my $var = $_[0]."::JobType";
    no strict 'refs';
    return $$var; 
}

# BEGIN CODE Copyright (C) 2014 by Logical Helion, LLC.
sub setService {
	setJobType(@_);
}
sub getService {
	getJobType(@_);
}
# END CODE Copyright (C) 2014 by Logical Helion, LLC.


sub setHostname {
    my $var = $_[0]."::Hostname";
    no strict 'refs';
    $$var = $_[1]; 
}
sub getHostname { 
    my $var = $_[0]."::Hostname";
    no strict 'refs';
    return $$var; 
}

sub setDriver { 
	my $var = $_[0]."::Driver";
	no strict 'refs';
	$$var = $_[1];
}
sub getDriver {
	return initDriver(@_);
}
sub initDriver {
	my $self = shift;
	my $config = $self->getConfig();
	if ($self->debug) { print $config->{dsn},$config->{user},$config->{password},"\n"; }
	my $driver = Helios::ObjectDriver::DBI->new(
	    dsn      => $config->{dsn},
	    username => $config->{user},
	    password => $config->{password}
	);	
	if ($self->debug) { print 'Logger->initDriver() DRIVER: ',$driver,"\n"; }
	$self->setDriver($driver);
	return $driver;	
}


=head1 INTERFACE METHODS

The following methods must be implemented by your Helios::Logger subclass for 
external logging to work.

=head2 init()

Class method to initialize the logging code for the external logging system.  
This will be run once when the service daemon starts.  You also can use init() 
to check for configuration errors or adjust configuration parameters 
(set/getConfig()).  If your logging system doesn't need any 
initialization, go ahead and declare an empty init() method in your class 
anyway. 

=cut

sub init {
	throw Helios::Error::LoggingError('init() not defined for '. __PACKAGE__);
}


=head2 logMsg($job, $priority_level, $message)

Class method to send the message to the external logging system for logging.  
The $job parameter is a Helios::Job object, while $priority_level is an integer 
corresponding to one of the symbols defined in Helios::LogEntry::Levels (which 
are the same as Sys::Syslog's).  The implementation of this method in your 
subclass should use the external logging system to log these values 
appropriately.  It should throw a Helios::Error::LoggingError if it encounters 
an error.   

NOTE: When Helios::Service->logMsg() calls this method, it is guaranteed to 
have three values, so when implementing this method in your subclass you don't 
have to worry about parameter parsing as much as the calling routine does.  
However, the values of $job and/or $priority_level may be undefined values, and 
your implementation of logMsg() will have to deal with that appropriately.  

=cut

sub logMsg {
	throw Helios::Error::LoggingError('logMsg() not defined for '. __PACKAGE__);
}


1;
__END__


=head1 SEE ALSO

L<Helios::Service>

=head1 AUTHOR

Andrew Johnson, E<lt>lajandy at cpan dotorgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2009-12 by Andrew Johnson

Portions of this software, where noted, are
Copyright (C) 2014 by Logical Helion, LLC.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.0 or,
at your option, any later version of Perl 5 you may have available.

=head1 WARRANTY

This software comes with no warranty of any kind.

=cut
