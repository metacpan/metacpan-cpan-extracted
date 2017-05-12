# bodyheaders.al -- Extracts headers from the message body.  -*- perl -*-
# $Id: bodyheaders.al,v 0.1 1997/12/26 08:09:04 eagle Exp $
#
# Copyright 1997 by Russ Allbery <rra@stanford.edu>
#
# This program is free software; you may redistribute it and/or modify it
# under the same terms as Perl itself.  This is a News::Gateway module and
# requires News::Gateway to be used.

# @@ Interface:  ['bodyheaders']

package News::Gateway;

############################################################################
# Configuration directives
############################################################################

# Our single directive gives a list of (case-insensitive) headers that we
# should look for and elevate out of the beginning of the article body.
sub bodyheaders_conf {
    my $self = shift;
    $$self{bodyheaders} = [ map { lc $_ } @_ ];
}


############################################################################
# Message rewrites
############################################################################

# We examine the beginning of the body up to the first non-blank, non-header
# line looking for headers that match the ones we're suppoesd to look for.
# If we find any, we splice the headers and any blank lines preceeding or
# following them out of the body and add the headers to the article headers
# (non-destructively).  Headers in the body override actual headers in the
# case of unique headers.
sub bodyheaders_mesg {
    my $self = shift;
    my ($lines, $found) = (0, 0);
    my $body = $$self{article}->body ();
    for (@$body) {
        $lines++;
        next if (/^\s*$/);
        if (/^(\S+):\s*(.*)$/) {
            my ($header, $value) = (lc $1, $2);
            if (grep { $_ eq $header } @{$$self{bodyheaders}}) {
                unless ($$self{article}->add_headers ($header => $value)) {
                    $$self{article}->drop_headers ($header);
                    $$self{article}->add_headers ($header => $value);
                }
                $found++;
            } else {
                last;
            }
        } else {
            last;
        }
    }
    $lines--;
    if ($found) { splice (@$body, 0, $lines) }
    undef;
}

1;
