package Device::Cisco::NXAPI;

use 5.020;
use strict;
use warnings;

use Moose;
use Modern::Perl;
use LWP::UserAgent;
use HTTP::Request;
use Data::Dumper;
use JSON;
use Carp;
use List::MoreUtils qw( natatime );
use Params::Validate qw(:all);
use URI;

use Device::Cisco::NXAPI::Test;


=head1 NAME

Device::Cisco::NXAPI - Interact with the NX-API (Nexus 9K Switches)

=head1 VERSION

Version 0.03

=cut

our $VERSION = '0.03';


=head1 SYNOPSIS

This module provides methods to make API calls and extract information from devices that support the NX-API.
This is predominantly the Nexus 9K range of switches in NXOS mode (not in ACI mode).

    use Device::Cisco::NXAPI;

    my $switch_api = Device::Cisco::NXAPI->new(uri => "https://192.168.1.1:8080", username => "admin", password => "admin");

    my @route_info = $switch_api->routes(vrf => "CustVRF");
    my %version_info = $switch_api->version();

=cut

has 'user_agent'    => ( is => 'rw', isa => 'LWP::UserAgent', default => sub { LWP::UserAgent->new });
has 'http_request'  => ( is => 'rw', isa => 'HTTP::Request');
has 'uri'          => ( is => 'ro', isa => 'Str', required => 1);
has 'username'      => ( is => 'ro', isa => 'Str', required => 1);
has 'password'      => ( is => 'ro', isa => 'Str', required => 1);
has 'debug'         => ( is => 'ro', isa => 'Bool', default => 0);

=head1 CONSTRUCTOR
 
This method constructs a new C<Device::Cisco::NXAPI> object.
 
    my $switch_api = Device::Cisco::NXAPI->new(
                                    # Mandatory parameters:
                                    uri => '',                  # URI of the switch to connect to.
                                    username => '',             # Username to logon to the switch
                                    password => '',             # Password to logon to the switch

                                    # Optional Parameters
                                    debug => (0 | 1),           # Output debugging information to stderr
                                );

=cut

sub BUILD {
    my $self = shift;
    
    my $uri = URI->new($self->uri);
    croak "Only http:// or https:// supported." if !($uri->scheme eq 'http' or $uri->scheme eq 'https');

    $self->http_request(HTTP::Request->new(POST => $uri->scheme()."://".$uri->host_port()."/ins"));
    $self->http_request()->content_type("application/json-rpc");
    $self->user_agent()->credentials($uri->host_port(), 'Secure Zone', $self->username, $self->password);
}

=head1 METHODS
 
=head2 tester()

Returns a B<Device::Cisco::NXAPI::Test> object for the switch. This object can be used to run test
cases against the switch.

=cut

sub tester {
    my $self = shift;
    return Device::Cisco::NXAPI::Test->new(switch => $self);
}

=head2 version()

    my %version_info = $switch->version()

Returns a hash consisting of system information. There are no arguments to this method.

The structure returned is as follows:

    (
      'kern_uptm_secs' => 17,
      'kickstart_ver_str' => '7.0(3)I2(2b)',
      'kick_file_name' => 'bootflash:///nxos.7.0.3.I2.2b.bin',
      'rr_ctime' => ' Mon Dec 19 04:57:51 2016',
      'kern_uptm_days' => 0,
      'kick_tmstmp' => '02/29/2016 05:21:45',
      'host_name' => 'switch',
      'cpu_name' => 'Intel(R) Core(TM) i3- CPU @ 2.50GHz',
      'kern_uptm_hrs' => 0,
      'manufacturer' => 'Cisco Systems, Inc.',
      'rr_sys_ver' => '11.3(2h)',
      'mem_type' => 'kB',
      'bootflash_size' => 7906304,
      'kern_uptm_mins' => 5,
      'bios_cmpl_time' => '10/12/2015',
      'bios_ver_str' => '07.41',
      'proc_board_id' => 'SAL1911BCSU',
      'kick_cmpl_time' => ' 2/28/2016 21:00:00',
      'header_str' => 'Cisco Nexus Operating System (NX-OS) Software',
      'rr_reason' => 'Reset Requested by CLI command reload',
      'memory' => 16401952,
      'chassis_id' => 'Nexus9000 C9372PX chassis',
      'rr_usecs' => 832622,
      'rr_service' => 'PolicyElem Ch reload'
    );

=cut

sub version {
    my $self = shift;

    my $ret = $self->_send_cmd("show version");
    _fixup_returned_structure($ret);
    return %{ $ret };
}

=head2 routes( %options )

    my @routes = $switch->routes(
        vrf => '',
        af => 'ipv4 | ipv6',
    );

	my $first_route = $routes[0]->{prefix};

Returns a list of HASHREFs with information on the routes present in the a VRFs routing table. The 'vrf =>' argument
determines the VRF, and if not specified the global routing table is used. The 'vrf => all' will return routes from
all routing tables on the switch.

The structure returned is as follows:

    (
      {
        'prefix' => '1.1.1.0/24'                        # The prefix of the route
        'vrf' => 'other_vrf',                           # VRF the route is in.
        'paths' => []                                   # Paths to next-hop (multiple paths in the case of ECMP)
                     {
                       'clientname' => 'direct',        # Protocol (e.g. direct, local, static, ospf)
                       'uptime' => 'P28DT19H43M28S',    # Time the route has been in the routing table
                       'ipnexthop' => '2.2.2.1',        # Next hop IP for the path
                       'ifname' => 'Eth1/1'             # Egress interface for the path
                     }
                   ],
      },
    )

=cut

sub routes {
    my $self = shift;
    my %args = validate(@_, 
        {
            vrf => { default => 'default', type => SCALAR | UNDEF },
            af  => { default => 'ipv4', type => SCALAR | UNDEF },
        }
    );

    my $per_af_command = {
        ipv4 => "show ip route vrf $args{vrf}",
        ipv6 => "show ipv6 route vrf $args{vrf}",
    }->{ $args{af} } // croak "Unknown address-family: $args{af}";

    my $ret = $self->_send_cmd($per_af_command);
    _fixup_returned_structure($ret);
    return _modify_returned_route_structure($ret);
}

sub _modify_returned_route_structure {
    my $route_structure = shift;    
    my @ret_routes;

    for my $vrf (@{ $route_structure->{vrf} }) {
        my $vrf_name = $vrf->{'vrf-name-out'};
        
        for my $addr_family (@{ $vrf->{addrf} }) {
			my $address_family = $addr_family->{addrf};

            for my $prefix (@{ $addr_family->{prefix} }) {
                my %prefix_info;

                $prefix_info{vrf} = $vrf_name;
                $prefix_info{prefix} = $prefix->{ipprefix};

                # The format of the paths structure is not great. It's a single array of hashrefs,
                # with 2 hashrefs for every IPv4 path and 3 HASHREFs for every IPv6 path.
                #
                # We first need to decide on how we iterate through the array:
				my $path_iteration_num = {
                    ipv4 => 2,
                    ipv6 => 3,
                }->{ $address_family };

                # Create the iterator
                my $path_iterate = natatime $path_iteration_num, @{ $prefix->{path} };
                while (my @path = $path_iterate->()) {

                    # Merge either the 2 or 3 HASHREFs into a single HASH
                    my %merged_path_entry = map { %{ $_ } } @path;

                    # Take a slice of the keys and vals that we want
                    my %path_entry = %merged_path_entry{ 'ipnexthop', 'uptime', 'ifname', 'clientname' };

                    push @{ $prefix_info{paths} }, \%path_entry;
                }

                push @ret_routes, \%prefix_info;
            }

        }
    }
    return @ret_routes;
}

=head2 arp( %options )

    my @arp_table = $switch->arp(
        vrf => '',
    );

Returns a list of HASREFs containing the ARP table information. The B<vrf> argument specifies the VRF to 
retrieve the ARP entries from. If no argument is specified the global routing table is used. If B<all> is 
specified as the VRF, ARP entries from all routing tables are returned.

The structure returned is as follows:

    (
     {
       'ifname' => 'mgmt0',         # Egress interface
       'vrf' => 'management',		# VRF
       'mac' => '0009.0fe9.9b39',	# MAC address
       'ip' => '10.47.64.4',		# IP address
       'time-stamp' => '00:01:20'	# Entry timeout
     }
    )

=cut

sub arp {
    my $self = shift;
    my %args = validate(@_, 
        {
            vrf => { default => 'default', type => SCALAR | UNDEF },
        }
    );

    my $ret = $self->_send_cmd("show ip arp vrf $args{vrf}");
    _fixup_returned_structure($ret);

    return _modify_returned_arp_structure($ret);
}

sub _modify_returned_arp_structure {
    my $arp_structure = shift;
    my @ret_arp;

    for my $vrf (@{ $arp_structure->{vrf} }) {
        my $vrf_name = $vrf->{'vrf-name-out'};

        for my $adjacency (@{ $vrf->{adj} }) {
            # Add the VRF and rename some of the keys to 
            # consistent values
            $adjacency->{vrf} = $vrf_name; # Add the VRF name
            $adjacency->{ip} = delete $adjacency->{'ip-addr-out'};
            $adjacency->{ifname} = delete $adjacency->{'intf-out'};

            push @ret_arp, $adjacency;
        }
    }
    return @ret_arp;
}

    

=head2 vlans()

    my @vlan_info = $switch->vlans();

Returns a list of HASHREFs containing information on the current layer 2 VLANs configured on the device.
This method has no arguments.

The data structure returned is as follows:

    (
      {
        'id' => '1',
        'utf_id' => '1',
        'name' => 'default',
        'admin_state' => 'noshutdown',
        'vlan_state' => 'active'
        'interfaces' => [
          'Ethernet1/3-22',
          'Ethernet1/26-44',
          'Ethernet1/47-54'
        ],
      },
    )


=cut

sub vlans {
    my $self = shift;

    my $ret = $self->_send_cmd("show vlan");
    _fixup_returned_structure($ret);
    return _modify_returned_vlan_structure($ret);
}

sub _modify_returned_vlan_structure {
    my $vlan_structure = shift;
    my @ret_vlans;

    for my $vlan (@{ $vlan_structure->{vlanbrief} }) {
        my @vlan_keys = (
            ['vlanshowbr-shutstate', 'admin_state'],
            ['vlanshowbr-vlanstate', 'vlan_state'],
            ['vlanshowbr-vlanid', 'id'],
            ['vlanshowbr-vlanname', 'name'],
            ['vlanshowplist-ifidx', 'interfaces'],
            ['vlanshowbr-vlanid-utf', 'utf_id'],
        );

        # Rename the keys
        my %renamed_vlan = map { $_->[1] => $vlan->{$_->[0]} } @vlan_keys;

        # The interfaces are in comma seperated form - split this out into an array
        my @split_interfaces = split ',', $renamed_vlan{interfaces};
        $renamed_vlan{interfaces} = \@split_interfaces;

        push @ret_vlans, \%renamed_vlan;
    }
    return @ret_vlans;
}

=head2 physical_interfaces()

    my @interface_info = $switch->physical_interfaces(); 

Returns a list of HASHREFs containing information on the physical interfacee state.

The structure returned is as follows:
    
     (
      {
        'name' => 'Ethernet1/5',
        'mac' => '84b8.020f.15d4',
        'speed' => 'auto-speed',
        'admin_state' => 'up', 		
        'op_state' => 'down',	
        'fps_in' => '0',		
        'fps_out' => '0',
        'bps_in' => '0',
        'bps_out' => '0',
        'bytes_in' => 0,				
        'bytes_out' => 0,		
        'packets_in' => 0,	
        'packets_out' => 0,
        'last_link_flap' => 'never'	
        'errors' => {
          'ignored_frames' => '0',	
          'bad_protocol' => '0',
          'runts' => 0,
          'crc_errors' => '0',
          'no_carrier' => '0',
          'in_errors' => '0',
          'collisions' => '0',
          'lost_carrier' => '0',
          'dribbles' => '0',
          'overruns' => '0',
          'bad_frames' => '0',
          'no_buffer' => 0,
          'late_collisions' => '0',
          'underruns' => '0',
          'out_errors' => '0',
          'babbles' => '0',
          'out_discards' => '0',
          'in_discards' => '0'
        },
      }
     )

=cut

sub physical_interfaces {
    my $self = shift;

    my $ret = $self->_send_cmd('show interface');
    _fixup_returned_structure($ret);
    return _modify_returned_phy_int_structure($ret);
}

sub _modify_returned_phy_int_structure {
    my $int_structure = shift;
    my @ret_interfaces;

    for my $interface (@{ $int_structure->{interface} }) {
        # The following structure is used to rename the keys
        # in the returned structure to better names.
        my @eth_info_keys = (
            ['interface', 'name'],
            ['admin_state', 'admin_state'],
            ['state', 'op_state'],
            ['eth_inbytes', 'bytes_in'],
            ['eth_outbytes', 'bytes_out'],
            ['eth_inpkts', 'packets_in'],
            ['eth_outpkts', 'packets_out'],
            ['eth_outrate1_bits', 'bps_out'],
            ['eth_outrate1_pkts', 'fps_out'],
            ['eth_inrate1_bits', 'bps_in'],
            ['eth_inrate1_pkts', 'fps_in'],
            ['eth_bia_addr', 'mac'],
            ['eth_speed', 'speed'],
            ['eth_link_flapped', 'last_link_flap'],
        );

        my @eth_err_keys = (
            ['eth_bad_eth', 'bad_frames'],
            ['eth_overrun', 'overruns'],
            ['eth_runts', 'runts'],
            ['eth_nobuf', 'no_buffer'],
            ['eth_lostcarrier', 'lost_carrier'],
            ['eth_ignored', 'ignored_frames'],
            ['eth_coll', 'collisions'],
            ['eth_crc', 'crc_errors'],
            ['eth_nocarrier', 'no_carrier'],
            ['eth_outerr', 'out_errors'],
            ['eth_inerr', 'in_errors'],
            ['eth_indiscard', 'in_discards'],
            ['eth_outdiscard', 'out_discards'],
            ['eth_babbles', 'babbles'],
            ['eth_latecoll', 'late_collisions'],
            ['eth_underrun', 'underruns'],
            ['eth_dribble', 'dribbles'],
            ['eth_bad_proto', 'bad_protocol'],
        );

        # We extract out the relevant keys and translate them to better names
        # We also move the interface errors to a sub-tree
        my %renamed_info = map { $_->[1] => $interface->{$_->[0] // ''} } @eth_info_keys;
        my %renamed_errors = map { $_->[1] => $interface->{$_->[0]} } @eth_err_keys;
        $renamed_info{errors} = \%renamed_errors;
    
        push @ret_interfaces, \%renamed_info;
    }

    return @ret_interfaces;
}

=head2 bgp_peers( %options )

    my @bgp_peers = $switch->bgp_peers(
        vrf => '',
        af => 'ipv4 | ipv6'
    );

This function retrieves information on the BGP peers configured on the device. If B<vrf> is not specified,
the peer info relating to the default routing table is retrieved. If B<vrf> is specified as 'all', peer info
from all VRFs (including the global routing table) is returned.

The structure returned is as follows:

    (
      {
        'capabilitiessent' => '0',
        'state' => 'Idle',
        'updatesrecvd' => '0',
        'up' => 'false',
        'index' => '1',
        'updatessent' => '0',
        'keepaliverecvd' => '0',
        'holdtime' => '180',
        'resettime' => 'never',
        'neighbor' => '1.1.1.1',
        'lastread' => 'never',
        'opensrecvd' => '0',
        'peerresettime' => 'never',
        'bytesrecvd' => '0',
        'notificationsrcvd' => '0',
        'msgrecvd' => '0',
        'rtrefreshrecvd' => '0',
        'rtrefreshsent' => '0',
        'version' => '4',
        'firstkeepalive' => 'false',
        'remoteas' => '65001',
        'keepalivesent' => '0',
        'notificationssent' => '0',
        'bytessent' => '0',
        'remote-id' => '0.0.0.0',
        'keepalivetime' => '60',
        'peerresetreason' => 'No error',
        'restarttime' => '00:00:01',
        'lastwrite' => 'never',
        'connsestablished' => '0',
        'connsdropped' => '0',
        'resetreason' => 'No error',
        'recvbufbytes' => '0',
        'connattempts' => '0',
        'elapsedtime' => '00:05:24',
        'sentbytesoutstanding' => '0',
        'msgsent' => '0',
        'openssent' => '0'
      },
    )

=cut

sub bgp_peers {
    my $self = shift;
    my %args = validate(@_, 
        {
            vrf => { default => 'default', type => SCALAR | UNDEF },
            af => { default => 'ipv4', type => SCALAR | UNDEF, regex => qr{(ipv4|ipv6)} }
        }
    );
   
    my $user_args = "vrf $args{vrf} $args{af}";

    my $ret = $self->_send_cmd("show bgp $user_args neighbors");
    _fixup_returned_structure($ret);
    return _modify_returned_bgp_peer_structure($ret);
}

sub _modify_returned_bgp_peer_structure {
    my $bgp_peer_structure = shift;
    my @ret_bgp_peers;

    for my $bgp_peer (@{ $bgp_peer_structure->{neighbor} }) {
        my @extracted_keys = (
      		'up',
      		'state',
      		'resettime',
      		'resetreason',
      		'peerresetreason',
      		'neighbor',
      		'remoteas',
      		'remote-id',
      		'version',
      		'holdtime',
      		'keepalivetime',
      		'connsdropped',
      		'connsestablished',
      		'restarttime',
      		'firstkeepalive',
      		'sentbytesoutstanding',
      		'msgsent',
      		'msgrecvd',
      		'bytessent',
      		'bytesrecvd',
      		'updatessent',
      		'updatesrecvd',
      		'openssent',
      		'opensrecvd',
      		'notificationssent',
      		'notificationsrcvd',
      		'rtrefreshsent',
      		'keepaliverecvd',
      		'connattempts',
      		'lastread',
      		'rtrefreshrecvd',
      		'index',
      		'peerresettime',
      		'recvbufbytes',
      		'capabilitiessent',
      		'elapsedtime',
      		'lastwrite',
      		'keepalivesent',
        );

        my %peer_info = %{ $bgp_peer }{ @extracted_keys };
        push @ret_bgp_peers, \%peer_info;
    }
    return @ret_bgp_peers;
}


=head2 bgp_rib( %options )

    my $bgp_rib_ref = $switch->bgp_rib(
        vrf => '',
        af => 'ipv4 | ipv6'
    );

Returns information on the BGP Routinng Information Base (RIB). If B<vrf =>> is not specified, the global routing table is returned.
If B<vrf =>> is set to 'all', the RIB for all VRFs, including the global routing table, is returned.

If B<af =>> is not specied, the RIB for the IPv4 address family is returned.

The structure returned is as follows:

    (
      {
        'prefix' => '1.2.3.0/24',
        'paths' => [
          {
            'pathnr' => '0',
            'ipnexthop' => '0.0.0.0',
            'weight' => '32768',
            'best' => '>',
            'metric' => '',
            'origin' => 'i',
            'aspath' => '',
            'localpref' => '100',
            'type' => 'l',
            'status' => '*'
          }
        ],
        'vrf' => 'default'
      },
    )


=cut
sub bgp_rib {
    my $self = shift;
    my %args = validate(@_, 
        {
            vrf => { default => 'default', type => SCALAR | UNDEF },
            af => { default => 'ipv4', type => SCALAR | UNDEF, regex => qr{(ipv4|ipv6)} }
        }
    );

    my ($vrf, $addr_family); 

    my %address_families = (
                            ipv4 => "ip unicast",
                            ipv6 => "ipv6 unicast",
                            all => "all",
                        );

    $vrf = "vrf ".$args{vrf};
    $addr_family = $address_families{ $args{af} }; 

    my $ret = $self->_send_cmd("show bgp $vrf $addr_family");
    _fixup_returned_structure($ret);
    return _modify_returned_bgp_rib_structure($ret);
}

sub _modify_returned_bgp_rib_structure {
    my $bgp_structure = shift;
    my @ret_bgp_rib;

    for my $vrf (@{ $bgp_structure->{vrf} }) {
        my $vrf_name = $vrf->{'vrf-name-out'};

        for my $afi (@{ $vrf->{afi} }) {
            for my $safi (@{ $afi->{safi} }) {
                for my $rd (@{ $safi->{rd} }) {
                    for my $prefix (@{ $rd->{prefix} }) {
                        my %bgp_prefix;

                        $bgp_prefix{vrf} = $vrf_name;
                        $bgp_prefix{prefix} = $prefix->{ipprefix};
                        $bgp_prefix{paths} = $prefix->{path};


                        push @ret_bgp_rib, \%bgp_prefix;
                    }
                }
            }
        }
    }
    return @ret_bgp_rib;
}


=head2 cdp_neighbours()

Returns a list of HASHREFs containing the current CDP information visible on the switch.

The structure returned is as follows:

    (
      {
        'platform_id' => 'cisco WS-C2960X-24TD-L',
        'intf_id' => 'mgmt0',
        'port_id' => 'GigabitEthernet1/0/3',
        'ifindex' => 83886080,
        'ttl' => 179,
        'device_id' => 'hostname',
        'capability' => 'IGMP_cnd_filtering'
      }
    )

=cut

sub cdp_neighbours {
    my $self = shift;

    my $ret = $self->_send_cmd("show cdp neighbors detail");
    _fixup_returned_structure($ret);
    return _modify_returned_cdp_structure($ret);
}

sub _modify_returned_cdp_structure {
    my $cdp_structure = shift;

    return @{ $cdp_structure->{cdp_neighbor_brief_info} };
}


sub _send_cmd {
    my $self = shift;
    my $command = shift;

    my $json = $self->_gen_cmd($command);
    if ($self->debug) {
        say "[DEBUG]: $json";
    }
    $self->http_request()->content($json);
    my $response = $self->user_agent()->request( $self->http_request );
    return $self->_check_and_return_response($response)->{result}->{body};
}

sub _gen_cmd {
    my $self = shift;
    my $command = shift;

    my $json_ref =  [{ 
                     jsonrpc => "2.0",
                     method  => "cli",
                     params  => {
                      cmd => "",
                      version => 1,
                     },
                     id => "1",
                    }];

    $json_ref->[0]->{params}->{cmd} = $command;
    return encode_json($json_ref);
}

sub _check_and_return_response {
    my $self = shift;
    my $response = shift;
    my $json_content;
    my $json_error_code;
    my $json_error_msg;
        
    $json_content = eval { decode_json($response->content) };

    if ($json_content->{error}) {
        $json_error_code = $json_content->{error}->{code} // "<No Code>";
        $json_error_msg = $json_content->{error}->{data}->{msg} // "";
    }

    $json_error_msg //= "";

    croak "HTTP Error (".$response->code()."): ".$response->status_line()." ".$json_error_msg if $response->is_error();

    croak "NX-API Error($json_error_code}): $json_error_msg" if $json_content->{error}; 

    return $json_content;
}

sub _fixup_returned_structure {
    my $structure_ref = shift;

    # Find all of the keys which a prefixed with 'TABLE_'
    my @table_keys = grep { m{TABLE_}sxm } keys %{ $structure_ref };

    return $structure_ref if (@table_keys == 0);

    for my $table_key (@table_keys) {
        # Rename the TABLE_ key
        my ($new_key) = $table_key =~ m{TABLE_(\w+)}sxm;

        # Generate the ROW_ key name
        my $row_key = "ROW_".$new_key;

        # If the row is a HASHREF, it means there's only one element.
        # We change this to an ARRAYREF of one HASHREF so that the table 
        # is always an ARRAYREF, even if it's only one element.
        if (ref($structure_ref->{ $table_key }->{ $row_key }) eq 'HASH') {
            $structure_ref->{ $new_key } = [ $structure_ref->{ $table_key }->{ $row_key } ];
        } else {
            $structure_ref->{ $new_key } = $structure_ref->{ $table_key }->{ $row_key };
        }

        delete $structure_ref->{ $table_key };

        # Go through each hash item and recursively fix them up
        for my $row (@{ $structure_ref->{ $new_key } }) {
            _fixup_returned_structure($row);
        }
   }
}
    


=head1 AUTHOR

Greg Foletta, C<< <greg at foletta.org> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-switch-nxapi at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Switch-NXAPI>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.




=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Device::Cisco::NXAPI


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Switch-NXAPI>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Switch-NXAPI>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Switch-NXAPI>

=item * Search CPAN

L<http://search.cpan.org/dist/Switch-NXAPI/>

=back


=head1 ACKNOWLEDGEMENTS


=head1 LICENSE AND COPYRIGHT

Copyright 2016 Greg Foletta.

This program is free software; you can redistribute it and/or modify it
under the terms of the the Artistic License (2.0). You may obtain a
copy of the full license at:

L<http://www.perlfoundation.org/artistic_license_2_0>

Any use, modification, and distribution of the Standard or Modified
Versions is governed by this Artistic License. By using, modifying or
distributing the Package, you accept this license. Do not use, modify,
or distribute the Package, if you do not accept this license.

If your Modified Version has been derived from a Modified Version made
by someone other than you, you are nevertheless required to ensure that
your Modified Version complies with the requirements of this license.

This license does not grant you the right to use any trademark, service
mark, tradename, or logo of the Copyright Holder.

This license includes the non-exclusive, worldwide, free-of-charge
patent license to make, have made, use, offer to sell, sell, import and
otherwise transfer the Package with respect to any patent claims
licensable by the Copyright Holder that are necessarily infringed by the
Package. If you institute patent litigation (including a cross-claim or
counterclaim) against any party alleging that the Package constitutes
direct or contributory patent infringement, then this Artistic License
to you shall terminate on the date that such litigation is filed.

Disclaimer of Warranty: THE PACKAGE IS PROVIDED BY THE COPYRIGHT HOLDER
AND CONTRIBUTORS "AS IS' AND WITHOUT ANY EXPRESS OR IMPLIED WARRANTIES.
THE IMPLIED WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR
PURPOSE, OR NON-INFRINGEMENT ARE DISCLAIMED TO THE EXTENT PERMITTED BY
YOUR LOCAL LAW. UNLESS REQUIRED BY LAW, NO COPYRIGHT HOLDER OR
CONTRIBUTOR WILL BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, OR
CONSEQUENTIAL DAMAGES ARISING IN ANY WAY OUT OF THE USE OF THE PACKAGE,
EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.


=cut

1; # End of Device::Cisco::NXAPI
