package Helios::Config;

use 5.008;
use strict;
use warnings;
use File::Spec;
use Sys::Hostname;

use Config::IniFiles;  	

use Helios::ObjectDriver::DBI;
use Helios::ConfigParam;
use Helios::Error::ConfigError;

our $VERSION = '2.82';

=head1 NAME

Helios::Config - base class for Helios configuration system

=head1 SYNOPSIS

 # to determine a service's config based on
 # a particular conf file and host
 use Helios::Config;
 Helios::Config->init(
     conf_file => '/path/to/helios.ini',
     hostname  => 'host',
     service   => 'ServiceName'
 );
 my $config = Helios::Config->parseConfig();
 
 # if $HELIOS_INI env var is set and current host is used
 use Helios::Config;
 Helios::Config->init(service => 'ServiceName');
 my $config = Helios::Config->parseConfig();
 
 # same as above; parseConfig() will automatically call init()
 use Helios::Config;
 my $config = Helios::Config->parseConfig(service => 'ServiceName');
 
 # you can also use accessor methods; for example, with Helios::TestService:
 use Helios::Config;
 Helios::Config->setService('Helios::TestService');
 Helios::Config->init();
 my $config = Helios::Config->parseConfig();

 # catch config errors with eval {}
 # Try::Tiny works too 
 use Helios::Config;
 my $config;
 eval {
 	Helios::Config->init(service => 'Helios::TestService');
 	$config = Helios::Config->parseConfig();
 } or do {
 	my $E = $@;
 	if ( $E->isa('Helios::Error::ConfigError') ) {
 		print "Helios configuration error: $E\n";
 	} else {
 		print "I do not know what happened, but it was bad.\n";
 	}
 };
 

=head1 DESCRIPTION

Helios::Config is the standard class for determining configuration information 
in the Helios framework.  It handles parsing configuration information from the 
Helios configuration file, and determining the configuration for services from 
information in the Helios collective database.  Helios::Config also acts as a 
base class for the Helios configuration API; services can define specialized
Helios::Config subclasses to extend configuration subsystem functionality.

Normally, the developer of Helios services does not need to interact with 
Helios::Config directly.  Helios normally handles all configuration 
transparently during service setup before a service's run() method is called.  
A Helios service need only call its getConfig() method to retrieve a hashref of 
its configuration parameters.  Only those wanting to retrieve a Helios service 
configuration outside of the service (e.g. to write an external utility as 
an adjunct to a Helios service) or those with advanced configuration needs
will need to work with Helios::Config directly.

It should be noted that, like Helios::Logger subclasses, Helios::Config methods
are actually class methods, not instance (object) methods.  If you need to 
implement other methods outside of the methods defined 
below, make sure you implement them as class methods.

=head1 ACCESSOR METHODS

Helios::Config provides 7 set/get accessor pairs to provide access to 
configuration data.  There are 3 categories of accessors:  ones that need to 
be set before configuration parsing is initialized, those that are used during 
configuration parsing, and those that hold the end results of the parsing
procedure (i.e. the actual configuration helios.pl and the Helios service will 
need).

=head2 INITIALIZATION ACCESSORS

These need to be set before configuration parsing is initialized with the 
init() method.  If they are not set, the init() method will try to set them 
from data in the environment.

 set/getConfFile()        path to the Helios conf file 
                          -defaults to $HELIOS_INI env variable
 set/getHostname()        hostname the Helios service is running on
                          -defaults to results of Sys::Hostname::hostname()
 set/getService()         name of the running Helios service
                          -defaults to undefined, which will cause the
                           resulting config to contain the contents of the 
                           helios.ini [global] section only

=head2 CONFIG PARSING ACCESSORS

These methods will be set during the configuration parsing process.  Most 
Helios service developers will not need to be aware of these, but if you are 
developing a specialized Helios::Config subclass, they may be useful.

 set/getConfFileConfig()  the config info parsed from helios.ini
 set/getDbConfig()        the config info parsed from the collective database
 set/getDriver()          Data::ObjectDriver object connected to collective db

=head2 PARSING RESULTS ACCESSORS

This method contains the results of the configuration parsing process.  In 
other words, the actual configuration information for the given Helios service.

 set/getConfig()          the complete config info from both conf file & db

=cut

my $Debug = 0;
my $Errstr;
sub debug  { my $self = shift; @_ ? $Debug = shift : $Debug;   }
sub errstr { my $self = shift; @_ ? $Errstr = shift : $Errstr; }

my $ConfFile = $ENV{HELIOS_INI};
sub setConfFile {
	my $var = $_[0]."::ConfFile";
	no strict 'refs';
	$$var = $_[1]; 
}
sub getConfFile { 
    my $var = $_[0]."::ConfFile";
    no strict 'refs';
    return $$var;	
}

my $Hostname = hostname();
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


my $ServiceName;
sub setServiceName {
	my $var = $_[0]."::ServiceName";
	no strict 'refs';
	$$var = $_[1]; 
}
sub getServiceName { 
    my $var = $_[0]."::ServiceName";
    no strict 'refs';
    return $$var;	
}
sub setService { setServiceName(@_); }
sub getService { getServiceName(@_); }

my $Driver;
sub setDriver {
	my $var = $_[0]."::Driver";
	no strict 'refs';
	$$var = $_[1]; 
}
sub getDriver { 
	initDriver(@_);
}
sub initDriver {
	my $self = shift;
	my $config = $self->getConfFileConfig();
	if ($self->debug) { print __PACKAGE__.'->initDriver('.$config->{dsn}.','.$config->{user}.")\n"; }
	my $driver = Helios::ObjectDriver::DBI->new(
	    dsn      => $config->{dsn},
	    username => $config->{user},
	    password => $config->{password}
	);	
	if ($self->debug) { print __PACKAGE__.'->initDriver() DRIVER: ',$driver,"\n"; }
	$self->setDriver($driver);
	return $driver;	
}


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

my $ConfFileConfig;
sub setConfFileConfig {
	my $var = $_[0]."::ConfFileConfig";
	no strict 'refs';
	$$var = $_[1]; 
}
sub getConfFileConfig { 
    my $var = $_[0]."::ConfFileConfig";
    no strict 'refs';
    return $$var;	
}

my $DbConfig;
sub setDbConfig {
	my $var = $_[0]."::DbConfig";
	no strict 'refs';
	$$var = $_[1]; 
}
sub getDbConfig { 
    my $var = $_[0]."::DbConfig";
    no strict 'refs';
    return $$var;	
}



=head1 CONFIGURATION INITIALIZATION METHODS

=head2 init([%params])

Prepares Helios::Config to parse the configuration for a particular Helios 
service.  Accepts initialization information as a hash of parameters; if a 
parameter is not given, init() will attempt to default to values based on 
information from the environment.

The init() method accepts 4 arguments:

 CONF_FILE  path to the helios.ini file (default: $HELIOS_INI env var)
 HOSTNAME   hostname (default: current hostname from Sys::Hostname::hostname())
 DEBUG      enable/disable debug mode (default: disabled)
 SERVICE    name of the Helios service to determine configuration for 
            (default: none)

For example, to initialize Helios::Config to parse the configuration 
information from /etc/helios/helios.ini for the Helios::TestService service 
on the host named host1.hosting.com, one would call init() as:

 Helios::Config->init(
 	CONF_FILE => '/etc/helios/helios.ini',
 	HOSTNAME  => 'host1.hosting.com',
 	SERVICE   => 'Helios::TestService'
 );

Normally the host and config file are specified by the operating system and the
$HELIOS_INI environment variable, so a more typical init() call in a properly 
set up Helios collective would only specify the service:

 Helios::Config->init(SERVICE => 'Helios::TestService');

=cut

sub init {
	my $self = shift;
	my %params = @_;
	foreach (keys %params) {
		$params{lc($_)} = $params{$_};
	}
	if ( defined($params{conf_file}) ) { $self->setConfFile($params{conf_file}); }
	if ( defined($params{service})   ) { $self->setServiceName($params{service}); }
	if ( defined($params{hostname})  ) { $self->setHostname($params{hostname}); }
	if ( defined($params{debug})     ) { $self->debug($params{debug}); }
	
	# pull hostname from the environment if not already set
	unless ( $self->getHostname() ) {
		$self->setHostname( hostname() );
	}
	# again, pull conf file from environment if not already set
	if ( !defined($self->getConfFile()) && defined($ENV{HELIOS_INI}) ) {
		$self->setConfFile( $ENV{HELIOS_INI} );
	}
	
	# init() clears previous config
	$self->setConfFileConfig(undef);
	$self->setDbConfig(undef);
	$self->setConfig(undef);
	
	return $self;
}


=head1 CONFIGURATION PARSING METHODS

=head2 parseConfig([%params])

Given a set of optional initialization parameters, parseConfig() will parse 
the helios.ini config file and query the Helios collective database for 
configuration information for a particular Helios service, combining the 
information into a single set of configuration information, which is returned 
to the calling routine as a hash reference.

The parseConfig() method controls the actual parsing and derivation of a 
service's configuration.  This process has 4 steps:

=over 4

=item * Initialization (optional)

If parseConfig() was given options, it will call the init() method 
to (re-)initialize the configuration parsing process.  If no options were 
specified, parseConfig() assumes all the necessary options have already been 
set.

=item * Conf file parsing

If the configuration file has not yet been parsed, parseConfig() calls 
parseConfFile() to parse it.  If the conf file information has already been 
parsed, parseConfig() skips this step.  This is to ensure the helios.pl daemon 
and Helios worker processes do not become unstable if the filesystem with the 
config file becomes unmounted.

See the parseConfFile() method entry for more information about this phase of 
configuration parsing.

=item * Conf database parsing

Given the information obtained in the previous step, parseConfig() calls the 
parseConfDb() method to query the Helios collective database for configuration 
information for the specified Helios service.  Unlike the previous step, 
parseConfig() B<always> calls parseConfDb().  This is so the helios.pl daemon 
and Helios worker processes can dynamically update their configuration from the 
database.

See the parseConfDb() method entry for more information about this phase of 
configuration parsing.

=item * Merging configurations

Once the configurations from the conf file and the database have been 
acquired, parseConfig() merges the config hashes together into a single hash of 
configuration parameters for the specified service.  This single config hashref 
is returned to the calling routine.  A cached copy is also made available 
via the getConfig() method.

Configuration parameters for a service specified in the collective 
database override parameters specified in the conf file.

NOTE: Prior to Helios::Config, Helios assembled configuration parameter hashes 
differently.  Originally, both helios.ini and database config parameters were 
reparsed each time a config refresh was requested, and the new parameters were 
merged with the old configuration values.  This caused config values to "stick"
even if they were completely deleted from the database or conf file.  For 
example, deleting a HOLD parameter was not enough to take a service out of hold
mode; the Helios administrator had to set HOLD to 0.  

Helios::Config merges configurations differently.  Though the conf file config 
is only parsed once, each refresh of the database config starts with a new 
hash, and the config merge process starts with a brand new hash as well.  That 
way the config hash returned by parseConfig() contains only the B<current> 
config parameters, leading to a more predictable configuration subsystem.

=back

=cut

sub parseConfig {
	my $self = shift;
	my $conf_file_config;
	my $conf_db_config;

	# if we were passed options,
	# OR we haven't been initialized,
	# go ahead and call init() (with the given options)
	if (@_ || !( $self->getConfFile() && $self->getHostname() ) ) {
		$self = $self->init(@_);
	}
	
	# only parse conf file once
	if ( $self->getConfFileConfig() ) {
		$conf_file_config = $self->getConfFileConfig();
	} else {
		$conf_file_config = $self->parseConfFile();
	}
	
	# conf db always gets reparsed
	$conf_db_config = $self->parseConfDb();

	# merge configs	
	# deref conf file hashref so db conf 
	# doesn't leak into file conf when merged
	my %conf = %{$self->getConfFileConfig()};
	while ( my ($key, $value) = each %$conf_db_config ) {
		$conf{$key} = $value;
	}
	$self->setConfig(\%conf);
	return \%conf;
}


=head2 parseConfFile([$conf_file, $service_name])

Given an optional conf file and an optional service name, parseConfFile() 
parses the conf file and returns the resulting hashref to the calling routine.  
It also makes the hashref available via the getConfFileConfig() accessor.  
If either the conf file or the service is not specified, the values from the 
getConfFile() and/or getService() accessor(s) are used.  The conf file 
location is set by init() to the value of the $HELIOS_INI environment variable 
unless otherwise specified.

The default Helios configuration file is the common .ini file format, where
section headings are denoted by brackets ([]).  Lines not starting with [ are 
considered parameters belonging to the last declared section.  Lines starting 
with # or ; are considered comments and are ignored.  See L<Config::IniFiles> 
(the default underlying file parser) for more format details.  

Helios requires at least one section, [global], in the conf file, which should 
contain at least 3 parameters:

 dsn       DBI datasource name of the Helios collective database
 user      the user to use to access the Helios collective db
 password  the password to use to access the Helios collective db

Without these, the helios.pl daemon will be unable to connect to the collective 
database and will fail to start.

You may also specify other configuration parameters in the [global] section.  
Options set in the [global] section will appear in the configuration parameters 
of all services using that conf file.  This can be useful if you need multiple 
services on a host to share a configuration (e.g. you want to configure all 
services on a host to log messages to a syslogd facility using 
HeliosX::Logger::Syslog).

In addition to [global], you can create other sections as well.  If a section 
name matches the service name specified, the configuration parameters in that 
section will be included in the config hash returned to the calling routine.  
You can use this feature to set defaults for a service, or to set sensitive 
parameters (e.g. passwords) that you do not want to be changable from the 
Helios::Panoptes web admin console.

For example, a Helios conf file that configures the Helios collective db and 
sets some config parameters for the Helios::TestService service would look 
something like:

 [global]
 dsn=dbi:mysql:host=dbhost;db=helios_db
 user=helios_user
 password=xyz123
 
 [Helios::TestService]
 MAX_WORKERS=1
 loggers=HeliosX::Logger::Syslog
 syslog_facility=user
 syslog_options=pid

=cut

sub parseConfFile {
	my $self = shift;
	my $conf_file    = @_ ? shift : $self->getConfFile();
	my $service_name = @_ ? shift : $self->getServiceName();
	my $conf;
	
	unless ($conf_file)    { Helios::Error::ConfigError->throw("No conf file specified"); }
	unless (-r $conf_file) { Helios::Error::ConfigError->throw("Cannot read conf file $conf_file"); }
	
	my $cif = Config::IniFiles->new( -file => $conf_file );
	unless ( defined($cif) ) { 
		# @Config::IniFiles::errors contains the parse error(s);
		my $E = join(" ", @Config::IniFiles::errors);
		Helios::Error::ConfigError->throw("parseConfFile(): Invalid config file: $E"); 
	}

	# global must exist 
	if ($cif->SectionExists("global") ) {
		foreach ( $cif->Parameters("global") ) {
			$conf->{$_} = $cif->val("global", $_);
		}
	} 

	# if there's a section specifically for this service class, read it too
	# (it will effectively override the global section, BTW)
	if ( $cif->SectionExists( $service_name ) ) {
		foreach ( $cif->Parameters($service_name) ) {
			$conf->{$_} = $cif->val($service_name, $_);
		}
	}

	$self->setConfFileConfig($conf);

	return $conf;
}


=head2 parseConfDb([$service_name, $hostname])

The parseConfDb() method queries the Helios collective database for 
configuration parameters matching the specified service name and hostname and 
returns a hashref with those parameters to the calling routine.  If the service 
name and hostname are not specified, the values returned from the 
getService() and getHostname() accessors are used.  The getHostname() value 
is normally set by init() to the value returned by Sys::Hostname::hostname() 
unless otherwise specified.

The default parseConfDb() queries the HELIOS_PARAMS_TB table in the Helios 
collective database.  Two separate queries are done:

=over 4

=item *

Config params matching the service name and a host of '*'.  Config params 
with a '*' host apply to all instances of the service in the entire 
collective.

=item *

Config params matching the service name and the current hostname.  Config 
params with a specific hostname apply only to instances of that service on 
that particular host.  These are useful for HOLDing or HALTing services only on 
one host, or working with differences between hosts (e.g. a host with 4 cores 
and 16GB of RAM can support a higher MAX_WORKERS value than a dual core system 
with 2GB of memory).

=back

The results of these two queries are merged, and the resulting hashref returned 
to the calling routine.  Config parameters for a specific host override config 
params for all ('*') hosts.

Configuration parameters in the Helios collective database can be set using 
the Helios::Panoptes web admin console or using your database's standard SQL
commands.

=cut

sub parseConfDb {
	my $self = shift;
	my $service_name = @_ ? shift : $self->getServiceName();
	my $hostname     = @_ ? shift : $self->getHostname();
	my $conf_all_hosts = {};
	my $conf_this_host = {};
	my $conf = {};
	my @dbparams;

	my $driver = $self->getDriver();
	
	@dbparams = $driver->search( 'Helios::ConfigParam' => {
			worker_class => $service_name,
			host => ['*', $self->getHostname() ],
		}
	);
	foreach(@dbparams) {
		if ($self->debug) { print $_->param(),'=>',$_->value(),"\n"; }
		if ( $_->host eq '*') {
			$conf_all_hosts->{$_->param()} = $_->value();
		} else {
			$conf_this_host->{ $_->param() } = $_->value();
		}
	}
	
	$conf = $conf_all_hosts;
	while ( my ($key, $value) = each %$conf_this_host) {
		$conf->{$key} = $value;
	}
	$self->setDbConfig($conf);
	return $conf;		
}





=head2 getParam(param => $param_name [, service => $service_name] [, hostname => $hostname])

Given a service name, parameter name, and (optionally) a hostname, getParam() 
returns the parameter name's value to the calling routine.

If hostname is not specified, the current host is assumed.

=cut

sub getParam {
	my $self = shift;
	my %params;
	if (scalar @_ == 1) {
		$params{param} = $_[0];
	} else {
		%params = @_;		
	}
	my $service_name = defined($params{service}) ? $params{service} : $self->getServiceName;
	my $param_name   = $params{param};
	my $host         = defined($params{hostname}) ? $params{hostname} : $self->getHostname();
	my $conf = {};

	# shortcut: if the current config hash has already been retrieved
	# and the requested param is set, return *that* param
	if ( defined($self->getConfig()) && 
		defined($self->getService) && ($self->getService eq $service_name) &&
		defined($self->getHostname) && ($self->getHostname eq $host) && 
		defined($self->getConfig()->{$param_name}) 
		) {
		return $self->getConfig()->{$param_name};
	}

	# if we don't have everything, stop before we try
	unless ($service_name && $host && $param_name) {
		Helios::Error::ConfigError->throw('getParam(): service and param are required.');
	}


	eval {
		my $driver = $self->getDriver();
		my @dbparams = $driver->search( 'Helios::ConfigParam' => {
				worker_class => $service_name,
				param        => $param_name,
				host => ['*', $host ],
			}
		);
		my %conf_all_hosts;
		my %conf_this_host;
		foreach(@dbparams) {
			if ($self->debug) { print $_->worker_class(),'|', $_->host(),'|', $_->param(),'=>',$_->value(),"\n"; }
			if ( $_->host() eq '*') {
				$conf_all_hosts{$_->param()} = $_->value();
			} else {
				$conf_this_host{ $_->param() } = $_->value();
			}
		}
		$conf = \%conf_all_hosts;
		
		# if host=*, we're done
		# otherwise, use the given host, if the param is available
		if ( $host ne '*' && defined($conf_this_host{$param_name}) ) {
			$conf->{$param_name} = $conf_this_host{$param_name};
		}

		1;
	} or do {
		my $E = $@;
		Helios::Error::ConfigError->throw("getParam(): $E");
	};

	if ($self->debug && !defined($conf->{$param_name})) {
		print "$service_name|$host|$param_name not found.\n";
	}

	return $conf->{$param_name};
}

# this is officially *undocumented*
sub getAllParams {
	my $self = shift;	
	my $conf_all_hosts = {};
	my $conf_this_host = {};
	my $conf = {};

	eval {
		my $driver = $self->getDriver();	
		my @dbparams = $driver->search( 'Helios::ConfigParam' );
		foreach(@dbparams) {
			if ($self->debug) { print $_->param(),'=>',$_->value(),"\n"; }
			$conf->{ $_->worker_class() }->{ $_->host() }->{ $_->param() } = $_->value();
		}
		
		1;
	} or do {
		my $E = $@;
		Helios::Error::ConfigError->throw("getAllParams(): $E");
	};

	return $conf;		
}


=head2 setParam(param => $param_name [, service => $service_name]  [, hostname => $hostname], value => $value)

Given a service name, parameter name, parameter value, and (optionally) 
a hostname, setParam() sets the value for that parameter for that service 
(and host) in the Helios collective database.  If hostname is not specified,
the current host is assumed.  To set a parameter for all instances of a 
service in a collective, set the hostname to '*'.

=cut

sub setParam {
	my $self = shift;
	my %params = @_;
	my $service_name = defined($params{service}) ? $params{service} : $self->getServiceName;
	my $param_name   = $params{param};  
	my $host         = defined($params{hostname}) ? $params{hostname} : $self->getHostname;   
	my $value        = $params{value};
	my $cp;

	# if we don't have everything, stop before we try
	unless ($service_name && $host && $param_name && defined($value) ) {
		Helios::Error::ConfigError->throw('setParam(): Service, param name, and value are required.');
	}

	eval {
		# HELIOS_PARAMS_TB does not have a Primary Key.
		# Because of that, we cannot use D::OD in the normal way (search() or 
		# lookup(), change the value, then save()).
		# If we find an existing param matching service|host|param, we have to
		# delete ALL of the matching service|host|param in the table, then 
		# create a new one.
		# In SQL terms, we'll always do SELECT>DELETE>INSERT instead of 
		# SELECT>UPDATE|INSERT.

		# query for existing service/host/param
		my $driver = $self->getDriver();	
		my @cps = $driver->search( 'Helios::ConfigParam' => {
				worker_class => $service_name,
				param        => $param_name,
				host         => $host,
			}
		);
		my $cp = shift @cps;
	
		# ok, if there is a service/host/param exists,
		# we have to clear it out first, then create a new one from scratch
		if (defined($cp)) {
			if ($self->debug) { print "$service_name|$host|$param_name already set to ",$cp->value,".  Clearing.\n"; }
			$driver->remove('Helios::ConfigParam' =>
				{
					worker_class => $service_name,
					host         => $host,
					param        => $param_name
				}, 
				{ nofetch => 1 } 
			);
		} else {
			if ($self->debug) { print "$service_name|$host|$param_name not found.  Creating.\n"; }
		}

		# now, create a new Helios::ConfigParam and insert into the database
		if ($self->debug) { print "$service_name|$host|$param_name setting to $value\n"; }
		$cp = Helios::ConfigParam->new();
		$cp->worker_class($service_name);
		$cp->host($host);
		$cp->param($param_name);
		$cp->value($value);	
		$driver->insert($cp);
		
		1;
	} or do {
		my $E = $@;
		# rethrow the error as a ConfigError
		Helios::Error::ConfigError->throw("setParam(): $E");
	};

	return 1;
}


=head2 unsetParam(param => $param_name [, service => $service_name] [, hostname => $hostname,])

Given a service name, parameter name, and (optionally) a hostname, unsetParam() 
deletes that parameter's entry in the Helios collective database.  

If hostname is not specified, the current host is assumed.  To unset a 
parameter that is in effect for all instances of a service, you must set the 
hostname to '*'.

=cut

sub unsetParam {
	my $self = shift;
	my %params = @_;
	my $service_name = defined($params{service}) ? $params{service} : $self->getServiceName;
	my $param_name   = $params{param};   
	my $host         = defined($params{hostname}) ? $params{hostname} : $self->getHostname;
	my $cp;

	# if we don't have everything, stop before we try
	unless ($service_name && $host && $param_name) {
		Helios::Error::ConfigError->throw('setParam(): Service and param name are required.');
	}

	eval {
		# delete ALL of the matching service|host|param in the table
		my $driver = $self->getDriver();
		if ($self->debug) { print "Clearing $service_name|$host|$param_name from param table.\n"; }
		$driver->remove('Helios::ConfigParam' =>
			{
				worker_class => $service_name,
				host         => $host,
				param        => $param_name
			}, 
			{ nofetch => 1 } 
		);
		
		1;
	} or do {
		my $E = $@;
		# rethrow the error as a ConfigError
		Helios::Error::ConfigError->throw("unsetParam(): $E");
	};

	return 1;
}



1;
__END__


=head1 EXTENDING HELIOS::CONFIG

Helios service developers with more advanced configuration needs than 
Helios::Config supplies can extend the Helios::Config class to override 
its methods and/or provide methods of their own.  There are 2 steps required 
to take advantage of this functionality:

=over 4

=item * Extend Helios::Config

In defining a Helios::Config subclass, there are 2 important methods that 
drive the configuration parsing process:  init() and parseConfig().  Without 
these methods, the Helios framework will be unable to use the new config 
class.  

=item * Set the ConfigClass() method in your Helios service 

Just like JobClass() with jobs, ConfigClass() defines an alternate class to use 
to perform configuration parsing for your particular Helios service.  For 
example:

 package MyService;
 
 use 5.010;
 use strict;
 use warnings;
 use parent 'Helios::Service';
 
 use MyConfig;
 
 sub ConfigClass { 'MyConfig' }

 sub run {
 	my $self = shift;
 	my $job = shift;
 	my $config = $self->getConfig();
 	my $args = $self->getJobArgs($job);
 	
 	....
 }
 
 1;


=back

=head1 HELIOS CONFIGURATION PARAMETERS

The Helios system itself defines a large number of configuration parameters to 
control the helios.pl daemon, worker launching, and other system tasks.  
Consult the L<Helios::Configuration> page for a full list of parameters and 
their functions.

=head1 AUTHOR

Andrew Johnson, E<lt>lajandy at cpan dot orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2012-4 by Logical Helion, LLC.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.0 or,
at your option, any later version of Perl 5 you may have available.

=head1 WARRANTY

This software comes with no warranty of any kind.

=cut

