###############################################################################
# Distribution : HiPi Modules for Raspberry Pi
# File         : lib/HiPi.pm
# Description  : Pepi module for Raspberry Pi
# Copyright    : Copyright (c) 2013-2023 Mark Dootson
# License      : This is free software; you can redistribute it and/or modify it under
#                the same terms as the Perl 5 programming language system itself.
#########################################################################################

package HiPi;

###############################################################################
use strict;
use warnings;
use parent qw( Exporter );
use HiPi::Constant qw( :hipi );
use HiPi::RaspberryPi;
use constant hipi_export_constants();
use Scalar::Util qw( weaken isweak refaddr );
use Carp;

our $VERSION ='0.88';

our @EXPORT_OK = hipi_export_ok();
our %EXPORT_TAGS = hipi_export_tags();

my $registered_exits = {};
my $signal_handlers_installed = 0;

our $interrupt_verbose = 0;

sub is_raspberry_pi { return HiPi::RaspberryPi::is_raspberry() ; }

sub alt_func_version { return HiPi::RaspberryPi::alt_func_version() ; }

sub _install_signal_handlers {
    $SIG{INT}  = \&_call_registered_and_exit;
    $SIG{TERM} = \&_call_registered_and_exit;
    $SIG{HUP}  = \&_call_registered_and_exit;
    $signal_handlers_installed = 1;
}

sub catch_sigpipe {
    $SIG{PIPE} = \&_call_registered_and_exit;
}

sub twos_compliment {
    my( $class, $value, $numbytes) = @_;
    my $onescomp = (~$value) & ( 2**(8 * $numbytes) -1 );
    return $onescomp + 1;
}

sub register_exit_method {
    my($class, $obj, $method) = @_;
    
    my $tid = 0;
    if( $HiPi::Threads::threads ) {
        $tid = threads->tid();
    }
    
    if( !$tid && !$signal_handlers_installed ) {
        _install_signal_handlers();
    }
    
    my $key = refaddr( $obj );
    $registered_exits->{$key} = [ $obj, $method ];
    weaken( $registered_exits->{$key}->[0] );
}

sub unregister_exit_method {
    my($class, $obj) = @_;
    my $key = refaddr( $obj );
    delete($registered_exits->{$key}) if exists($registered_exits->{$key});
}

sub _call_registered_and_exit {
    my $interrupt = shift;
    my $tid = 0;
    if( $HiPi::Threads::threads ) {
        $tid = threads->tid();
        HiPi::Threads->signal_handler( $interrupt ) unless( $tid ); # only call in main thread
    }
    
    for my $key ( keys %$registered_exits ) {
        my $method = $registered_exits->{$key}->[1];
        if( isweak( $registered_exits->{$key}->[0] ) && $registered_exits->{$key}->[0]->can($method) ) {
            $registered_exits->{$key}->[0]->$method();
        }
    }
    unless( $tid ) {
        # only in main thread
        if($interrupt_verbose) {
            Carp::confess(qq(\nInterrupt SIG$interrupt));
        } else {
            die qq(\nInterrupt SIG$interrupt);
        }
    }
}

sub call_registered_exit_method {
    my($class, $instance) = @_;
    my $key = refaddr( $instance );
    if(exists($registered_exits->{$key})) {
        my $method = $registered_exits->{$key}->[1];
        if( isweak( $registered_exits->{$key}->[0] ) && $registered_exits->{$key}->[0]->can($method) ) {
            $registered_exits->{$key}->[0]->$method();
        }
    }
}

1;

=pod

=encoding UTF-8

=head1 NAME

HiPi - Modules for Raspberry Pi GPIO

=head1 SYNOPSIS

    use HiPi;
    ....
    use HiPi qw( :rpi :i2c :spi :mcp3adc :mcp4dac :mpl3115a2 );
    ....
    use HiPi qw( :mcp23x17 :lcd :hrf69 :openthings :energenie );

=head1 DESCRIPTION

HiPi provides modules for use with the Raspberry Pi GPIO and
peripherals.

Documentation and details are available at

L<https://raspberry.znix.com>

=head1 AUTHOR

Mark Dootson, C<< mdootson@cpan.org >>.

=head1 COPYRIGHT

Copyright (c) 2013 - 2023 Mark Dootson

=cut

__END__


