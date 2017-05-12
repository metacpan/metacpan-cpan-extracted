package Farly::ASA::Annotator;

use 5.008008;
use strict;
use warnings;
use Carp;
use Scalar::Util qw(blessed);
use Log::Any qw($log);
use Farly::ASA::PortFormatter;
use Farly::ASA::ProtocolFormatter;
use Farly::ASA::ICMPFormatter;

our $VERSION = '0.26';
our $AUTOLOAD;

#each token type maps to a class
our $Token_Class_Map = {
    'STRING'       => 'Farly::Value::String',
    'DIGIT'        => 'Farly::Value::Integer',
    'NAME'         => 'Farly::Value::String',    #method replaces name with IP
    'NAME_ID'      => 'Farly::Value::String',    #this is just the name string
    'IF_REF'       => 'Farly::Object::Ref',
    'OBJECT_REF'   => 'Farly::Object::Ref',
    'GROUP_REF'    => 'Farly::Object::Ref',
    'RULE_REF'     => 'Farly::Object::Ref',
    'GROUP_TYPE'   => 'Farly::Value::String',
    'OBJECT_ENTRY' => 'Farly::Value::String',
    'OBJECT_TYPE'  => 'Farly::Value::String',
    'ANY'          => 'Farly::IPv4::Network',    #method ANY = '0.0.0.0 0.0.0.0'
    'IPADDRESS'    => 'Farly::IPv4::Address',
    'MASK'         => 'Farly::IPv4::Address',
    'IPNETWORK'    => 'Farly::IPv4::Network',
    'IPRANGE'      => 'Farly::IPv4::Range',
    'NAMED_NET'    => 'Farly::Value::String',    #method replaces name with IP
    'PROTOCOL'       => 'Farly::Transport::Protocol',
    'GROUP_PROTOCOL' => 'Farly::Value::String',    #not ::Protocol because of 'tcp-udp'
    'ICMP_TYPE'     => 'Farly::IPv4::ICMPType',       #method maps string to int
    'PORT_ID'       => 'Farly::Transport::Port',      #method maps string to int
    'PORT_RANGE'    => 'Farly::Transport::PortRange', #method maps string to int
    'PORT_GT'       => 'Farly::Transport::PortGT',    #method maps string to int
    'PORT_LT'       => 'Farly::Transport::PortLT',    #method maps string to int
    'ACTIONS'       => 'Farly::Value::String',
    'ACL_TYPES'     => 'Farly::Value::String',
    'REMARKS'       => 'Farly::Value::String',
    'ACL_DIRECTION' => 'Farly::Value::String',
    'ACL_GLOBAL'    => 'Farly::Value::String',
    'STATE'         => 'Farly::Value::String',
    'ACL_STATUS'    => 'Farly::Value::String',
    'LOG_LEVEL'     => 'Farly::Value::String',
    'DEFAULT_ROUTE' => 'Farly::IPv4::Network',    #method DEFAULT_ROUTE sets '0.0.0.0 0.0.0.0'
    'TUNNELED'      => 'Farly::Value::String'
};

# 'ENTRY' is like a namespace in which an ID must be unique
# A <type>_REF refers to a Farly::Object by ENTRY and ID
our $Entry_Map = {
    'IF_REF'     => 'INTERFACE',
    'OBJECT_REF' => 'OBJECT',
    'GROUP_REF'  => 'GROUP',
    'RULE_REF'   => 'RULE',
};

sub new {
    my ($class) = @_;

    my $self = {
        NAMES => {},    #name to address 'symbol table'
        PORT_FMT     => Farly::ASA::PortFormatter->new(),
        PROTOCOL_FMT => Farly::ASA::ProtocolFormatter->new(),
        ICMP_FMT     => Farly::ASA::ICMPFormatter->new()
    };
    bless $self, $class;
    
    $log->info("$self new");

    return $self;
}

sub port_formatter {
    return $_[0]->{PORT_FMT};
}

sub protocol_formatter {
    return $_[0]->{PROTOCOL_FMT};
}

sub icmp_formatter {
    return $_[0]->{ICMP_FMT};
}

sub visit {
    my ( $self, $node ) = @_;

    # set s of explored vertices
    my %seen;

    #stack is all neighbors of s
    my @stack;
    push @stack, $node;

    #my $key;

    while (@stack) {

        $node = pop @stack;

        next if ( $seen{$node}++ );

        #visit this node if its a token
        if ( exists( $node->{'__VALUE__'} ) ) {
            my $method = ref($node);
            $self->$method($node);
            next;
        }

        # add name info the the names "symbol table"
        if ( $node->isa('named_ip') ) {
            $self->named_ip($node);
        }

        # continue walking the parse tree
        foreach my $key ( keys %$node ) {

            next if ( $key eq 'EOL' );

            my $next = $node->{$key};

            if ( blessed($next) ) {

                push @stack, $next;
            }
        }
    }
    return 1;
}

sub named_ip {
    my ( $self, $node ) = @_;

    my $name = $node->{name}->{NAME_ID}->{__VALUE__}
      or confess "$self error: name not found for ", ref($node);

    my $ip = $node->{IPADDRESS}->{__VALUE__}
      or confess "$self error: IP address not found for ", ref($node);

    $log->debug("name = $name : ip = $ip");

    $self->{NAMES}->{$name} = $ip;
}

sub NAME {
    my ( $self, $node ) = @_;

    my $name = $node->{'__VALUE__'}
      or confess "$self error: __VALUE__ not found for name";

    my $ip = $self->{NAMES}->{$name}
      or confess "$self error: IP address not found for name $name";

    $node->{'__VALUE__'} = Farly::IPv4::Address->new($ip);
}

sub NAMED_NET {
    my ( $self, $node ) = @_;

    my $named_net = $node->{'__VALUE__'}
      or confess "$self error: __VALUE__ not found for name";

    my ( $name, $mask ) = split( /\s+/, $named_net );

    my $ip = $self->{NAMES}->{$name}
      or confess "$self error: IP address not found for name $name";

    $node->{'__VALUE__'} = Farly::IPv4::Network->new("$ip $mask");
}

sub ANY {
    my ( $self, $node ) = @_;
    $node->{'__VALUE__'} = Farly::IPv4::Network->new("0.0.0.0 0.0.0.0");
}

sub DEFAULT_ROUTE {
    my ( $self, $node ) = @_;
    $node->{'__VALUE__'} = Farly::IPv4::Network->new("0.0.0.0 0.0.0.0");
}

sub ICMP_TYPE {
    my ( $self, $node ) = @_;

    my $icmp_type = $node->{'__VALUE__'};

    $node->{'__VALUE__'} = defined( $self->icmp_formatter()->as_integer($icmp_type) )
      ? Farly::IPv4::ICMPType->new( $self->icmp_formatter()->as_integer($icmp_type) )
      : Farly::IPv4::ICMPType->new($icmp_type);
}

sub PROTOCOL {
    my ( $self, $node ) = @_;

    my $protocol = $node->{'__VALUE__'};

    $node->{'__VALUE__'} = defined( $self->protocol_formatter()->as_integer($protocol) )
      ? Farly::Transport::Protocol->new( $self->protocol_formatter()->as_integer($protocol) )
      : Farly::Transport::Protocol->new($protocol);
}

sub PORT_ID {
    my ( $self, $node ) = @_;

    my $port = $node->{'__VALUE__'};

    $node->{'__VALUE__'} = defined( $self->port_formatter()->as_integer($port) )
      ? Farly::Transport::Port->new( $self->port_formatter()->as_integer($port) )
      : Farly::Transport::Port->new($port);
}

sub PORT_RANGE {
    my ( $self, $node ) = @_;

    my $port_range = $node->{'__VALUE__'};

    my ( $low, $high ) = split( /\s+/, $port_range );

    if ( defined $self->port_formatter()->as_integer($low) ) {
        $low = $self->port_formatter()->as_integer($low);
    }

    if ( defined $self->port_formatter()->as_integer($high) ) {
        $high = $self->port_formatter()->as_integer($high);
    }

    $node->{'__VALUE__'} = Farly::Transport::PortRange->new("$low $high");
}

sub PORT_GT {
    my ( $self, $node ) = @_;

    my $port = $node->{'__VALUE__'};

    $node->{'__VALUE__'} = defined( $self->port_formatter()->as_integer($port) )
      ? Farly::Transport::PortGT->new( $self->port_formatter()->as_integer($port) )
      : Farly::Transport::PortGT->new($port);
}

sub PORT_LT {
    my ( $self, $node ) = @_;

    my $port = $node->{'__VALUE__'};

    $node->{'__VALUE__'} = defined( $self->port_formatter()->as_integer($port) )
      ? Farly::Transport::PortLT->new( $self->port_formatter()->as_integer($port) )
      : Farly::Transport::PortLT->new($port);
}

sub _new_ObjectRef {
    my ( $self, $token_class, $value ) = @_;

    my $entry = $Entry_Map->{$token_class}
      or confess "No token type to ENTRY mapping for token $token_class\n";

    my $ce = Farly::Object::Ref->new();

    $ce->set( 'ENTRY', Farly::Value::String->new($entry) );
    $ce->set( 'ID',    Farly::Value::String->new($value) );

    return $ce;
}

sub AUTOLOAD {
    my ( $self, $node ) = @_;

    my $type = ref($self)
      or confess "$self is not an object";

    confess "tree node for $type required"
      unless defined($node);

    confess "value not found in node ", ref($node)
      unless defined( $node->{'__VALUE__'} );

    my $token_class = ref($node);

    my $class = $Token_Class_Map->{$token_class}
      or confess "$self error: class not found for $token_class\n";

    my $object;

    my $value = $node->{'__VALUE__'};

    if ( $class eq 'Farly::Object::Ref' ) {
        #need to set 'ENTRY' and 'ID' properties
        $object = $self->_new_ObjectRef( $token_class, $value );
    }
    else {
        #create the object right away
        $object = $class->new($value);
    }

    $node->{'__VALUE__'} = $object;
}

sub DESTROY { }

1;
__END__

=head1 NAME

Farly::ASA::Annotator - Map tokens to value objects

=head1 DESCRIPTION

Farly::ASA::Annotator walks the Parse::RecDescent <autotree> parse tree
searching for Token objects. Token objects are recognized by the presence
of the '__VALUE__' key (see <autotree>). Farly::ASA::Annotator then
maps the Token object to a value object of suitable class based on
the type of Token object. The scalar value associated with the token's 
'__VALUE__' key is replaced with the new value object.

Farly::ASA::Annotator dies on error.

Farly::ASA::Annotator is used by the Farly::ASA::Builder only.

=head1 COPYRIGHT AND LICENCE

Farly::ASA::Annotator
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
