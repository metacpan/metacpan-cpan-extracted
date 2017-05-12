package Log::Dispatch::Slack;

# ABSTRACT: Dispatch log events to Slack

use strict;
use warnings;
 
our $VERSION = '0.0004';

use WebService::Slack::WebApi;
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
            token       => { type => SCALAR },
            channel     => { type => SCALAR },
            icon        => { type => SCALAR, optional => 1 },
            username    => { type => SCALAR, optional => 1 },
        }
    );
 
    $self->{channel}    = $p{channel};
    $self->{token}      = $p{token};
    $self->{username}   = $p{username};
    $self->{icon}       = $p{icon};
}

sub _make_handle {
    my $self = shift;
 
    $self->{client} = WebService::Slack::WebApi->new(
        token  => $self->{token},
    );
}

sub log_message {
    my $self = shift;
    my %p    = @_;
    
    my %post_params = (
        text    => $p{message},
        channel => $p{channel}  || $self->{channel},
    );
    if( $p{icon} ){
        $post_params{icon_url} = $p{icon};
    }elsif( $self->{icon} ){
        $post_params{icon_url} = $self->{icon};
    }
    
    if( $p{username} ){
        $post_params{username} = $p{username};
    }elsif( $self->{username} ){
        $post_params{username} = $self->{username};
    }else{
        $post_params{as_user} = 1;
    }
    
    my $response = $self->{client}->chat->post_message( %post_params );
    
    if( ! $response->{ok} ){
        die( sprintf( "Failed to send message to channel (%s): %s", $self->{channel}, $response->{error} ) );
    }
}
 
 
1;

=head1 NAME

Log::Dispatch::Slack

=head1 DESCRIPTION

Send log messages to Slack

=head1 SYNOPSIS

  log4perl.appender.hipchat=Log::Dispatch::Slack
  log4perl.appender.hipchat.auth_token=your-auth-token
  log4perl.appender.hipchat.channel=channel-to-talk-to

=head1 COPYRIGHT

Copyright 2016, Robin Clarke

=head1 AUTHOR

Robin Clarke <robin@robinclarke.net>

