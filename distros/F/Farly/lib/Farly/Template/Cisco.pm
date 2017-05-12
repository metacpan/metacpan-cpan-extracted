package Farly::Template::Cisco;

use 5.008008;
use strict;
use warnings;
use Carp;
use File::Spec;
use Template;
use Log::Any qw($log);

our $VERSION = '0.26';
our ( $volume, $dir, $file ) = File::Spec->splitpath( $INC{'Farly/Template/Cisco.pm'} );

sub new {
    my ( $class, $file, %args ) = @_;

    my $self = {
        FILE     => $file,
        TEMPLATE => undef,
        TEXT     => undef,    #set this to use text port and protocol names
    };

    bless $self, $class;

    $self->_init(%args);
    
    $log->info("$self new");

    return $self;
}

sub _template { return $_[0]->{TEMPLATE}; }
sub _file     { return $_[0]->{FILE}; }
sub _text     { $_[0]->{TEXT} }

sub _init {
    my ( $self, %args ) = @_;

    my $path = "$volume$dir" . "Files/";

    $self->{TEMPLATE} = Template->new(
        {
            %args,
            INCLUDE_PATH => $path,
            TRIM         => 1,
        }
      )
      or die "$Template::ERROR\n";
}

sub use_text {
    my ( $self, $flag ) = @_;
    $self->{TEXT} = $flag;
}

# port_formatter     => Farly::ASA::PortFormatter->new(),
# protocol_formatter => Farly::ASA::ProtocolFormatter->new(),
# icmp_formatter     => Farly::ASA::ICMPFormatter->new(),

sub set_formatters {
    my ( $self, $formatter ) = @_;
    foreach my $key ( keys %$formatter ) {
        confess "invalid formatters"
          if ( $key !~ /port_formatter|protocol_formatter|icmp_formatter/ );
        $self->{$key} = $formatter->{$key};
    }
}

sub _value_format {
    my ( $self, $value ) = @_;

    my $string;

    if ( $value->isa('Farly::IPv4::Address') ) {

        $string = "host " . $value->as_string();
    }
    elsif ( $value->isa('Farly::Transport::Protocol') ) {

        if ( $self->_text ) {
            $string = defined($self->{protocol_formatter}) && defined( $self->{protocol_formatter}->as_string( $value->as_string() ) )
              ? $self->{protocol_formatter}->as_string( $value->as_string() )
              : $value->as_string();
        }
        else {
            $string = $value->as_string();
        }
    }
    elsif ( $value->isa('Farly::Transport::PortGT') ) {
        $string = "gt ";
        if ( $self->_text ) {
            $string .= defined($self->{port_formatter}) && defined( $self->{port_formatter}->as_string( $value->as_string() ) )
              ? $self->{port_formatter}->as_string( $value->as_string() )
              : $value->as_string();
        }
        else {
            $string .= $value->as_string();
        }
    }
    elsif ( $value->isa('Farly::Transport::PortLT') ) {
        $string = "lt ";
        if ( $self->_text ) {
            $string .= defined($self->{port_formatter}) && defined( $self->{port_formatter}->as_string( $value->as_string() ) )
              ? $self->{port_formatter}->as_string( $value->as_string() )
              : $value->as_string();
        }
        else {
            $string .= $value->as_string();
        }
    }
    elsif ( $value->isa('Farly::Transport::Port') ) {
        $string = "eq ";
        if ( $self->_text ) {
            $string .= defined($self->{port_formatter}) && defined( $self->{port_formatter}->as_string( $value->as_string() ) )
              ? $self->{port_formatter}->as_string( $value->as_string() )
              : $value->as_string();
        }
        else {
            $string .= $value->as_string();
        }
    }
    elsif ( $value->isa('Farly::Transport::PortRange') ) {

        $string = "range ";

        if ( $self->_text ) {

            $string .= defined($self->{port_formatter}) && defined( $self->{port_formatter}->as_string( $value->first() ) )
              ? $self->{port_formatter}->as_string( $value->first() )
              : $value->first();

            $string .= " ";

            $string .= defined($self->{port_formatter}) && defined( $self->{port_formatter}->as_string( $value->last() ) )
              ? $self->{port_formatter}->as_string( $value->last() )
              : $value->last();
        }
        else {
            $string .= $value->as_string();
        }
    }
    elsif ( $value->isa('Farly::Object::Ref') ) {

        $string = $value->get("ID")->as_string();
    }
    else {

        $string = $value->as_string();
        $string =~ s/0.0.0.0 0.0.0.0/any/g;
        $string =~ s/^\s+|\s+$//g;
    }

    return $string;
}

sub _format {
    my ( $self, $ce ) = @_;

    my $GROUP_REF = Farly::Object::Ref->new();
    $GROUP_REF->set( 'ENTRY', Farly::Value::String->new('GROUP') );

    my $OBJECT_REF = Farly::Object::Ref->new();
    $OBJECT_REF->set( 'ENTRY', Farly::Value::String->new('OBJECT') );

    my $IF_REF = Farly::Object::Ref->new();
    $IF_REF->set( 'ENTRY', Farly::Value::String->new('INTERFACE') );

    my $NAME = Farly::Object->new();
    $NAME->set( 'ENTRY', Farly::Value::String->new('NAME') );

    my $INTERFACE = Farly::Object->new();
    $INTERFACE->set( 'ENTRY', Farly::Value::String->new('INTERFACE') );

    my $ROUTE = Farly::Object->new();
    $ROUTE->set( 'ENTRY', Farly::Value::String->new('ROUTE') );

    my $RULE = Farly::Value::String->new('RULE');

    my $ALL           = Farly::Transport::PortRange->new('1 65535');
    my $ANY_ICMP_TYPE = Farly::IPv4::ICMPType->new(-1);

    my $hash;

    #names should not be prefixed with 'host'
    if ( $ce->matches($NAME) ) {
        foreach my $key ( $ce->get_keys() ) {
            $hash->{$key} = $ce->get($key)->as_string();
        }
        return $hash;
    }

    #interface ip addresses should not be prefixed with 'host'
    if ( $ce->matches($INTERFACE) ) {
        foreach my $key ( $ce->get_keys() ) {
            $hash->{$key} = $ce->get($key)->as_string();
        }
        return $hash;
    }

    # for routes, neither interface names nor ip addresses should be prefixed
    if ( $ce->matches($ROUTE) ) {
        foreach my $key ( $ce->get_keys() ) {
            if ( $key eq 'INTERFACE' ) {

                # use _value_format because $ce isa 'Farly::Object::Ref'
                $hash->{$key} = $self->_value_format( $ce->get($key) );
                next;
            }
            $hash->{$key} = $ce->get($key)->as_string();
        }
        return $hash;
    }

    foreach my $key ( $ce->get_keys() ) {

        my $value = $ce->get($key);

        my $prefix;
        my $string;

        # skip port range 1 - 65535
        if ( $value->equals($ALL) ) {
            next;
        }

        # skip default ICMP type '-1'
        if ( $value->equals($ANY_ICMP_TYPE) ) {
            next;
        }

        if ( $value->isa('Farly::Object::Ref') ) {

            if ( $value->matches($GROUP_REF) ) {
                if ( $ce->get('ENTRY')->equals($RULE) ) {
                    $prefix = 'object-group';
                }
            }
            elsif ( $value->matches($OBJECT_REF) ) {
                $prefix = 'object';
            }
            elsif ( $value->matches($IF_REF) ) {
                $prefix = 'interface';
            }
        }

        $string = defined($prefix)
          ? $prefix . ' ' . $self->_value_format($value)
          : $self->_value_format($value);

        if ( $self->_text && $key eq 'ICMP_TYPE' ) {

            $string = defined($self->{icmp_formatter}) && defined( $self->{icmp_formatter}->as_string( $value->as_string() ) )
              ? $self->{icmp_formatter}->as_string( $value->as_string() )
              : $value->as_string();
        }

        $hash->{$key} = $string;
    }

    return $hash;
}

sub as_string {
    my ( $self, $ce ) = @_;

    my $hash = $self->_format($ce);

    $self->_template()->process( $self->_file, $hash )
      or die $self->_template()->error();
}

1;
__END__

=head1 NAME

Farly::Template::Cisco - Converts the Farly model into Cisco format

=head1 DESCRIPTION

Farly::Template::Cisco formats and prints the Farly firewall model into 
Cisco configuration formats.

=head1 METHODS

=head2 new()

The constructor. Device type required.

  $template = Farly::Template::Cisco->new('ASA');

Valid device types:

  ASA

=head2 as_string( <Farly::Object> )

Prints the current Farly object in Cisco format.

  $template->as_string( $object );

=head2 set_formatters( \%formatters )

Set the device specific integer to string formatters to use. Each
of 'port_formatter', 'protocol_formatter' and 'icmp_formatter' must
be specified.

  my $formatters = {
    'port_formatter'     => Farly::ASA::PortFormatter->new(),
    'protocol_formatter' => Farly::ASA::ProtocolFormatter->new(),
    'icmp_formatter'     => Farly::ASA::ICMPFormatter->new(),
  };

  $template->set_formatters($formatters);

=head2 use_text( 0|1 )

Configure the object to use the specified value formatters

  $template->use_text(1);

=head1 COPYRIGHT AND LICENCE

Farly::Template::Cisco
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
