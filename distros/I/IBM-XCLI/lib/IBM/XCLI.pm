package IBM::XCLI;

use warnings;
use strict;

use Carp;
use Fcntl;

our $VERSION	= '0.51';

sub new 		{
	my ($class, %args) = @_;
	my $self = (bless {}, $class);
	defined $args{ip_address}	? $self->{ip_address}	= $args{ip_address}	: croak "Constructor failed: ip_address not defined";
	defined $args{username}		? $self->{username}	= $args{username}	: croak "Constructor failed: username not defined";
	defined $args{password}		? $self->{password}	= $args{password}	: croak "Constructor failed: password not defined";
	defined $args{xcli}		? $self->{xcli}		= $args{xcli}		: croak "Constructor failed: xcli not defined";
	-x $self->{xcli}  		or croak "Constructor failed: Unable to execute xcli binary";
	open my $dummy_conn, '-|', $self->{xcli}, 'test'
					or croak "Constructor failed: XCLI dummy connection failed";
	my $output = <$dummy_conn>;
	close $output;
	$output eq "Missing user.\n" 	or croak "Constructor failed: XCLI dummy test failed";
	return $self;
}

our %M_MAP = (
	pool_list		=> { xcli_cmd => 'pool_list', 		sort_by => 'name'				},
	host_list		=> { xcli_cmd => 'host_list', 		sort_by => 'name'				},
	mirror_list		=> { xcli_cmd => 'mirror_list', 	sort_by => 'name' 				},
	vol_list		=> { xcli_cmd => 'vol_list', 		sort_by => 'name' 				},
	cluster_list		=> { xcli_cmd => 'cluster_list', 	sort_by => 'name' 				},
	target_list		=> { xcli_cmd => 'target_list', 	sort_by => 'name' 				},
	dest_list		=> { xcli_cmd => 'dest_list', 		sort_by => 'name' 				},
	snap_group_list		=> { xcli_cmd => 'snap_group_list', 	sort_by => 'name' 				},
	ipinterface_list	=> { xcli_cmd => 'ipinterface_list', 	sort_by => 'ipinterface'			},
	target_port_list	=> { xcli_cmd => 'target_port_list', 	sort_by => 'iscsi_address'			},
	reservation_key_list	=> { xcli_cmd => 'reservation_key_list',sort_by => 'initiator_port'			},
	fc_connectivity_list	=> { xcli_cmd => 'fc_connectivity_list',sort_by => 'wwpn' 				},
	host_connectivity_list	=> { xcli_cmd => 'host_connectivity_list',sort_by => 'host_port'			},
	ups_list		=> { xcli_cmd => 'ups_list', 		sort_by => 'component_id'			},
	psu_list		=> { xcli_cmd => 'psu_list', 		sort_by => 'component_id'			},
	ats_list		=> { xcli_cmd => 'ats_list', 		sort_by => 'component_id'			},
	cf_list			=> { xcli_cmd => 'cf_list', 		sort_by => 'component_id'			},
	dimm_list		=> { xcli_cmd => 'dimm_list', 		sort_by => 'component_id'			},
	fan_list		=> { xcli_cmd => 'fan_list',		sort_by => 'component_id'			},
	mm_list			=> { xcli_cmd => 'mm_list',		sort_by => 'component_id'			},
	switch_list		=> { xcli_cmd => 'switch_list',		sort_by => 'component_id'			},
	service_list		=> { xcli_cmd => 'service_list',	sort_by => 'component_id'			},
	component_list		=> { xcli_cmd => 'component_list',	sort_by => 'component_id'			},
	fc_port_list		=> { xcli_cmd => 'fc_port_list',	sort_by => 'component_id'			},
	ethernet_cable_list	=> { xcli_cmd => 'ethernet_cable_list',	sort_by => 'component_id'			},
	fs_list			=> { xcli_cmd => 'fs_list', 		sort_by => 'module_id'				},
	cg_list			=> { xcli_cmd => 'cg_list', 		sort_by => 'name'				},
	rule_list		=> { xcli_cmd => 'rule_list', 		sort_by => 'name'				},
	metadata_list		=> { xcli_cmd => 'metadata_list', 	sort_by => 'object_type'			},
	reservation_list	=> { xcli_cmd => 'reservation_list', 	sort_by => 'volume_name'			},
	event_threshold_list	=> { xcli_cmd => 'event_threshold_list',sort_by => 'code'				},
	snapshot_list		=> { xcli_cmd => 'snapshot_list',	sort_by => 'name',	xcli_args => ['vol']	},
	mapping_list		=> { xcli_cmd => 'mapping_list',	sort_by => 'volume',	xcli_args => ['host']	},
	);

{
	no strict 'refs';
	
	foreach my $m (keys %M_MAP) {
		*{ __PACKAGE__ . "::$m" . '_raw' } = sub {
			my $self= shift;
			my $args;

			foreach my $arg (@{$M_MAP{$m}{xcli_args}}) {
				@_	? $args .= "$arg=".(shift).' '
					: return carp "Missing argument $arg" 
			}
			
			return $self->_xcli_execute( xcli_cmd => $M_MAP{$m}{xcli_cmd}, xcli_args=> $args );
		};

		*{ __PACKAGE__ . "::$m" } = sub {
			my $self= shift;
			my $p 		= $m . '_raw';
			my @data	= $self->$p(@_);

			my @headers	= map { s/%/percent/g; s/#/no/g; s/ /_/g; s/["\(\)\?]//g; lc $_ } (split /,/, shift @data);
			my ($idx)	= grep { $headers[$_] eq $M_MAP{$m}{sort_by} } 0..$#headers;
			my %res;

			foreach (@data) {
				my @d	=  map { s/"//g; $_ } (split /","/);
				my $c	= 0;

				foreach (@d) { $res{$d[$idx]}{$headers[$c]} = $_; $c++ }
			}

			return %res
		}
	}
}

sub _xcli_execute	{
	my ($self,%args)= @_;
	$args{xcli_args} ||= '';
	my $xcli_arg	= "-s -u $self->{username} -p $self->{password} -m $self->{ip_address} $args{xcli_cmd} $args{xcli_args} -t all";
	open my $conn, '-|', $self->{xcli}, $xcli_arg or croak 'Couldn\'t open connection to XCLI';
	my @result = map { chomp ; $_ } <$conn>;

	return ( $result[0] =~ /^["\w*",?]+/ ? @result : undef )
}

=head1 NAME

IBM::XCLI - A Perl interface to the IBM XIV XCLI

=cut

=head1 SYNOPSIS

	use IBM::XCLI;
	
	my $xiv = IBM::XCLI->new(	
				ip_address	=>	$ip_address,
				username	=>	$user
				password	=>	$password,
				xcli		=>	$xcli
			);

	my @volumes	= $xiv->vol_list();

	foreach (@volumes) {
		s/^"\|"$//g;
		my(@volume) = split /","/;
		print "Volume:\t$volume[0]\tSize:\t$volume[1]\tUsed:\t$volume[6]\n";
	}
	

=head1 DESCRIPTION

This module provides a simple object oriented interface to the IBM XIV XCLI utility.

The IBM XIV XCLI is a utility providing a command line interface to an IBM XIV storage array
exposing complete management and administrative capabilities of the system.

This module provides a simple interface to the IBM XIV XCLI utility by providing convenient
wrapper methods for a number of XCLI native method calls.  These methods are named for and are
analagous to their corresponding XCLI counterparts; for example, a call to the vol_list method
exposed by this module returns the same data as would an execution of the native vol_list
command would be expected to return.

The primary difference between the return value of method calls exposed by this module and 
the return value of native XCLI calls is that methods in this module using native method names 
return a nested hash rather than whitespace delimited or comma-separated data.

Note that if access to the raw data as returned by the XCLI native method call is required then
the B<raw> methods can be used to retrieve CSV data as retured directly from the XCLI.  See the
B<RAW METHODS> section below for further details.

The XCLI utility must be installed on the same machine as from which the script is ran.

=head1 METHODS

=head2 new

	my $xiv = IBM::XCLI->new(	
				ip_address	=> $ip_address,
				username	=> $user
				password	=> $password,
				xcli		=> $xcli
			);

Constructor method.  Creates a new IBM::XCLI object representing a connection to and an instance 
of a XCLI connection to the target XIV unit.

Required parameters are:

=over 3

=item ip_address

The IP address of a management interface on the target XIV unit.

=item username

The username with which to connect to the target XIV unit.

=item password

The password with which to connect to the target XIV unit.

=item xcli

The path to the XCLI binary.  This must be an absolute path to a local file for which the executing
user has appropriate privileges.

=back

=head2 host_list

This method is analagous to the native XCLI command 'host_list' and returns a nested hash containing the details 
of all configured hosts and indexed by host name.  The hash has the following structure:

	host-name-1 => {
		cluster 			=> string,
		creator 			=> string,
		fc_ports 			=> comma-separated list of WWPNs,
		iscsi_ports 			=> comma-separated list of WWPNs,
		iscsi_chap_secret 		=> string,
		iscsi_chap_name 		=> string,
		name 				=> string,
		performance_class 		=> string,
		type 				=> string,
		user_group 			=> string
	},
	...
	host-name-n => {
		...
	}
	
=head2 pool_list

This method is analagous to the native XCLI command 'pool_list' and returns a nested hash containing the details 
of all configured pools indexed by pool name.  The hash has the following structure:

	pool-name-1 => {
		create_last_consistent_snapshot	=> boolean,
		creator				=> string,
		empty_hard_space_gb 		=> int,
		empty_hard_space_mib		=> int,
		empty_space_gb 			=> int,
		empty_space_mib 		=> int,
		hard_size_gb 			=> int,
		hard_size_mib 			=> int,
		lock_behavior 			=> string,
		locked 				=> boolean,
		name 				=> string,
		protected_snapshots_priority 	=> int,
		size_gb 			=> int,
		size_mib 			=> int,
		snapshot_size_gb 		=> int,
		snapshot_size_mib 		=> int,
		used_by_snapshots_gb 		=> int,
		used_by_snapshots_mib 		=> int,
		used_by_volumes_gb 		=> int,
		used_by_volumes_mib 		=> int
	},
	...
	pool-name-2 => {
		...
	}

=head2 mirror_list

This method is analagous to the native XCLI command 'mirror_list' and returns a nested hash containing the details 
of all configured mirrors index by mirror name.  The hash has the following structure:

	mirror-name-1 => {
		active				=> boolean,
		designation			=> string,
		last_replicated			=> timestamp (YYYY-MM-DD HH:MM:SS),
		link_up				=> boolean,
		mirror_error			=> string,
		mirror_object			=> string,
		mirror_type			=> string,
		name				=> string-f,
		operational			=> boolean,
		remote_peer			=> string-f,
		remote_rpo			=> time (hh:mm:ss),
		remote_system			=> string,
		role				=> string,
		rpo				=> time (hh:mm:ss),
		schedule_name			=> string,
		size_to_sync_mb			=> signed int,
		status				=> string,
		sync_progress_percent		=> percent (range 0-100)
	},
	...
	mirror-list-n => {
		...
	}

=head2 vol_list

This method is analagous to the native XCLI command 'vol_list' and returns a nested hash containing the details 
of all configured volumes indexed by voluem name.  The hash has the following structure:

	vol-list-1 => {
		capacity_blocks			=> int,
		consistency_group		=> string,
		creator				=> vcuser,
		deletion_priority		=> int,
		locked				=> boolean,
		locked_by_pool			=> boolean,
		master_copy_creation_time 	=> timestamp (YYYY-MM-DD HH:MM:SS),,
		master_name			=> int,
		mirrored			=> boolean,
		modified			=> boolean,
		name				=> string,
		pool				=> string,
		serial_number			=> int,
		short_live_io			=> boolean,
		size_gb				=> int,
		size_mib			=> int,
		snapshot_creation_time		=> timestamp (YYYY-MM-DD HH:MM:SS),,
		snapshot_format			=> boolean,
		snapshot_group_name		=> string,
		snapshot_of			=> string,
		snapshot_of_snap_group		=> string,
		used_capacity_gb		=> int,
		used_capacity_mib		=> int,
		vaai_disabled_by_user		=> boolean,
		vaai_enabled			=> boolean,
		wwn				=> WWN
	},
	...
	vol-list-n => {
		...
	}

=head2 cluster_list

This method is analagous to the native XCLI command 'cluster_list' and returns a nested hash containing the details 
of all configured clusters index by cluster name.  The hash has the following structure:

	cluster-1 => {
		creator				=> string,
		hosts				=> comma-separated list of host names,
		name				=> string,
		type				=> string,
		user_group			=> string
	},
	...
	cluster-n => {
		...
	}

=head2 target_list

This method is analagous to the native XCLI command 'target_list' and returns a nested hash containing the details 
of all configured targets index by target name.  The hash has the following structure:

	target-1 => {
		connected			=> boolean,
		connection_threshold		=> int,
		creator				=> string,
		iscsi_name			=> IQN,
		max_initialization_rate		=> percentage (range 0-100),
		max_resync_rate			=> int,
		max_syncjob_rate		=> int,
		name				=> string,
		number_of_ports			=> int,
		scsi_type			=> string,
		system_id			=> int,
		xiv_target			=> boolean
	}
	...
	target-n => {
		...
	}

=head2 dest_list

This method is analagous to the native XCLI command 'dest_list' and returns a nested hash containing the details 
of all configured destinations indexed by destination name.  The hash has the following structure:

	dest-list-1 => {
		area_code			=> int,
		creator				=> string,
		email_address			=> email address,
		gateways			=> string,
		heartbeat_days			=> int,
		heartbeat_time			=> int,
		name				=> string,
		phone_number			=> phone number,
		snmp_manager			=> string,
		type				=> string,
		user				=> string
	},
	...
	dest-list-n => {
		...
	}

=head2 snap_group_list

This method is analagous to the native XCLI command 'snap_group_list' and returns a nested hash containing the details 
of all configured snap groups indexed by snap grop name.  The hash has the following structure:

	snap-group-1 => {
		cg				=> string,
		deletion_priority		=> int,
		locked				=> boolean,
		modified			=> boolean,
		name				=> string,
		snapshot_group_format		=> boolean,
		snapshot_time			=> timestamp (YYYY-MM-DD HH:MM:SS)
	},
	...
	snap-group-n => {
		...
	}

=head2 ipinterface_list

This method is analagous to the native XCLI command 'ipinterface_list' and returns a nested hash containing the details 
of all configured IP interfaces indexed by IP interface name.  The hash has the following structure:

	ipinterface-1 => {
		default_gateway			=> IP address (A.B.C.D),
		ip_address			=> IP address (A.B.C.D),
		module				=> Module designation (e.g. 1:Module:1),
		mtu				=> int,
		name				=> string,
		network_mask			=> netmask (A.B.C.D),
		ports				=> int,
		type				=> string
	},
	...
	ipinterface-n => {
		...
	}

=head2 target_port_list

This method is analagous to the native XCLI command 'target_port_list' and returns a nested hash containing the details 
of all configured target ports iSCSI IP address.  The hash has the following structure:

	target-port-1 => {
		active				=> boolean,
		iscsi_address			=> IP address (A.B.C.D),
		iscsi_port			=> int,
		port_type			=> string,
		target_name			=> string,
		wwpn				=> WWPN
	},
	...
	target-port-n => {
		...
	}

=head2 reservation_key_list

This method is analagous to the native XCLI command 'reservation_key_list' and returns a nested hash containing the details 
of all configured reservation keys indexed by reservation key.  The hash has the following structure:

	reservation-key-1 => {
		initiator_port			=> WWPN,
		reservation_key			=> string,
		volume_name			=> string
	},
	...
	reservation-key-2 => {
		...
	}

=head2 fc_port_list

This method is analagous to the native XCLI command 'fc_port_list' and returns a nested hash containing the details
of configured FC ports in the target unit.  Note that FC ports are defined in this context as being FC ports physically belonging 
to the XIV unit.

The hash is indexed by FC port WWPN and has the following structure:

	wwpn-1 => {
		active_firmware			=> string,
		component_id			=> component ID (1:FC_Port:1:1),
		configured_rate_gbaud		=> string,
		credit				=> int,
		current_rate_gbaud		=> int,
		currently_functioning		=> boolean,
		enabled				=> int,
		error_count			=> int,
		hba_vendor			=> string,
		link_type			=> string,
		maximum_supported_rate_gbaud	=> string,
		model				=> string,
		module				=> module ID (e.g. 1:Module:1),
		original_model			=> string,
		original_serial			=> string,
		port_id				=> string,
		port_number			=> int,
		port_state			=> string,
		requires_service		=> string,
		role				=> string,
		serial				=> string,
		service_reason			=> string,
		status				=> string,
		user_enabled			=> boolean,
		wwpn				=> WWPN
	},
	...
	wwpn-n => {
		...
	}

=head2 fc_connectivity_list

This method is analagous to the native XCLI command 'fc_connectivity_list' and returns a nested hash containing the details
of connected FC ports in the target unit.  Note that FC ports are defined in this context as being FC ports physically belonging 
to the XIV unit.

The hash is indexed by FC port WWPN and has the following structure:

	wwwpn-1 => {
		component_id			=> connected component ID (e.g. 1:FC_Port:1:1),
		port_id				=> int,
		role				=> string,
		wwpn				=> WWPN
	},
	...
	wwwpn-n => {
		...
	}

=head2 host_connectivity_list

This method is analagous to the native XCLI command 'host_connectivity_list' and returns a nested hash containing all details
of configured host ports in the target unit. 

The hash is indexed by WWPN (the same as the value of 'host_port') and has the following structure:

	wwpn-1 => {	
		host				=> string,
		host_port			=> WWPN,
		local_fc_port			=> connected component ID (e.g. 1:FC_Port:1:1),
		local_iscsi_port		=> IQN,
		module				=> connected module ID (e.g. 1:Module:5),
		type				=> string
	},
	...
	wwpn-n => {
		...
	}

=head2 ups_list

This method is analagous to the native XCLI command 'ups_list' and returns a nested hash containing details of all UPSs
(Untinterruptible Power Supplys) indexed by the UPS component identifier (the same as the value of component_id).  
The hash has the following structure:

	ups-id-1 => {
		aos_version			=> string,
		apparent_load_percent_va	=> int,
		battery_charge_level		=> percentage (range 0-100),
		battery_week_born		=> signed int,
		battery_year_born		=> signed int,
		component_id			=> component ID (i.e. 1:UPS:1),
		component_test_status		=> string,
		currently_functioning		=> boolean,
		input_power_on			=> boolean,
		last_calibration_date		=> date (MM/DD/YYYY),
		last_calibration_result		=> string,
		last_self_test_date		=> date (MM/DD/YYYY),
		last_self_test_result		=> string,
		load_percent_watts		=> int,
		monitoring_enabled		=> boolean,
		next_self_test			=> timestamp (YYYY-MM-DD HH:MM:SS),
		original_serial			=> string,
		power_consumption		=> int,
		predictive_power_load_percent	=> int,
		predictive_remaining_runtime	=> int,
		requires_service		=> string,
		self-test_status		=> string,
		serial				=> string,
		service_reason			=> string,
		status				=> string,
		temperature			=> int,
		ups_manufacture_date		=> date (MM/DD/YYYY),
		ups_status			=> string,
		runtime_remaining		=> int
`	},
	...
	ups-id-n => {
		...
	}

=head2 psu_list

This method is analagous to the native XCLI command 'psu_list' and returns a nested hash containing details of all PSUs
(Power Supply Units) indexed by the PSU component identifier (the same as the value of component_id).  The hash has the 
following structure:

	psu-id-1 => {
		component_id			=> component ID (e.g. 1:PSU:1:1),
		currently_functioning		=> boolean,
		hardware_status			=> string,
		requires_service		=> string,
		service_reason			=> string,
		status				=> string
	},
	...
	psu-id-n => {
		...
	}

=head2 ats_list

This method is analagous to the native XCLI command 'ats_list' and returns a nested hash containing details of all ATSs
(Automatic Transfer Switches) indexed by the ATS component identifier (the same as the value of component_id).  The hash 
has the following structure:

	ats-id-1 => {
		3-phase				=> boolean,
		a_pick-up			=> boolean,
		b_pick-up			=> boolean,
		c_pick-up			=> boolean,
		d_pick-up			=> boolean,
		ats_connect_errors		=> int,
		ats_reply_errors		=> int,
		coil_a_on			=> boolean,
		coil_b_on			=> boolean,
		coil_c_on			=> boolean,
		coil_d_on			=> boolean,
		component_id			=> component ID (e.g. 1:ATS:1),
		currently_functioning		=> boolean,
		default_calibration		=> boolean,
		dual_active			=> boolean,
		firmware_j1_version		=> string,
		firmware_j2_version		=> string,
		firmware_version		=> string,
		interlock_failed		=> boolean,
		j1_source			=> boolean,
		j2_source			=> boolean,
		l1_input_ok			=> boolean,
		l2_input_ok			=> boolean,
		logic_power			=> boolean,
		no_oc_switching			=> boolean,
		outlet_1_state			=> string,
		outlet_2_state			=> string,
		outlet_3_state			=> string,
		output_10a			=> boolean,
		output_30a_no1			=> boolean,
		output_30a_no2			=> boolean,
		output_30a_no3			=> boolean,
		over-current_j1_phase_a		=> boolean,
		over-current_j1_phase_b		=> boolean,
		over-current_j1_phase_c		=> boolean,
		over-current_j2_phase_a		=> boolean,
		over-current_j2_phase_b		=> boolean,
		over-current_j2_phase_c		=> boolean,
		p1_current_fault		=> boolean,
		p3_current_fault		=> boolean,
		p2_current_fault		=> boolean,
		requires_service		=> string,
		rms_current_outlet_p1		=> int,
		rms_current_outlet_p3		=> int,
		rms_current_outlet_p2		=> int,
		serial_control			=> boolean,
		service_reason			=> string,
		status				=> string,
		us_type				=> boolean
	},
	...
	ats-id-n => {
		...
	}

=head2 cf_list

This method is analagous to the native XCLI command 'cf_list' and returns a nested hash containing details of all CFs
(Compact Flash cards) indexed by the CF component identifier (the same as the value of component_id).  The hash 
has the following structure:

	cf-id-1 => {
		component_id			=> component ID (e.g. 1:CF:1:1,
		currently_functioning		=> boolean,
		device_name			=> string,
		hardware_status			=> string,
		original_part_number		=> string,
		original_serial			=> string,
		part_no				=> string,
		requires_service		=> string,
		serial				=> string,
		service_reason			=> string,
		status				=> string
	},
	...
	cf-id-n => {
		...
	}

=head2 dimm_list

This method is analagous to the native XCLI command 'dimm_list' and returns a nested hash containing details of all DIMMS
(Dual Inline Memory Modules) indexed by the DIMM component identifier (the same as the value of component_id).  
The hash has the following structure:

	dimm-id-1 => {
		bank				=> int,
		channel				=> int,
		component_id			=> component ID (e.g. 1:DIMM:1:1),
		currently_functioning		=> boolean,
		hardware_status			=> string,
		manufacturer			=> string,
		original_part_number		=> string,
		original_serial			=> string,
		part_no				=> string,
		requires_service		=> string,
		serial				=> string,
		sizemb				=> int,
		speedmhz			=> int,
		status				=> string
	},
	...
	dimm-id-1 => {
		...
	}

=head2 fan_list

This method is analagous to the native XCLI command 'fan_list' and returns a nested hash containing details of all fans
indexed by the fan component identifier (the same as the value of component_id).  The hash has the following structure:

	fan-id-1 => {
		component_id			=> component ID (e.g. 1:Fan:1:1),
		currently_functioning		=> boolean,
		requires_service		=> string,
		service_reason			=> string,
		status				=> string
	},
	...
	fan-id-n => {
		...
	}

=head2 mm_list

This method is analagous to the native XCLI command 'mm_list' and returns a nested hash containing details of all maintenance
modules indexed by the maintenance module identifier (the same as the value of component_id).  The hash has the following structure:

	mm-id-1 => {
		component_id			=> component ID (e.g. 1:MaintenanceModule:1),
		currently_functioning		=> boolean,
		enabled				=> boolean,
		free_disk_/			=> int,
		free_disk_/var			=> int,
		free_memory			=> int,
		linkno1				=> boolean,
		linkno2				=> boolean,
		original_serial			=> string,
		original_part_number		=> string,
		part_no				=> string,
		requires_service		=> string,
		service_reason			=> string, 
		serial				=> string,
		status				=> string,
		temperature			=> string,
		total_memory			=> int,
		version				=> string
	},
	...
	mm-id-n => {
		...
	}

=head2 switch_list

This method is analagous to the native XCLI command 'switch_list' and returns a nested hash containing details of all switches
indexed by the switch component identifier (the same as the value of component_id).  The hash has the following structure:

	switch-id-1 => {
		ac_power_state			=> string,
		component_id			=> component ID (e.g. 1:Switch:1),
		current_active_version		=> string,
		currently_functioning		=> boolean,
		dc_power_state			=> string,
		failed_fans			=> int,
		interconnect			=> string,
		original_serial			=> string,
		next_active_version		=> string,
		requires_service		=> string,
		serial				=> string,
		service_reason			=> string,
		status				=> string,
		temperature			=> int,
		temperature_status		=> string
	},
	...
	switch-id-n => {
		...
	}

=head2 service_list

This method is analagous to the native XCLI command 'service_list' and returns a nested hash containing details of all component
generic services indexed by the service component identifier (the same as the value of component_id).  The hash has the following 
structure:

	server-id-1 => {
		component_id			=> service component ID (e.g. 1:Data:1),
		currently_functioning		=> boolean,
		status				=> string,
		target_status			=> string
	},
	...
	service-id-n => {
		...
	}

=head2 component_list

This method is analagous to the native XCLI command 'component_list' and returns a nested hash containing details of all system
components indexed by the system component identifier (the same as the value of component_id).  The hash has the following structure:

	component-id-1 => {
		component_id			=> system component ID (e.g. 1:Data:9),
		currently_functioning		=> boolean,
		requires_service		=> string,
		service_reason			=> string,
		status				=> string
	},
	...
	component-id-n => {
		...
	}

=head2 ethernet_cable_list

This method is analagous to the native XCLI command 'ethernet_cable_list' and returns a nested hash containing details of all 
Ethernet cables indexed by the system Ethernet cable identifier (the same as the value of component_id).  The hash has the 
following structure:

	ethernet-cable-1 => {
		component_id			=> Ethernet cable component ID (e.g. 1:Ethernet_Cable:6:8),
		connected_to			=> switchport component ID (e.g. 1:Switch:1:1),
		currently_functioning		=> boolean,
		interface_role			=> string,
		link_status			=> string,
		requires_service		=> string,
		service_reason			=> string,
		should_be_connected_to		=> switchport component ID (e.g. 1:Switch:1:1),
		status				=> string
	},
	...
	ethernet-cable-n => {
		...
	}

=head2 fs_list

This method is analagous to the native XCLI command 'fs_list' and returns a nested hash containing details of all file
systems indexed by the file system module identifier (the same as the value of module_id).  The hash has the following structure:

	module-id-1 => {
		device				=> string,
		good				=> boolean,
		module_id			=> module identifier (e.g. 1:Module:1),
		mount_point			=> string,
		total_inodes			=> int,
		total_size			=> int,
		type				=> string,
		used_inodes			=> int,
		used_size			=> int,
		writable			=> boolean
	},
	...
	module-id-n => {
		...
	}

=head2 cg_list

This method is analagous to the native XCLI command 'cg_list' and returns a nested hash containing details of all consistency 
groups indexed by the consistency group name.  The hash has the following structure:

	consistency-group-name-1 => {
		mirrored			=> boolean,
		name				=> string,
		pool_name			=> string
	},
	...
	consistency-group-name-n => {
		...
	}

=head2 rule_list

This method is analagous to the native XCLI command 'rule_list' and returns a nested hash containing details of all event
notification rules and indexed by the rule name.  The hash has the following structure:

	rule-name-1 => {
		active				=> boolean,
		category			=> string,
		creator				=> string,
		destinations			=> string (destination name),
		escalation_only			=> boolean,
		escalation_rule			=> string,
		escalation_time			=> int,
		event_codes			=> string,
		except_codes			=> string,
		minimum_severity		=> string,
		name				=> string,
		snooze_time			=> int
	},
	...
	rule-name-n => {
		...
	}

=head2 metadata_list

This method is analagous to the native XCLI command 'metadata_list' and returns a nested hash containing details of all
metatdata objects indexed by the object name.  The hash has the following structure:

	metadata-object-name-1 => {
		key				=> string,
		name				=> string,
		object_type			=> string,
		value				=> string
	},
	...
	metadata-object-name-n => {
		...
	}

=head2 reservation_list

This method is analagous to the native XCLI command 'reservation_list' and returns a nested hash containing details of all
volume reservations indexed by volume name.  The hash has the following structure:

	volume-name-1 => {
		initiator_uid			=> signed integer,
		persistent_access_type		=> string,
		persistent_reservation_type	=> string,
		pr_generation			=> int,
		reservation_age			=> string,
		reservation_type		=> string,
		reserving_port			=> string,
		volume_name			=> string
	},
	...
	reservation-volume-name-n => {
		...
	}
	

=head2 event_threshold_list

This method is analagous to the native XCLI command 'event_threshold_list' and returns a nested hash containing details of 
all event threshold events for volumes indexed by volume name.  The hash has the following structure:

	volume-name-1 => {
		code				=> string,
		critical			=> percentage (range 0-100),
		criticaldef			=> percentage (range 0-100),
		has_thresholds			=> boolean,
		informational			=> string,
		informationaldef		=> percentage (range 0-100),
		major				=> percentage (range 0-100),
		majordef			=> percentage (range 0-100),
		minor				=> percentage (range 0-100),
		minordef			=> percentage (range 0-100),
		not_in_use			=> boolean,
		replaced_by			=> string,
		warning				=> percentage (range 0-100),
		warningdef			=> percentage (range 0-100)
	},
	...
	volume-name-1 => {
		...
	}
	
=head2 snapshot_list ( $volume )

This method is analagous to the native XCLI command 'snapshot_list' and returns a nested hash containing details of 
all snapshots for the specified volume indexed by snapshot name.  The hash has the following structure:

	snapshot-1 => {
		capacity_blocks			=> int,
		consistency_group		=> string,
		creator				=> string,
		deletion_priority		=> int,
		locked				=> boolean,
		locked_by_pool			=> boolean,
		master_copy_creation_time	=> string,
		master_name			=> string,
		mirrored			=> boolean,
		modified			=> boolean,
		name				=> string,
		pool				=> string,
		serial_number			=> int,
		short_live_io			=> boolean,
		size_gb				=> int,
		size_mib			=> int,
		snapshot_creation_time		=> string,
		snapshot_format			=> boolean,
		snapshot_group_name		=> string,
		snapshot_of			=> string,
		snapshot_of_snap_group		=> string,
		used_capacity_gb		=> int,
		used_capacity_mib		=> int,
		vaai_disabled_by_user		=> boolean,
		vaai_enabled			=> boolean,
		wwn				=> WWN
	}.
	...
	snapshot-n => {
		...
	}

=head2 mapping_list ( $host )

This method is analagous to the native XCLI command 'mapping_list' and returns a nested hash containing mapping details
of all volumes for the specified host indexed by volume name.  The hash has the following structure:

	volume-1 => {
		locked				=> boolean,
		lun				=> int,
		master				=> string,
		serial_number			=> int,
		size				=> int,
		volume				=> string
	},
	...
	volume-n => {
		...
	}


=head1 RAW METHODS

The methods below return data as retrieved directly from a call to the corresponding XCLI method with no 
additional data formatting.  These methods may be useful if you wish to perform data processing or manipulation 
in your own custom methods rather than using the methods above.

=head2 host_list_raw

This method is analagous to the native host_list XCLI command, it returns an unformatted response as retrieved
directly from the XCLI invocation.

=head2 pool_list_raw

This method is analagous to the native pool_list XCLI command, it returns an unformatted response as retrieved
directly from the XCLI invocation.

=head2 mirror_list_raw

This method is analagous to the native mirror_list XCLI command, it returns an unformatted response as retrieved
directly from the XCLI invocation.

=head2 vol_list_raw

This method is analagous to the native vol_list XCLI command, it returns an unformatted response as retrieved
directly from the XCLI invocation.

=head2 cluster_list_raw

This method is analagous to the native cluster_list XCLI command, it returns an unformatted response as retrieved
directly from the XCLI invocation.

=head2 target_list_raw

This method is analagous to the native target_list XCLI command, it returns an unformatted response as retrieved
directly from the XCLI invocation.

=head2 dest_list_raw

This method is analagous to the native dest_list XCLI command, it returns an unformatted response as retrieved
directly from the XCLI invocation.

=head2 snap_group_list_raw

This method is analagous to the native snap_group_list XCLI command, it returns an unformatted response as retrieved
directly from the XCLI invocation.

=head2 ipinterface_list_raw

This method is analagous to the native ipinterface_list XCLI command, it returns an unformatted response as retrieved
directly from the XCLI invocation.

=head2 target_port_list_raw

This method is analagous to the native target_port_list XCLI command, it returns an unformatted response as retrieved
directly from the XCLI invocation.

=head2 reservation_key_list_raw

This method is analagous to the native reservation_key_list XCLI command, it returns an unformatted response as retrieved
directly from the XCLI invocation.

=head2 fc_port_list_raw

This method is analagous to the native fc_port_list XCLI command, it returns an unformatted response as retrieved
directly from the XCLI invocation.

=head2 fc_connectivity_list_raw

This method is analagous to the native connectivity_list XCLI command, it returns an unformatted response as retrieved
directly from the XCLI invocation.

=head2 host_connectivity_list_raw

This method is analagous to the native host_connectivity_list XCLI command, it returns an unformatted response as retrieved
directly from the XCLI invocation.

=head2 ups_list_raw

This method is analagous to the native ups_list XCLI command, it returns an unformatted response as retrieved
directly from the XCLI invocation.

=head2 psu_list_raw

This method is analagous to the native psu_list XCLI command, it returns an unformatted response as retrieved
directly from the XCLI invocation.

=head2 ats_list_raw

This method is analagous to the native ats_list XCLI command, it returns an unformatted response as retrieved
directly from the XCLI invocation.

=head2 cf_list_raw

This method is analagous to the native cf_list XCLI command, it returns an unformatted response as retrieved
directly from the XCLI invocation.

=head2 dimm_list_raw

This method is analagous to the native dimm_list XCLI command, it returns an unformatted response as retrieved
directly from the XCLI invocation.

=head2 fan_list_raw

This method is analagous to the native fan_list XCLI command, it returns an unformatted response as retrieved
directly from the XCLI invocation.

=head2 mm_list_raw

This method is analagous to the native mm_list XCLI command, it returns an unformatted response as retrieved
directly from the XCLI invocation.

=head2 switch_list_raw

This method is analagous to the native switch_list XCLI command, it returns an unformatted response as retrieved
directly from the XCLI invocation.

=head2 service_list_raw

This method is analagous to the native service_list XCLI command, it returns an unformatted response as retrieved
directly from the XCLI invocation.

=head2 component_list_raw

This method is analagous to the native component_list XCLI command, it returns an unformatted response as retrieved
directly from the XCLI invocation.

=head2 ethernet_cable_list_raw

This method is analagous to the native ethernet_cable_list XCLI command, it returns an unformatted response as retrieved
directly from the XCLI invocation.

=head2 fs_list_raw

This method is analagous to the native fs_list XCLI command, it returns an unformatted response as retrieved
directly from the XCLI invocation.

=head2 cg_list_raw

This method is analagous to the native cg_list XCLI command, it returns an unformatted response as retrieved
directly from the XCLI invocation.

=head2 rule_list_raw

This method is analagous to the native rule_list XCLI command, it returns an unformatted response as retrieved
directly from the XCLI invocation.

=head2 metadata_list_raw

This method is analagous to the native metadata_list XCLI command, it returns an unformatted response as retrieved
directly from the XCLI invocation.

=head2 reservation_list_raw

This method is analagous to the native reservation_list XCLI command, it returns an unformatted response as retrieved
directly from the XCLI invocation.

=head2 event_threshold_list_raw

This method is analagous to the native event_threshold_list XCLI command, it returns an unformatted response as retrieved
directly from the XCLI invocation.

=head2 snapshot_list_raw ( $volume )

This method is analagous to the native snapshot_list XCLI command, it returns an unformatted response as retrieved
directly from the XCLI invocation.

=head2 mapping_list_raw ( $host )

This method is analagous to the native mapping_list XCLI command, it returns an unformatted response as retrieved
directly from the XCLI invocation.

=head1 AUTHOR

Luke Poskitt, C<< <ltp at cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-ibm-xcli at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=IBM-XCLI>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.


=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc IBM::XCLI


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=IBM-XCLI>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/IBM-XCLI>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/IBM-XCLI>

=item * Search CPAN

L<http://search.cpan.org/dist/IBM-XCLI/>

=back

=head1 LICENSE AND COPYRIGHT

Copyright 2012 Luke Poskitt.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.


=cut

1;
