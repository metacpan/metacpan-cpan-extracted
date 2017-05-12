package AnyEvent::Gearman::Worker::RetryConnection;

# ABSTRACT: patching AnyEvent::Gearman::Worker for retrying support

our $VERSION = '0.8'; # VERSION 

use namespace::autoclean;

use Log::Log4perl qw(:easy);
Log::Log4perl->easy_init($ERROR);

use Scalar::Util 'weaken';
use AnyEvent;
use AnyEvent::Socket;
use AnyEvent::Handle;
use Any::Moose;

use Data::Dumper;

has retrying=>(is=>'rw',isa=>'Int',clearer=>'reset_retry',default=>sub{0});
has retry_timer=>(is=>'rw',isa=>'Object',clearer=>'reset_timer');
has registered=>(is=>'ro',isa=>'HashRef',default=>sub{return {};});

has retry_interval=>(is=>'rw',isa=>'Int',default=>sub{1});

extends 'AnyEvent::Gearman::Worker::Connection';
override connect=>sub{
    my ($self) = @_;
 
    # already connected
    return if $self->handler;
 
    my $g = tcp_connect $self->_host, $self->_port, sub {
        my ($fh) = @_;
 
        if ($fh) {
            my $handle = AnyEvent::Handle->new(
                fh       => $fh,
                on_read  => sub { $self->process_packet },
                on_error => sub {
                    my ($hdl, $fatal, $msg) = @_;

                    DEBUG $fatal;
                    DEBUG $msg;

                    my @undone = @{ $self->_need_handle },
                                 values %{ $self->_job_handles };
                    $_->event('on_fail') for @undone;
 
                    $self->_need_handle([]);
                    $self->_job_handles({});
                    $self->mark_dead;
                    
                    $self->retry_connect();
                },
            );
 
            $self->handler( $handle );
            $_->() for map { $_->[0] } @{ $self->on_connect_callbacks };
            
            DEBUG "connected"; 
            if( $self->retrying )
            {
                foreach my $key (keys %{$self->registered})
                {
                    DEBUG "re-register '".$key."'";
                    $self->register_function($key,$self->registered->{$key},1);
                }
            }
            $self->reset_retry;
            $self->reset_timer;
        }
        else {
            $self->retry_connect;
            return;
        }
 
        $self->on_connect_callbacks( [] );
    };
 
    weaken $self;
    $self->_con_guard($g);
 
    $self;
};

after 'register_function'=>sub{
    my $self = shift;
    my ($key,$code,$retrying) = @_;
    $self->registered->{$key} = $code unless $retrying;
};

sub retry_connect{
    my $self = shift;
    if( !$self->retry_timer ){
        my $timer = AE::timer $self->retry_interval,0,sub{
            DEBUG "retry connect";
            $self->retrying(1);
            $self->reset_timer;

            $self->connect();
        };
        $self->retry_timer($timer);
    }
}
__PACKAGE__->meta->make_immutable;
no Any::Moose;

sub patch_worker{
    my $worker = shift;
    my $js = $worker->job_servers();
    for(my $i=0; $i<@{$js}; $i++)
    {
        $js->[$i] = __PACKAGE__->new(hostspec=>$js->[$i]->hostspec);
    }
    return $worker;
}
1;

__END__
=pod

=head1 NAME

AnyEvent::Gearman::Worker::RetryConnection - patching AnyEvent::Gearman::Worker for retrying support

=head1 VERSION

version 0.8

=head1 ATTRIBUTES

=head2 retry_interval

set/get retry interval. default => 1

=head1 METHODS

=head2 patch_worker

replace Connections of a worker to RetryConnections.

   my $worker = gearman_worker $server;
   $worker = AnyEvent::Gearman::Worker::RetryConnection::patch_worker($worker);

=head1 AUTHOR

KHS, HyeonSeung Kim <sng2nara@hanmail.net>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2012 by HyeonSeung Kim.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

