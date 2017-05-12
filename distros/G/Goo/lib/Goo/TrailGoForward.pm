# -*- Mode: cperl; mode: folding; -*-

package Goo::TrailGoForward;

###############################################################################
# Nigel Hamilton
#
# Copyright Nigel Hamilton 2005
# All Rights Reserved
#
# Author:       Nigel Hamilton
# Filename:     Goo::TrailGoForward.pm
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
use Goo::LiteDatabase;
use Goo::Thing::gml::Writer;

use base qw(Goo::Object);


###############################################################################
#
# run - go forward!!
#
###############################################################################

sub run {

    my ($this, $thing) = @_;

    $thing->{end_position} = $thing->{end_position} + $thing->{buffer_size};

    my $max_actionid = Goo::LiteDatabase::get_max("actionid", "gootrail");

    if ($thing->{end_position} > $max_actionid) {
        $thing->{end_position} = $max_actionid;
    }

    $thing->{start_position} = $thing->{end_position} - $thing->{buffer_size};

    # update the thing!
    Goo::Thing::gml::Writer::write($thing, $thing->get_full_path());

    # OK show the profile again
    $thing->do_action("P");

}

1;


__END__

=head1 NAME

Goo::TrailGoForward - Jump forwards in the Goo Trail

=head1 SYNOPSIS

use Goo::TrailGoForward;

=head1 DESCRIPTION

Action handler for moving forward in the Trail (i.e., [F]orward)

=head1 METHODS

=over

=item run

Go forward in the Trail.


=back

=head1 AUTHOR

Nigel Hamilton <nigel@trexy.com>

=head1 SEE ALSO

