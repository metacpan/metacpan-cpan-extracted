# $Id: /mirror/gungho/lib/Gungho/Log.pm 3261 2007-10-14T05:37:42.099746Z lestrrat  $
#
# Copyright (c) 2007 Daisuke Maki <daisuke@endeworks.jp>
# All rights reserved.

package Gungho::Log;
use strict;
use warnings;
use base qw(Gungho::Base);

BEGIN
{

    foreach my $level qw(debug info warn error fatal) {
        eval <<"        EOM";
            sub is_$level {
                Carp::carp("Gungho::Log->is_$level has been deprecated. Configure logs using 'min_level' parameter");
                return 0;
            }
        EOM
    }
}

1;

__END__

=head1 NAME

Gungho::Log - Log Base Class For Gungho

=head1 METHODS

=head2 is_debug

=head2 is_info

=head2 is_warn

=head2 is_error

=head2 is_fatal

These methods have been deprecated, and are here only for backwards compatibility

=cut