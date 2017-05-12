# whitelist.al -- Check the From line against valid posters.  -*- perl -*-
# $Id: whitelist.al,v 0.4 1997/09/15 02:49:05 eagle Exp $
#
# Copyright 1997 by Russ Allbery <rra@stanford.edu>
#
# This program is free software; you may redistribute it and/or modify it
# under the same terms as Perl itself.  This is a News::Gateway module and
# requires News::Gateway to be used.

# @@ Interface:  ['whitelist']

package News::Gateway;

############################################################################
# Configuration directives
############################################################################

# Our single directive takes a file that contains a list of acceptable
# posters.
sub whitelist_conf {
    my ($self, $directive, $whitelist) = @_;
    open (WHITELIST, $whitelist)
        or $self->error ("Can't open whitelist file $whitelist: $!");
    local $_;
    while (<WHITELIST>) {
	chomp;
	$$self{whitelist}{lc $_} = 1;
    }
    close WHITELIST;
}


############################################################################
# Post checks
############################################################################

# Check the address in the From line of the article against the list of
# valid posters.
sub whitelist_mesg {
    my ($self) = @_;
    my $from = $$self{article}->header ('from');
    my ($address) = ($from =~ /<(\S+)>/);
    ($address) = split (' ', $from) unless $address;
    unless ($$self{whitelist}{lc $address}) {
        return "Unknown poster $address";
    }
    undef;
}

1;
