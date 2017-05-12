package Goo::TrailGoBack;

###############################################################################
# Nigel Hamilton
#
# Copyright Nigel Hamilton 2005
# All Rights Reserved
#
# Author:       Nigel Hamilton
# Filename:     Goo::TrailGoBack.pm
# Description:  Jump backwards in the Goo Trail
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
use Goo::Thing::gml::Writer;

use base qw(Goo::Object);


###############################################################################
#
# run - go back!!
#
###############################################################################

sub run {

    my ($this, $thing) = @_;

    $thing->{start_position} = $thing->{start_position} - $thing->{buffer_size};

    if ($thing->{start_position} < 1) { $thing->{start_position} = 1; }

    $thing->{end_position} = $thing->{end_position} - $thing->{buffer_size};

    # update the thing!
    Goo::Thing::gml::Writer::write($thing, $thing->get_full_path());

    # OK show the profile again
    $thing->do_action("P");

}

1;


__END__

=head1 NAME

Goo::TrailGoBack - Jump backwards in the Goo Trail

=head1 SYNOPSIS

use Goo::TrailGoBack;

=head1 DESCRIPTION



=head1 METHODS

=over

=item run

go back!!


=back

=head1 AUTHOR

Nigel Hamilton <nigel@trexy.com>

=head1 SEE ALSO

