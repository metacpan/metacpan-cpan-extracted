#! /usr/bin/env perl

use v5.10;
use warnings;

#===================================
package ClobalConstructor;

#===================================

use Moo;
use Kaiten::Container;

has 'config' => ( is => 'rw', );

# just private method
my $logger_init;

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


                my $loger_engine;
                if ( $config->{logger} eq 'engine1' ){
                  $loger_engine = 'system_logger1';
                }
                elsif( $config->{logger} eq 'engine2' ){
                  $loger_engine = 'system_logger2';
                }
                
                my $selected_logger = $c->get_by_name($loger_engine);

                my $ilogger;
                eval {
                    $ilogger = $c->get_by_name('ilogger');
                    $ilogger->engine($selected_logger);
                };

                # we are have simple default resolver
                $ilogger = $selected_logger if ( ( $config->{logger} eq 'engine1' ) && !$ilogger );
                die 'unresolved dependencies [logger] ' unless $ilogger;

                return $ilogger;

            },
            probe => sub { 1 }
                         },
        system_logger1 => {
            handler => sub {
                my $c = shift;

                my $debugger = $c->get_by_name('logger_engine');
                my $level    = $c->get_by_name('debug_level');

                $debugger->set_level($level);

                return $debugger;

            },
            probe => sub { 1 }
                          },
        system_logger2 => {
            handler => sub {
                my $c = shift;

                my $debugger = $c->get_by_name('logger_engine2');
                my $level    = $c->get_by_name('debug_level');

                $debugger->set_level2($level);

                # you MAY change some properties of object after creation
                $debugger->color_message( $config->{message_color} ) if $config->{message_color};

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

    my $container = Kaiten::Container->new( init => $init_conf );

    my $loggers_config = $logger_init->($config);

    while ( my ( $name, $conf ) = each %$loggers_config ) {
        $container->add( $name, $conf );
    }

    return $container;
}

# here we ara should to build all Loggers to initialize container properly
$logger_init = sub {
    my $config = shift;

    my $debug_color = $config->{debug_color} ? $config->{debug_color} : 'white';

    my $loggers_config = {

        logger_engine => {
            handler => sub { LoggerEngine->new() },
            probe   => sub {
                my $self = shift;
                $self->self_check( 'self-testing at livel [' . $self->level . '] ok' );
            },
        },
        # you MAY init objects on create too
        logger_engine2 => {
            handler => sub { LoggerEngine2->new( color_debug => $debug_color) },
            probe   => sub {
                my $self = shift;
                $self->self_check2( 'self-testing at livel [' . $self->level2 . '] ok' );
            },
        },

        ilogger => {
                     handler => sub { ILoggerEngine->new() },
                     probe   => sub { shift->self_check },
                   },

    };

    return $loggers_config;

};

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
package LoggerEngine2;

#===================================

use Moo;
use Term::ANSIColor;

has 'level2' => (
                  is      => 'rw',
                  writer  => 'set_level2',
                  default => sub { 0 },
                );

has 'color_message' => (
                         is      => 'rw',
                         default => sub { 'red' },
                       );

has 'color_debug' => (
                       is      => 'rw',
                       default => sub { 'cyan' },
                     );

sub output2 {
    my $self    = shift;
    my $message = shift;

    print color $self->color_message;
    say( 'logger2 ' . ( $self->level2 ? 'DEBUG ON: ' : 'DEBUG OFF: ' ) . $message );
    print color 'reset';
}

sub self_check2 {
    my $self    = shift;
    my $message = shift;

    print color $self->color_debug;
    say 'logger2 ' . "** CHECK:[$message] **";
    print color 'reset';
}

#===================================
package ILoggerEngine;

#===================================

use Moo;

has 'engine' => ( is => 'rw', );

sub output {
    my $self    = shift;
    my $message = shift;

    my $engine = $self->engine;

    # no need check |else| - container filter it
    if ( ref $engine eq 'LoggerEngine' ){
      $engine->output($message)
    }
    elsif( ref $engine eq 'LoggerEngine2' ){
      $engine->output2($message)
    }

}

sub self_check { 1 }

#===================================
package main;

#===================================

=pod

Q. How I can use different module to make something without changing CODE, only by config?
A. Just create routing at container, may be you should to create an Interface to translate one command to another.

=cut

foreach my $log_engine ( 'engine1', 'engine2' ) {

    say "\n====test with [$log_engine]";

    my $stable_config = {
                          mode          => 'production',
                          logger        => $log_engine,
                          # next two settings working only for engine2 and have no effect to engine1
                          message_color => 'bold yellow',
                          debug_color   => 'black on_white'
                        };

    my $global_constructor = ClobalConstructor->new( config => $stable_config );
    my $container = $global_constructor->create_container();

    # ok, its seems little complexly, but this way can used to replace handler with mock
    my $mock_object = {
                        handler => sub { 1 },
                        probe   => sub { 1 }
                      };

    $container->remove('debug_level')->add( 'debug_level' => $mock_object );

    my $logger    = $container->get_by_name('system_logger');
    my $full_name = $container->get_by_name('host_full_name');

    $logger->output( 'it is worked at - ' . $full_name );

}

say "\n all ok";
