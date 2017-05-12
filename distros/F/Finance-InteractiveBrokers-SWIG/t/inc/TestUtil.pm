package TestUtil;
#
#   Finance::InteractiveBrokers::SWIG - Misc test utilities
#
#   Copyright (c) 2010-2014 Jason McManus
#

use strict;
use warnings;

BEGIN {
    require Exporter;
    our @ISA       = qw( Exporter );
    our @EXPORT_OK = qw( random_string );
    our $VERSION   = '0.13';
}

# Junk object
sub new
{
    my $class = shift;
    my $self = [];
    bless( $self, $class );
    return( $self );
}

# Generate random string of $length
sub random_string
{
    my $length = shift || 6;

    return( map { ('a'..'z')[rand 26] } 1..$length );
}

1;

__END__
