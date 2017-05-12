# previoushop.al -- Adds the previous mail hop to the Path.  -*- perl -*-
# $Id: previoushop.al,v 0.1 1997/12/29 11:24:21 eagle Exp $
#
# Copyright 1997 by Russ Allbery <rra@stanford.edu>
#
# This program is free software; you may redistribute it and/or modify it
# under the same terms as Perl itself.  This is a News::Gateway module and
# requires News::Gateway to be used.

# @@ Interface:  []

package News::Gateway;

############################################################################
# Message rewrites
############################################################################

# Troll through the raw Received headers and find the first one that
# specifies a hostname (in the form "from hostname").  Extract hostname and
# add it to the Path header.  This is for unmoderated groups that have both
# news to mail and mail to news gateways, to avoid creating loops.
sub previoushop_mesg {
    my $self = shift;
    my $host;
    for (@{scalar $$self{article}->rawheaders ()}) {
        /^Received: \s+ from \s+ ([\w.@-]+)/ixs or next;
        $host = $1;
        last;
    }
    if ($host) {
        my $path = $$self{article}->header ('path');
        $path = $path ? "$host!$path" : $host;
        $$self{article}->set_headers (path => $path);
    }
    undef;
}

1;
