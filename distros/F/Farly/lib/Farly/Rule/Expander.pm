package Farly::Rule::Expander;

use 5.008008;
use strict;
use warnings;
use Carp;
use Log::Any qw($log);
use Farly::Object::Aggregate;

our $VERSION = '0.26';

sub new {
    my ( $class, $fw ) = @_;

    confess "configuration container object required"
      unless ( defined($fw) );

    confess "Farly::Object::List object required"
      unless ( $fw->isa('Farly::Object::List') );

    my $self = {
        CONFIG    => $fw,
        AGGREGATE => undef,
    };

    bless $self, $class;
    
    $log->info("$self new");
    $log->info( "$self CONFIG " . $self->{CONFIG} );

    $self->_init();

    return $self;
}

sub config { return $_[0]->{CONFIG}; }
sub _agg   { return $_[0]->{AGGREGATE}; }

sub _init {
    my ($self) = @_;
    $self->{AGGREGATE} = Farly::Object::Aggregate->new( $self->config );
    $self->{AGGREGATE}->groupby( 'ENTRY', 'ID' );
}

sub _set_defaults {
    my ( $self, $ce ) = @_;

    my $RULE = Farly::Object->new();
    $RULE->set( 'ENTRY', Farly::Value::String->new('RULE') );

    my $IP   = Farly::Transport::Protocol->new('0');
    my $TCP  = Farly::Transport::Protocol->new('6');
    my $UDP  = Farly::Transport::Protocol->new('17');
    my $ICMP = Farly::Transport::Protocol->new('1');

    #Check if the config entry is an access-list
    if ( $ce->matches($RULE) ) {

        return if ( $ce->has_defined('COMMENT') );

        #Check if the access-list protocol is ip, tcp or udp
        if (   $ce->get('PROTOCOL')->equals($IP)
            || $ce->get('PROTOCOL')->equals($TCP)
            || $ce->get('PROTOCOL')->equals($UDP) )
        {

            $log->debug("defaulting ports for $ce");

            #if a srcport is not defined, define all ports
            if ( !$ce->has_defined('SRC_PORT') ) {

                $ce->set( 'SRC_PORT', Farly::Transport::PortRange->new( 1, 65535 ) );
                $log->debug( 'set SRC_PORT = ' . $ce->get('SRC_PORT') );
            }

            #if a dst port is not defined, define all ports
            if ( !$ce->has_defined('DST_PORT') ) {

                $ce->set( 'DST_PORT', Farly::Transport::PortRange->new( 1, 65535 ) );
                $log->debug( "set DST_PORT = " . $ce->get('DST_PORT') );
            }
        }

        if (   $ce->get('PROTOCOL')->equals($IP)
            || $ce->get('PROTOCOL')->equals($ICMP) )
        {
            $log->debug("defaulting ports for $ce");

            #if an icmp type is not defined, define all icmp types as -1
            if ( !$ce->has_defined('ICMP_TYPE') ) {

                $ce->set( 'ICMP_TYPE', Farly::IPv4::ICMPType->new(-1) );
                $log->debug('set ICMP_TYPE to -1 ');
            }
        }
    }
    else {
        confess "_set_defaults is for RULE objects only";
    }
}

sub expand_all {
    my ($self) = @_;

    my $expanded = Farly::Object::List->new();

    my $RULE = Farly::Value::String->new('RULE');

    my $RULE_SEARCH = Farly::Object->new();
    $RULE_SEARCH->set( 'ENTRY', $RULE );

    my $rules = Farly::Object::List->new();

    $self->config->matches( $RULE_SEARCH, $rules );

    foreach my $ce ( $rules->iter() ) {
        eval {
            my $clone = $ce->clone();
            $self->expand( $clone, $expanded );
        };
        if ($@) {
            confess "$@ \n expand failed for ", $ce->dump(), "\n";
        }
    }

    return $expanded;
}

# { 'key' => ::HashRef } refers to one or more actual Objects
#   Replace the ::HashRef with a ::Set of the actual objects
#   the actual objects might hold a ::HashRef
# { 'key' => ::Set } is a list of config ::Hash or ::HashRef's.
#   For every object in the Set clone the RULE object
#   and replace the RULE value with the object from the ::Set
# { 'key' => Farly::Object }
#   use "OBJECT" key/value in the raw RULE object

sub expand {
    my ( $self, $rule, $result ) = @_;

    my $is_expanded;
    my @stack;
    push @stack, $rule;

    my $COMMENT = Farly::Object->new();
    $COMMENT->set( 'OBJECT_TYPE', Farly::Value::String->new('COMMENT') );

    my $SERVICE = Farly::Object->new();
    $SERVICE->set( 'OBJECT_TYPE', Farly::Value::String->new('SERVICE') );

    my $VIP = Farly::Object->new();
    $VIP->set( 'OBJECT_TYPE', Farly::Value::String->new('VIP') );

    while (@stack) {
        my $ce = pop @stack;

        foreach my $key ( $ce->get_keys() ) {

            my $value = $ce->get($key);

            $log->debug("entry $ce : key = $key : value = $value");

            $is_expanded = 1;

            if ( $value->isa('Farly::Object::Ref') ) {

                $is_expanded = 0;

                my $actual = $self->_agg->matches($value);

                if ( !defined $actual ) {
                    confess "actual not found for $key";
                }

                $ce->set( $key, $actual );

                push @stack, $ce;

                last;
            }
            elsif ( $value->isa('Farly::Object::List') ) {

                $is_expanded = 0;

                $log->debug("$ce => $key isa $value");

                foreach my $object ( $value->iter() ) {

                    my $clone = $ce->clone();

                    $clone->set( $key, $object );

                    push @stack, $clone;
                }

                last;
            }
            elsif ( $value->isa('Farly::Object') ) {

                $is_expanded = 0;

                my $clone = $ce->clone();

                if ( $value->matches($COMMENT) ) {

                    $log->debug( "skipped group comment :\n" . $ce->dump() . "\n" );

                    last;
                }
                if ( $value->matches($VIP) ) {

                    $self->_expand_vip( $key, $clone, $value );
                }
                elsif ( $value->matches($SERVICE) ) {

                    $self->_expand_service( $clone, $value );
                }
                elsif ( $value->has_defined('OBJECT') ) {

                    $clone->set( $key, $value->get('OBJECT') );
                }
                else {

                    $log->warn( "skipped $ce property $key has no OBJECT\n" . $ce->dump() );

                    last;
                }

                push @stack, $clone;

                last;
            }
        }

        if ($is_expanded) {
            $self->_set_defaults($ce);
            $result->add($ce);
        }
    }

    return $result;
}

sub _expand_service {
    my ( $self, $clone, $service_object ) = @_;
    my @keys = qw(PROTOCOL SRC_PORT DST_PORT ICMP_TYPE);
    foreach my $key (@keys) {
        if ( $service_object->has_defined($key) ) {
            $clone->set( $key, $service_object->get($key) );
        }
    }
    return;
}

sub _expand_vip {
    my ( $self, $key, $clone, $vip_object ) = @_;

    $log->debug("processing VIP $vip_object : key = $key");

    if ( $key eq 'DST_IP' ) {
        $clone->set( $key, $vip_object->get('REAL_IP') );
    }
    elsif ( $key eq 'DST_PORT' ) {
        $clone->set( $key, $vip_object->get('REAL_PORT') );
    }
    else {
        confess "invalid key for VIP\n", "key $key \n", "rule: ",
          $clone->dump(), "\n", "vip: ", $vip_object->dump(), "\n";
    }

    return;
}

1;
__END__

=head1 NAME

Farly::Rule::Expander - Expands configuration firewall rules

=head1 DESCRIPTION

Farly::Rule::Expander converts a firewall configuration rule set into a expanded rule set.
The expanded firewall rule set is an Farly::Object::List<Farly::Object> containing
all firewall rules.  

An expanded rule set has no references to other firewall objects.  The expanded 
firewall rule is for specific packet to firewall rule matching.

=head1 METHODS

=head2 new( $list )

The constructor. The firewall configuration is provided.

  $rule_expander = Farly::Rule::Expander->new( <Farly::Object::List> );

=head2 expand_all()

Returns a Farly::Object::List<Farly::Object> container of all
expanded firewall rule entries in the current Farly firewall model.

  $expanded_ruleset = $rule_expander->expand_all();

=head2 expand( $rule<Farly::Object>, $result<Farly::Object::List>)

Returns the expanded version of the given firewall rule in the
provided result container.

  $expanded_rule = $rule_expander->expand( $rule, $result );

=head1 COPYRIGHT AND LICENCE

Farly::Rule::Expander
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
