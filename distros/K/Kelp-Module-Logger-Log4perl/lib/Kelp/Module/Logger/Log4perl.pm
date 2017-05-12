package Kelp::Module::Logger::Log4perl;
our $VERSION = "0.003";
$VERSION = eval $VERSION;
use strict;
use warnings;

use Kelp::Base 'Kelp::Module::Logger';
use Log::Log4perl;
use Log::Log4perl::Level;
use Data::Dumper;

attr 'category' => '';

use constant ({
    NOTICE    => $INFO + 1,
    CRITICAL  => $ERROR + 1,
    ALERT     => $FATAL + 1,
    EMERGENCY => $OFF - 1
});

sub _logger {
    my ( $self, %args ) = @_;
    
    Log::Log4perl::Level::add_priority('NOTICE',    NOTICE,     2, 2);
    Log::Log4perl::Level::add_priority('CRITICAL',  CRITICAL,   0, 5);
    Log::Log4perl::Level::add_priority('ALERT',     ALERT,     -1, 6);
    Log::Log4perl::Level::add_priority('EMERGENCY', EMERGENCY, -1, 7);
    Log::Log4perl->init($args{conf});

    return Log::Log4perl->get_logger($args{category} || '');
}

# Override <message> because Log4perl has own configurable layouts.
sub message {
    my ($self, $level, @messages) = @_;

    my %LEVELS_map = (
        trace     => $TRACE,
        debug     => $DEBUG,
        info      => $INFO,
        warn      => $WARN,
        error     => $ERROR,
        fatal     => $FATAL,
        always    => $OFF,

        notice    => NOTICE,
        critical  => CRITICAL,
        alert     => ALERT,
        emergency => EMERGENCY,
    );
    
    for (@messages) {
        my $message = ref($_) ? Dumper($_) : $_;
        $self->{logger}->log( $LEVELS_map{$level}, $message );
    }
}

1;

__END__

=pod

=head1 NAME

Kelp::Module::Logger::Log4perl - Log4perl for Kelp applications

=head1 DESCRIPTION

This module provides log interface for Kelp web application. It uses
L<Log::Log4perl> instead of L<Log::Dispatch>. 

=head1 SYNOPSIS


    # conf/config.pl
    {
        'modules' => ['Logger::Log4perl'],
        'modules_init' => {
            'Logger::Log4perl' => {
                'category' => '',
                'conf'     => {
                    'log4perl.rootLogger'                                  => 'TRACE, CommonLog',
                    'log4perl.appender.CommonLog'                          => 'Log::Log4perl::Appender::Screen',
                    'log4perl.appender.CommonLog.layout'                   => 'Log::Log4perl::Layout::PatternLayout::Multiline',
                    'log4perl.appender.CommonLog.layout.ConversionPattern' => '%d{yyyy-MM-dd HH:mm:ss} - %p - %m%n',
                    'log4perl.appender.CommonLog.utf8'                     => '1',
                }
            }
        }
    }

    # lib/MyApp.pm
    sub run {
        my $self = shift;
        my $app  = $self->SUPER::run(@_);
        ...;
        $app->info( 'Kelp is ready to rock!' );
        $app->logger( 'trace', $some_ref_to_dump );

        return $app;
    }

Although module provides alternarive ways of initialization like L<Log::Log4perl/Alternative-initialization>:

    # conf/config.pl

    {
        'modules_init' => {
            'Logger::Log4perl' => {
                'category' => '',
                'conf'     => 'conf/logger.conf',
            }
        }
    };

or even scalar ref:

    {
        'modules' => [ 'Logger::Log4perl' ],
        'modules_init' => {
            'Logger::Log4perl' => {
                'category' => '',
                'conf'     => \<<CONF
    log4perl.rootLogger                                  = DEBUG, CommonLog
    log4perl.appender.CommonLog                          = Log::Log4perl::Appender::Screen
    log4perl.appender.CommonLog.layout                   = Log::Log4perl::Layout::PatternLayout::Multiline
    log4perl.appender.CommonLog.layout.ConversionPattern = %d{yyyy-MM-dd HH:mm:ss} - %p - %m%n
    log4perl.appender.CommonLog.utf8                     = 1
    CONF
           }
        }
    };

=head1 CONFIGURATION

Configuration accepts href with two keys:

=head2 category

The L<Log::Log4perl> category to send logs to. Defaults to '' which sends to root logger.

=head2 conf

Configuration for <Log::Log4perl::init> method.

=head1 REGISTERED METHODS

Log methods can take array of scalars or reference as arguments. In case of
reference L<Data::Dumper> is used to deserialize information.

=head2 debug/info/error

Write log message to $DEBUG/$INFO/$ERROR level.

    # inside controller
    $c->debug( $debug_data );
    $c->info( "my info message." );
    $c->error( @error_messages );

=head2 logger

Write message to one of the following default L<Log::Log4perl> log levels:
C<trace>, C<debug>, C<info>, C<warn>, C<error>, C<fatal>, C<always>. For
backward compability you can use L<Log::Dispatch> levels too.

    # inside controller
    $c->logger( 'always', @messages );

    # log dispatch level
    $c->logger( 'notice', 'Some notice' );

=head1 AUTHOR

Konstantin Yakunin

=head1 LICENSE

This program is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.2 or,
at your option, any later version of Perl 5 you may have available.

=head1 BUGS

None reported... yet.

=head1 SEE ALSO

L<Log::Log4perl>

L<Kelp::Module::Logger>

=cut

