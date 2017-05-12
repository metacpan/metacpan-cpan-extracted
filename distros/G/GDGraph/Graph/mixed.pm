#==========================================================================
#              Copyright (c) 1995-1998 Martien Verbruggen
#--------------------------------------------------------------------------
#
#   Name:
#       GD::Graph::mixed.pm
#
# $Id: mixed.pm,v 1.13 2007/04/26 03:16:09 ben Exp $
#
#==========================================================================

package GD::Graph::mixed;
 
($GD::Graph::mixed::VERSION) = '$Revision: 1.13 $' =~ /\s([\d.]+)/;

use strict;
 
use GD::Graph::axestype;
use GD::Graph::lines;
use GD::Graph::points;
use GD::Graph::linespoints;
use GD::Graph::bars;
use GD::Graph::area;
use Carp;
 
# Even though multiple inheritance is not really a good idea, I will
# do it here, because I need the functionality of the markers and the
# line types We'll include axestype as the first one, to make sure
# that's where we look first for methods.

@GD::Graph::mixed::ISA = qw( 
    GD::Graph::axestype 
    GD::Graph::bars
    GD::Graph::lines 
    GD::Graph::points 
);

sub initialise
{
    my $self = shift;
    $self->SUPER::initialise();
}

sub correct_width
{
    my $self = shift;

    return $self->{correct_width} if defined $self->{correct_width};

    for my $type ($self->{default_type}, @{$self->{types}})
    {
        return 1 if $type eq 'bars';
    }
}

sub draw_data_set
{
    my $self = shift;
    my $ds   = $_[0];

    my $rc;

    my $type = $self->types($ds);

    # Try to execute the draw_data_set function in the package
    # specified by type
    $rc = eval '$self->GD::Graph::'.$type.'::draw_data_set(@_)';

    # If we fail, we try it in the package specified by the
    # default_type, and warn the user
    if ($@)
    {
        carp "Set $ds, unknown type $type, assuming $self->{default_type}";
        #carp "Error message: $@";

        $rc = eval '$self->GD::Graph::'.
            $self->{default_type}.'::draw_data_set(@_)';
    }

    # If even that fails, we bail out
    croak "Set $ds: unknown default type $self->{default_type}" if $@;

    return $rc;
}

sub draw_legend_marker
{
    my $self = shift;
    my $ds = $_[0];

    my $type = $self->types($ds);

    eval '$self->GD::Graph::'.$type.'::draw_legend_marker(@_)';

    eval '$self->GD::Graph::'.
        $self->{default_type}.'::draw_legend_marker(@_)' if $@;
}

# undocumented as can be: returns the type-list (with the default
# inserted as appropriate), or the type associated with a particular
# (1-indexed) dataset number (undef if there is no such dataset).  The
# range check means that this cannot be called when there is no
# GD::Graph::Data object in $self->{_data}.

sub types
{
    my $self = shift;
    if ( defined $_[0] ) {
        $_[0] > 0 && $_[0] <= $self->{_data}->num_sets
          ? $self->{types}->[$_[0] - 1] || $self->{default_type}
          : undef
    } else {
        map { $self->{types}->[$_ - 1] || $self->{default_type} }
          1 .. $self->{_data}->num_sets;
    }
}

"Just another true value";
