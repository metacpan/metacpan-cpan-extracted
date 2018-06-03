###############################################################################
# Distribution : HiPi Modules for Raspberry Pi
# File         : lib/HiPi.pm
# Description  : Pepi module for Raspberry Pi
# Copyright    : Copyright (c) 2013-2017 Mark Dootson
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

our $VERSION ='0.71';

our @EXPORT_OK = hipi_export_ok();
our %EXPORT_TAGS = hipi_export_tags();

sub is_raspberry_pi { return HiPi::RaspberryPi::is_raspberry() ; }

sub twos_compliment {
    my( $class, $value, $numbytes) = @_;
    my $onescomp = (~$value) & ( 2**(8 * $numbytes) -1 );
    return $onescomp + 1;
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

http://raspberry.znix.com

=head1 AUTHOR

Mark Dootson, C<< mdootson@cpan.org >>.

=head1 COPYRIGHT

Copyright (c) 2013 - 2017 Mark Dootson

=cut

__END__


