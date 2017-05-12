package Farly::ASA::Rewriter;

use 5.008008;
use strict;
use warnings;
use Carp;
use Scalar::Util qw(blessed);
use Log::Any qw($log);

our $VERSION = '0.26';

# the parser rule name maps to an abstract syntax tree (AST) root node class
# this will become the 'ENTRY' model meta data in the Farly firewall model
# 'ENTRY' is roughly equivalent to a namespace or table name

our $AST_Root_Class = {
    'hostname'     => 'HOSTNAME',
    'named_ip'     => 'NAME',
    'interface'    => 'INTERFACE',
    'object'       => 'OBJECT',
    'object_group' => 'GROUP',
    'access_list'  => 'RULE',
    'access_group' => 'ACCESS_GROUP',
    'route'        => 'ROUTE',
};

# The $AST_Node_Class hash key is the rule name and the class of the parse tree node
# The $AST_Node_Class hash value is the new AST node class
# Any Token / '__VALUE__' found in the parse tree beneath the given nodes
# in the parse tree becomes the AST node '__VALUE__'
# The AST node class will become the key in the Farly::Object object
# AST node '__VALUE__' becomes the Farly::Object value object
# i.e. The $AST_Node_Class mapping defines the vendor to Farly model mapping :
# $object->set( ref($ast_node), $ast_node->{__VALUE__} );

my $AST_Node_Class = {
    'named_ip'                => 'OBJECT',
    'name'                    => 'ID',
    'name_comment'            => 'COMMENT',
    'hostname'                => 'ID',
    'interface'               => 'INTERFACE',
    'if_name'                 => 'ID',
    'sec_level'               => 'SECURITY_LEVEL',
    'if_ip'                   => 'OBJECT',
    'if_mask'                 => 'MASK',
    'if_standby'              => 'STANDBY_IP',
    'object_id'               => 'ID',
    'object_address'          => 'OBJECT',
    'object_service_protocol' => 'PROTOCOL',
    'object_service_src'      => 'SRC_PORT',
    'object_service_dst'      => 'DST_PORT',
    'object_icmp'             => 'ICMP_TYPE',
    'object_group'            => 'GROUP_TYPE',
    'og_id'                   => 'ID',
    'og_protocol'             => 'GROUP_PROTOCOL',
    'og_network_object'       => 'OBJECT',
    'og_port_object'          => 'OBJECT',
    'og_group_object'         => 'OBJECT',
    'og_protocol_object'      => 'OBJECT',
    'og_description'          => 'OBJECT',
    'og_icmp_object'          => 'OBJECT',
    'og_service_object'       => 'OBJECT',
    'og_so_protocol'          => 'PROTOCOL',
    'og_so_src_port'          => 'SRC_PORT',
    'og_so_dst_port'          => 'DST_PORT',
    'acl_action'              => 'ACTION',
    'acl_id'                  => 'ID',
    'acl_line'                => 'LINE',
    'acl_type'                => 'TYPE',
    'acl_protocol'            => 'PROTOCOL',
    'acl_src_ip'              => 'SRC_IP',
    'acl_src_port'            => 'SRC_PORT',
    'acl_dst_ip'              => 'DST_IP',
    'acl_dst_port'            => 'DST_PORT',
    'acl_icmp_type'           => 'ICMP_TYPE',
    'acl_remark'              => 'COMMENT',
    'acl_log_level'           => 'LOG_LEVEL',
    'acl_log_interval'        => 'LOG_INTERVAL',
    'acl_time_range'          => 'TIME_RANGE',
    'acl_inactive'            => 'STATUS',
    'ag_id'                   => 'ID',
    'ag_direction'            => 'DIRECTION',
    'ag_interface'            => 'INTERFACE',
    'route_interface'         => 'INTERFACE',
    'route_dst'               => 'DST_IP',
    'route_nexthop'           => 'NEXTHOP',
    'route_cost'              => 'COST',
    'route_track'             => 'TRACK',
    'route_tunneled'          => 'TUNNELED',
    'port_neq'                => 'NEQ',              #not used yet
    'OBJECT_TYPE'             => 'OBJECT_TYPE',      #imaginary token mapping
};

sub new {
    my ($class) = @_;

    my $self = bless {}, $class;

    $log->info("$self NEW");

    return $self;
}

sub rewrite {
    my ( $self, $pt_node ) = @_;
    # $node is a reference to the current node in the parse tree
    # i.e. the root of the parse tree to begin with

    # $root is a reference to the root of the new abstract syntax tree
    my $root = bless( {}, 'NULL' );

    # $ast_node is a reference to current ast node
    my $ast_node;

    # set s of explored vertices
    my %seen;

    #stack is all neighbors of s
    my @stack;
    push @stack, [ $pt_node, $ast_node ];

    my $key;

    while (@stack) {

        my $rec = pop @stack;

        $pt_node  = $rec->[0];
        $ast_node = $rec->[1];

        $log->debug( "parse tree node = " . ref($pt_node) . " : ast node = " . ref($ast_node) );

        next if ( $seen{$pt_node}++ );

        my $pt_node_class = ref($pt_node);

        # redefine the abstract syntax tree root node class
        if ( defined( $AST_Root_Class->{$pt_node_class} ) ) {

            $root     = bless( {}, $AST_Root_Class->{$pt_node_class} );
            $ast_node = $root;

            $log->debug( "new ast root class = " . ref($root) );
        }

        # create new abstract syntax tree nodes
        if ( defined( $AST_Node_Class->{$pt_node_class} ) ) {

            # create a new AST node and add it to the AST
            my $new_ast_node_class = $AST_Node_Class->{$pt_node_class};
            $ast_node->{$new_ast_node_class} = bless( {}, $new_ast_node_class );

            #update the $ast_node reference to refer to the new AST node
            $ast_node = $ast_node->{$new_ast_node_class};

            $log->debug( "mapped $pt_node_class to AST class " . ref($ast_node) );

            # the AST root class has to have been changed or something is very wrong
            confess "rewrite error" if ( $root->isa('NULL') );
        }

        # continue exploring the parse tree
        foreach my $key ( keys %$pt_node ) {

            # not interested in the EOL token
            next if ( $key eq "EOL" );

            my $next = $pt_node->{$key};

            # skip and filter out string values
            if ( blessed($next) ) {

                if ( $key eq '__VALUE__' ) {

                    #then $next isa token
                    $ast_node->{'__VALUE__'} = $next;
                    $log->debug( "ast node = " . ref($ast_node) . " : token = " . ref($next) );
                }
                else {
                    push @stack, [ $next, $ast_node ];
                }
            }
        }
    }

    confess "rewrite error" if ( $root->isa('NULL') );

    return $root;
}

1;
__END__

=head1 NAME

Farly::ASA::Rewriter - Rewrite the parse tree into an abstract syntax tree

=head1 DESCRIPTION

Farly::ASA::Rewriter rewrites the Parse::RecDescent <autotree> parse tree into
an abstract syntax tree (AST). The AST structure mirrors the parse tree structure. 
Farly::ASA::Rewriter is run after Farly::ASA::Annotator has converted the
tokens into value objects. 

The AST node classes are defined in $AST_Node_Class. The AST node values
are the Token objects from the parse tree and are recognized by the presence
of the '__VALUE__' key.

Farly::ASA::Rewriter dies on error.

Farly::ASA::Rewriter is used by the Farly::ASA::Builder only.

=head1 COPYRIGHT AND LICENCE

Farly::ASA::Rewriter
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

