# nobinaries.al -- Detect and reject binary files.  -*- perl -*-
# $Id: nobinaries.al,v 0.2 1997/12/25 16:17:07 eagle Exp $
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

# Attempt to detect and reject all binaries.  This code is derived from
# George Theall's purge-binaries script.  The following metrics are used in
# making this determination:
#
#   * Any message with a Content-Type containing the strings "application",
#     "audio", "image", or "video" is rejected, whether the header is in the
#     headers or in the body of the message.
#   * Any message with a Content-Transfer-Encoding of "base64" is rejected,
#     whether the header is in the headers or in the body.
#   * Any message with at least 50% encoded lines and at least 40 lines,
#     where encoded lines are defined as lines beginning with M and either
#     60 or 61 characters long (optionally indented or quoted) or lines
#     containing no spaces and between 59 and 80 characters long.
#
# Eventually, this really should be smarter about multipart posts....
sub nobinaries_mesg {
    my $self = shift;
    my $article = $$self{article};

    # Check the transfer encoding.
    return 'base64 encoded'
        if (lc $article->header ('content-transfer-encoding') eq 'base64');

    # Check the content type in the main article headers.
    my $type = $article->header ('content-type');
    return 'Invalid content type'
        if ($type =~ /(application|audio|image|video)/i);

    # Now, scan the body line by line, counting possibly encoded lines, and
    # reject the message if they exceed the above parameters or if we
    # encounter a Content-Type header in the body with a bad type (or a
    # Content-Transfer-Encoding header with a bad type).
    my ($lines, $uulines, $mimelines) = (0, 0, 0);
    for (@{scalar $$self{article}->body ()}) {
        $lines++;
        if (/^Content-Type:\s+(application|audio|image|video)/i) {
            return 'Invalid content type';
        } elsif (/^Content-Transfer-Encoding:\s+base64/i) {
            return 'base64 encoded';
        } elsif (/^(\s|>|:)*M.{60,61}\s*$/) {
            $uulines++;
        } elsif (/^[^M~]\S{59,80}\s*$/) {
            $mimelines++;
        }
    }
    if ($lines >= 40 && $uulines / $lines > 0.5) {
        return 'Apparently uuencoded';
    } elsif ($lines >= 40 && $mimelines / $lines > 0.5) {
        return 'Apparently base64-encoded';
    }

    # Looks like it isn't a binary!  Yay!
    undef;
}

1;
