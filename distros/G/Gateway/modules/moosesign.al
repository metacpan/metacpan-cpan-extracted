# moosesign.al -- Sign a post with PGPMoose.  -*- perl -*-
# $Id: moosesign.al,v 0.2 1997/12/23 12:29:46 eagle Exp $
#
# Copyright 1997 by Russ Allbery <rra@stanford.edu>
#
# This program is free software; you may redistribute it and/or modify it
# under the same terms as Perl itself.  This is a News::Gateway module and
# requires News::Gateway to be used.

# @@ Interface:  ['pgpkey']

package News::Gateway;

############################################################################
# Configuration directive
############################################################################

# We support a pgpkey directive giving the name of the newsgroup, the
# passphrase, to use for signing posts to that newsgroup, and the key ID
# (which is optional and defaults to the name of the newsgroup surrounded by
# spaces).
sub moosesign_conf {
    my ($self, $direct, $newsgroup, @args) = @_;
    $$self{moosesign}{$newsgroup} = [ @args ];
}


############################################################################
# Post rewrites
############################################################################

# This is a simple implementation of PGPMoose, which only signs the post for
# every group we have a key for and doesn't attempt to do anything regarding
# crossposts.
sub moosesign_mesg {
    my $self = shift;
    for (split (/,/, $$self{article}->header ('newsgroups'))) {
        if ($$self{moosesign}{$_}) {
            $$self{article}->sign_pgpmoose ($_, @{$$self{moosesign}{$_}});
        }
    }
    undef;
}

1;
