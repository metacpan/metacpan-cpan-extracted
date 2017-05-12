#! /usr/bin/env perl

use v5.10;
use warnings;

#===================================
package ClobalConstructor;
#===================================

use Moo;
use Kaiten::Container;

has 'config' => ( is => 'rw', );

sub create_container {
    my $self   = shift;
    my $config = $self->config;

    my $init_conf = {
        host_production => {
                             handler => sub { 'www.coolsite.com' },
                             probe   => sub { 1 }
                           },
        host_develop => {
                          handler => sub { 'localhost' },
                          probe   => sub { 1 }
                        },
        host_full_name => {
            handler => sub {
                my $c = shift;

                # no need checking - if entity absence - all die
                my $host = $c->get_by_name( 'host_' . $config->{mode} );
                return $host;
            },
            probe => sub { 1 }
                          },
        debug_level => {
            handler => sub {
                die 'original method have huge dependecies';
            },
            probe => sub { shift }
                       },
        system_logger => {
            handler => sub {
                my $c = shift;

                my $debugger = $c->get_by_name('logger_engine');
                my $level    = $c->get_by_name('debug_level');

                $debugger->set_level($level);

                return $debugger;

            },
            probe => sub { 1 }
                         },
        deadly_things => {
            handler => sub {
                die 'just died if you touch this';
            },
            probe => sub { shift }
                         },
                    };

    my $container = Kaiten::Container->new( init => $init_conf )

}


#===================================
package LoggerEngine;
#===================================

use Moo;

has 'level' => (
                 is      => 'rw',
                 writer  => 'set_level',
                 default => sub { 0 },
               );

sub output {
    my $self    = shift;
    my $message = shift;

    say( ( $self->level ? 'DEBUG ON: ' : 'DEBUG OFF: ' ) . $message );

}

sub self_check {
    my $self    = shift;
    my $message = shift;

    say "** CHECK:[$message] **";

}


#===================================
package main;
#===================================

my $stable_config = { 
                      mode => 'production', 
                    };

my $global_constructor = ClobalConstructor->new( config => $stable_config );
my $container = $global_constructor->create_container();

my $logger_engine_conf = {
                           handler => sub { LoggerEngine->new() },
                           probe   => sub { 
                                            my $self = shift; 
                                            $self->self_check( 'self-testing at livel [' . $self->level . '] ok' ) 
                                          },
                         };

$container->add( 'logger_engine' => $logger_engine_conf );

# ok, its seems little complexly, but this way can used to replace handler with mock
my $mock_object = {
                    handler => sub { 1 },
                    probe   => sub { 1 }
                  };

$container->remove('debug_level')->add( 'debug_level' => $mock_object );

my $logger    = $container->get_by_name('system_logger');
my $full_name = $container->get_by_name('host_full_name');

$logger->output( 'it is worked at - ' . $full_name );

say 'all ok';
