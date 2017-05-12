package GOBO::Base;
use Moose;
use strict;

# separate verbosity and strictness/exceptions. Global settings override local
# ones, but this can be overridden in child classes
has 'verbose' => (
    is   => 'rw',
    isa  => 'Bool',
    default => $ENV{BIOPERL_DEBUG} || 0
    );


1;

__END__

=head2 NAME

GOBO::Base

=head2 DESCRIPTION

base class for all objects. Intended to be compatible with BioPerl/BioMoose.

=cut
