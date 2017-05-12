#########################################################################################
# Package       HiPi::Interface::MCP3008
# Description:  compatibility
# Copyright    : Copyright (c) 2013-2017 Mark Dootson
# License      : This is free software; you can redistribute it and/or modify it under
#                the same terms as the Perl 5 programming language system itself.
#########################################################################################

package HiPi::Interface::MCP3008;

#########################################################################################

use strict;
use warnings;

use parent qw( HiPi::Interface::MCP3ADC );
use HiPi qw( :mcp3adc );

our $VERSION = '0.59';

our @EXPORT = ();
our @EXPORT_OK = ();
our %EXPORT_TAGS = ( all => \@EXPORT_OK );

# compatibility
{
    my @const = qw(
        MCP3008_S0 MCP3008_S1 MCP3008_S2 MCP3008_S3
        MCP3008_S4 MCP3008_S5 MCP3008_S6 MCP3008_S7
        MCP3008_DIFF_0_1 MCP3008_DIFF_1_0 MCP3008_DIFF_2_3
        MCP3008_DIFF_3_2 MCP3008_DIFF_4_5 MCP3008_DIFF_5_4
        MCP3008_DIFF_6_7 MCP3008_DIFF_7_6
    );
    push( @EXPORT_OK, @const );
    $EXPORT_TAGS{mcp} = \@const;
}

sub new {
    my ($class, %params) = @_;
    
    $params{ic} = MCP3008;
    
    my $self = $class->SUPER::new( %params );
    return $self;
}

1;

__END__

