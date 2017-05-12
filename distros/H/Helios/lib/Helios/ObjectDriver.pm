package Helios::ObjectDriver;

use 5.008;
use strict;
use warnings;

use Helios::Config;
use Helios::ObjectDriver::DBI;
use Helios::Error;
use Helios::Error::ObjectDriverError;

our $VERSION = '2.80';

=head1 NAME

Helios::ObjectDriver - class to return Helios::ObjectDriver::DBI objects pointing to the collective database

=head1 SYNOPSIS

 # in code that needs a Helios::ObjectDriver::DBI object
 my $driver = Helios::ObjectDriver->getDriver();
 
 # if the config parameters have already been parsed,
 # save the trouble of reparsing them by passing the configuration
 my $conf = Helios::Config->parseConfig(service_name => 'MyService');
 my $driver = Helios::ObjectDriver->getDriver(config => $conf);

=head1 DESCRIPTION

The Helios::ObjectDriver class provides methods to create 
Helios::ObjectDriver::DBI driver objects that connect to the Helios collective 
database.  Having this code in a central class reduces the amount of duplicated
code in various other Helios classes and provides a level of abstraction 
between the Helios API classes and Data::ObjectDriver, the current ORM.

Like Helios::Config and Helios::Logger classes, Helios::ObjectDriver is not 
designed to be instantiated and thus provides only class methods.

=head1 ACCESSOR METHODS

 debug
 set/getConfig
 set/getDriver

=cut

my $Debug = 0;
sub debug  { my $self = shift; @_ ? $Debug = shift : $Debug;   }

my $Config;
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

my $Driver;
sub setDriver {
	my $var = $_[0]."::Driver";
	no strict 'refs';
	$$var = $_[1]; 
}

sub getDriver { 
	initDriver(@_);
}


=head2 initDriver([config => $config_hashref])

The initDriver() method is the method that actually instantiates the driver 
object connecting to the database.

If a config is specified, Helios::ObjectDriver will use the parameters in the 
config hash to connect to the database and instantiate the driver object.  If 
config is not specified, initDriver() will call Helios::Config->parseConfig() 
to (re)parse the current Helios configuration itself.  If the Helios config has 
been parsed already, specifying it in the initDriver() call will save some 
time.

THROWS:  Helios::Error::ObjectDriverError if the driver creation fails.

=cut

sub initDriver {
	my $self = shift;
	my %params = @_;
	my $conf;
	my $driver;
	
	# handle config
	$conf = $params{config} || $self->getConfig() || Helios::Config->parseConfig();
	$self->setConfig($conf);

	if ($self->debug) { print __PACKAGE__.'->initDriver('.$conf->{dsn}.','.$conf->{user}.")\n"; }

	eval {
		$driver = Helios::ObjectDriver::DBI->new(
		    dsn      => $conf->{dsn},
	    	username => $conf->{user},
		    password => $conf->{password}
		);	
		if ($self->debug) { print __PACKAGE__.'->initDriver() DRIVER: ',$driver,"\n"; }
		1;
	} or do {
		my $E = $@;
		Helios::Error::ObjectDriverError->throw("$E");
	};
	
	$self->setDriver($driver);
	return $driver;	
}



1;
__END__


=head1 SEE ALSO

L<Helios::ObjectDriver::DBI>

=head1 AUTHOR

Andrew Johnson, E<lt>lajandy at cpan dot orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2013 by Logical Helion, LLC.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.0 or,
at your option, any later version of Perl 5 you may have available.

=head1 WARRANTY

This software comes with no warranty of any kind.

=cut
