# anykeyword.al -- Require articles to have some keyword.  -*- perl -*-
# $Id: anykeyword.al,v 0.2 1997/12/14 08:46:11 eagle Exp $
#
# Copyright 1997 by Russ Allbery <rra@stanford.edu>
#
# This program is free software; you may redistribute it and/or modify it
# under the same terms as Perl itself.  This is a News::Gateway module and
# requires News::Gateway to be used.

# @@ Interface:  []

package News::Gateway;

############################################################################
# Post rewrites
############################################################################

# Make sure that the post has a keyword (any keyword is acceptable).
# Keywords are in the form of [\S+] at the beginning of the subject line.
sub anykeyword_mesg {
    my $self = shift;
    my $subject = $$self{article}->header ('subject');
    if ($subject =~ /^(?:Re:\s+)?\[\S+\]/) {
        return undef;
    } else {
        return "No keyword found";
    }
}

1;
