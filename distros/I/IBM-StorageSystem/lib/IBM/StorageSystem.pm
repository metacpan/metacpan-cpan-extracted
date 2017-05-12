package IBM::StorageSystem;

use strict;
use warnings;

use IBM::StorageSystem::Array;
use IBM::StorageSystem::Disk;
use IBM::StorageSystem::Drive;
use IBM::StorageSystem::Enclosure;
use IBM::StorageSystem::Export;
use IBM::StorageSystem::Fabric;
use IBM::StorageSystem::FileSystem;
use IBM::StorageSystem::Health;
use IBM::StorageSystem::Host;
use IBM::StorageSystem::Interface;
use IBM::StorageSystem::IOGroup;
use IBM::StorageSystem::Mount;
use IBM::StorageSystem::Node;
use IBM::StorageSystem::Pool;
use IBM::StorageSystem::Replication;
use IBM::StorageSystem::Service;
use IBM::StorageSystem::Task;
use IBM::StorageSystem::Quota;
use IBM::StorageSystem::VDisk;
use IBM::StorageSystem::Statistic;
use IBM::StorageSystem::StatisticsSet;
use IBM::StorageSystem::Statistic::ClusterThroughput;
use IBM::StorageSystem::Statistic::ClusterClientThroughput;
use IBM::StorageSystem::Statistic::ClusterCreateDeleteLatency;
use IBM::StorageSystem::Statistic::ClusterCreateDeleteOperations;
use IBM::StorageSystem::Statistic::ClusterOpenCloseLatency;
use IBM::StorageSystem::Statistic::ClusterOpenCloseOperations;
use IBM::StorageSystem::Statistic::ClusterReadWriteLatency;
use IBM::StorageSystem::Statistic::ClusterReadWriteOperations;
use IBM::StorageSystem::Statistic::Node::Memory;
use IBM::StorageSystem::Statistic::Node::CPU;
use IBM::StorageSystem::Statistic::Pool::Throughput;
use Net::OpenSSH;
use Carp qw(croak);

our $VERSION = '0.045';

our @ATTR = qw(auth_service_cert_set auth_service_configured auth_service_enabled 
auth_service_pwd_set auth_service_type auth_service_url auth_service_user_name 
bandwidth cluster_isns_IP_address cluster_locale cluster_ntp_IP_address code_level 
console_IP email_contact email_contact2 email_contact2_alternate email_contact2_primary 
email_contact_alternate email_contact_location email_contact_primary email_reply 
email_state gm_inter_cluster_delay_simulation gm_intra_cluster_delay_simulation 
gm_link_tolerance gm_max_host_delay has_nas_key id id_alias inventory_mail_interval 
iscsi_auth_method iscsi_chap_secret layer location name partnership rc_buffer_size 
relationship_bandwidth_limit space_allocated_to_vdisks space_in_mdisk_grps 
statistics_frequency statistics_status stats_threshold tier tier_capacity tier_free_capacity 
time_zone total_allocated_extent_capacity total_free_space total_mdisk_capacity 
total_overallocation total_used_capacity total_vdisk_capacity total_vdiskcopy_capacity);

our @STAT = qw(compression_cpu_pc cpu_pc drive_r_io drive_r_mb drive_r_ms drive_w_io 
drive_w_mb drive_w_ms fc_io fc_mb iscsi_io iscsi_mb mdisk_r_io mdisk_r_mb mdisk_r_ms 
mdisk_w_io mdisk_w_mb mdisk_w_ms sas_io sas_mb total_cache_pc vdisk_r_io vdisk_r_mb 
vdisk_r_ms vdisk_w_io vdisk_w_mb vdisk_w_ms write_cache_pc);

$|++;

foreach my $attr ( @ATTR ) {
        {   
	no strict 'refs';
	*{ __PACKAGE__ .'::'. $attr } = sub {
		my( $self, $val ) = @_; 
		$val =~ s/\#/no/ if $val; 
		$self->{$attr} = $val if $val;

		return $self->{$attr}
	}           
        }           
}

foreach my $stat ( @STAT ) { 
	{ 
	no strict 'refs'; 
	*{ __PACKAGE__ .'::'. $stat } = sub {
		my $self = shift;
		$self->stats_threshold or return $self->{$stat};

		return ( ( time - $self->{$stat}->{ts} ) > $self->stats_threshold 
			? $self->{$stat}->refresh
			: $self->{$stat} )
	} 
	} 
}

our $STATS = { 
                cluster_throughput => {
                        cmd     => '-g cluster_throughput',
                        class   => 'IBM::StorageSystem::Statistic::ClusterThroughput'
		},
                cluster_client_throughput => {
                        cmd     => '-g client_throughput',
                        class   => 'IBM::StorageSystem::Statistic::ClusterClientThroughput'
		},
		cluster_create_delete_latency => {
			cmd	=> '-g cluster_create_delete_latency',
			class	=> 'IBM::StorageSystem::Statistic::ClusterCreateDeleteLatency'
		},
		cluster_create_delete_operations => {
			cmd	=> '-g cluster_create_delete_operations',
			class	=> 'IBM::StorageSystem::Statistic::ClusterCreateDeleteOperations'
		},
		cluster_open_close_latency => {
			cmd	=> '-g cluster_open_close_latency',
			class	=> 'IBM::StorageSystem::Statistic::ClusterOpenCloseLatency'
		},
		cluster_open_close_operations => {
			cmd	=> '-g cluster_open_close_operations',
			class	=> 'IBM::StorageSystem::Statistic::ClusterOpenCloseOperations'
		},
		cluster_read_write_operations => {
			cmd	=> '-g cluster_read_write_operations',
			class	=> 'IBM::StorageSystem::Statistic::ClusterReadWriteOperations'
		},
		cluster_read_write_latency => {
			cmd	=> '-g cluster_read_write_latency',
			class	=> 'IBM::StorageSystem::Statistic::ClusterReadWriteLatency'
		}
};

foreach my $stat ( keys %{ $STATS } ) { 
        {   
        no strict 'refs';
        *{ __PACKAGE__ .'::'. $stat } = 
        sub {
                my( $self, $t ) = @_; 
                $t ||= 'minute';
                my $stats = $self->__lsperfdata( cmd   => "$STATS->{$stat}->{cmd} -t $t",
                                                 class => $STATS->{$stat}->{class} 
					       );
                return $stats
        }   
        }   
}


# Our object hash for programmatic generation of methods.
#
# Each hash represents an object type that we will generate methods for - for example, given the below;
#
# 	drive => 
#		bcmd	=> 'lsdrive -nohdr -delim :',
#		cmd	=> 'lsdrive',
#		id	=> 'id',
#		class	=> 'IBM::StorageSystem::Drive',
#		type	=> 'drive'
#	},
#
# drive	- 	is the object type - in this case a drive in Storwize nomenclature representing a physical
# 		hard drive.
#
# bcmd	-	is the base cmd to be executed in the Storwize CLI to retrieve a list of drive objects.  This
#		parameter is only required for object types where object enumeration is required as a prequisite
#		to execution of object specific commands.
#
#		Using the example above for 'lsdrive -nohdr -delim :', the base cmd is necessary to first enumerate
#		all drives to obtain a summary listing of all drives and their ID's.  The ID's can then be used in
#		the 'cmd' command (e.g. lsdrive 1) to obtain detailed information on each drive.  
#
#		As there is no way in which to obtain detailed information of some objects without specifying the
#		object ID, the bcmd is necessary to first produce a list of these ID's.  Contrast the operation of
#		the lsdrive command and the need for an ID parameter to obtain detailed information with the operation
#		of the lsnode command, which provides detailed information on all nodes without any parameters.
#
#		*NOTE* that the bcmd is	not necessary for all objects - only those which there is no single command 
#		to produce a detailed listing without specifying an ID type parameter.  Note also, that you probably
#		want to specify additional options to the bcmd command (like -nohdr and -delim :) to prevent header
#		information from being parsed.
#
# cmd	-	is the CLI command that will be used to retrieve information about the object.  *NOTE* the above information
#		on the use of the bcmd value and how this command works in conjunction with it.
#
# id	-	is a single field in the CLI command output (or multiple fields concatenated by colon) that is 
#		able to uniquely identify each object in a global context for this object type.  For example; 
#		in a systems with more than one enclosure it is necessary to identify an enclosure PSU by specifying 
#		both the enclosure id and the PSU id - e.g. Enclosure 2, PSU 1 - which when separated by a colon 
#		would become 2:1 which is sufficient to uniquely identify a enclsoure PSU in a system of any number
#		of enclosures.
#
# class	-	the Perl package namespace into which this object will be blessed as a class.
#
# type	-	the 'type' of object - this is usually the same as the root key type, however it must also be
#		globally unique within this class.  This value is used internally to implement object caching
#		and is not used in method naming so need not necessarily intuitive to a user.
#
# sl	-	this optional parameter is used to designate the CLI command output type as 'single-line' - this
#		is in contrast to 'multi-line' output.  In general, CLI command output falls into two categories;
#		'single-line' output contains output on multiple objects with each line representative of a unique
#		object - this may also be referred to as 'row-based' data.  An example of such output is the 'lsnode'
#		command.
#
#		'multi-line' output contains output about a single object as key-value pairs over multiple lines,
#		may also be referred to as 'columnar' data.  An output of such output is the 'lsdrive' command when
#		executed with a valid drive id parameter (e.g. lsdrive 1).
#
#		By default, CLI commands are assumed to use columnar output, so it is necessary for any commands
#		using row-based output to also specify a true value for the 'sl' key to ensure that the output is 
#		parsed correctly.  CLI commands that output columnar data should not specify this command.

our $OBJ = {	drive => {
			bcmd	=> 'lsdrive -nohdr -delim :',
			cmd	=> 'lsdrive -bytes',
			id	=> 'id',
			class	=> 'IBM::StorageSystem::Drive',
			type	=> 'drive'
		},
		vdisk => {
			bcmd	=> 'lsvdisk -nohdr -delim :',
			cmd	=> 'lsvdisk -bytes',
			id	=> 'id',
			class	=> 'IBM::StorageSystem::VDisk',
			type	=> 'vdisk'
		},
		disk => {
			cmd	=> 'lsdisk -Y -v',
			id	=> 'Name',
			class	=> 'IBM::StorageSystem::Disk',
			type	=> 'disk',
			sl	=> 1
		},
		enclosure => {
			bcmd	=> 'lsenclosure -nohdr -delim :',
			cmd	=> 'lsenclosure',
			id	=> 'id',
			class	=> 'IBM::StorageSystem::Enclosure',
			type	=> 'enclosure'
		},
		host => {
			bcmd    => 'lshost -nohdr -delim :',
			cmd     => 'lshost',
			id      => 'id',
			class   => 'IBM::StorageSystem::Host',
			# so we don't clobber IBM::StorageSystem::host variable
			type    => 'IBM::StorageSystem::Host::host'
		},
		enclosurebattery => {
			cmd     => 'lsenclosurebattery -delim :',
			id      => 'enclosure_id:battery_id',
			class   => 'IBM::StorageSystem::EnclosureBattery', 
			type    => 'enclosurebattery',
			sl      => 1
		},
		fabric => {
			cmd     => 'lsfabric -delim :',
			id      => 'local_wwpn:remote_wwpn',
			class   => 'IBM::StorageSystem::Fabric', 
			type    => 'fabric',
			sl      => 1
		},
		array => {
			bcmd	=> 'lsarray -nohdr -delim :',
			cmd	=> 'lsarray -bytes',
			id	=> 'mdisk_id',
			class	=> 'IBM::StorageSystem::Array', 
			type 	=> 'array'
		},
		export => {
			cmd	=> 'lsexport -Y -v',
			id	=> 'Name:Path',
			class	=> 'IBM::StorageSystem::Export',
			type	=> 'export',
			sl	=> 1
		},
		mount => {
			cmd	=> 'lsmount -Y -v',
			id	=> 'File_system',
			class	=> 'IBM::StorageSystem::Mount',
			type	=> 'mount',
			sl	=> 1
		},
		node => {
			cmd	=> 'lsnode -Y -v',
			id	=> 'Hostname',
			class	=> 'IBM::StorageSystem::Node',
			type	=> 'node',
			sl	=> 1
		},
		health => {
			cmd	=> 'lshealth -Y',
			id	=> 'Host:Sensor',
			class	=> 'IBM::StorageSystem::Health',
			type	=> 'health',
			sl	=> 1
		},
		iogroup => {
			bcmd	=> 'lsiogrp -nohdr -delim :',
			cmd	=> 'lsiogrp -bytes',
			id	=> 'id',
			type	=> 'iogroup',
			class	=> 'IBM::StorageSystem::IOGroup'
		},
		filesystem => {
			cmd	=> 'lsfs -Y -v',
			id	=> 'Device_name',
			class	=> 'IBM::StorageSystem::FileSystem',
			type	=> 'fs',
			sl	=> 1
		},
		service => {
			cmd	=> 'lsservice -Y',
			id	=> 'Name',
			class	=> 'IBM::StorageSystem::Service',
			type	=> 'service',
			sl	=> 1
		},
		task => {
			cmd	=> 'lstask -Y -v',
			id	=> 'Name',
			class	=> 'IBM::StorageSystem::Task',
			type	=> 'task',
			sl	=> 1
		},
		replication => {
			cmd	=> 'lsrepl -Y',
			id	=> 'log_Id',
			class	=> 'IBM::StorageSystem::Replication',
			type	=> 'replication',
			sl	=> 1
		},
		quota => {
			cmd	=> 'lsquota -Y',
			id	=> 'Cluster:Device:Type:ID',
			class	=> 'IBM::StorageSystem::Quota',
			type	=> 'quota',
			sl	=> 1
		},
		interface => {
			cmd	=> 'lsnwinterface -x -Y',
			id	=> 'Node:Interface',
			class	=> 'IBM::StorageSystem::Interface',
			type	=> 'interface',
			sl	=> 1
		},
		pool => {
			cmd	=> 'lspool -Y',
			id	=> 'Filesystem:Name',
			class	=> 'IBM::StorageSystem::Pool',
			type	=> 'pool',
			sl	=> 1
		}
	};

foreach my $obj ( keys %{ $OBJ } ) {
	{
	no strict 'refs';
	my $m = 'get_'.$obj.'s';

	*{ __PACKAGE__ ."::$obj" } = sub { 
		my ( $self, $id ) = @_;

		return ( $self->{$obj}->{$id}	? $self->{$obj}->{$id} 
						: $self->$m( $id ) )
	};

	*{ __PACKAGE__ .'::get_'. $obj } = sub { 
		return $_[0]->$m( $_[1] ) 
	};

	if ( $OBJ->{$obj}->{sl} ) {
		*{ __PACKAGE__ . "::$m" } = sub {
			my ( $self, $id ) = @_;
			my %args = (	cmd	=> $OBJ->{$obj}->{cmd}, 
					class	=> $OBJ->{$obj}->{class}, 
					type	=> $OBJ->{$obj}->{type}, 
					id	=> $OBJ->{$obj}->{id} 
			);
			my @res = $self->__get_sl_objects( %args );
			
			return ( defined $id ? $self->{ $OBJ->{$obj}->{type} }->{$id} : @res )
		}
	}
	else {
		*{ __PACKAGE__ . "::$m" } = sub {
			my ( $self, $id ) = @_;
			my @objs = map { ( split /:/, $_ )[0] } 
				   split /\n/, $self->__cmd( $OBJ->{$obj}->{bcmd} );

			my %args = (	cmd	=> $OBJ->{$obj}->{cmd}, 
					objects => [@objs], 
					id	=> $OBJ->{$obj}->{id}, 
					class	=> $OBJ->{$obj}->{class}, 
					type	=> $OBJ->{$obj}->{type} 
			);
			my @res = $self->__get_ml_objects( %args );

			return ( defined $id ? $self->{ $OBJ->{$obj}->{type} }->{$id} : @res )
		}
	}
	}
}

sub new {
	my ($class, %args) = @_;
	my $self = bless {} , $class;
	$args{user}	? $self->{user}	= $args{user}		: croak 'Mandatory parameter "user" not given';
	$args{host}	? $self->{host}	= $args{host}		: croak 'Mandatory parameter "host" not given';
	$args{key_path}	? $self->{key_path} = $args{key_path}	: croak 'Mandatory parameter "key_path" not given';
	my %opts = ( user => $self->{user}, key_path => $self->{key_path}, batch_mode => 1, master_opts => '-q' );
	$self->{ssh} = Net::OpenSSH->new( $args{host}, %opts );
	$self->{ssh}->error and croak 'Could not create Net::OpenSSH object: ' . $self->{ssh}->error . "\n";

	unless ( $args{no_stats} ) {
		$self->__lssystem;
		$self->refresh_system_stats;
		$self->{stats_threshold} = ( $args{stats_threshold} ? $args{stats_threshold} : 0 );
	}

	return $self
}

sub refresh_system_stats {
	my $self = shift;

	foreach my $stat ( splice @{ [ split /\n/, $self->__cmd( 'lssystemstats -gui -delim :' ) ] }, 1 ) {
		my ( $name, $epoch, $current, $peak, $peak_time, $peak_epoch ) = split /:/, $stat;
		$self->{$name} = IBM::StorageSystem::Statistic->new(	$self, 
									name	=> $name, 
									epoch	=> $epoch, 
									current => $current,
									peak	=> $peak, 
									peak_time => $peak_time, 
									peak_epoch => $peak_epoch 
								);
	}
}

sub __lssystem {
	my $self = shift;
	my ( %a, %dkeys );
	my @output = split /\n/, ( split /\n\n/, $self->__cmd( 'lssystem' ) )[0];
	%dkeys = map { $_ => $dkeys{ $_ }++ } 
		 map { ( split /\s/, $_ )[0] } @output;

	for ( @output ) {
		last if /^\s*$/;
		s/$/ -/;
		my ( $var, $val ) = ( split /\s/ )[0,1];

		if ( $dkeys{ $var } >= 1 ) { 
			push @{ $self->{$var} }, $val 
		}
		else { 
			$self->{$var} = $val 
		}
	}

	return $self
}

sub __lsperfdata {
	my ( $self, %args ) = @_;
	my $stats = IBM::StorageSystem::StatisticsSet->new;
	my @output = split /\n/, $self->__cmd( "lsperfdata $args{cmd}" );
	shift @output;
	pop @output;

	foreach my $line ( @output ) {
		my @values = split /,/, $line;
		$stats->__push( $args{class}->new( @values ) )
	}

	return $stats;
}

sub __cmd { 
	return $_[0]->{ssh}->capture( $_[1] ) 
}

# __get_sl_objects - Get Single Line Objects
# This method is used to parse CLI output where information is returned 
# in a row-based format - e.g.
#
#	Column_1, Column_2, Column_3, ... Column_N
#	Value_1 , Value_2,  Value_3,  ... Value_N
#	Value_1 , Value_2,  Value_3,  ... Value_N
#	Value_1 , Value_2,  Value_3,  ... Value_N
#
# To parse this data into an array of objects, we treat each row as a single object.
# We split the column headers on a delimeter (usually :) and use each header as a hash
# key for the corresponding value in each row - i.e.
#
#	Column_1 => Value_1,
#	Column_2 => Value_2 ...etc.
#
# Each hash is then passed to the constructor for this object type (given as the 'class'
# argument in our %args hash), and the resultant object conditionally cached within our 
# IBM::StorageSystem object and pushed onto our returned array.
#
# Note that this method includes a slight hack to cater for the lack of non-unique per-object
# keys in CLI output for some object types.  In this scenario it is necessary to create
# a unique key via composite fields concatenated with a colon.

sub __get_sl_objects {
	my( $self, %args ) = @_;
	my @objs = split /\n/, $self->__cmd( $args{ cmd } );
	my @headers = map { s/ /_/g; s/\.//g; $_ } 
		      split /:/, shift @objs;
	my @res;

	foreach my $object ( @objs ) {
		my (%a, $c);
		
		foreach my $val ( split /:/, $object ) {
			$c++;
			next if $headers[ $c - 1 ] =~ /^(lsnode|lsexport|lshealth|lsfs|SensorSummary|Share|CtdbHost|HEADER|reserved)$/;
			$a{ $headers[ $c - 1 ] } = $val
		}

		if ( $args{ id } =~ /:/ ) { 
			my ($nid, $nval);

			foreach my $id ( split /:/, $args{ id } ) {
				$nid .= ":$id"; $nval .= ":$a{ $id }" 
			}

			$nid =~ s/^://; $nval =~ s/^://;
			$a{ $nid } = $nval
		}

		my $obj = $args{ class }->new( $self, %a );
		$self->{ $args{ type } }->{ $a{ $args{ id } } } = $obj unless $args{ nocache };
		push @res, $obj
	}

	return @res
}

# __get_ml_objects - Get Multi-Line Objects
# This method is used to parse CLI command where detailed information on
# single object is returned in a columnar format - e.g.
#
#	Column_1	Value_1
#	Column_2	Value_2
#	...		...
#	Column_N	Value_N
#
# To parse this data we split the output on a delimiter (usually whitespace)
# and treat each row as a name,value hash pair for an attribute of a single object.
# For example, the above example output would become:
#
#	Column_1 => Value_1,
#	Column_2 => Value_2,
#	...
#	Column_N => Value_N,
#
# The resultant hash is passed as the argument to the constructor of the type
# specified by the $args{ class } value and the resultant object is optionally cached 
# in our and pushed onto the return array.
#
# Things to note in this sub include the hack required to handle non-unique column names.
# For example; an 'lsfabric' output may include multiple 'WWPN' columns, so it is 
# neccesary to identify duplicate column names and treat the corresponding hash values
# as anonymous arrays rather than scalars.

sub __get_ml_objects {
	my ( $self, %args ) = @_;
	my @res;
	
	foreach my $object ( @{ $args{ objects } } ) {
		my ( %a, %dkeys );
		my @output = split /\n/, ( split /\n\n/, $self->__cmd( "$args{ cmd } $object" ) )[0];
		%dkeys = map { $_ => $dkeys{ $_ }++ } 
			 map { ( split /\s/, $_ )[0] } @output;

		for ( @output ) {
			last if /^\s*$/;
			s/$/ -/;
			my ( $var, $val ) = ( split /\s/ )[0,1];

			if ( $dkeys{ $var } >= 1 ) { 
				push @{ $a{ $var } }, $val 
			}
			else { 
				$a{ $var } = $val 
			}
		}

		my $obj = $args{ class }->new( $self, %a );
		$self->{ $args{ type } }->{ $a{ $args{ id } } } = $args{ class }->new( $self, %a ) unless ( $args{ nocache } );
		push @res, $obj
	}

	return @res
}

1;

__END__

=head1 NAME

IBM::StorageSystem - Perl API to IBM StorageSystem CLI

=head1 VERSION

Version 0.01

=head1 SYNOPSIS

IBM::StorageSystem is a Perl module that provides a simple API to the IBM StorageSystem CLI.

	use IBM::StorageSystem;

	# Create a IBM::StorageSystem object
	my $ibm = IBM::StorageSystem->new(	
					user		=> 'admin',
					host		=> 'my-StorageSystem',
					key_path	=> '/path/to/my/.ssh/private_key'
			) or die "Couldn't create object! $!\n";

	# Get a list of our enclosures as IBM::StorageSystem::Enclosure objects
	my @enclosures = $ibm->get_enclosures;

	# Print the status of each enclosure
	map { printf( "Enclosure %s status: %10s\n", $_->id, $_->status ) } @enclosures;

	# Get the status of each PSU in each enclosure as IBM::StorageSystem::Enclsoure::PSU objects
	map { printf( "\tPSU %s status: %s", $_->id, $_->status ) }
		map { print "--- Enclosure $_->id ---\n"; $ $_->get_psus } @enclosures;

	# Prints something like:
	# --- Enclosure 1 ---
	#     PSU 1 status: online
	#     PSU 2 status: online
	# --- Enclosure 2 ---
	#     PSU 1 status: online
	#     PSU 2 status: online
	# ...

	# Get a list of canisters in the first enclosure as IBM::StorageSystem::Enclosure::Canister objects
	my @canisters = $enclosures[0]->get_canisters;

	# Get the temperature of just the first canister in the second enclosure
	print "Temperature: ", $ibm->enclosure(2)->canister(1)->temperature, "\n";

	# Prints - Temperature: 39
    ...

=head1 METHODS

=head3 new 

	my $ibm = IBM::StorageSystem->new(	
					user		=> 'admin',
					host		=> 'my-StorageSystem',
					key_path	=> '/path/to/my/.ssh/private_key'
			) or die "Couldn't create object! $!\n";

Constructor - creates a new IBM::StorageSystem object.  This method accepts three mandatory parameters
and one optional parameter, the three mandatory parameters are:

=over 3

=item user

The username of the user with which to connect to the device.

=item host

The hostname or IP address of the device to which we are connecting.

=item key_path

Either a relative or fully qualified path to the private ssh key valid for the
user name and device to which we are connecting.  Please note that the executing user
must have read permission to this key.

=back

The optional parameter is:

=over 3

=item stats_threshold

The period in seconds for which retrieved system statistics will be considered fresh,
after which they will be re-retrieved.  If not set, the default value of this parameter
is zero meaning that the statistics are not refreshed unless done explicitly via the 
B<refresh> method of an L<IBM:StorageSystem::Statistic> object.

=back

=head3 auth_service_cert_set

Specifies if the authentication service certificate has been set.

=head3 auth_service_configured

True if the auth_service_type is configured and either one of the following is true:     

=over 3

=item * The auth_service_type is LDAP-only (if at least one LDAP server is configured)    

=item * The auth_service_type is TIP-only:                  

=over 5

=item * The name, password, and URL are established

=item * An SSL certificate is created (if an HTTPS URL is available)

=back

=back

=head3 auth_service_enabled

True if auth_service_type is configured.

=head3 auth_service_pwd_set

Specifies if the authentication password has been set.

=head3 auth_service_type

returns the authentication services type, either; Tivoli Integrated Portal (TIP) or Native Lightweight
Directory Access Protocol (LDAP)

=head3 auth_service_url

Returns the authentication services URL.

=head3 auth_service_user_name

Returns the user name used for authentication services.

=head3 bandwidth

Returns the bandwidth available on the intersystem link for background copy, in megabytes per second (MBps).

=head3 cluster_isns_IP_address

Returns the cluster ISNS IP address.

=head3 cluster_locale

Returns the cluster configured locale.

=head3 cluster_ntp_IP_address

Returns the cluster NTP service address.

=head3 code_level

Returns the cluster code level.

=head3 console_IP

Returns the cluster console IP address.

=head3 email_contact

Returns the clusters email contact information - this value is usually the system name.

=head3 email_contact2

Returns the clusters extended email contact information.

=head3 email_contact2_alternate

Returns the clusters extended alternate email contact information.

=head3 email_contact2_primary

Returns the clusters extended primary email contact information.

=head3 email_contact_alternate

Returns the clusters email contact alternate information.

=head3 email_contact_location

Returns the clusters email contact location.

=head3 email_contact_primary

Returns the clusters email contact phone number.

=head3 email_reply

Returns the clusters email reply email.

=head3 email_state

Returns the clusters email operational state.

=head3 gm_inter_cluster_delay_simulation

Returns the cluster gm inter cluster delay simulation.

=head3 gm_intra_cluster_delay_simulation

Returns the cluster gm intra cluster delay simulation.

=head3 gm_link_tolerance

Returns the cluster gm link delay tolerance in seconds.

=head3 gm_max_host_delay

Returns the cluster gm maximum host delay value.

=head3 has_nas_key

Specifies if the cluster has a NAS key configured.

=head3 id

Returns the cluster ID.

=head3 id_alias

Returns the cluster ID alias.

=head3 inventory_mail_interval

Returns the cluster inventory mail interval period in days.

=head3 iscsi_auth_method

Returns the cluster iSCSI authentication method.

=head3 iscsi_chap_secret

Returns the iSCSI CHAP secret.

=head3 layer

Returns the cluster layer type; either replication or storage (default).
Replication means the system can create partnerships with Storwize StorageSystem Unified. 
Storage means the system can present storage to Storwize StorageSystem Unified.

=head3 location

Returns the cluster location type, either local or remote.

=head3 name

Returns the cluster name.

=head3 partnership

Returns the cluster partnership type, either one of; fully_configured, partially_configured_local, 
partially_configured_local_stopped, not_present, fully_configured_stopped, fully_configured_remote_stopped,
fully_configured_local_excluded, fully_configured_remote_excluded or fully_configured_exceeded

=head3 rc_buffer_size

Returns the cluster resource buffer size assigned for Metro Mirror or Global Mirrored Copy Services.

=head3 relationship_bandwidth_limit

Returns the cluster relationship bandwidth limit in megabytes per second (MBps).

=head3 space_allocated_to_vdisks

Returns the space allocated to VDisks - this may be in a variable notation format.

=head3 space_in_mdisk_grps

Returns the space allocated to MDisk groups - this may be in a variable notation format.

=head3 statistics_frequency

Returns the statistics collection frequency interval.

=head3 statistics_status

Returns the statistics collection status.

=head3 tier

Returns an array containing the supported tier types for the cluster.

B<Note> that this method returns an array of the available tier types and that the ordering
of these types is preserved from the CLI output.  The ordering of these types can be used to 
retrieve the tier capacity of each tier type with the B<tier_capacity> command.

=head3 tier_capacity

Returns the total tier capacity for each tier type in the cluster.

B<Note> that this method returns an array of tier capacity ivalues, the index of
which corresponds with the array indexes of tier types as returned by the B<tier> method.

For example, to print each tier type and the corresponding tier capacity for this cluster:

        for ( my $i = 0; $i < scalar @{ $ibm->tier } ; $i++ ) {
                print "Tier: " . $ibm->tier->[$i] .
                        " - Capacity: " . $ibm->tier_capacity->[$i] . "\n"
        }

Returns

=head3 tier_free_capacity

Returns the free tier capacity for each tier type in the cluster.

B<Note> that like the B<tier> and B<tier_capacity> methods, this method also returns an
array of tier free capacity values, the order of which corresponds with the arrays returned
by the aforementioned methods.

=head3 time_zone

Returns the cluster time zone.

=head3 total_allocated_extent_capacity

Returns the clusters total allocated capacity - this may be in a variable notation format.

=head3 total_free_space

Returns the clusters total free space - this may be in a variable notation format.

=head3 total_mdisk_capacity

Returns the clusters total MDisk capacity - this may be in a variable notation format.

=head3 total_overallocation

Returns the cluster total overallocation limit.

=head3 total_used_capacity

Returns the clusters total used capacity - this may be in a variable notation format.

=head3 total_vdisk_capacity

Returns the clusters total VDisk capacity - this may be in a variable notation format.

=head3 total_vdiskcopy_capacity

Returns the clusters total VDisk copy capacity - this may be in a variable notation format.

=head3 compression_cpu_pc

Returns an L<IBM::StorageSystem::Statistic> object for allocated CPU capacity utilised for compression.

=head3 cpu_pc

Returns an L<IBM::StorageSystem::Statistic> object for allocated CPU capacity utilised for the system.

=head3 drive_r_io

Returns an L<IBM::StorageSystem::Statistic> object the average amount of I/O operations transferred 
per second for read operations to drives during the sample period.

=head3 drive_r_mb

Returns an L<IBM::StorageSystem::Statistic> object for the average number of megabytes transferred 
per second for read operations to drives during the sample period.

=head3 drive_r_ms

Returns an L<IBM::StorageSystem::Statistic> object for the average amount of time in milliseconds 
that the system takes to respond to read requests to drives over the sample period.

=head3 drive_w_io

Returns an L<IBM::StorageSystem::Statistic> object the average amount of I/O operations transferred 
per second for write operations to drives during the sample period.

=head3 drive_w_mb

Returns an L<IBM::StorageSystem::Statistic> object for the average number of megabytes transferred 
per second for write operations to drives during the sample period.

=head3 drive_w_ms

Returns an L<IBM::StorageSystem::Statistic> object for the average amount of time in milliseconds 
that the system takes to respond to write requests to drives over the sample period.

=head3 fc_io

Returns an L<IBM::StorageSystem::Statistic> object for the total input/output (I/O) operations 
transferred per seconds for Fibre Channel traffic on the system. This value includes 
host I/O and any bandwidth that is used for communication within the system.

=head3 fc_mb

Returns an L<IBM::StorageSystem::Statistic> object for the total number of megabytes transferred 
per second for Fibre Channel traffic on the system. This value includes host I/O and any 
bandwidth that is used for communication within the system.

=head3 iscsi_io

Returns an L<IBM::StorageSystem::Statistic> object for the total I/O operations transferred 
per second for iSCSI traffic on the system.

=head3 iscsi_mb

Returns an L<IBM::StorageSystem::Statistic> object for the total number of megabytes 
transferred per second for iSCSI traffic on the system.

=head3 mdisk_r_io

Returns an L<IBM::StorageSystem::Statistic> object for the average amount of I/O operations 
transferred per second for read operations to MDisks during the sample period.

=head3 mdisk_r_mb

Returns an L<IBM::StorageSystem::Statistic> object for the average number of megabytes transferred 
per second for read operations to MDisks during the sample period.

=head3 mdisk_r_ms

Returns an L<IBM::StorageSystem::Statistic> object for the average amount of time in milliseconds 
that the system takes to respond to read requests to MDisks over the sample period.

=head3 mdisk_w_io

Returns an L<IBM::StorageSystem::Statistic> object for the average amount of I/O operations 
transferred per second for write operations to MDisks during the sample period.

=head3 mdisk_w_mb

Returns an L<IBM::StorageSystem::Statistic> object for the average number of megabytes transferred 
per second for write operations to MDisks during the sample period.

=head3 mdisk_w_ms

Returns an L<IBM::StorageSystem::Statistic> object for the average amount of time in milliseconds 
that the system takes to respond to write requests to MDisks over the sample period.

=head3 sas_io

Returns an L<IBM::StorageSystem::Statistic> object for the total I/O operations transferred per 
second for SAS traffic on the system. This value includes host I/O and bandwidth that 
is used for background RAID activity.

=head3 sas_mb

Returns an L<IBM::StorageSystem::Statistic> object for the total number of megabytes 
transferred per second for iSCSI traffic on the system.

=head3 total_cache_pc

Returns an L<IBM::StorageSystem::Statistic> object for the total percentage for both the 
write and read cache usage for the node.

=head3 vdisk_r_io

Returns an L<IBM::StorageSystem::Statistic> object for the average amount of I/O operations 
transferred per second for read operations to volumes during the sample period.

=head3 vdisk_r_mb

Returns an L<IBM::StorageSystem::Statistic> object for the average number of megabytes 
transferred per second for read operations to MDisks during the sample period.

=head3 vdisk_r_ms

Returns an L<IBM::StorageSystem::Statistic> object for the average amount of time in 
milliseconds that the system takes to respond to read requests to MDisks over the 
sample period.

=head3 vdisk_w_io

Returns an L<IBM::StorageSystem::Statistic> object for the average amount of I/O operations 
transferred per second for read operations to drives during the sample period. 

=head3 vdisk_w_mb

Returns an L<IBM::StorageSystem::Statistic> object for the average number of megabytes transferred 
per second for read operations to drives during the sample period

=head3 vdisk_w_ms

Returns an L<IBM::StorageSystem::Statistic> object for the average amount of time in milliseconds 
that the system takes to respond to read requests to MDisks over the sample period.

=head3 write_cache_pc

Returns an L<IBM::StorageSystem::Statistic> object for the percentage of the write cache usage 
for the node.

=head3 refresh_system_stats

This method refreshes all system statistics with updated values from the system.  This
method may be handy if instantiate an IBM::StorageSystem object within a long running or non-exiting 
process and wish to either periodically retrieve updated system statistics.

B<Note> that you can call B<refresh> on individual system statistics which may have a slight
performance increase over this method.

=head3 stats_threshold

This method allows you specify the statistics threshold freshness interval in seconds. This
interval is used to determine if the value sreturned by a statistics method are fresh or
whether they should be refreshed from the atregt system.

By default this value is zero, meaning that the statistics are never refreshed unless explicitly
done so by calling the B<reefresh> method of the statistic object.  This may result in a
performance increase in situations where statistic methods are frequently used, and may also
result in more consistent reporting of the target system state as the statistic values will more
closely represent a single point in time overview of the system rather than a series of 
consecutive snapshots.

In situation where you may want to gather a set of statistical values for the target system over
a finite period, you could set the threshold value low, and reset it afterwards. e.g.

	# Print the current FC IOPS value every two seconds for a minute
	$ibm->stats_threshold = 1;
	for ( 1 .. 30 ) {
		print $ibm->fc_io_current;
		sleep 2
	}
	# Disable automatic refreshing
	$ibm->stats_threshold = 0;

=head3 cluster_throughput ( $interval )

Returns either a single, or list, of L<IBM::StorageSystem::StatisticsSet> objects containing 
L<IBM::StorageSystem::Statistics::ClusterThroughput> performance data on bytes read and written
acorss all nodes and all GPFS filesystems in the cluster.

The method accepts a single optional parameter; the time period for which to return the data.
The allowed values for this parameter are one of; minute, hour, day, week, month, quarter and year.
If omitted, this parameter will default to minute.


=head3 cluster_client_throughput ( $interval )

Returns either a single, or list, of L<IBM::StorageSystem::StatisticsSet> objects containing 
L<IBM::StorageSystem::Statistics::ClusterClientThroughput> performance data on client throughput across 
all nodes in the target cluster.

The method accepts a single optional parameter; the time period for which to return the data.
The allowed values for this parameter are one of; minute, hour, day, week, month, quarter and year.
If omitted, this parameter will default to minute.

=head3 cluster_create_delete_latency ( $interval )

Returns either a single, or list, of L<IBM::StorageSystem::StatisticsSet> objects containing 
L<IBM::StorageSystem::Statistics::ClusterCreateDeleteLatency> performance data on cluster file creation
and deletion latency across all nodes in the target cluster.

The method accepts a single optional parameter; the time period for which to return the data.
The allowed values for this parameter are one of; minute, hour, day, week, month, quarter and year.
If omitted, this parameter will default to minute.

=head3 cluster_create_delete_operations ( $interval )

Returns either a single, or list, of L<IBM::StorageSystem::StatisticsSet> objects containing 
L<IBM::StorageSystem::Statistics::ClusterCreateDeleteOperations> performance data on cluster file creation
and deletion operations across all nodes in the target cluster.

The method accepts a single optional parameter; the time period for which to return the data.
The allowed values for this parameter are one of; minute, hour, day, week, month, quarter and year.
If omitted, this parameter will default to minute.

=head3 cluster_open_close_latency ( $interval )

Returns either a single, or list, of L<IBM::StorageSystem::StatisticsSet> objects containing 
L<IBM::StorageSystem::Statistics::ClusterOpenCloseLatency> performance data on cluster file open
and close latency across all nodes in the target cluster.

The method accepts a single optional parameter; the time period for which to return the data.
The allowed values for this parameter are one of; minute, hour, day, week, month, quarter and year.
If omitted, this parameter will default to minute.

=head3 cluster_open_close_operations ( $interval )

Returns either a single, or list, of L<IBM::StorageSystem::StatisticsSet> objects containing 
L<IBM::StorageSystem::Statistics::ClusterCreateDeleteOperations> performance data on cluster file open
and close operations across all nodes in the target cluster.

The method accepts a single optional parameter; the time period for which to return the data.
The allowed values for this parameter are one of; minute, hour, day, week, month, quarter and year.
If omitted, this parameter will default to minute.

=head3 cluster_read_write_latency ( $interval )

Returns either a single, or list, of L<IBM::StorageSystem::StatisticsSet> objects containing 
L<IBM::StorageSystem::Statistics::ClusterReadWriteLatency> performance data on cluster file read
and write latency across all nodes in the target cluster.

The method accepts a single optional parameter; the time period for which to return the data.
The allowed values for this parameter are one of; minute, hour, day, week, month, quarter and year.
If omitted, this parameter will default to minute.

=head3 cluster_read_write_operations ( $interval )

Returns either a single, or list, of L<IBM::StorageSystem::StatisticsSet> objects containing 
L<IBM::StorageSystem::Statistics::ClusterReadWriteOperations> performance data on cluster file read
and write operations across all nodes in the target cluster.

The method accepts a single optional parameter; the time period for which to return the data.
The allowed values for this parameter are one of; minute, hour, day, week, month, quarter and year.
If omitted, this parameter will default to minute.

=head3 array( $id )

	# Print the capacity and RAID level of array 1 in GB
	my $array = $ibm->array( 1 );
	print "Array 1 capacity: " . int ( $array->capacity / ( 1024 ** 3 ) )
		. " (" . $array->raid_level . ")\n"

	# e.g. Array 1 capacity: 5824G (raid10)

Returns an L<IBM::StorageSystem::Array> object representing the array specified by the numerical
id parameter.

B<Note> that this is a caching method and that a previously retrieved L<IBM::StorageSystem::Array> object will
be returned if one has been cached from previous invocations.

=head3 get_array( $id )

Returns the array specified by the value of the numerical ID argument as an L<IBM::StorageSystem:Array> object.

B<Note> that this method is non-caching and the array information will always be retrieved from the StorageSystem
system even if a cached object exists.

=head3 get_arrays

	# Print the array status of all arrays in our system
        map { print "Array ", $_->mdisk_id, " status ", $_->status, "\n" } $ibm->get_arrays;

Returns an array of L<IBM::StorageSystem::Array> objects representing all arrays in the target system.

=head3 disk ( $id ) 

	# Get the disk named "system_vol_00" as an IBM::StorageSystem::Disk object
	my $disk = $ibm->disk(system_vol_00);
	
	# Print the disk status
	print $disk->status;

	# Alternately
	print $ibm->disk(system_vol_00)->status;

Returns a L<IBM::StorageSystem::Disk> object representing the disk specified by the value of the id parameter, 
which should be a valid disk name in the target system.

=head3 get_disk( $id )

This is a functionally equivalent non-caching implementation of the B<disk> method.

=head3 get_disks

	# Print a listing of all disks in the target system including their name, the assigned pool and status

	printf( "%-20s%-20s%-20s\n", "Name", "Pool", "Status" );
	printf( "%-20s%-20s%-20s\n", "-----", "------", "-------" );
	foreach my $disk ( $ibm->get_disks ) { printf( "%-20s%-20s%-20s\n", $disk->name, $disk->pool, $disk->status ) }

	# Prints something like:
	#
	# Name                Pool                Status              
	# -----               ------              -------             
	# silver_vol_00       silver              ready               
	# silver_vol_01       silver              ready               
	# silver_vol_02       silver              ready    
	# ... etc.

Returns an array of L<IBM::StorageSystem::Disk> objects representing all disks in the target system.

=head3 drive ( $id ) 

	# Get drive ID 2 as an IBM::StorageSystem::Drive object
        my $drive = $ibm->drive( 2 );

        # Print the drive capacity in bytes
        print $drive->capacity;

	# Alternately;
	print $ibm->drive( 2 )->capacity;

        # Print the drive vendor and product IDs
        print "Vendor ID: ", $drive->vendor_id, " - Product ID: ", $drive->product_id, "\n";

Returns the drive specified by the value of the integer argument as a L<IBM::StorageSystem::Drive> object.

B<note> that this method implements caching and that a cached object will be retrieved if present.

If you require a non-cached object, then use the B<get_drive> method instead.

=head3 get_drive( $id )

Returns the drive specified by the value of the integer argument.  This method is non-caching and
always retrieves information directly from the target system even if a cached object is present.

=head3 get_drives( $id )

        # Print the SAS port status and drive status for all drives in a nicely formatted list
        printf("%-20s%-20s%-20s%-20s\n", 'Drive', 'SAS Port 1 Status', 'SAS Port 2 Status', 'Status');
        printf("%-20s%-20s%-20s%-20s\n", '-'x18, '-'x18, '-'x18, '-'x18);
        map { printf( "%-20s%-20s%-20s%-20s\n", $_->id, $_->port_1_status, $_->port_2_status, $_->status) } $ibm->get_drives;

        # e.g.
        # Drive               SAS Port 1 Status   SAS Port 2 Status   Status              
        # ------------------  ------------------  ------------------  ------------------  
        # 0                   online              online              online              
        # 1                   online              online              online              
        # 2                   online              online              online              
        # 3                   online              online              online
        # ...

Returns all drives as an array of L<IBM::StorageSystem::Drive> objects.

=head3 enclosure( $id )

	# Print the status of a specific enclosure
        print "Enclosure two status is " . $ibm->enclosure(2)->status . "\n";

        # Get all PSUs in an enclosure as L<IBM::StorageSystem::Enclosure::PSU> objects.
        my @psus = $ibm->enclosure(1)->psus;

Returns the enclosure specified by the numerical identifer of the id parameter as an 
L<IBM::StorageSystem::Enclosure> object.

B<Note> that this is a caching method and that a cached object will be returned if one is present.
If you require a non-cached result, then please use the B<get_enclosure> method.

=head3 get_enclosure( $id )

This method is a functionally equivalent non-caching implementation of the B<enclosure> method.

=head3 get_enclosures

        # Print the status of each enclosure in our system.
        foreach my $enclosure ( $ibm->get_enclosures ) {
                print "Enclosure ", $enclosure->id, " status: ", $enclosure->status, "\n"
        }

Returns an array of L<IBM::StorageSystem::Enclosure> objects representing all enclosures present in teh target
system.

=head3 get_exports

        # Print a listing of all configured exports containing the export name, the export path,
        # the export protocol and the export status.

        printf( "%-20s%-40s%-10s%-10s\n", 'Name', 'Path', 'Protocol', 'Active' );

        foreach my $export ( $ibm->get_exports ) { 
                print '-'x100,"\n";
                printf( "%-20s%-40s%-10s%-10s\n", $export->name, $export->path, $export->protocol, $export->active )
        }

        # Prints something like:
        #
        #Name                Path                                    Protocol  Active    
        # ----------------------------------------------------------------------------------------------------
        # homes_root          /ibm/fs1/homes                          NFS       true      
        # ----------------------------------------------------------------------------------------------------
        # shares_root         /ibm/fs1/shares                         NFS       true      
        # ----------------------------------------------------------------------------------------------------
        # test                /ibm/fs1/test                           CIFS      true      
        # ----------------------------------------------------------------------------------------------------
        # ... etc.

Returns all configured exports on the target system as an array of L<IBM::StorageSystem::Export> objects.

=head3 get_fabrics

        # Print a list of our fabrics (sorted by fabric ID) including the fabric ID, node ID, port ID,
        # local WWPN, remote WWPN and fabric status.

        printf( "%-5s%-8s%-8s%-20s%-20s%-10s\n", 'ID', 'Node', 'Port', 'Local WWPN', 'Remote WWPN', 'Status');
        print '-'x80,"\n";

        for my $fabric ( map { $_->[0] } sort { $a->[1] cmp $b->[1] } map { [$_, $_->id] } $ibm->get_fabrics ) {
                printf( "%-5s%-8s%-8s%-20s%-20s%-10s\n", $fabric->id, $fabric->node_name, $fabric->local_port,
                        $fabric->local_wwpn, $fabric->remote_wwpn, $fabric->state )
        }

        # Prints something like:
        #
        # ID   Node    Port    Local WWPN          Remote WWPN         Status    
        # --------------------------------------------------------------------------------
        # 1    node1   1       5005076802159D73    21000024FF43DE7B    active    
        # 1    node1   2       5005076802259D73    21000024FF35B8FC    active    
        # 2    node2   1       5005076802159D74    21000024FF43DE7A    active    
        # 2    node2   2       5005076802259D74    21000024FF35B8FD    active 

Returns all configured fabrics on the target system as an array of L<IBM::StorageSystem::Fabric> objects.

=head3 filesystem( $filesystem_name )

        # Print the block size of file system 'fs1'
        print $ibm->filesystem(fs1)->block_size;
        
        # Get the file system 'fs2' as a IBM::StorageSystem::FileSystem object
        my $fs = $ibm->filesystem(fs2);

        # Print the mount point of this file system
        print "fs2 mount point: " . $fs->mount_point . "\n";

        # Call a function if inode usage on file system 'fs2' exceeds 90% of maximum allocation.
        monitoring_alert( 'Inode allocation > 90% on '.$filesystem->device_name ) 
                if ( ( ( $fs->inodes / $fs->max_inodes ) * 100 ) > 90 );

Returns the file system specified by the value of the named parameter as a L<IBM::StorageSystem::FileSystem> object.

Note that this is a caching method and a cached object will be retrieved if one exists,  If you require a
non-cached object, then please use the B<get_filesystem> method.

=head3 get_filesystem( $filesystem_name )

This is a non-caching functionally equivalent implementation of the B<filesystem> method.  Use this method if
you require the file system information to be retrieved directly from the target system rather than cache.

=head3 get_filesystems

        # Do the same for all file systems
        map { monitoring_alert( 'Inode allocation > 90% on '.$_->device_name )
                if ( ( ( $fs->inodes / $fs->max_inodes ) * 100 ) > 90 ) } $ibm->get_filesystems;

Returns an array of L<IBM::StorageSystem:FileSystem> objects representing all configured file systems on the
target system.

=head3 get_healths

        # Simple one-liner to print the sensor status and value for any error conditions.
        map { print join ' -> ', ( $_->sensor, $_->value."\n" ) } 
                grep { $_->status =~ /ERROR/ } $ibm->get_healths;

        # e.g.
        # CLUSTER -> Alert found in component cluster
        # MDISK -> Alert found in component mdisk
        # NODE -> Alert found in component node

Returns an array of L<IBM::StorageSystem::Health> objects representative of all health sensors on the target system.

B<Note> that this method is only implemented on StorageSystem Unified systems and not StorageSystem SONAS systems.

=head3 host( $hostname )

	# Print the host status of the attached host 'sauron'
	print "Status: " . $ibm->host(sauron)->status . "\n";

Returns the host specified by the value of the named host parameter as an L<IBM::StorageSystem::Host> object.

B<Note> that this is a caching method and a cached object will be returned if one exists.  If you require
a non-cached object, then please use the B<get_host> method.

=head3 get_host( $hostname )

This is a functionally equivalent non-caching implementation of the B<host> method.

=head3 get_hosts

        # Print a list of all configured hosts sorted by hostname, their WWPNs,
        # port state and login status.

        foreach $host ( map { $_->[0] } sort { $a->[1] cmp $b->[1] } map { [ $_, $_->name ] } $ibm->get_hosts ) { 
                my $c = 0;

                foreach $wwpn ( @{ $host->WWPN } ) { 
                        print ( $c ? "\t" : ('-'x100)."\n".$host->name );
                        print "\t\t\t$wwpn\t" . @{ $host->state }[$c] . "\t\t" .
                                ( @{$host->node_logged_in_count }[$c] ? '' : 'not ' ) . "logged in\n";
                        $c++
                }   
        }

        # Prints something similar to:
        # ----------------------------------------------------------------------------------------------------
        # host-3                        2101001B32A3D94C        active          logged in
        #                               2100001B3283D94C        active          logged in
        # ----------------------------------------------------------------------------------------------------
        # host-4                        2100001B320786E7        active          logged in
        #                               2101001B322786E7        active          logged in
        # ----------------------------------------------------------------------------------------------------
        # storage-2                     210100E08BB40A08        offline         not logged in
        #                               210000E08B940A08        offline         not logged in
        # ... etc.

Returns an array of L<IBM::StorageSystem::Host> objects representing all host attached to the target system.

=head3 iogroup( $id )

        # Get I/O group 0
        my $io_group = $ibm->get_iogroup(0);

        # Print the I/O group maintenance state
        print $io_group->maintenance_state;

        # Alternately:
        print $ibm->iogroup(0)->maintenance_state;

Returns the I/O group identified by the value of the numerical ID parameter as an L<IBM::StorageSystem::IOGroup>
object.

B<Note> that this method implements caching and a cached object will be returned shoudl one be present.
If you require a non-cached object then please use the B<get_iogroup> method.

=head3 get_iogroup( $id )

This is a functionally equivalent non-caching implementation of the B<iogroup> method.

=head3 get_iogroups

        # Print a formatted listing of all I/O groups by ID and name, along with
        # their VDisk count, host count, node count and maintenance state.
        map { printf("%-8s%-20s%-20s%-20s%-20s%-20s\n", 
                $_->id,
                $_->name,
                $_->vdisk_count,
                $_->host_count,
                $_->node_count,
                $_->maintenance )
        } $ibm->get_iogroups;

        # Prints something like:
        #
        # ID      Name                VDisk Count         Host Count          Node Count          Maintenance         
        # 0       io_grp0             2                   3                   2                   no                  
        # 1       io_grp1             0                   3                   0                   no                  
        # 2       io_grp2             0                   3                   0                   no                  
        # 3       io_grp3             0                   3                   0                   no
        # ... etc.

Returns an array of L<IBM::StorageSystem::IOGroup> objects representing all configured I/O groups on the target system.

=head3 interface ( $id )

	# Get interface ethX0 on management node mgmt001st001 as an IBM::StorageSystem::Interface object
        # Print the interface status
        print $interface->up_or_down;

        # Print the interface status
        print $interface->speed;

        # Alternately;
        print $ibm->interface('mgmt001st001:ethX0')->speed;

Returns the interface identified by the value of the id parameter as an L<IBM::StorageSystem::Interface> object.

The value of the id parameter must be a valid node and interface name separated by a colon.

B<Note> that this method implements caching and a cached object will be returned shoudl one be present.
If you require a non-cached object then please use the B<get_iogroup> method.

=head3 get_interface( $id )

This is a functionally equivalent non-caching implementation of the B<interface> method.

=head3 get_interfaces

        # Print a list of all interfaces, their status, speed and role
        
        foreach my $interface ( $ibm->get_interfaces ) {
                print "Interface: " . $interface->interface . "\n";
                print "\tStatus: " . $interface->up_or_down . "\n";
                print "\tSpeed: " . $interface->speed . "\n";
                print "\tRole: " . $interface->isubordinate_or_master . "\n----------\n";
        }
        
                 'node:interface' => 'mgmt002st001:ethXsl1_1',
                 'MAC' => '00%3A90%3Afa%3A05%3A88%3A9e',
                 'IPaddresses' => '',
                 'MTU' => '1500',
                 'up_or_down' => 'UP',
                 'lsnwinterface' => 'lsnwinterface',
                 'speed' => '10000',
                 'master_or_subordinate' => 'SUBORDINATE',
                 'transmit_hash_policy' => ''

Returns an array of L<IBM::StorageSystem::Interface> objects representing all interfaces on the target system.

=head3 mount( $mount )

	# Print mount status of file system fs1
	print "Mount status: " . $ibm->mount(fs1) . "\n";

	# Print only those file system that are not mounted
	map { print $_->file_system . " is not mounted.\n" }
	grep { $_->mount_status ne 'mounted' }
	$ibm->get_mounts;

Returns the mount identified by the mount parameter as a L<IBM::StorageSystem::Mount> object.

B<Note> that this method implements caching and a cached object will be returned shoudl one be present.
If you require a non-cached object then please use the B<get_iogroup> method.

=head3 get_mount( $mount )

This is a functionally equivalent non-caching implementation of the B<mount> method.

=head3 get_mounts

This method returns an array of L<IBM::StorageSystem::Mount> objects representing all mounts on the target system.

=head3 node( $node )

        # Get node mgmt001st001 as an IBM::StorageSystem::Node object
        my $node = $ibm->node( mgmt001st001 );
        
        # Print the node description
        print "Description: " . $node->description . "\n";

        # Prints something like: "Description: active management node"
        # Or alternately;
        print "Description: " . $ibm->node( mgmt001st001 )->description . "\n";


Returns the node identified by the value of the node parameter as a L<IBM::StorageSystem::Node> object.

B<Note> that this method implements caching and that a cached object will be returned if one is available.
If you require a non-cached object, then please use the non-caching B<get_node> method.

=head3 get_node( $node )

This is a functionally equivalent non-caching implementation of the B<node> method.

=head3 get_nodes

        # Print the GPFS and CTDB stati of all nodes
        foreach my $node ( $ibm->get_nodes ) {
                print "GPFS status: " . $node->GPFS_status . " - CTDB status: " . $node->CTDB_status . "\n"
        }

Returns an array of L<IBM::StorageSystem::Node> objects representing all configured nodes on the target system.

=head3 pool( $pool )

Returns the pool identified by the value of the node parameter as a L<IBM::StorageSystem::Pool> object.

B<Note> that this method implements caching and that a cached object will be returned if one is available.
If you require a non-cached object, then please use the non-caching B<get_pool> method.

=head3 get_pool( $pool )

This is a functionally equivalent non-caching implementation of the B<pool> method.

=head3 get_pools( $pool )

Returns an array of L<IBM::StorageSystem::Pool> objects representing all configured pools on the target system.

=head3 replication( $eventlog_id )

Returns the replication event identified by the eventlog_id parameter as an L<IBM::StorageSystem::Replication> object.

B<Note> that this method implements caching and that a cached object will be returned if one is available.
If you require a non-cached object, then please use the non-caching B<get_node> method.

=head3 get_replication( $eventlog_id )

This is a functionally equivalent non-caching implementation of the B<replication> method.

=head3 get_replications

        use Date::Calc qw(date_to_Time Today_and_Now);

        my $ibm = IBM::StorageSystem->new(      
                                        user            => 'admin',
                                        host            => 'my-v7000',
                                        key_path        => '/path/to/my/.ssh/private_key'
                                ) or die "Couldn't create object! $!\n";

        # Generate an alert for any replication errors in the last six hours

        foreach my $task ( $ibm->get_replications ) {

                if ( $task->status eq 'ERROR' and ( Date_to_Time( Today_and_Now ) 
                        - ( Date_to_Time( split /-| |\./, $task->time ) ) ) < 21_600 ) {
                        alert( "Replication failure for filesystem " . $task->filesystem . 
                                " - log ID: " . $task->log_id . )
                }

        }

Returns all asynchornous replication tasks as an array of L<IBM::StorageSystem::Replication> objects.

=head3 service( $service )

        # Print the enabled status of the NFS service
        print $ibm->service(NFS)->enabled;

        # Print the configured and enabled status of all services
        printf( "%-20s%-20s%-20s\n", 'Service', 'Configured', 'Active' );
        map { printf( "%-20s%-20s%-20s\n", $_->name, $_->configured, $_->active ) } $ibm->get_services;

Returns a L<IBM::StorageSystem::Service> object representing the service identified by the value of the
service parameter.

B<Note> that this method implements caching and that a cached object will be returned if one is available.
If you require a non-cached object, then please use the non-caching B<get_node> method.

=head3 get_service( $service )

This is a functionally equivalent non-caching implementation of the B<service> method.

=head3 get_services

Returns an array of L<IBM::StorageSystem::Service> objects representing all configured services on the target
system.

=head3 task( $task )

	# Print the status of the SNAPSHOTS task
	my $snapshots = $ibm->task(SNAPSHOTS);
	print "Status: " . $snapshots->status . "\n";

	# Alternately
	print "Status: " . $ibm->task(SNAPSHOTS)->status . "\n";

Return the task identified by the value of the task parameter as an L<IBM::StorageSystem::Task> object.

B<Note> that this method implements caching and that a cached object will be returned if one is available.
If you require a non-cached object, then please use the non-caching B<get_node> method.

=head3 get_task( $task )

This is a functionally equivalent non-caching implementation of the B<task> method.

=head3 get_tasks

	# Call an alert function for any tasks that are not in an OK state
	map { alert( $_->name ) } grep { $_->status ne 'OK' } $ibm->get_tasks;

Returns an array of L<IBM::StorageSystem::Task> objects representing all tasks on the target system.

=head3 vdisk( $id )

        # Get the VDisk ID 3 and print the VDisk UUID
        my $vdisk = $ibm->vdisk(3);
        print $vdisk->vdisk_UUID;

        # Alternately:
        print $ibm->vdisk(3)->vdisk_UUID;

Returns an L<IBM::StorageSystem::VDisk> object representing the VDisk identified by the numerical ID parameter.

B<Note> that this method implements caching to improve performance and reduce network overhead, and that a cached 
object will be returned if one is present.  If you require a non-cached object then please use the B<get_vdisk>
method.

=head3 get_vdisk( $id )

This is a functionally equivalent non-caching implementation of the B<vdisk> method.

=head3 get_vdisks

        # Print the name, ID, capacity in GB and MDisk group name of all VDisks in a
        # nicely formatted output
        printf( "%-20s%-8s%-15s%20s\n", 'Name', 'ID', 'Capacity (GB)', 'MDisk Group Name' );
        printf( "%-20s%-8s%-15s%20s\n", '-'x18, '-'x4, '-'x12, '-'x15 );
        map { printf( "%-20s%-8s%-15s%20s\n", $_->name, $_->id, (int($_->capacity / (1024**3))), $_->mdisk_grp_name) } 
        grep { $_->status eq 'online' } $ibm->get_vdisks;

        # Should print something like:
        # Name                ID      Capacity (GB)      MDisk Group Name
        # ------------------  ----    ------------       ---------------
        # file-host-1         0       5823               FILE_POOL
        # backup-host-2       1       2330               BACKUP_POOL
        # ... etc.

Returns all configured VDisks in the target system as an array of L<IBM::StorageSystem::VDisk> objects.

=head3 get_quotas 

	# Call a function to send a quota warning email for any quotas where the current
	# usage exceeds 85% of the quota usage hard limit.

	map  { send_quota_warning_email( $_ ) }
	grep { ( $_->used_usage / $_->HL_usage ) > 0.85 }
	grep { $_->name ne 'root' }
	grep { $_->type eq 'U' } $ibm->get_quotas;

Returns all quotas defined on the target system as an array of L<IBM::StorageSystem::Quota> objects.

=head1 AUTHOR

Luke Poskitt, C<< <ltp at cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-ibm-StorageSystem at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=IBM-StorageSystem>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc IBM::StorageSystem


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=IBM-StorageSystem>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/IBM-StorageSystem>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/IBM-StorageSystem>

=item * Search CPAN

L<http://search.cpan.org/dist/IBM-StorageSystem/>

=back


=head1 ACKNOWLEDGEMENTS


=head1 LICENSE AND COPYRIGHT

Copyright 2012 Luke Poskitt.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.


=cut

