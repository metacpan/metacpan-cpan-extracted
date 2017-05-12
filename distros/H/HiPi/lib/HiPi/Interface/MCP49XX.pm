#########################################################################################
# Package        HiPi::Interface::MCP49XX
# Description  : compatibility
# Copyright    : Copyright (c) 2013-2017 Mark Dootson
# License      : This is free software; you can redistribute it and/or modify it under
#                the same terms as the Perl 5 programming language system itself.
#########################################################################################

package HiPi::Interface::MCP49XX;

#########################################################################################

use strict;
use warnings;
use parent qw( HiPi::Interface::MCP4DAC );
use HiPi qw( :mcp4dac );

our $VERSION = '0.59';

our @EXPORT = ();
our @EXPORT_OK = ();
our %EXPORT_TAGS = ( all => \@EXPORT_OK );

# legacy compat exports
{
    my @const = qw(
        MCP4801 MCP4811 MCP4821 MCP4802 MCP4812 MCP4822
        MCP4901 MCP4911 MCP4921 MCP4902 MCP4912 MCP4922
    );
    
    push( @EXPORT_OK, @const );
    $EXPORT_TAGS{mcp} = \@const;
}

sub new {
    my $class = shift;   
    my $self = $class->SUPER::new( @_ );
    return $self;
}

1;

__END__
