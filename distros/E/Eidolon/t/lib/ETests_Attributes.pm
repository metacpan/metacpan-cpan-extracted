package ETests_Attributes;
# ==============================================================================
#
#   Eidolon
#   Copyright (c) 2009, Atma 7
#   ---
#   t/lib/ETests_Attributes.pm - attributes test class
#
# ==============================================================================

use base qw/Eidolon::Core::Attributes/;
use warnings;
use strict;

# ------------------------------------------------------------------------------
# akira()
# test function, does nothing
# ------------------------------------------------------------------------------
sub akira : Yamaoka
{
}

1;

