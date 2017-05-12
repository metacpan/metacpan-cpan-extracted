# mailtonews.al -- Translate e-mail into a news article.  -*- perl -*-
# $Id: mailtonews.al,v 0.13 1998/04/15 07:14:18 eagle Exp $
#
# Copyright 1997, 1998 by Russ Allbery <rra@stanford.edu>
#
# This program is free software; you may redistribute it and/or modify it
# under the same terms as Perl itself.  This is a News::Gateway module and
# requires News::Gateway to be used.

# @@ Interface:  []

package News::Gateway;

############################################################################
# Option settings
############################################################################

# We take one option, the newsgroup to post to if there is no Newsgroups
# header in the original message.
sub mailtonews_init {
    my $self = shift;
    $$self{mailtonews} = shift;
}


############################################################################
# Post rewrites
############################################################################

# Munge a mail message into a news article.  This involves making a variety
# of header changes, dropping headers that the news server won't accept in
# posts, adding a Newsgroups header if one doesn't exist, and ensuring that
# all required headers are present.  Note that we *don't* enforce RFC 1036
# compliance in the From header; this is a conscious design decision since
# some groups may not want this.  It should be done in another module.
sub mailtonews_mesg {
    my $self = shift;
    my $article = $$self{article};

    # Make sure that we have a From header.  If not, we reject this article.
    # We also turn any newlines in the From header into spaces, since
    # otherwise INN may reject the article incorrectly.
    my $from = $article->header ('from')
        or return 'Missing required From header';
    if ($from =~ tr/\n/ /) { $article->set_headers (from => $from) }

    # Make sure the body isn't empty.  If it is, we reject this article.
    if ($article->lines () == 0) { return 'Empty body' }

    # Ensure that we have a valid Newsgroups header.  If we don't have one,
    # add one with the default group; otherwise, strip out whitespace and
    # extra commas from the one we have and remove any duplicate groups or
    # groups that don't match /^[\w.+-]+$/.
    my $newsgroups = $article->header ('newsgroups');
    if ($newsgroups) {
        my %seen;
        my @groups = split (/(?:\s*,\s*)+/, $newsgroups);
        @groups = grep { not $seen{$_}++ } grep { /^[\w.+-]+$/ } @groups;
        $newsgroups = join (',', @groups);
    }
    unless ($newsgroups) {
        $newsgroups = $$self{mailtonews} if defined $$self{mailtonews};
    }
    return 'No Newsgroups header or default group' unless $newsgroups;
    $article->set_headers (newsgroups => $newsgroups);

    # Drop headers that the news server would refuse rename a few others
    # which are worth saving.
    $article->drop_headers (qw(lines received relay-version xref));
    for (qw(nntp-posting-host sender)) {
        $article->rename_header ($_, "x-original-$_", 'add');
    }

    # Add a sender header giving the maintainer address, since this is the
    # entity responsible for introducing the message into the news system.
    $article->set_headers (sender => $$self{maintainer});

    # Check the mail message ID and see if it looks reasonable.  If not,
    # rename it so that we'll generate our own.  Note that news servers may
    # reject message IDs with a trailing period, so don't allow them.  This
    # is not a complete check; a complete check should really use the code
    # from INN and needs more than a simple regex.
    my $id = $article->header ('message-id');
    $article->rename_header ('message-id', 'x-original-message-id', 'add')
        if ($id && $id !~ /^<[^\s\@>]+\@[^\s.>]+(\.[^.\s>]+)+>$/);

    # Many mail clients put the message ID of the message being replied to
    # in the In-Reply-To header and just carry References over.  We
    # therefore try to extract a message ID out of the In-Reply-To header
    # and append it to the References line if it isn't already there.  This
    # is a hack, but I think it's a necessary one.  This regex probably
    # still isn't quite what we want.  We don't refold the References header
    # here.  We probably should.
    $id = $article->header ('in-reply-to');
    if ($id && $id =~ /(<[^\s\@>]+\@[^\s.>]+(\.[^.\s>]+)+>)/) {
        $id = $1;
        my $references = $article->header ('references');
        if (!$references) {
            $article->set_headers (references => $id);
        } elsif ((split (' ', $references))[-1] ne $id) {
            $references .= ' ' . $id;
            $article->set_headers (references => $references);
        }
    }

    # Make sure we have a subject line; if the message didn't have one, we
    # add a default one of "(none)" and special-case this later on.
    $article->set_headers (subject => '(none)')
        unless ($article->header ('subject'));

    # We succeeded, so return undef.
    undef;
}

1;
