package Log::Dispatch::HipChat;

# ABSTRACT: Dispatch log events to HipChat

use strict;
use warnings;
 
our $VERSION = '0.0007';

use WebService::HipChat;
use Log::Dispatch::Output;
use Try::Tiny;
use JSON::XS qw/decode_json/;
 
use base qw( Log::Dispatch::Output );

use Params::Validate qw(validate SCALAR BOOLEAN);
Params::Validate::validation_options( allow_extra => 1 );

sub APPEND {0}
 
sub new {
    my $proto = shift;
    my $class = ref $proto || $proto;
 
    my %p = @_;
 
    my $self = bless {}, $class;
 
    $self->_basic_init(%p);
    $self->_make_handle;
 
    return $self;
}

sub _basic_init {
    my $self = shift;
 
    $self->SUPER::_basic_init(@_);
 
    my %p = validate(
        @_, {
            auth_token  => { type => SCALAR },
            room        => { type => SCALAR },
            color       => { type => SCALAR, optional => 1 },
        }
    );
 
    $self->{room}       = $p{room};
    $self->{color}      = $p{color};
    $self->{auth_token} = $p{auth_token};
}

sub _make_handle {
    my $self = shift;
 
    $self->{client}     = WebService::HipChat->new(
        auth_token  => $self->{auth_token},
    );
}

sub log_message {
    my $self = shift;
    my %p    = @_;

    my $http_response;
    my $color = $p{color} || $self->{color};
    if( ! $color and $p{level} ){
        if( $p{level} >= 4 ){
            $color = 'red';
        }elsif( $p{level} >= 3 ){
            $color = 'yellow';
        }elsif( $p{level} >=1 ){
            $color = 'green';
        }else{
            $color = 'gray';
        }
    }
    $color ||= 'gray';
        
    try{
        $self->{client}->send_notification( $self->{room}, { color => $color, message => $p{message} } );
    }catch{
        # If it fails, it will die with the http response
        $http_response = $_;
    };

    if( $http_response ){
        # Try to decode the response content
        try{
            my $response = HTTP::Response->parse( $http_response );
            my $data = decode_json( $response->decoded_content );
            if( $data->{error}{message} ){
                die( sprintf( "Failed to send message to room (%s): %s", $self->{room}, $data->{error}{message} ) );
            }else{
                die( "Could not find error message..." );
            }
        }catch{
            warn( $_ );
        };
    }
}
 
 
1;

=head1 NAME

Log::Dispatch::HipChat

=head1 DESCRIPTION

Send log messages to HipChat

=head1 SYNOPSIS

  log4perl.appender.hipchat=Log::Dispatch::HipChat
  log4perl.appender.hipchat.auth_token=your-auth-token
  log4perl.appender.hipchat.room=room-to-talk-to
  log4perl.appender.hipchat.color=color  <-- optional

=head1 COPYRIGHT

Copyright 2015, Robin Clarke

=head1 AUTHOR

Robin Clarke <robin@robinclarke.net>

