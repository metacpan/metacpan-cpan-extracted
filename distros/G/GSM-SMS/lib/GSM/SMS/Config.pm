package GSM::SMS::Config;
use strict;
use vars qw( $REVISION $VERSION @EXPORT );

use base qw( Exporter );
@EXPORT = qw( &setup &generate_config );

use Carp;
use Log::Agent;
use ExtUtils::MakeMaker qw( prompt );
use Config;
use File::Path;
use File::Spec;

$VERSION = "0.161";
$REVISION = '$Revision: 1.6 $';

=head1 NAME

GSM::SMS::Config - Implements a simple .ini style config.

=head1 DESCRIPTION

Implements a simple configuration format. Used mainly for the transports 
config file.

The configuration format is defined as follows

  ^#         := comment
  ^[.+]$     := start block
  ^.+=.+$    := var, value pair
  
The structure allows attribute (configuration) access as follows

  $_preferences->{$blockname}->{$var}=$value
  $blockname = ( 'default', <blocknames> }

=head1 METHODS

=over 4

=item B<new> - The constructor

  my $cfg = GSM::SMS::Config->new(
               -file => $config_file, # Optional otherwise take default config
			   -check => 1            # Optional, does a sanity check
			);

=cut

my $Config_defaults = {};
if ( $^O =~ /^MSWin/ ) {
	$Config_defaults->{'logdir'} = "C:\\gsmsms\\log";
	$Config_defaults->{'spool'} = "C:\\gsmsms\\spool";
	$Config_defaults->{'port'} = 'COM1';
	$Config_defaults->{'filetransport'} = "C:\\gsmsms\\filetransport";
} else {
	$Config_defaults->{'logdir'} = "/var/log/gsmsms";
	$Config_defaults->{'spool'} = "/var/spool/gsmsms";
	$Config_defaults->{'port'} = '/dev/ttyS0';
	$Config_defaults->{'filetransport'} = "/tmp/filetransport";
}

sub new {
	my ($proto, %arg) = @_;

	my $class = ref($proto) || $proto;

	my $self = {
			_config_file => $arg{-file},
			_check => $arg{-check}
	};

	bless $self, $class;

	$self->read_config( $self->{_config_file}, $self->{_check} );

	return $self;
}

=item B<setup> - run the setup script

=cut

sub setup {
	my $config = _config_wizard();

	if ($config) {
		require File::Spec;
		my $config_file = File::Spec->catfile(
			$Config{'installsitelib'}, "GSM", "SMS", "Config", "Default.pm"
		);		
		open OUT, ">$config_file" or die "$!: $config_file";
		print OUT $config;
		close OUT;
		print "Config saved.\n";
	}
}

=item B<save_default> - save this configuration as the default

=cut

sub save_default {
	my ($self) = @_;

}

=item B<read_config> - read a configuration file

=cut

sub read_config {
	my ($self, $filename, $check) = @_;
	my $config = {};
	
	# prepare default config
	my $hook = {};
	$config->{'default'} = [];
	push(@{$config->{'default'}}, $hook);
	
	# open config file
	local(*F);
	
	if ( $filename ) {
		
		logdbg "debug", "Reading config from a specific file ($filename)";
		
		open F, $filename or do 
							 { 
								logcroak "Could not open config file $filename ($!)"; 
								return undef 
							 };

		while (<F>) {
			chomp;					# loose trailing newline
			s/#.*//;				# loose comments
			s/^\s+//;				# loose leading white
			s/\s+$//;				# loose trailing white;
			next unless length;		# did we loose everything?
			
			# recon block or var/value pair ...
			if ( /\[(.+?)\]/ ) {
				$hook =  {} ;
				$config->{$1} = [];
				push( @{$config->{$1}}, $hook );
			} else {
				my ($var, $value) = split(/\s*=\s*/, $_, 2);
				$hook->{$var} = $value;
			}
		}
		close F if $filename;

	} else {

		logdbg "debug", "Getting default configuration.";
	
		require GSM::SMS::Config::Default;
		$config = $GSM::SMS::Config::Default::Config;
	}
	$self->{_config} = $config;

	return undef unless $check && $self->is_sane();

	return $config;
}

=item B<is_sane> - check if a configuration complies with some rules

=cut

sub is_sane {
	my ($self) = @_;

	my $config = $self->{_config};

	# we need a spool_dir for the transports ...
	unless (defined $self->get_value( undef, 'spooldir' ))
	{
		logcroak "insane config: 'spooldir' is mandatory in config file";
		return undef;
	}

	# we need a router object for the transports
	unless (defined $self->get_value( undef, 'router' ))
	{
		logcroak "insane config: 'router' is mandatory in config file";
		return undef;
	}

	# we also need to know here we want the logfiles ... although this can be
	# application specific
	unless (defined $self->get_value( undef, 'log' ))
	{
		logcroak "insane config: 'log' is mandatory in config file";
		return undef;
	}
	
	# we need at least one defined transport ...
	if (keys(%{$config}) <= 1)
	{ 
		logcroak "insane config: We need at least one defined transport";
		return undef;
	}

	return 1;
}

=item B<get_section_names> - Get an array of all the section names

=cut

sub get_section_names {
	my ($self) = @_;

	return keys %{$self->{_config}};
}


=item B<get_config> - get a specific config file section

  $config->get_config( 'default' );
  $config->get_config( 'Serial01' );

=cut

sub get_config {
	my ($self, $name) = @_;
	
	return ${$self->{_config}->{$name}}[0];
}

=item B<get_value> - get the config value for that section

  $value = $config->get_value($section, $name);

=cut

sub get_value {
	my ($self, $section, $name) = @_;

	$section = $section || 'default';

	return ${$self->{_config}->{$section}}[0]->{$name};
}

=item B<generate_config> - Generate a boilerplate config file

  perl -MGSM::SMS::Config -egenerate_config


This method prints out a boilerplate config file starting from the settings
in the default configuration.

Use this as a starting point to generate the configuration files for the examples.

=cut

sub generate_config {
	my $cfg = GSM::SMS::Config->new;		

print <<"EOT";
#### GSM::SMS configuration file
#
# Generated by GSM::SMS::Config ($REVISION)
#

EOT

	# default first
	my $default = $cfg->get_config( 'default' );
	foreach my $key (keys %{$default}) {
		print $key . " = " . $default->{$key} . "\n";
	}

	foreach my $section ($cfg->get_section_names) {
		if ( $section ne 'default' ) {
			print "\n[$section]\n";
			my $section_cfg = $cfg->get_config( $section );
			foreach my $key (keys %{$section_cfg}) {
				print "\t" . $key . " = " . $section_cfg->{$key} . "\n";
			}
		}
	}
}

=item B<_config_wizard> - The actual question asking mind boggling configurator

This method implements a console based configuration script for the package.
It will generate a site-wide config file that will be the default when instantiating a L<GSM::SMS::NBS> class.

=cut

sub _config_wizard {
	my $config = '';

	print <<EOT;
   
     ____ ____  __  __     ____  __  __ ____
    / ___/ ___||  \\/  |_ _/ ___||  \\/  / ___|
   | |  _\\___ \\| |\\/| (_|_)___ \\| |\\/| \\___ \\
   | |_| |___) | |  | |_ _ ___) | |  | |___) |
    \\____|____/|_|  |_(_|_)____/|_|  |_|____/

        Perl Modules For Smart Messaging


Welcome to the GSM::SMS package! Thanks for using it!

This configuration script gives you the possibility to configure the
default settings of the system. You can override these settings by
providing a configuration file when using the package.

EOT

	# Check for Device::SerialPort or Win32::SerialPort
	if ( $^O =~ /^MSWin/ ) {
		unless( eval "require Win32::SerialPort" ) {
			print "You don't have Win32::SerialPort installed!\nPlease install if you want to use a GSM modem\n\n";
		}
	} else {
		unless( eval "require Device::SerialPort" ) {
			print "You don't have Device::SerialPort installed!\nPlease install if you want to use a GSM modem\n\n";
		}
	}

	my $in;
	$in = prompt('Do you want to configurate the package? (y|n)', 'n');
	return if $in =~ /[nN]/;
	print "Let's ask some questions ...\n\n";

	# Configurate system wide settings

	# 1. logfiles
	my $path_default = $Config_defaults->{'logdir'};
	my $logdir = prompt("Where do you want the logfile(s)?", $path_default);
	_create_directory( $logdir ) unless (stat($logdir));

	# 2. Spool directory
	my $spool_default = $Config_defaults->{'spool'};
	my $spooldir = prompt("Where do you wish to keep the spool directory?", $spool_default);
	_create_directory( $spooldir ) unless (stat($spooldir));

	# 3. Test GSM number
	$in = prompt( "Mobile phone number to receive the tests on (leave empty for no sending)" );
	my $testgsm = $in;

	# create config file - generic part
	$config .= <<EOT;
package GSM::SMS::Config::Default;

\$Config = {	
	'default' => [
					{
					'router' => 'Simple',
					'spooldir' => '$spooldir',
					'log' => '$logdir',
					'testmsisdn' => '$testgsm'
					}
				 ],
EOT
	
	# 3. Transports
	print "\nWe're going to configure the transports\n\n";

	# 3.1 Serial
	$in = prompt( "Do you have a serial transport? (y/n)", "n");
	if ( $in =~ /y/i ) {
		$config .= _config_transport_serial();
	}

	# 3.2 NovelSoft
	print "\n";
	$in = prompt( "Do you have a NovelSoft account? (y/n)", "n" );
	if ( $in =~ /y/i ) {
		$config .= _config_transport_novelsoft();
	}

	# 3.3 MCube
	print "\n";
	$in = prompt( "Do you have an MCube account? (y/n)", "n" );
	if ( $in =~ /y/i ) {
		$config .= _config_transport_mcube();
	}

	# 3.4 File
	print "\n";
	$in = prompt( "Do you want the file test transport activated? (y/n)", "y" );
	if ( $in =~ /y/i ) {
		$config .= _config_transport_file();
	}

	$config .= <<EOT;

	};
1;
EOT

	return $config;
}

=item B<_config_transport_serial> - Gather config parameters for the serial transport

=cut

sub _config_transport_serial {
		my $config = '';
		my ($in, $name, $port, $csca, $pincode, $baud, $originator, $memory, $acl );
		do {
			do {
				$name = prompt( "What's the name?", "serial01" );
				$port = prompt( "What's the port?", $Config_defaults->{'port'} );
				$csca = prompt( "What's the CSCA?", "+32475161616" );
				$pincode = prompt( "What's the pincode?", "0000" );
				$baud = prompt( "What's the baudrate?", "9600" );
				$originator = prompt( "What's the originator?", "GSM::SMS" );
				$memory = prompt( "How big is the SMS memory?", "10" );
				$acl = prompt( "What's the access control list regex?", ".*" );

				print <<EOT;
Serial transport summary
------------------------

name:           $name
port:           $port
csca:           $csca
pincode:        $pincode
baudrate:       $baud
originator:     $originator
memory:         $memory
acl:            $acl

EOT
				$in = prompt( 'Is this correct? (y/n)', 'y' );
			} while ( $in =~ /n/i );
	
			$config .= <<EOT;

'$name' => [
			{
			'type' => 'Serial',	
			'name' => '$name',
			'pin_code' => '$pincode',
			'csca' => '$csca',
			'serial_port' => '$port',
			'baud_rate' => '$baud',
			'originator' => '$originator',
			'match' =>	'$acl',
			'memorylimit' => '$memory'
			}
		   ],
EOT

			print "Serial $name saved\n\n";
			$in = prompt( 'Do you want to configure another serial transport? (y/n)', 'n');
		} while ( $in =~ /y/i );

	return $config;
}

=item B<_config_transport_novelsoft> - Gather NovelSoft config info

=cut

sub _config_transport_novelsoft {
	my $config = '';
	my ($in, $user, $password, $proxy, $acl, $originator);
	do {
		$user = prompt( "What's your account name?" );
		$password = prompt( "What's your account password?" );
		$proxy = prompt( "Give url of http proxy, if any." );
		$originator = prompt( "What's the originator?", "GSM::SMS" );
		$acl = prompt( "What's the access control list regex?", ".*" );

		print <<EOT;
Novelsoft summary
-----------------

user:         $user
password:     $password
proxy:        $proxy
originator:   $originator
acl:          $acl
		
EOT

		$in = prompt( 'Is this correct? (y/n)', 'y' );
	} while ( $in =~ /n/i );
	$config .= <<EOT;
'NovelSoft' => [
				{
				'type' => 'NovelSoft',
				'name' => 'NovelSoft',
				'proxy' =>	'$proxy',
				'userid' => '$user',
				'password' => '$password',
				'originator' => '$originator',
				'smsserver' =>	'http://clients.sms-wap.com:80/cgi/csend.cgi',
				'backupsmsserver' => 'http://clients.sms-wap.com:80/cgi/csend.cgi',
				'match' =>	'$acl'
				}
			   ],

EOT
	return $config;
}

=item B<_config_transport_mcube> - Gather MCube specific config params

=cut

sub _config_transport_mcube {
	my $config = '';
	my ($in, $user, $password, $proxy, $acl, $originator);
	do {
		$user = prompt( "What's your account name?" );
		$password = prompt( "What's your account password?" );
		$proxy = prompt( "Give url of http proxy, if any." );
		$originator = prompt( "What's the originator?", "GSM::SMS" );
		$acl = prompt( "What's the access control list regex?", ".*" );

		print <<EOT;
MCube summary
-------------

user:         $user
password:     $password
proxy:        $proxy
originator:   $originator
acl:          $acl
		
EOT

		$in = prompt( 'Is this correct? (y/n)', 'y' );
	} while ( $in =~ /n/i );
	$config .= <<EOT;

'MCube' => [
			{
			'type' => 'MCube',
			'name' => 'MCube',
			'proxy' =>	'$proxy',
			'userid' => '$user',
			'password' =>	'$password',
			'originator' => '$originator',
			'smsserver' =>	'http://www.m3.be/scripts/httpgate1.cfm',
			'match' =>	'$acl'
			}
		   ],
EOT

	return $config;
}

=item B<_config_transport_file> - Configure the file transport

=cut

sub _config_transport_file {
	my $config = '';
	my ($in, $acl, $originator, $directory);

	do {
		$directory = prompt("Directory to put the files", 
								$Config_defaults->{'filetransport'});
		_create_directory( $directory ) unless (stat($directory));

		$originator = prompt( "What's the originator?", "GSM::SMS" );
		$acl = prompt( "What's the access control list regex?", "^555" );

		print <<EOT;
File transport summary
----------------------

out directory: $directory
originator:    $originator
acl:           $acl
		
EOT

		$in = prompt( 'Is this correct? (y/n)', 'y' );
	} while ( $in =~ /n/i );
	$config .= <<EOT;

'File' => [
			{
			'type' => 'File',
			'name' => 'File',
			'out_directory' => '$directory',
			'originator' => '$originator',
			'match' =>	'$acl'
			}
		  ],
EOT

	return $config;
}

=item B<_create_directory> - Creates a directory

This method will ask you if you want to create a directory, and creates it.

=cut

sub _create_directory {
	my ($dir) = @_;
	
	print "The directory <$dir> does not exist.\n";
	my $yn;
	do {
		$yn = prompt( "Do you want to create it? (y/n)", 'y');
	} while ( $yn !~ /[nNyY]/ );
	mkpath( $dir, 1, 0777) if ( $yn =~ /y/i );	
}

1; 

=head1 AUTHOR

Johan Van den Brande <johan@vandenbrande.com>

=cut
