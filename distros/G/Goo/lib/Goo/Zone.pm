package Goo::Zone;

###############################################################################
# Nigel Hamilton
#
# Copyright Nigel Hamilton 2005
# All Rights Reserved
#
# Author:       Nigel Hamilton
# Filename:     Zone.pm
# Description:  Show the tail of the Goo trail
#
# Date          Change
# -----------------------------------------------------------------------------
# 21/08/2005    Deleted method: generateProfile
# 21/08/2005    Deleted method: showProfile
# 21/08/2005    Deleted method: getGooTrailTable
#
###############################################################################

use strict;

use Goo::Object;
use Goo::Loader;

use base qw(Goo::Object);


###############################################################################
#
# run - go back!!
#
###############################################################################

sub run {

    my ($this, $thing) = @_;

    # get the previous action in the GooTrail
    # do the action again!
    my $trail = Goo::Loader::load("tail.trail");

    # do the action again!
    $trail->do_action("P");

}

1;


__END__

=head1 NAME

Goo::Zone - Show the tail of the Goo trail

=head1 SYNOPSIS

use Goo::Zone;

=head1 DESCRIPTION

Action handler for viewing the trail of the Goo Trail (i.e., [Z]one).
It tries to answer the question, "what am I currently juggling?"

=head1 METHODS

=over

=item run

Show the tail of the Goo Trail

=back

=head1 AUTHOR

Nigel Hamilton <nigel@trexy.com>

=head1 SEE ALSO

