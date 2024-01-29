package Lemonldap::NG::Portal::Lib::Radius;
use Authen::Radius;

use strict;
use Mouse;

our $VERSION = '2.18.0';

# INITIALIZATION

has radius                      => ( is => 'rw' );
has req_attributes_rules        => ( is => 'rw', default => sub { {} } );
has radius_server               => ( is => 'rw' );
has radius_secret               => ( is => 'rw' );
has radius_timeout              => ( is => 'rw' );
has radius_req_attribute_config => ( is => 'rw' );
has radius_dictionary           => ( is => 'rw' );
has modulename                  => ( is => 'rw' );
has p                           => ( is => 'rw' );
has logger                      => ( is => 'rw' );

sub BUILD {
    my $self = shift;

    if ( $self->radius_dictionary ) {

        # required to be able to resolve names and values
        # default to /etc/raddb/dictionary ( same as Authen::Radius library ).
        if ( -r $self->radius_dictionary ) {
            Authen::Radius->load_dictionary( $self->radius_dictionary );
        }
        else {
            # log an error, avoid server error if missing.
            $self->logger->error(
                    "Radius library resolution of attribute names"
                  . " requires to set a dictionary in "
                  . $self->radius_dictionary
                  . ", this file could not be read." );
        }
    }

    my $attribute_config = $self->radius_req_attribute_config || {};
    while ( my ( $attr, $rule ) = each %{$attribute_config} ) {
        my $compiled_rule = $self->p->buildRule( $rule,
            $self->modulename . " request attribute" );
        if ($compiled_rule) {
            $self->req_attributes_rules->{$attr} = $compiled_rule;
        }
    }
    return 1;
}

sub _get_radius {
    my ($self) = @_;

    # Cache radius object in between requests
    my $radius = $self->radius;
    return $radius if $radius;

    foreach (qw(radius_server radius_secret)) {
        unless ( $self->$_ ) {
            $self->logger->error(
                $self->modulename . ": missing \"$_\" parameter, aborting" );
            return;
        }
    }

    my @server_list  = split /[,\s]+/, $self->radius_server;
    my $first_server = $server_list[0];
    $self->logger->error( $self->modulename . ': connection to server failed' )
      unless (
        $self->radius(
            Authen::Radius->new(
                Host   => $first_server,
                Secret => $self->radius_secret,
                (
                    $self->radius_timeout
                    ? ( TimeOut => $self->radius_timeout )
                    : ()
                ),
                ( @server_list > 1 ? ( NodeList => \@server_list ) : () ),
            )
        )
      );

    return $self->radius;
}

sub _check_pwd_radius {
    my ( $self, @attributes ) = @_;

    my $radius = $self->_get_radius;
    unless ($radius) {
        return;
    }

    my $nas = eval { $radius->{'sock'}->sockhost() };
    $radius->clear_attributes;
    $radius->add_attributes( @attributes,
        { Name => 4, Value => $nas || '127.0.0.1', Type => 'ipaddr' } );
    $radius->send_packet(Authen::Radius::ACCESS_REQUEST);
    my $rcv = $radius->recv_packet();

    # Authen::Radius does not handle retrying automatically in
    # failover scenarios
    if ( $radius->get_error eq "ETIMEOUT" ) {
        $self->logger->warn(
            "Radius request has timed out, retrying on all configured hosts");
        $radius->send_packet( Authen::Radius::ACCESS_REQUEST, 1 );
        $rcv = $radius->recv_packet();
    }

    unless ( defined($rcv) ) {
        $self->logger->error(
            "Error contacting Radius server: " . $radius->strerror );
        return;
    }
    return {
        result     => ( $rcv == Authen::Radius::ACCESS_ACCEPT ),
        attributes =>
          $self->_parse_attributes( $self->radius->get_attributes() ),
    };
}

sub _parse_attributes {
    my ( $self, @recv_attributes ) = @_;
    my %attribute_result;

    foreach my $a (@recv_attributes) {
        $self->logger->debug( 'Radius attribute '
              . 'attrName='
              . $a->{AttrName}
              . ' name='
              . $a->{Name} . ' tag='
              . $a->{Tag} . '['
              . $a->{Code} . '] = '
              . $a->{RawValue} );
        $attribute_result{ $a->{AttrName} } = $a->{RawValue};
    }
    return \%attribute_result;
}

sub check_pwd {
    my ( $self, $req, $sessionInfo, $name, $pwd ) = @_;

    my @attributes;
    push @attributes, { Name => 1, Value => $name, Type => 'string' };
    if ($pwd) {
        push @attributes, { Name => 2, Value => $pwd, Type => 'string' };
    }

    while ( my ( $k, $r ) = each %{ $self->req_attributes_rules } ) {
        my $v    = eval { $r->( $req, $sessionInfo ) };
        my $user = $req->user;
        if ($@) {
            $self->logger->warn( "Error evaluating Radius attribute rule"
                  . " for attribute $k of user $user: $@" );
        }
        $self->logger->debug("Adding attribute $k => $v to Radius request");
        push @attributes, { Name => $k, Value => $v, };
    }

    return $self->_check_pwd_radius(@attributes);
}

1;
