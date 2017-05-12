###########################################################################
#
# Java::SJ
#
# $Id: SJ.pm,v 1.4 2003/07/20 18:52:15 wiggly Exp $
#
# $Author: wiggly $
#
# $DateTime$
#
# $Revision: 1.4 $
#
###########################################################################

package Java::SJ;

use strict;

use Carp;
use Cwd;
use Data::Dumper;
use English;
use File::Path;
use File::Slurp;
use File::Spec;
use File::Temp qw( tempfile );
use IO::File;
use IO::Handle;
use Java::SJ::Config;

our $VERSION = '0.01';

our $LOG = undef;

###########################################################################
#
# sj - main program for sj script
#
###########################################################################
sub sj
{
	my $config = new Java::SJ::Config;

	my $script = shift @ARGV;

	my $log_file;

	my $handle;

	croak "[ERROR] Please specify a script file on the command line.\n"
		unless defined( $script );

	# find out the canonical path to the script	
	$script = File::Spec->rel2abs( $script );

	# open the script and read it into our configuration
	$handle = new IO::File( "<$script" )
		or croak "[ERROR] Cannot open file $script, $!\n";

	$config->load_app_configuration( $handle, 0 )
		or croak "[ERROR] Could not load configuration\n";

	$handle->close;

	# open LOG filehandle
	$log_file = $config->get_var( 'dir.log' ) . "/sj.log";

	$LOG = new IO::File $log_file, "w"
		or croak "[ERROR] Cannot open log file $log_file, $!\n";

	print $LOG "[INFO] Java::SJ::sj\n";
	print $LOG "[INFO] PROGRAM $PROGRAM_NAME\n";
	print $LOG "[INFO] PID $PROCESS_ID\n";
	print $LOG "[INFO] CWD " . getcwd . "\n";
	print $LOG "[INFO] ARGV " . join( ' ', @ARGV ) . "\n";
	print $LOG "[INFO] SCRIPT " . $script . "\n";


	print $LOG "[DEBUG] configuration\n";
	print $LOG "[DEBUG]\n";
	print $LOG Dumper( $config );
	print $LOG "\n\n";

	print $LOG "[INFO] Now generate a cached script file in our script dir.\n";

	my $program_file = $config->get_var( 'dir.script' ) . "/" . $config->get_var( 'app.name' );

	print $LOG "[INFO] Program file : $program_file\n";


	# ensure script directory exists
	my ( $volume, $directories, $file ) = File::Spec->splitpath( $program_file );

	eval
	{
		mkpath( $directories );
	};
	
	if( $@ )
	{
		( $handle, $program_file ) = tempfile( 'sj_script.XXXXXXXX', DIR => $config->get_var( 'dir.tmp' ) );
	}
	else
	{
		$handle = new IO::File( ">$program_file"  )
			or croak "[ERROR] Cannot open program file $program_file for writing, $!\n";	
	}
	
	print $handle "#!$EXECUTABLE_NAME\n";
	print $handle "use Java::SJ;\n";
	print $handle "&Java::SJ::run;\n";
	print $handle "__END__\n";
	print $handle read_file( $script );

	$handle->close;

	# make it executable
	chmod 0755, $program_file;

	# execute the script
	{
		exec ( $program_file, @ARGV );
	};

	croak "[ERROR] Could not exec program $program_file, $!\n";	
}


###########################################################################
#
# run
#
###########################################################################
sub run
{
	my $config = new Java::SJ::Config;

	my $vm = undef;

	my @prop = ();
	
	my @param = ();

	my @cp = ();

	my $command = '';

	my $log_file;

	my ( $key, $bcp, $pbcp, $abcp, $cp );

	$config->load_script_configuration;

	# open LOG filehandle
	$log_file = $config->get_var( 'dir.log' ) . "/sj.log";

	$LOG = new IO::File $log_file, "w"
		or croak "[ERROR] Cannot open log file $log_file, $!\n";

	print $LOG "[INFO] Java::SJ::run\n";
	print $LOG "[INFO] PROGRAM $PROGRAM_NAME\n";
	print $LOG "[INFO] PID $PROCESS_ID\n";
	print $LOG "[INFO] CWD " . cwd . "\n";
	print $LOG "[DEBUG] configuration\n";
	print $LOG "[DEBUG]\n";
	print $LOG Dumper( $config );
	print $LOG "\n\n";
	print $LOG "[DEBUG] BOOTCLASSPATH : " . $config->{'bootclasspath'}->generate_classpath( $config->get_var( 'dir.lib' ) ) . "\n";
	print $LOG "[DEBUG] PBOOTCLASSPATH : " . $config->{'prepend_bootclasspath'}->generate_classpath( $config->get_var( 'dir.lib' ) ) . "\n";
	print $LOG "[DEBUG] ABOOTCLASSPATH : " . $config->{'append_bootclasspath'}->generate_classpath( $config->get_var( 'dir.lib' ) ) . "\n";
	print $LOG "[DEBUG] CLASSPATH : " . $config->{'classpath'}->generate_classpath( $config->get_var( 'dir.lib' ) ) . "\n";
	print $LOG "\n\n";


	print $LOG "[DEBUG] get vm we need to use\n";
	
	$vm = $config->{'vm'}{$config->{'vmref'}};
	
	print $LOG "[DEBUG] got VM '" . $vm->name . "'\n";

	print $LOG "[DEBUG] construct environment\n";

	foreach $key ( keys %{$config->{'env'}} )
	{
		print $LOG "[DEBUG] ENV $key -> " . $config->{'env'}{$key} . "\n";
		$ENV{$key} = $config->{'env'}{$key};
	}

	foreach $key ( keys %{$vm->{'env'}} )
	{
		print $LOG "[DEBUG] ENV $key -> " . $vm->{'env'}{$key} . "\n";
		$ENV{$key} = $vm->{'env'}{$key};
	}

	# set JAVA_HOME based on VM
	$ENV{'JAVA_HOME'} = $vm->home;

	print $LOG "[DEBUG] construct property list\n";

	foreach $key ( keys %{$config->{'prop'}} )
	{
		print $LOG "[DEBUG] PROP $key -> " . $config->{'prop'}{$key} . "\n";
		push @prop, sprintf( "-D%s=%s", $key, $config->{'prop'}{$key} );
	}

	foreach $key ( keys %{$vm->{'prop'}} )
	{
		print $LOG "[DEBUG] PROP $key -> " . $vm->{'prop'}{$key} . "\n";
		push @prop, sprintf( "-D%s=%s", $key, $vm->{'prop'}{$key} );
	}

	print $LOG "[DEBUG] property list : " . join( ' ', @prop ) . "\n";

	print $LOG "[DEBUG] construct parameter list\n";

	foreach $key ( keys %{$config->{'param'}} )
	{
		print $LOG "[DEBUG] PARAM $key -> " . $config->{'param'}{$key} . "\n";
		push @param, sprintf( "%s%s", $key, $config->{'param'}{$key} );
	}

	foreach $key ( keys %{$vm->{'param'}} )
	{
		print $LOG "[DEBUG] PARAM $key -> " . $vm->{'param'}{$key} . "\n";
		push @param, sprintf( "%s%s", $key, $vm->{'param'}{$key} );
	}

	print $LOG "[DEBUG] param list : " . join( ' ', ( @param, @ARGV ) ) . "\n";

	print $LOG "[DEBUG] construct java command line\n";


	$bcp = $config->{'bootclasspath'}->generate_classpath( $config->get_var( 'dir.lib' ) );
	$pbcp = $config->{'prepend_bootclasspath'}->generate_classpath( $config->get_var( 'dir.lib' ) );
	$abcp = $config->{'append_bootclasspath'}->generate_classpath( $config->get_var( 'dir.lib' ) );
	$cp = $config->{'classpath'}->generate_classpath( $config->get_var( 'dir.lib' ) );

	if( length( $bcp ) )
	{
		push @cp, "-Xbootclasspath:$bcp";
	}

	if( length( $pbcp ) )
	{
		push @cp, "-Xbootclasspath/p:$pbcp";
	}

	if( length( $abcp ) )
	{
		push @cp, "-Xbootclasspath/a:$abcp";
	}

	if( length( $cp ) )
	{
		push @cp, "-classpath $cp";
	}

	#$command .= 'echo "';
	$command .= $vm->home;
	$command .= '/bin/java';
	$command .= ' ';
	$command .= join( ' ', @cp );
	$command .= ' ';
	$command .= join( ' ', @prop );
	$command .= ' ';
	$command .= $config->get_var( 'app.class' );
	$command .= ' ';
	$command .= join( ' ', @param );
	$command .= ' ';
	$command .= join( ' ', @ARGV );
	$command .= ' ';
	#$command .= '"';
	
	print $LOG "[DEBUG] write out PID file if required\n";

	print $LOG "[DEBUG] command :\n$command\n\n";

	# execute java
	exec $command;
}

###########################################################################
1;

=pod

=head1 NAME

Java::SJ - Highly configurable Java program startup system

=head1 SYNOPSIS

  sj myprogram.sj

=head1 DESCRIPTION

This module allows you to very easily run Java services that rely on complex
configuration at the VM and library level. It also provides an easy way of
specifying a sensible 'default' configuration that can be overridden by specific
applications should they need to.

The system is configured on a machine and application level. The system
looks for configuration files in a set of well-known locations, currently
these are:

=over 4

=item * F</etc/sj.conf>

=item * F<.sj.conf> in users HOME directory

=item * F<.sj.conf> in current working directory

=back

Every application is defined in terms of a similar configuration file. The
configuration system has been designed so that it is easy to write a simple
and minimal configuration file for a program.

Provided the system has a fairly complete configuration associated with it
then an application configuration file need only have the class name to be
executed.

=head1 FEATURES

Some of the Goodness(tm) that you get with SJ is as follows:

=over 4

=item Easy co-existence of multiple Virtual Machines

Any number of VMs can be supported and used concurrently on the same
machine. Developers don't need to know where the JDK/JRE resides, just a
symbolic name for it.

=item Easy co-existence of multiple versions of JAR files

Any number of different versions of the same JAR file may co-exist. SJ sorts
out which ones to use and only places those JAR files that are required in
an application's CLASSPATH

=item Control over BOOTCLASSPATH variables

All three flavours of the bootclasspath can be configured on a system-wide
and application specific basis.

=item Process control

PID files can be automatically generated and placed wherever you wish.

=item Cache of executable scripts

Application configuration files are cached as executable scripts that can be
directly invoked.

=back


This will probably make more sense as a set of examples, so here goes.

=head1 EXAMPLES

=head2 Simple Configuration

	<?xml version="1.0"?>
	<sj>
	  <!-- define a virtual machine -->
	  <vm name="ibm" 
	      home="/usr/local/IBMJava-1.3.1" 
	      default="true"/>
	</sj>

The above minimal system configuration simply tells the system where to find
a virtual machine called 'ibm' and that it should be used as the default VM
unless an application specifically requests another one.

	<?xml version="1.0"?>
	<sj>
	  <!-- define the class file to run -->
	  <class>myclass</class>
	</sj>

The above minimal application configuration simply provides a class file
name to run. If both of the above simple configuration files were used then
the class 'myclass' would have to be in the system's CLASSPATH environment
variable already.

=head2 Useful Configuration

The above simple configuration is only really useful to test that the system
is working. Running a simple class on the command line isn't normally very
difficult and so sj doesn't actually add very much to the above case.

If we had a system where we wished to test that the same code was compatible
with multiple virtual machines and multiple library versions then the
following configuration files would enable us to run these programs with
different parameters easily.

	<?xml version="1.0"?>
	<sj>
	  <!-- important locations -->
	  <var name="dir.base" value="/usr/local"/>
	  <var name="dir.pid" value="${dir.base}/var/run"/>
	  <var name="dir.log" value="${dir.base}/var/log/sj"/>
	  <var name="dir.tmp" value="/tmp"/>
	  <var name="dir.lib" value="${dir.base}/lib/sj"/>
	  <var name="dir.script" value="${dir.base}/var/sj/script"/>

	  <!-- write out a PID file for every program -->
	  <pid/>	

	  <!-- use this as our default CLASSPATH -->
	  <classpath>
	    <jar name="xalan"/>
	    <jar name="xerces"/>
	    <jar name="xml-apis"/>
	    <jar name="commons-cli" version="1.0.3"/>
	  </classpath>

	  <vm name="ibm118" 
	      vendor="IBM" 
	      version="1.1.8" 
	      home="/usr/local/IBMJava-1.1.8"/>

	  <vm name="ibm141" 
	      vendor="IBM" 
	      version="1.4.1" 
	      home="/usr/local/IBMJava-1.4.1"/>

	  <vm name="blackdown118" 
	      vendor="Blackdown" 
	      version="1.1.8" 
	      home="/usr/local/blackdown-1_1_8"/>

	  <vm name="sun131" 
	      vendor="Sun Microsystems" 
	      version="1.3.1" 
	      home="/usr/local/sunjdk_131"
	      default="true"/>
	</sj>


The above system configuration contains a lot more information than our
initial simple example.

=over 4

=item Variables

There are explicitly declared variables that SJ will use when figuring
out where things should be read from/written to.

Variables may be defined in terms of other variables, even if they have not
been declared yet. The syntax for referring to variables thorughout is the
same as Ant, ${variable_name}.

=item PID file

It states that by default a PID file should be written when running an
application. This is most useful for multithreaded server applications where
you want to be able to kill or HUP the server without figuring out what the
lead process PID is.

=item Classpath

The classpath definition instructs SJ to look for the latest available
versions of xalan, xerces and xml-apis and version 1.0.3 of the commons-cli
libraries and add these to the classpath when running any program.

SJ will look for the libraries in the path defined by ${dir.lib}.

SJ is currently very simplistic about library versioning. If it needs to
look for a specific version of a library then it simply looks for the
library name and library version number joined by a single hyphen. So in the
case of the commons-cli library SJ would look for commons-cli-1.0.3.jar in
the ${dir.lib} directory.

You may be wondering how SJ figures out which is the 'latest' version of a
JAR file if no version is specified. Quite simply it chooses the one whose
filename begins with the required name and is lexicographically last in an
ordered list of those filenames that match. It's not great but with any
half-sensible version numbering scheme it will work.

=item Virtual Machines

There are four virtual machines defined here. In addition to the home
directory for each there is now information regarding the vendor and
version. Currently this is for informational purposes only but future
versions of SJ should be able to choose a VM based on the version or vendor.

=back

	<?xml version="1.0"?>
	<sj>
	  <!-- define the class file to run -->
	  <class>myclass</class>
	  <vm ref="blackdown118"/>
	</sj>

	<?xml version="1.0"?>
	<sj>
	  <!-- define the class file to run -->
	  <class>myclass</class>
	  <vm ref="ibm118"/>
	</sj>

	<?xml version="1.0"?>
	<sj>
	<!-- define the class file to run -->
	  <class>myclass</class>
	  <vm ref="sun131"/>
	</sj>

The above application configurations are exactly the same as the simple
version with the addition of a vm reference tag to determine which VM they
should be executed under.

=head2 High Granularity

In addition to being able to specify which VMs and libraries to use you have
complete control over the environment that the VM is run under, the
properties that are passed the the VM and even default command line options
on a per system, VM and application basis.

	<?xml version="1.0"?>
	<sj>
	  <!-- important locations -->
	  <var name="dir.base" value="/usr/local"/>
	  <var name="dir.pid" value="${dir.base}/var/run"/>
	  <var name="dir.log" value="${dir.base}/var/log/sj"/>
	  <var name="dir.tmp" value="/tmp"/>
	  <var name="dir.lib" value="${dir.base}/lib/sj"/>
	  <var name="dir.script" value="${dir.base}/var/sj/script"/>

	  <!-- add these as -Dname=val VM properties-->
	  <property name="ORBSingletonClass" value="jacorb.ORBSingleton"/>

	  <!-- add these to the environment for every app -->
	  <environment name="TZ" value="CET"/>
	  <environment name="PAGER" value="less"/>

	  <!-- add these to the command line parameters of every app -->
	  <param name="--debuglevel" value="3"/>
	  <param name="--colour" value="blue" sep="="/>
	  <param name="-g" value="3" sep=":"/>

	  <!-- write out a PID file for every program -->
	  <pid/>	

	  <!-- use this as our default CLASSPATH -->
	  <classpath>
	    <jar name="xalan"/>
	    <jar name="xerces"/>
	    <jar name="xml-apis"/>
	    <jar name="commons-cli" version="1.0.3"/>
	  </classpath>

	  <vm name="ibm118" 
	      vendor="IBM" 
	      version="1.1.8" 
	      home="/usr/local/IBMJava-1.1.8">
	    <!-- set USE_JIT whenever this VM is chosen -->
	    <environment name="USE_JIT" value="true"/>
	  </vm>

	  <vm name="ibm141" 
	      vendor="IBM" 
	      version="1.4.1" 
	      home="/usr/local/IBMJava-1.4.1"/>

	  <vm name="blackdown118" 
	      vendor="Blackdown" 
	      version="1.1.8" 
	      home="/usr/local/blackdown-1_1_8">
	    <!-- set this parameter for this VM only -->
	    <param name="-Xmx" value="81920k" sep=""/>
	  </vm>

	  <vm name="sun131" 
	      vendor="Sun Microsystems" 
	      version="1.3.1" 
	      home="/usr/local/sunjdk_131"
	      default="true"/>
	</sj>

The above system configuration is identical to our useful configuration
except we have now added directives that SJ will use to alter the
environment and command line parameters passed to the application and VMs.

Using VM specific parameters you can make sure that the correct threading
models are used or that memory limuts are enforced unless someone needs to
tweak the settings.

In an application configuration file it is possible to override previously
declared parameters such as the -Xmx directive above for the blackdown VM.

For example:

	<?xml version="1.0"?>
	<sj>
	  <!-- define the class file to run -->
	  <class>myclass</class>
	  <vm ref="blackdown118">
	  	<param name="-Xmx" value="80m" sep=""/>
	  </vm>
	</sj>

The L<Java::SJ::Config> documentation describes every configuration
directive in detail, also have a look in the sample directory for ideas.

=head1 TODO

Test, test, test.

=head1 BUGS

None known so far. Please report any and all to Nigel Rantor <F<wiggly@wiggly.org>>

=head1 SUPPORT / WARRANTY

This module is free software. IT COMES WITHOUT WARRANTY OF ANY KIND.

=head1 LICENSE

The Java::SJ module is Copyright (c) 2003 Nigel Rantor. England. All rights
reserved.

You may distribute under the terms of either the GNU General Public License
or the Artistic License, as specified in the Perl README file.

=head1 AUTHORS

Nigel Rantor <F<wiggly@wiggly.org>>

=head1 SEE ALSO

L<Java::SJ::Config>.

=cut
