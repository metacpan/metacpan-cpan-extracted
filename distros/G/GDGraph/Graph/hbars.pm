#==========================================================================
#              Copyright (c) 1995-1998 Martien Verbruggen
#--------------------------------------------------------------------------
#
#   Name:
#       GD::Graph::hbars.pm
#
# $Id: hbars.pm,v 1.3 2005/12/14 04:09:49 ben Exp $
#
#==========================================================================
 
package GD::Graph::hbars;

($GD::Graph::hbars::VERSION) = '$Revision: 1.3 $' =~ /\s([.\d]+)/;

use strict;

use GD::Graph::bars;
use GD::Graph::utils qw(:all);
use GD::Graph::colour qw(:colours);

@GD::Graph::hbars::ISA = qw(GD::Graph::bars);

sub initialise
{
    my $self = shift;
    $self->SUPER::initialise();
    $self->set(rotate_chart => 1);
}

"Just another true value";

__END__

=head1 NAME

GD::Graph::hbars - make bar graphs with horizontal bars

=head1 SYNOPSIS

use GD::Graph::hbars;

=head1 DESCRIPTION

This is a wrapper module which is completely identical to creating a
GD::Graph::bars object with the C<rotate_chart> attribute set to a true
value.

=head1 SEE ALSO

L<GD::Graph>

=head1 AUTHOR

Martien Verbruggen E<lt>mgjv@tradingpost.com.auE<gt>

=head2 Copyright

(c) Martien Verbruggen

=head2 Acknowledgements

The original author of most of the code needed to implement this was
brian d foy, who sent this module to me after I complained I didn't have
the time to implement horizontal bar charts. I took the code that lived
in here, and distributed it over axestype.pm and bars.pm, to allow for a
better integration all around. His code, in turn, was mainly based on an
earlier version of bars.pm and axestype.pm.

=cut

