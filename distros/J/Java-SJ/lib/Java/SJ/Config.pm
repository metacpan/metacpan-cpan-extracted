###########################################################################
#
# Java::SJ::Config
#
# $Id: Config.pm,v 1.3 2003/07/20 18:52:21 wiggly Exp $
#
# $Author: wiggly $
#
# $DateTime$
#
# $Revision: 1.3 $
#
###########################################################################

package Java::SJ::Config;

use Carp;
use Cwd;
use Data::Dumper;
use English;
use File::Spec::Functions qw( tmpdir );
use IO::File;
use IO::Handle;
use XML::XPath;
use Java::SJ::Classpath;
use Java::SJ::VirtualMachine;

our $VERSION = '0.01';

my @CONFIG_FILE = 
	(
		'/etc/sj.conf',
		$ENV{'HOME'} . '/.sj.conf',
		getcwd . '/.sj.conf',
	);

my $DEFAULT_DIR_BASE = '/usr/local';
my $DEFAULT_DIR_LIB = '${dir.base}/lib/sj';
my $DEFAULT_DIR_PID = '${dir.base}/var/run';
my $DEFAULT_DIR_LOG = '${dir.base}/var/log/sj';
my $DEFAULT_DIR_TMP = tmpdir;
my $DEFAULT_DIR_SCRIPT = '${dir.base}/var/sj/script';
my $DEFAULT_FILE_PID = '${app.name}.pid';

###########################################################################
#
# Constructor
#
###########################################################################
sub new
{
	my $class = shift;
	my $self = {};
	bless $self, $class;
	$self->set_defaults;
	$self->load_system_configuration;
	#print STDERR "[DEBUG] CONFIG\n" . Dumper( $self ) . "\n\n";
	return $self;		
}


###########################################################################
#
# get_var
#
###########################################################################
sub get_var
{
	my $self = shift;
	my $name = shift;
	my $var = $self->{'var'}{$name};
	my $rep = undef;

	#
	# resolve and replace any sub-vars such as ${app.name}
	#
	while( $var =~ m/\$\{(.*?)\}/ )
	{
		$rep = $self->get_var( $1 );
		$var =~ s/\$\{(.*?)\}/$rep/;	
	}

	return $var;
}


###########################################################################
#
# set_defaults
#
# Set defaults for those configuration options that have defaults
#
###########################################################################
sub set_defaults
{
	my $self = shift;

	# application variables
	$self->{'var'}{'app.name'} = undef;
	$self->{'var'}{'app.class'} = undef;

	# directories
	$self->{'var'}{'dir.base'} = $DEFAULT_DIR_BASE;
	$self->{'var'}{'dir.lib'} = $DEFAULT_DIR_LIB;
	$self->{'var'}{'dir.pid'} = $DEFAULT_DIR_PID;
	$self->{'var'}{'dir.log'} = $DEFAULT_DIR_LOG;
	$self->{'var'}{'dir.tmp'} = $DEFAULT_DIR_TMP;
	$self->{'var'}{'dir.script'} = $DEFAULT_DIR_SCRIPT;

	# pid filename
	$self->{'var'}{'file.pid'} = $DEFAULT_FILE_PID;

	# properties
	$self->{'prop'} = undef;

	# environment
	$self->{'env'} = undef;

	# environment
	$self->{'param'} = undef;

	# virtual machine
	$self->{'var'}{'vm.default'} = undef;
	
	$self->{'bootclasspath'} = new Java::SJ::Classpath;
	$self->{'prepend_bootclasspath'} = new Java::SJ::Classpath;
	$self->{'append_bootclasspath'} = new Java::SJ::Classpath;
	$self->{'classpath'} = new Java::SJ::Classpath;
	$self->{'write_pid'} = 0;
	$self->{'vm'} = undef;
	$self->{'vmref'} = undef;
	$self->{'debug'} = 0;

	1;
}


###########################################################################
#
# load_configuration
#
###########################################################################
sub load_configuration
{
	my $self = shift;

	my $handle = shift;
	my $type = shift;

	my $xp;
	my ( $nodeset, $dir_nodeset, $jar_nodeset, $property_nodeset, $environment_nodeset, $param_nodeset );
	my ( $node, $dir_node, $jar_node, $property_node, $environment_node, $param_node );

	#print STDERR "[INFO] load_configuration\n";
	#print STDERR "[INFO] HANDLE : $handle\n";
	#print STDERR "[INFO] TYPE : $type\n";

	$xp = XML::XPath->new( ioref => $handle )
		or croak "[ERROR] Could not create new XPath object from handle, $!\n";

	#
	# get config parameters into our config object
	#

	#
	# DEBUG
	#
	$nodeset = $xp->find('/sj/debug');

	if( $nodeset->size() > 1 )
	{
		print STDERR "[WARN] Multiple DEBUG nodes.\n";
	} 
	elsif( $nodeset->size() == 1 )
	{
		$node = $nodeset->shift();
		
		#print STDERR "[INFO] Node : " . $node->getName() . "\n";
		#print STDERR "[INFO] Level : " . $node->getAttribute( 'level' ) . "\n";
		$self->{'debug'} = $node->getAttribute( 'level' );
	}
	else
	{
		#print STDERR "[INFO] No DEBUG defined\n";
	}

	#
	# NAME
	#
	$nodeset = $xp->find('/sj/name');

	if( $nodeset->size() > 1 )
	{
		print STDERR "[WARN] Multiple NAME nodes.\n";
	} 
	elsif( $nodeset->size() == 1 )
	{
		$node = $nodeset->shift();
		
		#print STDERR "[INFO] Node : " . $node->getName() . "\n";
		#print STDERR "[INFO] Name : " . $node->string_value() . "\n";
		$self->{'var'}{'app.name'} = $node->string_value();
	}
	else
	{
		#print STDERR "[INFO] No NAME defined\n";
	}

	#
	# CLASS
	#
	$nodeset = $xp->find('/sj/class');

	if( $nodeset->size() > 1 )
	{
		print STDERR "[WARN] Multiple CLASS nodes.\n";
	} 
	elsif( $nodeset->size() == 1 )
	{
		$node = $nodeset->shift();
		
		#print STDERR "[INFO] Node : " . $node->getName() . "\n";
		#print STDERR "[INFO] Class : " . $node->string_value() . "\n";
		$self->{'var'}{'app.class'} = $node->string_value();
	}
	else
	{
		#print STDERR "[INFO] No CLASS defined\n";
	}

	#
	# VAR
	#
	$nodeset = $xp->find('/sj/var');

	while( $node = $nodeset->shift() )
	{	
		#print STDERR "[INFO] Node : " . $node->getName() . "\n";
		#print STDERR "[INFO] Name : " . $node->getAttribute( 'name' )  . "\n";				
		#print STDERR "[INFO] Value : " . $node->getAttribute( 'value' )  . "\n";				
		$self->{'var'}{$node->getAttribute( 'name' )} = $node->getAttribute( 'value' );
	}

	#
	# PROPERTY
	#
	$nodeset = $xp->find('/sj/property');

	while( $node = $nodeset->shift() )
	{	
		#print STDERR "[INFO] Node : " . $node->getName() . "\n";
		#print STDERR "[INFO] Name : " . $node->getAttribute( 'name' )  . "\n";				
		#print STDERR "[INFO] Value : " . $node->getAttribute( 'value' )  . "\n";				
		$self->{'prop'}{$node->getAttribute( 'name' )} = $node->getAttribute( 'value' );
	}

	#
	# ENVIRONMENT
	#
	$nodeset = $xp->find('/sj/environment');

	while( $node = $nodeset->shift() )
	{	
		#print STDERR "[INFO] Node : " . $node->getName() . "\n";
		#print STDERR "[INFO] Name : " . $node->getAttribute( 'name' )  . "\n";				
		#print STDERR "[INFO] Value : " . $node->getAttribute( 'value' )  . "\n";				
		$self->{'env'}{$node->getAttribute( 'name' )} = $node->getAttribute( 'value' );
	}

	#
	# PARAM
	#
	$nodeset = $xp->find('/sj/param');

	while( $node = $nodeset->shift() )
	{	
		#print STDERR "[INFO] Node : " . $node->getName() . "\n";
		#print STDERR "[INFO] Name : " . $node->getAttribute( 'name' )  . "\n";				
		#print STDERR "[INFO] Value : " . $node->getAttribute( 'value' )  . "\n";				
		#print STDERR "[INFO] Sep : " . $node->getAttribute( 'sep' )  . "\n";				

		if( $node->getAttribute( 'value' ) !~ /^$/ )
		{
			if( $node->getAttribute( 'sep' ) !~ /^$/ )
			{
				$self->{'param'}{$node->getAttribute( 'name' )} = $node->getAttribute( 'sep' ) . $node->getAttribute( 'value' );
			}
			else
			{
				$self->{'param'}{$node->getAttribute( 'name' )} = ' ' . $node->getAttribute( 'value' );
			}
		}
		else
		{
			$self->{'param'}{$node->getAttribute( 'name' )} = '';
		}
	}

	#
	# PID
	#
	$nodeset = $xp->find('/sj/pid');

	while( $node = $nodeset->shift() )
	{	
		#print STDERR "[INFO] Node : " . $node->getName() . "\n";
		#print STDERR "[INFO] Name : " . $node->getAttribute( 'name' )  . "\n";				
		#print STDERR "[INFO] Dir : " . $node->getAttribute( 'dir' )  . "\n";				
		#print STDERR "[INFO] File : " . $node->getAttribute( 'file' )  . "\n";				

		$self->{'write_pid'} = 1;

		if( $node->getAttribute( 'dir' ) )
		{
			$self->{'var'}{'dir.pid'} = $node->getAttribute( 'dir' );
		}
		
		if( $node->getAttribute( 'file' ) )
		{
			$self->{'var'}{'file.pid'} = $node->getAttribute( 'file' );
		}
	}

	#
	# BOOTCLASSPATH
	#
	$nodeset = $xp->find('/sj/bootclasspath');

	if( $nodeset->size() > 1 )
	{
		print STDERR "[WARN] Multiple BOOTCLASSPATH nodes.\n";
	} 
	elsif( $nodeset->size() == 1 )
	{
		$node = $nodeset->shift();
		
		#print STDERR "[INFO] Node : " . $node->getName() . "\n";

		$dir_nodeset = $xp->find( 'dir', $node );

		while( $dir_node = $dir_nodeset->shift() )
		{
			#print STDERR "[INFO] Node : " . $dir_node->getName() . "\n";
			#print STDERR "[INFO] Path : " . $dir_node->getAttribute( 'path' )  . "\n";				

			$self->{'bootclasspath'}->add_dir( $dir_node->getAttribute( 'path' ) );
		}

		$jar_nodeset = $xp->find( 'jar', $node );

		while( $jar_node = $jar_nodeset->shift() )
		{
			#print STDERR "[INFO] Node : " . $jar_node->getName() . "\n";
			#print STDERR "[INFO] Path : " . $jar_node->getAttribute( 'name' )  . "\n";				
			#print STDERR "[INFO] Version : " . $jar_node->getAttribute( 'version' )  . "\n";				
			#print STDERR "[INFO] File : " . $jar_node->getAttribute( 'file' )  . "\n";				

			my %jar_info = 
				(
					name => $jar_node->getAttribute( 'name' ),
					version => $jar_node->getAttribute( 'version' ),
					file => $jar_node->getAttribute( 'file' ),
				);

			$self->{'bootclasspath'}->add_jar( %jar_info );
		}
	}
	else
	{
		#print STDERR "[INFO] No BOOTCLASSPATH defined\n";
	}

	#
	# PREPEND_BOOTCLASSPATH
	#
	$nodeset = $xp->find('/sj/prepend_bootclasspath');

	if( $nodeset->size() > 1 )
	{
		print STDERR "[WARN] Multiple PREPEND_BOOTCLASSPATH nodes.\n";
	} 
	elsif( $nodeset->size() == 1 )
	{
		$node = $nodeset->shift();
		
		#print STDERR "[INFO] Node : " . $node->getName() . "\n";

		$dir_nodeset = $xp->find( 'dir', $node );

		while( $dir_node = $dir_nodeset->shift() )
		{
			#print STDERR "[INFO] Node : " . $dir_node->getName() . "\n";
			#print STDERR "[INFO] Path : " . $dir_node->getAttribute( 'path' )  . "\n";				

			$self->{'prepend_bootclasspath'}->add_dir( $dir_node->getAttribute( 'path' ) );
		}

		$jar_nodeset = $xp->find( 'jar', $node );

		while( $jar_node = $jar_nodeset->shift() )
		{
			#print STDERR "[INFO] Node : " . $jar_node->getName() . "\n";

			#print STDERR "[INFO] Path : " . $jar_node->getAttribute( 'name' )  . "\n";				
			#print STDERR "[INFO] Version : " . $jar_node->getAttribute( 'version' )  . "\n";				
			#print STDERR "[INFO] File : " . $jar_node->getAttribute( 'file' )  . "\n";				

			my %jar_info = 
				(
					name => $jar_node->getAttribute( 'name' ),
					version => $jar_node->getAttribute( 'version' ),
					file => $jar_node->getAttribute( 'file' ),
				);

			$self->{'prepend_bootclasspath'}->add_jar( %jar_info );
		}
	}
	else
	{
		#print STDERR "[INFO] No PREPEND_BOOTCLASSPATH defined\n";
	}

	#
	# APPEND_BOOTCLASSPATH
	#
	$nodeset = $xp->find('/sj/append_bootclasspath');

	if( $nodeset->size() > 1 )
	{
		print STDERR "[WARN] Multiple APPEND_BOOTCLASSPATH nodes.\n";
	} 
	elsif( $nodeset->size() == 1 )
	{
		$node = $nodeset->shift();
		
		#print STDERR "[INFO] Node : " . $node->getName() . "\n";

		$dir_nodeset = $xp->find( 'dir', $node );

		while( $dir_node = $dir_nodeset->shift() )
		{
			#print STDERR "[INFO] Node : " . $dir_node->getName() . "\n";
			#print STDERR "[INFO] Path : " . $dir_node->getAttribute( 'path' )  . "\n";				

			$self->{'append_bootclasspath'}->add_dir( $dir_node->getAttribute( 'path' ) );
		}

		$jar_nodeset = $xp->find( 'jar', $node );

		while( $jar_node = $jar_nodeset->shift() )
		{
			#print STDERR "[INFO] Node : " . $jar_node->getName() . "\n";

			#print STDERR "[INFO] Path : " . $jar_node->getAttribute( 'name' )  . "\n";				
			#print STDERR "[INFO] Version : " . $jar_node->getAttribute( 'version' )  . "\n";				
			#print STDERR "[INFO] File : " . $jar_node->getAttribute( 'file' )  . "\n";				

			my %jar_info = 
				(
					name => $jar_node->getAttribute( 'name' ),
					version => $jar_node->getAttribute( 'version' ),
					file => $jar_node->getAttribute( 'file' ),
				);

			$self->{'append_bootclasspath'}->add_jar( %jar_info );
		}
	}
	else
	{
		#print STDERR "[INFO] No APPEND_BOOTCLASSPATH defined\n";
	}

	#
	# CLASSPATH
	#
	$nodeset = $xp->find('/sj/classpath');

	if( $nodeset->size() > 1 )
	{
		print STDERR "[WARN] Multiple CLASSPATH nodes.\n";
	} 
	elsif( $nodeset->size() == 1 )
	{
		$node = $nodeset->shift();
		
		#print STDERR "[INFO] Node : " . $node->getName() . "\n";

		$dir_nodeset = $xp->find( 'dir', $node );

		while( $dir_node = $dir_nodeset->shift() )
		{
			#print STDERR "[INFO] Node : " . $dir_node->getName() . "\n";
			#print STDERR "[INFO] Path : " . $dir_node->getAttribute( 'path' )  . "\n";				

			$self->{'classpath'}->add_dir( $dir_node->getAttribute( 'path' ) );
		}

		$jar_nodeset = $xp->find( 'jar', $node );

		while( $jar_node = $jar_nodeset->shift() )
		{
			#print STDERR "[INFO] Node : " . $jar_node->getName() . "\n";

			#print STDERR "[INFO] Path : " . $jar_node->getAttribute( 'name' )  . "\n";				
			#print STDERR "[INFO] Version : " . $jar_node->getAttribute( 'version' )  . "\n";				
			#print STDERR "[INFO] File : " . $jar_node->getAttribute( 'file' )  . "\n";				

			my %jar_info = 
				(
					name => $jar_node->getAttribute( 'name' ),
					version => $jar_node->getAttribute( 'version' ),
					file => $jar_node->getAttribute( 'file' ),
				);

			$self->{'classpath'}->add_jar( %jar_info );
		}
	}
	else
	{
		#print STDERR "[INFO] No CLASSPATH defined\n";
	}

	#
	# VM
	#
	$nodeset = $xp->find('/sj/vm');

	while( $node = $nodeset->shift() )
	{				
		#print STDERR "[INFO] Node : " . $node->getName() . "\n";

		#print STDERR "[INFO] Name : " . $node->getAttribute( 'name' )  . "\n";
		#print STDERR "[INFO] Vendor : " . $node->getAttribute( 'vendor' )  . "\n";
		#print STDERR "[INFO] Version : " . $node->getAttribute( 'version' )  . "\n";
		#print STDERR "[INFO] Language : " . $node->getAttribute( 'language' )  . "\n";
		#print STDERR "[INFO] Home : " . $node->getAttribute( 'home' )  . "\n";
		#print STDERR "[INFO] Default : " . $node->getAttribute( 'default' )  . "\n";
		#print STDERR "[INFO] Ref : " . $node->getAttribute( 'ref' )  . "\n";

		if( $node->getAttribute( 'ref' ) !~ /^$/ )
		{
			# set the VM ref to use as required
			$self->{'vmref'} = $node->getAttribute( 'ref' );

			# place env, prop and params into config

			# properties
			$property_nodeset = $xp->find( 'property', $node );
			while( $property_node = $property_nodeset->shift() )
			{	
				#print STDERR "[INFO] Node : " . $property_node->getName() . "\n";
				#print STDERR "[INFO] Name : " . $property_node->getAttribute( 'name' )  . "\n";				
				#print STDERR "[INFO] Value : " . $property_node->getAttribute( 'value' )  . "\n";				
				$self->{'prop'}{$property_node->getAttribute( 'name' )} = $property_node->getAttribute( 'value' );
			}

			# environment
			$environment_nodeset = $xp->find( 'environment', $node );
			while( $environment_node = $environment_nodeset->shift() )
			{	
				#print STDERR "[INFO] Node : " . $environment_node->getName() . "\n";
				#print STDERR "[INFO] Name : " . $environment_node->getAttribute( 'name' )  . "\n";				
				#print STDERR "[INFO] Value : " . $environment_node->getAttribute( 'value' )  . "\n";				
				$self->{'env'}{$environment_node->getAttribute( 'name' )} = $environment_node->getAttribute( 'value' );
			}

			# params
			$param_nodeset = $xp->find('param', $node );

			while( $param_node = $param_nodeset->shift() )
			{	
				#print STDERR "[INFO] Node : " . $param_node->getName() . "\n";
				#print STDERR "[INFO] Name : " . $param_node->getAttribute( 'name' )  . "\n";				
				#print STDERR "[INFO] Value : " . $param_node->getAttribute( 'value' )  . "\n";				
				#print STDERR "[INFO] Sep : " . $param_node->getAttribute( 'sep' )  . "\n";				

				if( $param_node->getAttribute( 'value' ) !~ /^$/ )
				{
					if( $param_node->getAttribute( 'sep' ) !~ /^$/ )
					{
						$self->{'param'}{$param_node->getAttribute( 'name' )} = $param_node->getAttribute( 'sep' ) . $param_node->getAttribute( 'value' );
					}
					else
					{
						$self->{'param'}{$param_node->getAttribute( 'name' )} = ' ' . $param_node->getAttribute( 'value' );
					}
				}
				else
				{
					$self->{'param'}{$param_node->getAttribute( 'name' )} = '';
				}
			}
		}
		else
		{
			my $vm = new Java::SJ::VirtualMachine;

			$vm->name( $node->getAttribute( 'name' ) );
			$vm->vendor( $node->getAttribute( 'vendor' ) );
			$vm->version( $node->getAttribute( 'version' ) );
			$vm->language( $node->getAttribute( 'language' ) );
			$vm->home( $node->getAttribute( 'home' ) );
			$vm->default( $node->getAttribute( 'default' ) );

			if( $vm->default )
			{
				$self->{'vmref'} = $vm->name;
			}

			$property_nodeset = $xp->find( 'property', $node );

			while( $property_node = $property_nodeset->shift() )
			{
				#print STDERR "[INFO] Node : " . $property_node->getName() . "\n";
				#print STDERR "[INFO] Name : " . $property_node->getAttribute( 'name' )  . "\n";
				#print STDERR "[INFO] Value : " . $property_node->getAttribute( 'value' )  . "\n";
				$vm->add_property( $property_node->getAttribute( 'name' ), $property_node->getAttribute( 'value' ) );
			}

			$param_nodeset = $xp->find( 'param', $node );

			while( $param_node = $param_nodeset->shift() )
			{
				#print STDERR "[INFO] Node : " . $param_node->getName() . "\n";
				#print STDERR "[INFO] Name : " . $param_node->getAttribute( 'name' )  . "\n";
				#print STDERR "[INFO] Value : " . $param_node->getAttribute( 'value' )  . "\n";
				#print STDERR "[INFO] Sep : " . $param_node->getAttribute( 'sep' )  . "\n";

				$vm->add_environment( $param_node->getAttribute( 'name' ), $param_node->getAttribute( 'value' ), $param_node->getAttribute( 'sep' ) );
			}

			$environment_nodeset = $xp->find( 'environment', $node );

			while( $environment_node = $environment_nodeset->shift() )
			{
				#print STDERR "[INFO] Node : " . $environment_node->getName() . "\n";
				#print STDERR "[INFO] Name : " . $environment_node->getAttribute( 'name' )  . "\n";
				#print STDERR "[INFO] Value : " . $environment_node->getAttribute( 'value' )  . "\n";

				$vm->add_environment( $environment_node->getAttribute( 'name' ), $environment_node->getAttribute( 'value' ) );
			}

			$self->{'vm'}{$vm->name} = $vm;
		}
	}

	$xp = undef;
	1;
}


###########################################################################
#
# load_system_configuration
#
# Load configuration from well known file locations
#
###########################################################################
sub load_system_configuration
{
	my $self = shift;

	my $file;
	my $handle;

	#print STDERR "[INFO] load_system_configuration\n";

	foreach $file ( @CONFIG_FILE )
	{
		if( -f $file && -r _ )
		{
			#print STDERR "[INFO] configuration file found : $file\n";
			
			$handle = new IO::File( "<$file" )
				or croak "[ERROR] Cannot open file $file for reading, $!\n";
			
			$self->load_configuration( $handle, 0 );
		}
		else
		{
			#print STDERR "[INFO] configuration file absent : $file\n";
		}
	}
	1;
}


###########################################################################
#
# load_app_configuration
#
# Load a configuration from a script file before it has been converted into
# a cached script with it's configuration in a DATA section.
#
###########################################################################
sub load_app_configuration
{
	my $self = shift;
	my $handle = shift;

	$self->load_configuration( $handle, 1 );

	1;
}


###########################################################################
#
# load_script_configuration
#
# Load a configuration from a Script's DATA section
#
###########################################################################
sub load_script_configuration
{
	my $self = shift;

	my $handle;

	#print STDERR "[INFO] load_script_configuration\n";

	$handle = new IO::Handle;

	$handle->fdopen( main::DATA, 'r' )
		or croak "[ERROR] Could not create IO::Handle from main::DATA filehandle, $!\n";

	$self->load_configuration( $handle, 1 );

	1;
}


###########################################################################
1;

=pod

=head1 NAME

Java::SJ::Config - SJ Configuration File

=head1 DESCRIPTION

This module represents SJ configurations. It uses L<XML::XPath> to parse
configuration files and generates objects to represent the directives.

Unless you're working on the module what you really want to know is what
directives are allowed and their meaning. You're in luck, its below.

=head1 CONFIGURATION

All the tags defined below may appear in either the system or application
configuration files. Some of course make more sense in one than the other.
It may appear that some (class for example) have no business being in the
system configuratino at all.

This is allowed for two reasons. Firstly it makes parsing and overriding
configuration easier. Secondly it allows you to do things such as print nice
error message for people when classes are not defined in app config files.

=head2 Name

C<E<lt>name/E<gt>>

Name to use for this application. If this is not set then the configuration
script filename is used without extension. So a script called 'hello.sj' would
be run as a program named 'hello'.

It doesn't make much sense to place this in the system configuration but you
could do so if you felt kinky.

=head2 Class

C<E<lt>class/E<gt>>

Full name of the class whose main method you wish to run for this
application.

It makes no sense to place this in the system configuration unless you want
to do something really perverted.

=head2 Var

C<E<lt>var name="" value=""/E<gt>>

Specify variables that can be used within configuration files. The names of
the variables may be used as values in the configuration file.

=head2 Property

C<E<lt>property name="" value=""/E<gt>>

Specify properties to define for the VM that is eventually used to run the
application. These get turned into -D options to the VM

=head2 Environment

C<E<lt>environment name="" value=""/E<gt>>

Specify environment settings to define for the interpreter and VM. This can
be useful to set things such as TimeZones, Locales etc.

=head2 Param

C<E<lt>param name="" value="" sep=""/E<gt>>

Specify a command line argument. This may simply be a name for option
switches or can include a value. The sep attribute defines what to seperate
the argument name and value by, the default is a single space.

Params can be defined for VMs and for applications generally. Params for VMs
will be passed to the VM whilst params defined in the application
configuration main section will be passed to the application after the class
name

=head2 Dir

C<E<lt>dir path=""/E<gt>>

Specify a directory path. These are used in multiple places but primarily in
specifying where to look for classes.

=head2 Jar

C<E<lt>jar name="" version="" file=""/E<gt>>

Specify the location of a JAR file.

If only a name is provided then the highest version JAR available in the SJ
library directory will be used. Otherwise SJ will look for a specific
version number and attempt to use that.

If file is given then that exact JAR file is used.

=head2 Pid

C<E<lt>pid dir="${dir.pid}" file="${app.name}.pid"/E<gt>>

Specify whether or not to keep a PID file for this application.

Additionally this tag allows you to change where the PID file is kept and
what it is called. These default to the ${dir.pid} directory and
${app.name}.pid for filename.

This tag when specified in the application configuration means that a PID
file should be written, otherwise one will not be created. You should only
wish to create PID files for programs that require control over time using
the other SJ admin scripts.

Programs that run interactively or that can have multiple instances running
concurrently should not use the PID tag in their application config file
since the PID file will be overwritten for any currently running instances.

=head2 Bootclasspath

C<
E<lt>bootclasspathE<gt>
E<lt>dir/E<gt>*
E<lt>jar/E<gt>*
E<lt>/bootclasspathE<gt>
>

Specify the boot classpath to use for the VM in full.

=head2 Prepend_bootclasspath

	<prepend_bootclasspath>
	  <dir/>*
	  <jar/>*
	</prepend_bootclasspath>

Specify elements to prepend to the boot classpath.

=head2 Append_bootclasspath

	<append_bootclasspath>
	  <dir/>*
	  <jar/>*
	</append_bootclasspath>

Specify elements to append to the boot classpath.

=head2 Classpath

	<classpath>
	  <dir/>*
	  <jar/>*
	</classpath>

Specify elements to add to the classpath.

=head2 VM

	<vm name="" vendor="" version="" language="" home="" default="true|false">
	  <property/>*
	  <param/>*
	  <environment/>*
	</vm>

	<vm ref="">
	  <property/>*
	  <param/>*
	  <environment/>*
	</vm>


The VM tag is used to define or refer to an existing VM description.

In the first instance a VM definition includes;

=over 4

=item name

A unique name to refer to this VM description

=item vendor

The vendor name

=item version

The version number

=item language

The Java language version this VM supports

=item home

The JAVA_HOME location for this VM

=item default

Whether or not to use this VM if one is not explicitly specified
by an application.

=back

The VM marked 'default' in the system config will be used unless the
application config specifically mentions another VM. 

Only a single VM should be marked as 'default'.

When used with a ref attribute it refers to a previously defined VM by name
and possible adds/overrides some of the proeprties and environment settings.

The VM tag allows you to specify properties to set on a per-vm bases and
also allows you to specify arbitrary command line arguments to pass to the
VM. It also allows you to specify environment settings to apply to the VM.

=head2 Debug

<debug level=""/>

Set the debug level 


=head1 VARIABLES

The following variables and their relevant defaults are used by the system.
These defaults have been chosen to make it as easy as possible to install SJ
on a fairly standard UNIX system and have logs, and directories in places
that you would expect to find them.

The full paths that will be used if every default is in effect is also shown
below.


dir.base
 - default /usr/local
 - full /usr/local

The base directory for the system. This directory is used in conjunction
with defaults to find directories if they have not been defined elsewhere.


dir.lib
 - default ${dir.base}/lib/sj
 - full /usr/local/lib/sj

The directory to find jar files in.


dir.pid
 - default ${dir.base}/var/run
 - full /usr/local/var/run

The directory to store PID files in. 


dir.log
 - default ${dir.base}/var/log/sj
 - full /usr/local/var/log/sj

The directory to store log files in


dir.script
 - default ${dir.base}/var/sj/script
 - full /usr/local/var/sj/script

The directory to store generated script files in.


dir.tmp
 - default &File::Spec::Functions::tmpdir
 - full N/A (depends on system)

The directory to store temporary files in.


app.name
 - no default

The name of the application


app.class
 - no default

The class file for the application


vm.default
 - Defined by whichever VM has default=true attribute

The default VM tag to use if none supplied by the application

=head1 TODO

Test, test, test.

=head1 BUGS

None known so far. Please report any and all to Nigel Rantor <F<wiggly@wiggly.org>>

=head1 SUPPORT / WARRANTY

This module is free software. IT COMES WITHOUT WARRANTY OF ANY KIND.

=head1 LICENSE

The Java::SJ::Config module is Copyright (c) 2003 Nigel Rantor. England.
All rights reserved.

You may distribute under the terms of either the GNU General Public License
or the Artistic License, as specified in the Perl README file.

=head1 AUTHORS

Nigel Rantor <F<wiggly@wiggly.org>>

=head1 SEE ALSO

L<Java::SJ>.

=cut
