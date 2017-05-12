# mailpath.al -- Generates an X-Mail-Path from Received.  -*- perl -*-
# $Id: mailpath.al,v 0.6 1998/02/20 08:04:33 eagle Exp $
#
# Copyright 1997 by Russ Allbery <rra@stanford.edu>
# Based heavily on code by Andrew Gierth <andrew@erlenstar.demon.co.uk>
#
# This program is free software; you may redistribute it and/or modify it
# under the same terms as Perl itself.  This is a News::Gateway module and
# requires News::Gateway to be used.

# @@ Interface:  []

package News::Gateway;

############################################################################
# Post rewrites
############################################################################

# Munge the received lines of the original message into an X-Mail-Path
# header and then remove them from the final article.  This is probably
# always going to be a work in progess since no RFC specifies the precise
# syntax for relaying comments and sites would probably ignore them anyway.
#
# Needs to be able to cope with:
#
#   Received: from foobar (really [1.2.3.4]) by...
#   Received: from foobar (foobar.baz.com [1.2.3.4]) by...
#   Received: from foobar ([1.2.3.4]) by...
#   Received: from foobar by...
#             (peer crosschecked as: foobar.baz.com [1.2.3.4])
#   Received: from foobar by...
#             (peer crosschecked as: [1.2.3.4])
#   Received: from foobar.baz.com (1.2.3.4) by...
#   Received: from foobar.baz.com (@1.2.3.4) by...
#   Received: from foobar.baz.com (something@1.2.3.4) by...
#   Received: from foobar.baz.com (HELO foobar) (1.2.3.4) by...
#   Received: from unknown (HELO foobar) (1.2.3.4) by...
#   Received: from foobar.baz.com [1.2.3.4] by...
#   Received: from foobar by...
#
# The above headers would be transformed respectively to:
#
#   foobar[1.2.3.4]
#   foobar.baz.com
#   foobar[1.2.3.4]
#   foobar.baz.com
#   foobar[1.2.3.4]
#   foobar.baz.com
#   foobar.baz.com
#   something@foobar.baz.com
#   foobar.baz.com
#   foobar[1.2.3.4]
#   foobar.baz.com[1.2.3.4]
#   foobar[UNTRUSTED]
#
# The envelope sender is then added as the rightmost element.
sub mailpath_mesg {
    my $self = shift;
    my (@path, $element);

    # Build the list of path elements from the Received headers using lots
    # of black magic regexes.
    for (@{scalar $$self{article}->rawheaders ()}) {
        undef $element;
        /^Received: \s+ from \s+                # Required token
         ([\w.@-]+)? \s*                        # Identified host name (1)
         (?:
          (?:\(HELO\ (\S+)\) \s*)?              # qmail HELO argument (2)
          \((?:                                 # First comment after host
           (?:
            (?:(\S*)\@)?                        # ident information (3)
            (\d+\.\d+\.\d+\.\d+)                # qmail IP address (4)
           ) |
           (?:
            really |                            # No real host name
            ([\w.@-]+)                          # The real host name (5)
           \ )?
           \[(\d+\.\d+\.\d+\.\d+)\]             # The IP address (6)
          )
          |                                     # Alternately....
          \[(\d+\.\d+\.\d+\.\d+)\]              # The IP address (7)
          |
          .* \(peer\ crosschecked\ as: \s+      # UUNet relay machines
          (?:([\w.@-]+)\s+)?                    # The real host name (8)
          \[(\d+\.\d+\.\d+\.\d+)\]              # The IP address (9)
         )?
        /ixs or next;
        $element = $8, next if $8;
        $element = $1 . "[$9]", next if $9;
        $element = $3 . '@' . $1, next if ($4 and $3 and $1 ne 'unknown');
        $element = $1, next if ($4 and $1 ne 'unknown');
        $element = $2 . "[$4]", next if ($4 and $2);
        $element = $4, next if $4;
        $element = $5, next if ($5 and index ($5, '.') > 0);
        $element = $1 . "[$6]", next if $6;
        $element = $1 . "[$7]", next if $7;
        $element = $1 . '[UNTRUSTED]' if $1;
    } continue {
        push (@path, $element) if $element;
    }

    # Add the envelope sender to the end of the path if there is one,
    # otherwise add a note that we don't know.
    push (@path, $$self{article}->envelope () || 'UNKNOWN');

    # Add the X-Mail-Path header.
    $$self{article}->add_headers ('x-mail-path' => join ('!', @path));

    # Return success.
    undef;
}

1;
