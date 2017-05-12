package Farly::ASA::Parser;

use 5.008008;
use strict;
use warnings;
use Carp;
use Log::Any qw($log);
use Parse::RecDescent;

our $VERSION = '0.26';

$::RD_ERRORS = 1;    # Make sure the parser dies when it encounters an error

#$::RD_WARN   = 1; # Enable warnings. This will warn on unused rules &c.
#$::RD_HINT   = 1; # Give out hints to help fix problems.
#$::RD_TRACE   = 1;

sub new {
    my ($class) = @_;

    my $self = { PARSER => undef, };
    bless $self, $class;
    
    $log->info("$self NEW");

    $self->_init();

    return $self;
}

sub _init {
    my ($self) = @_;

    $self->{PARSER} = Parse::RecDescent->new( $self->_grammar() );
    
    $log->info( "$self new Parser " . $self->{PARSER} );
}

sub parse {
    my ( $self, $string ) = @_;

    defined($string) or confess "blank line received";

    #STDERR should go to a log file
    my $tree = $self->{PARSER}->startrule($string);

    #throw an error if the parse fails
    defined($tree) or confess "unrecognized line\n";

    return $tree;
}

sub _grammar {
    my ($self) = @_;

    my $grammar = q{
<autotree>

startrule :
		object_group EOL
	|	access_list EOL
	|	named_ip EOL
	|	interface EOL
	|	object EOL
	|	access_group EOL
	|	hostname EOL
	|	route EOL
	|	<error>

hostname :
		'hostname' STRING

#
# names
#

named_ip :
		'name' IPADDRESS name

name :
		NAME_ID name_comment
	|	NAME_ID

name_comment :
		'description' REMARKS

#
# interfaces
# 

interface :
		'interface' STRING interface_options

interface_options :
		if_name
	|	sec_level
	|	if_addr
	|	EOL

if_name :
		'nameif' STRING interface_options

sec_level :
		'security-level' DIGIT interface_options

if_addr :
		'ip address' if_ip interface_options

if_ip :
		IPADDRESS if_mask
	|	NAME if_mask

if_mask :
		MASK if_standby
	|	MASK

if_standby :
		'standby' IPADDRESS
	|	'standby' NAME

#
# objects
#

object :
		'object' OBJECT_ENTRY object_id

object_id : 
		STRING object_address
	|	STRING object_service

object_address :
		'host' IPADDRESS
{
	$item{'OBJECT_TYPE'} = bless( {'__VALUE__' => 'HOST'}, 'OBJECT_TYPE' );
	bless {%item}, $item[0];
}
    |
		'range' IPRANGE
{
	$item{'OBJECT_TYPE'} = bless( {'__VALUE__' => 'RANGE'}, 'OBJECT_TYPE' );
	bless {%item}, $item[0];
}
    |
		'subnet' IPNETWORK
{
	$item{'OBJECT_TYPE'} = bless( {'__VALUE__' => 'NETWORK'}, 'OBJECT_TYPE' );
	bless {%item}, $item[0];
}

object_service :
		'service' object_service_protocol
{
	$item{'OBJECT_TYPE'} = bless( {'__VALUE__' => 'SERVICE'}, 'OBJECT_TYPE' );
	bless {%item}, $item[0];
}

object_service_protocol :
		PROTOCOL object_service_src
	|	PROTOCOL object_service_dst
	|	PROTOCOL object_icmp
	|	PROTOCOL

object_service_src :
		'source' port object_service_dst
	|	'source' port

object_service_dst :
		'destination' port

object_icmp :
		ICMP_TYPE

#
# object-group
#

object_group :
		'object-group' GROUP_TYPE og_id

og_id :
		STRING og_object
	|	STRING og_protocol

og_protocol :
		GROUP_PROTOCOL og_object

og_object :
		og_network_object
	|	og_port_object
	|	og_group_object
	|	og_protocol_object
	|	og_description
	|	og_icmp_object
	|	og_service_object

og_network_object :
		'network-object' address
{
	$item{'OBJECT_TYPE'} = bless( {'__VALUE__' => 'NETWORK'}, 'OBJECT_TYPE' );
	bless {%item}, $item[0];
}

og_port_object :
		'port-object' port
{
	$item{'OBJECT_TYPE'} = bless( {'__VALUE__' => 'PORT'}, 'OBJECT_TYPE' );
	bless {%item}, $item[0];
}

og_group_object :
		'group-object' GROUP_REF
{
	$item{'OBJECT_TYPE'} = bless( {'__VALUE__' => 'GROUP'}, 'OBJECT_TYPE' );
	bless {%item}, $item[0];
}

og_protocol_object :
		'protocol-object' PROTOCOL
{
	$item{'OBJECT_TYPE'} = bless( {'__VALUE__' => 'PROTOCOL'}, 'OBJECT_TYPE' );
	bless {%item}, $item[0];
}

og_description :
		'description' REMARKS
{
	$item{'OBJECT_TYPE'} = bless( {'__VALUE__' => 'COMMENT'}, 'OBJECT_TYPE' );
	bless {%item}, $item[0];
}

og_icmp_object :
		'icmp-object' ICMP_TYPE
{
	$item{'OBJECT_TYPE'} = bless( {'__VALUE__' => 'ICMP_TYPE'}, 'OBJECT_TYPE' );
	bless {%item}, $item[0];
}

og_service_object :
		'service-object' og_so_protocol
{
	$item{'OBJECT_TYPE'} = bless( {'__VALUE__' => 'SERVICE'}, 'OBJECT_TYPE' );
	bless {%item}, $item[0];
}

og_so_protocol :
		PROTOCOL og_so_dst_port
	|	PROTOCOL og_so_src_port
	|	PROTOCOL object_icmp
	|	PROTOCOL

og_so_src_port : 
		'source' port og_so_dst_port
	|	'source' port

og_so_dst_port : 
		'destination' port
	|	port

#
# access-lists
#

access_list :
		'access-list' acl_id

acl_id :
		STRING acl_line
	|	STRING acl_type
	|	STRING acl_action

acl_line :
		'line' DIGIT acl_type
	|	'line' DIGIT acl_action

acl_type :
		ACL_TYPES acl_action
	|	acl_remark

acl_remark :
		'remark' REMARKS

acl_action :
		ACTIONS acl_protocol

#
# protocol options
#

acl_protocol :
		PROTOCOL acl_src_ip
	|	'OG_PROTOCOL' GROUP_REF acl_src_ip
	|	'OG_SERVICE' GROUP_REF acl_src_ip
	|	'object' OBJECT_REF acl_src_ip

#
# access-list source IP addresses
#

acl_src_ip :
		address acl_dst_ip
	|	address acl_src_port

#
# access-list source ports
#

acl_src_port : 
		port acl_dst_ip

#
# access-list destination IP address
#

acl_dst_ip :
		address acl_dst_port
	|	address acl_options

#
# access-list destination ports
#

acl_dst_port : 
		port acl_options
	|	acl_icmp_type acl_options

#
# icmp_types
#

acl_icmp_type :
		'OG_ICMP-TYPE' GROUP_REF
	|	ICMP_TYPE

#
# access-list options
#

acl_options :
		acl_logging
	|	acl_time_range
	|	acl_inactive
	|	EOL
	|	<error>

acl_logging :
		'log' acl_log_level
	|	'log' acl_time_range
{
	$item{'LOG_LEVEL'} = bless( {'__VALUE__' => '6'}, 'LOG_LEVEL' );
	bless {%item}, 'acl_log_level';
}
	|	'log' acl_inactive
{
	$item{'LOG_LEVEL'} = bless( {'__VALUE__' => '6'}, 'LOG_LEVEL' );
	bless {%item}, 'acl_log_level';
}
	|	'log'
{
	$item{'LOG_LEVEL'} = bless( {'__VALUE__' => '6'}, 'LOG_LEVEL' );
	bless {%item}, 'acl_log_level';
}

acl_log_level :
		LOG_LEVEL acl_log_interval
	|	LOG_LEVEL acl_time_range
	|	LOG_LEVEL acl_inactive
	|	LOG_LEVEL

acl_log_interval :
		'interval' DIGIT acl_time_range
	|	'interval' DIGIT acl_inactive
	|	'interval' DIGIT

acl_time_range :
		'time-range' STRING acl_inactive
	|	'time-range' STRING

acl_inactive :
		ACL_STATUS

#
# access_group
#

access_group :
		'access-group' ag_id

ag_id :
		RULE_REF ag_direction
	|	RULE_REF ag_global

ag_global :
		ACL_GLOBAL

ag_direction :
		ACL_DIRECTION ag_interface

ag_interface :
		'interface' IF_REF

#
# routes
#

route :
		'route' route_interface

route_interface :
		IF_REF route_dst

route_dst :
		IPNETWORK route_nexthop
	|	NAMED_NET route_nexthop
	|	DEFAULT_ROUTE route_nexthop

route_nexthop :
		IPADDRESS route_options

route_options :
		route_cost
	|	route_track
	|	route_tunneled
	|	EOL
	|	<error>

route_cost :
		DIGIT route_options

route_track :
		'track' DIGIT route_options

route_tunneled :
		TUNNELED

#
# IP address types
#
# "object" should be fine here because "object" can not  
# be used to specify ports 
#

address :
		'host' IPADDRESS
	|	'host' NAME
	|	IPNETWORK
	|	NAMED_NET
	|	ANY
	|	'object' OBJECT_REF
	|	'interface' IF_REF
	|	'OG_NETWORK' GROUP_REF

#
# port types
#

port :
		port_eq
	|	port_range
	|	'OG_SERVICE' GROUP_REF
	|	port_gt
	|	port_lt
	|	port_neq

port_eq :
	'eq' PORT_ID

port_range :
	'range' PORT_RANGE

port_gt :
	'gt' PORT_GT

port_lt :
	'lt' PORT_LT

port_neq :
	'neq' <error: neq is unsupported>

#
# Token Definitions
#

STRING :
		/\S+/

DIGIT :
		/\d+/

# converted to an IP address
NAME :
		/((^|\s[a-zA-Z])(\.|[0-9a-zA-Z_-]+)+)/

# not converted to an IP address
NAME_ID :
		/((^|\s[a-zA-Z])(\.|[0-9a-zA-Z_-]+)+)/

IF_REF :
		/\S+/

OBJECT_REF :
		/\S+/

GROUP_REF :
		/\S+/

RULE_REF :
		/\S+/

GROUP_TYPE :
		'service' | 'icmp-type' | 'network' | 'protocol'

OBJECT_ENTRY :			
			'network'
		|	'service'

ANY :
		'any'

DEFAULT_ROUTE :
			/0(\s+)0/

IPADDRESS :
		/((\d{1,3})((\.)(\d{1,3})){3})/

MASK :
		/(255|254|252|248|240|224|192|128|0)((\.)(255|254|252|248|240|224|192|128|0)){3}/

IPNETWORK :
		/((\d{1,3})((\.)(\d{1,3})){3})\s+((255|254|252|248|240|224|192|128|0)((\.)(255|254|252|248|240|224|192|128|0)){3})/

IPRANGE :
		/((\d{1,3})((\.)(\d{1,3})){3})\s+((\d{1,3})((\.)(\d{1,3})){3})/

NAMED_NET :
		/((^|\s[a-zA-Z])(\.|[0-9a-zA-Z_-]+)+)\s+((255|254|252|248|240|224|192|128|0)((\.)(255|254|252|248|240|224|192|128|0)){3})/

PROTOCOL :
		/\d+/ | 'ah' | 'eigrp' | 'esp' | 'gre' | 'icmp' | 'icmp6' | 'igmp' 
	| 'igrp' | 'ipinip' | 'ipsec' | 'ip' | 'nos' | 'ospf' | 'pcp' 
	| 'pim' | 'pptp' | 'snp' | 'tcp' | 'udp'

GROUP_PROTOCOL :
		'tcp-udp' | 'tcp' | 'udp'

ICMP_TYPE : 
		/\d+/ | 'alternate-address' | 'conversion-error' | 'echo-reply' | 'echo'
	| 'information-reply' | 'information-request' | 'mask-reply' | 'mask-request'
	| 'mobile-redirect' | 'parameter-problem' | 'redirect' | 'router-advertisement'
	| 'router-solicitation' | 'source-quench' | 'time-exceeded' | 'timestamp-reply'
	| 'timestamp-request' | 'traceroute' | 'unreachable'

PORT_ID :
		/\S+/

PORT_GT :
		/\S+/

PORT_LT :
		/\S+/

PORT_RANGE :
		/\S+\s+\S+/

ACTIONS :
		'permit'
	|	'deny'

ACL_TYPES :
		'extended'

REMARKS :
		/.*$/

ACL_DIRECTION :
		'in'
	|	'out'

ACL_GLOBAL :
		'global'

ACL_STATUS :
		'inactive'

STATE :		
		'enable'
	|	'disable'

TUNNELED :
		'tunneled'

LOG_LEVEL :
		/\d+/ | 'emergencies' | 'alerts' | 'critical' | 'errors' 
	| 'warnings' | 'notifications' | 'informational' | 'debugging'
	| 'disable'

EOL :
		/$/
		
#
# Imaginary Tokens
#
# OBJECT_TYPE
#

};

    return $grammar;
}

1;
__END__

=head1 NAME

Farly::ASA::Parser - Recognizes pre-processed firewall configurations

=head1 DESCRIPTION

Farly::ASA::Parser creates and configures a Parse::RecDecsent parser
capable of recognizing lines of pre formatted firewall configuration as
created by Farly::ASA::Filter. Farly::ASA::Parser returns the parse
tree created by the Parse::RecDecsent <autotree> directive.

Farly::ASA::Parser dies on an error, which would typically be an
unrecognized line of configuration which was allowed through the filter.

Farly::ASA::Parser is used by the Farly::ASA::Builder only.

=head1 COPYRIGHT AND LICENCE

Farly::ASA::Parser
Copyright (C) 2012  Trystan Johnson

This program is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program.  If not, see <http://www.gnu.org/licenses/>.
