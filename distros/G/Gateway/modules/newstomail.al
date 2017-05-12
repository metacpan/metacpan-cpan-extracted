# newstomail.al -- Translate news articles into e-mail.  -*- perl -*-
# $Id: newstomail.al,v 0.1 1998/03/26 04:27:10 eagle Exp $
#
# Copyright 1998 by Russ Allbery <rra@stanford.edu>
#
# This program is free software; you may redistribute it and/or modify it
# under the same terms as Perl itself.  This is a News::Gateway module and
# requires News::Gateway to be used.

# @@ Interface:  ['newstomail']

package News::Gateway;

############################################################################
# Configuration directives
############################################################################

# Takes one argument, which specifies a file of newsgroup to e-mail address
# mappings.
sub newstomail_conf {
    my ($self, $directive, $mapping) = @_;
    my $split = sub { split (' ', $_[0], 2) };
    $$self{newstomail} = $self->hash_open ($mapping, $split)
        or $self->error ("Can't open mapping file $mapping: $!");
}


############################################################################
# Post rewrites
############################################################################

# Take the incoming news article and rewrite it into a mail message,
# removing or renaming those headers that may cause a problem in a mail
# system.
sub newstomail_mesg {
    my $self = shift;
    my $article = $$self{article};

    # Make sure that we have a Newsgroups header.  If not, we reject.
    my $newsgroups = $article->header ('newsgroups');
    unless ($newsgroups) { return 'Missing required Newsgroups header' }

    # Now, pass through the Newsgroups header, adding addresses to which
    # we're going to send this post.  If we don't end up finding any
    # mappings, we reject the message.
    my @newsgroups = split (/\s*,\s*/, $newsgroups);
    my @addresses;
    for (@newsgroups) {
        my $address = $$self{newstomail}{$_};
        push (@addresses, $address) if $address;
    }
    unless (@addresses) { return 'No newsgroup with a mapping' }
    my %seen;
    @addresses = grep { !$seen{$_}++ } @addresses;

    # We need to rename any header that could possibly be taken to be a
    # recipient address, so as not to confuse our mailer.  qmail also
    # assigns special meaning to Return-Path, and we're going to insert our
    # own Sender header.  We drop the Bcc lines instead of renaming them,
    # since that seems more consistent with the Bcc semantics.
    $article->drop_headers (qw(bcc resent-bcc));
    for (qw(to cc apparently-to resent-to resent-cc return-path sender)) {
        $article->rename_header ($_, "x-original-$_", 'add');
    }
    $article->set_headers (sender => $$self{maintainer});

    # Add a To header pointing to our addresses.
    $article->set_headers (to => join (', ', @addresses));

    # All done, return success.
    return undef;
}

1;
