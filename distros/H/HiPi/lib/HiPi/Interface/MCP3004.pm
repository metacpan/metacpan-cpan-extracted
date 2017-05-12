#########################################################################################
# Package       HiPi::Interface::MCP3004
# Description:  compatibility
# Created       Sun Dec 02 01:42:27 2012
# Copyright    : Copyright (c) 2013-2017 Mark Dootson
# License      : This is free software; you can redistribute it and/or modify it under
#                the same terms as the Perl 5 programming language system itself.
#########################################################################################

package HiPi::Interface::MCP3004;

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
        MCP3004_S0 MCP3004_S1 MCP3004_S2 MCP3004_S3
        MCP3004_DIFF_0_1 MCP3004_DIFF_1_0
        MCP3004_DIFF_2_3 MCP3004_DIFF_3_2
    );
    
    push( @EXPORT_OK, @const );
    $EXPORT_TAGS{mcp} = \@const;
}


sub new {
    my ($class, %params) = @_;
    
    $params{ic} = MCP3004;
    
    my $self = $class->SUPER::new( %params );
    return $self;
}

1;

__END__