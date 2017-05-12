# cleanbody.al -- Various standard article body cleaning. -*- perl -*-
# $Id: cleanbody.al,v 0.4 1998/01/01 14:41:41 eagle Exp $
#
# Copyright 1997 by Russ Allbery <rra@stanford.edu>
#
# This program is free software; you may redistribute it and/or modify it
# under the same terms as Perl itself.  This is a News::Gateway module and
# requires News::Gateway to be used.
#
# @@ Interface:  []

package News::Gateway;

############################################################################
# Post checks
############################################################################

# We perform the following tests and munging to the body of the post:
#
#   * Undo quoted-printable.
#   * Smart quote undoing: 0221 -> `  0222 -> '  0223 -> "  0224 -> "
#                          0205 -> --
#   * Strip out any Ctrl-Ms or literal deletes.
#   * Reject if the body contains invalid characters.
#   * Reject if any line is longer than 79 characters.
sub cleanbody_mesg {
    my $self = shift;
    my $quoted = lc $$self{article}->header ('content-transfer-encoding');
    $quoted = ($quoted eq 'quoted-printable');
    local $_;

    # First pass.  We'll only need two passes if there were quoted-printable
    # continuation lines.
    my ($save, $splice);
    for (@{scalar $$self{article}->body ()}) {
        # Fix quoted-printable, which is annoying to have to deal with.
        if ($quoted) {
            if ($save) {
                $_ = $save . $_;
                undef $save;
            }
            s/=([0-9A-F]{2})/chr (hex $1)/eg;
            s/=\n//g;
            if (s/=$//) {
                # Continuation line.  Ugh.  Replace line with a disallowed
                # character and save this line; we'll need to splice this
                # line out later on another pass.
                $save = $_;
                $_ = "\0";
                $splice = 1;
                next;
            }
        }

        # Convert Microsoft smart quotes to their real counterparts.
        tr/\x91\x92\x93\x94/\`\'\"\"/;
        s/\x85/--/g;

        # Remove CRs (DOS line endings, most likely) and delete characters.
        tr/\r\x7f//d;

        # Check for validity.  We allow any ISO 8859-1 characters.
        return "Invalid characters in body" if (!/^[\s!-~\xa0-\xff]*$/);
        return "Line over 79 characters" if (length $_ > 80);
    }

    # Second pass if there were continuation lines to splice out the removed
    # lines of body text.
    if ($splice) {
        my $body = $$self{article}->body ();
        my $i;
        for ($i = 0; $i < @$body; $i++) {
            splice (@$body, $i, 1) if ($$body[$i] eq "\0");
        }
    }

    # Fix Content-Transfer-Encoding header if we decoded quoted-printable.
    $$self{article}->set_headers ('content-transfer-encoding' => '8bit')
        if $quoted;

    # Return success.
    undef;
}

1;
