# newsgroups.al -- Logic to build Newsgroups header.  -*- perl -*-
# $Id: newsgroups.al,v 0.12 1998/04/14 09:08:37 eagle Exp $
#
# Copyright 1997, 1998 by Russ Allbery <rra@stanford.edu>
#
# This program is free software; you may redistribute it and/or modify it
# under the same terms as Perl itself.  This is a News::Gateway module and
# requires News::Gateway to be used.
#
# You don't want to understand what this module does.  You really don't.
# Trust me.  It will make your head explode.  Just go happily along with
# your life, tell this module what group your script is gatewaying for, tell
# it as much as you can about what addresses correspond to what groups your
# script should be posting to, let it work its magic, and try not to think
# about it too hard.
#
# Really.  I'm serious.
#
# You're still reading?  You poor, doomed fool....
#
# The problem that this module is trying to solve is hard.  In fact, it's a
# good bit harder than one would expect on first inspection.
#
# We have an incoming mail message and we have to decide what newsgroups to
# post it too.  We want to crosspost the message between multiple groups if
# we can figure out how to do so from the mail headers (this is an
# insolvable problem in the general case, but we can handle several specific
# cases of it).  We also, however, have to deal with messages that have a
# Newsgroups header already in them, and the various things that could mean.
#
# So.
#
# We have the following pieces of information at our disposal:
#
# * The group for which we in particular are a mail to news gateway or
#   robomoderator.  We get that information from the argument we're given,
#   since our script should know that information.  Knowing this is
#   fundamental to the design of this algorithm; the theory is that we will
#   figure out in our script, either from a command line argument passed to
#   us by sendmail or from the envelope recipient, what specific group this
#   invocation of the script corresponds to, and this module will receive
#   that information through its required argument.
#
# * The visible addressees of the message (the To and Cc headers) and
#   mappings between addresses and newsgroups we've been told about in our
#   configuration file directives.
#
# * The Newsgroups header of the incoming message, which can mean various
#   things (see the discussion below).
#
# The design goals of the following approach are two-fold:  To crosspost
# whenever possible rather than multiposting, and to try to never generate
# duplicate posts even though we may get duplicate mail messages.
#
# We start by building a list of newsgroups to which we think the message
# should go, based on the To and Cc headers.  The order of this list is
# significant; we always iterate through the addresses in the To header and
# then through the addresses in the Cc header (and rely on the assumption
# that MTAs won't be changing the order of those fields, a hopefully good
# assumption).
#
# If that list is non-empty, there is no Newsgroups header already, and the
# group for which we are a mail to news gateway is the first group on that
# list, then we use that list as our Newsgroups header.  This handles the
# simple case of a message sent directly to the mail to news gateway
# address, and it also handles crossposting.
#
# If instead the group with which we're specifically associated occurs in
# that list but *isn't* the first newsgroup, then we return an error.
# Specifically, we return "Not primary instance", and a script using this
# module will probably want to exit silently if we return that message.
# This is because we assume that all of the mail to news gateways that we
# have been told about are going to be handled by us, and in particular some
# instance of our script will get the mail sent to the address that resolves
# to the first newsgroup in the list we built.  That instance of the script
# will do the crossposting, so all other instances of the script that get
# the mail sent to the other addresses we recognized need to exit silently
# to avoid multiposting.
#
# If there's no Newsgroups header and the group for which we're a mail to
# news gateway isn't in that list (either because the list is empty or
# because it's composed only of other groups), then either we didn't
# recognize its address (because it's hidden behind an alias or mailing list
# or what have you) or it was Bcc'd.  In either case, we should post the
# message just to the group we're associated with.
#
# If there is a Newsgroups header in the article, it could mean several
# different things.  It could mean that the article was posted to a
# moderated group and was therefore never actually posted but instead was
# sent by mail to the moderator (which may be us).  It could mean that the
# article was posted to those newsgroups and cc'd to a mail to news gateway
# (us).  It could also mean that the original message was just a reply to a
# news posting sent via e-mail to a mail to news gateway with a client that
# includes the Newsgroups header on e-mail replies to posted articles, and
# that it was never posted anywhere and the Newsgroups header was
# meaningless.
#
# Unfortunately, disambiguating these reasons is very hard, and in one case
# impossible.
#
# If the Newsgroups header contains only one group and that group is the
# group for which we are a mail to news gateway or if the groups in the
# Newsgroups header are a (possibly improper) subset of the list of
# newsgroups built from the To and Cc headers and our address/newsgroup
# correspondances, then we ignore the supplied Newsgroups header and follow
# the exact same logic as we would if a Newsgroups header weren't present
# (see above for the details).
#
# If our associated group is in neither the Newsgroups header nor the list
# built from the To and Cc headers, post only to it.
#
# Now we come to the hard cases; the Newsgroups header is either a superset
# of the groups found from To and Cc addresses or those two sets have
# neither a subset nor a superset relationship.  In general, there are
# multiple possible interpretations in these cases and we aren't going to be
# able to unambiguously decide.  We have to take our best guess.
#
# The most common case here is where someone crossposted to a moderated
# group without doing anything odd with e-mail Cc's; in that case, our
# associated group will be the only group in the list built from the To and
# Cc headers, and we should use the supplied Newsgroups header.  We also use
# the supplied Newsgroups header if we don't recognize any of the addresses
# in the To and Cc headers, or if the newsgroup we're associated with is in
# the Newsgroups header and doesn't occur in the list of groups built from
# the To and Cc headers.
#
# If the To and Cc headers contain addresses corresponding to groups in the
# Newsgroups header, but none of them correspond to our associated group,
# then we actually want to return the "Not primary instance" error.  The
# reason for this is that obviously our address was either Bcc'd or hidden
# behind an address that we didn't recognize, but we're going to get
# multiple copies (since we're going to get copies from those To and Cc
# addresses that we recognize).  So we're going to step back and let one of
# those other addresses do the posting, since otherwise we'd end up doing
# the same thing in both cases and have a duplicate posting.  Note that this
# assumes that each address in the To and Cc headers will get a copy of the
# message *which is not necessarily true*.  But we're screwed any way we try
# to disambiguate this, and hopefully we won't bite anyone who's not trying
# to be strange.
#
# Finally, if none of the above cases apply, split the newsgroups found from
# mappings of addresses in the To and Cc headers into two sections; the
# newsgroups also present in the Newsgroups header and the ones not also
# present.  If our associated group is the first group in the first section
# (the groups also found in the Newsgroups header), post using the supplied
# Newsgroups header.  If our associated group is the first group in the
# second section (the groups not found in the Newsgroups header), post to
# the list of groups in the second group.  Otherwise, return "Not primary
# instance."
#
# Implicit in that last paragraph is a trust of the Newsgroups header over
# the list of groups built from recognizing the To and Cc headers.  This is
# because we have to deal with moderation, where the Newsgroups header
# preserves the original intended crosspost if one of the groups posted to
# was moderated.  If we eventually use a different method of encapsulating
# messages sent to moderated groups, we can stop paying any attention at all
# to a supplied Newsgroups header in a mail message.  (Thank heaven, and may
# that day come soon.)
#
# If a Newsgroups header is supplied and we don't post to those groups, we
# rename it to X-Original-Newsgroups to preserve that information in case
# someone cares.
#
# Now, finally, we have one more issue to deal with.  The message ID.
# (What, you thought we were done?  Ah, innocence....)
#
# We want to preserve the message ID if at all possible, since it contains
# information that people find valuable.  (People may score up their own
# posts, want to killfile any followups to posts by a particular person, and
# similar sorts of things, and maintaining message IDs allows this to be
# done with *much* less overhead and maintenance of state.)  On the other
# hand, despite the lengths to which we're going to try to crosspost
# properly, there are still several cases in which we're going to be
# multiposting.  If we do multipost, each post except one is going to have
# to have a new message ID generated for it, since otherwise the news server
# is going to reject our posts as duplicates.
#
# The rule is this:  Rename the Message-ID header (causing a new message ID
# to be generated) if there's a Newsgroups header the groups in it and the
# groups to which we're posting are disjoint sets, or if there is no
# Newsgroups header and the groups to which we're posting and the set of
# groups formed from analyzing the To and Cc headers are disjoint sets.  The
# former will catch those cases where the message was both posted and
# e-mailed to a mail to news gateway or where we're splitting the message
# into two posts.  The latter means that the crosspost between the groups in
# the To and Cc headers gets the original message ID and new message IDs are
# generated for any other posts generated by the same message.
#
# After all of that analysis, we're still not handling several obvious
# cases.  For example, if all of the copies of a given message don't go to
# the identical same script using this module, the message ID renaming can
# break down badly (the obvious case is where the same message was sent via
# e-mail to the moderation submission addresses of two different moderated
# groups, neither of which know of each other, and both of them attempt to
# preserve the message ID).  E-mail clients that include the Newsgroups
# header of the message to which they are responding can cause the response
# (if gated back through a mail to news gateway) to be much more widely
# crossposted than the author intended, since the Newsgroups header is
# trusted due to the needs of moderation.  If someone both posts and mails
# their post to a mail to news gateway for one of the groups they posted to,
# we're probably going to end up with a duplicate message.
#
# It's worth bearing in mind that attempting to retain the message ID is a
# very controversial decision, and the subject for quite a bit of debate in
# the past on the moderators' mailing list.  I'm one of those people who
# sets score rules based on the message IDs generated by my newsreader when
# I post, and therefore I'm a strong proponent of preserving the message ID.
# Preserving the message ID is *not* the correct *technical* decision,
# however; mail message IDs do not have the uniqueness guarantee required by
# the news RFCs, and they can lead to collisions in cases such as that
# described above.  Caveat emptor; if you wish to take the more technically
# correct approach and always generate new message IDs, use the headers
# module and rename or drop the Message-ID header on all incoming articles.
#
# Note that the mailtonews module, which should be used in conjunction with
# this module, handles renaming the Message-ID header if the mail message
# ID is invalid for news.
#
# Oh, and if any MTAs along the way drop or change the order of the headers
# we're worried about (To, Cc, and Newsgroups), or if the addresses in the
# To and Cc headers aren't actually getting copies of the message, we're
# doomed.  None of our assumptions are valid, all of this could break, and I
# wash my hands of the entire situation.
#
# And if that weren't enough, this module *also*, if using a supplied
# Newsgroups header, checks the groups contained in it to make sure that
# they're all groups we're allowed to crosspost to.  This is why, in
# addition to having directives to associate addresses or address patterns
# with groups, we also have directives just listing newsgroups or newsgroup
# patterns, which indicate that it's permitted to crosspost to those groups
# but that we don't handle an address associated with them.

# @@ Interface:  ['group']

package News::Gateway;

############################################################################
# Option settings
############################################################################

# We take one argument, the newsgroup this instance of the gateway is
# associated with.  Note that it will be necessary to set this argument
# differently according to the address via which the message arrived.  This
# means that either the envelope recipient has to be available to and
# analyzed by the script, or each separate mail-to-news address will have to
# pass the script a command line argument specifying what newsgroup that
# instance of the script should be associated with.
sub newsgroups_init {
    my $self = shift;
    $$self{newsgroups}{main} = shift;
}


############################################################################
# Configuration directives
############################################################################

# Takes a pattern in the form /<regex>/ and transforms it into an anonymous
# sub that takes one argument and returns true in a scalar context if the
# regex matches that argument and false otherwise.  In an array context, the
# anonymous sub returns the list of substrings matched by parens, just like
# with a normal match, so this can potentially be used to extract newsgroups
# out of an address eventually.  This is not currently implemented in the
# rest of this module.  Returns a ref to the anonymous sub.  We will be able
# to get rid of this sub once we require a version of Perl with compiled
# regex support.
sub newsgroups_glob {
    my ($self, $regex) = @_;
    $regex = substr ($regex, 1, -1);
    my $glob = eval "sub { \$_[0] =~ /$regex/ }";
    if ($@) { $self->error ("Invalid regex /$regex/: $@") }
    $glob;
}

# We take four forms of group directives designating which groups we are
# allowed to crosspost to:
#
#    group <newsgroup> [<address> | /<pattern>/]
#    group /<pattern>/
#    group <file> /<pattern>/
#
# The first adds just that particular group and associates any address found
# in the To or Cc headers that matches <address> or <pattern> with that
# group.  The second allows crossposts from all groups matching <pattern>
# and the third allows crossposts to all groups listed in the file <file>
# that match <pattern>.  The newsgroup is presumed to be the first
# whitespace-separated word on each line of <file>, so <file> can be an
# active file or newsgroups file (for example).
sub newsgroups_conf {
    my ($self, @args);
    ($self, undef, @args) = @_;

    # If we haven't already initialized our data structure, do so now.
    # groups is a hash with each group to which crossposting is allowed
    # entered as a key.  addresses is a hash associating literal addresses
    # with groups.  patterns and grouplist are parallel arrays; patterns are
    # anonymous pattern match subs associated with the corresponding group
    # in grouplist.  Finally, masks are anonymous pattern match subs
    # specifying newsgroups to which we can crosspost.  patterns can't be a
    # hash because a pattern is a code ref.
    unless (exists $$self{newsgroups}{groups}) {
        $$self{newsgroups}{groups}    = {};
        $$self{newsgroups}{addresses} = {};
        $$self{newsgroups}{patterns}  = [];
        $$self{newsgroups}{grouplist} = [];
        $$self{newsgroups}{masks}     = [];
    }

    # Now we have to figure out what sort of argument we've been given.  If
    # the first argument ends with a /, we assume it's a pattern.
    # Otherwise, if the first argument starts with a /, we assume it's a
    # file containing a list of groups.  If neither of those is true, but
    # the second argument begins with a /, we assume it's a single newsgroup
    # associated with an address pattern.  Finally, if none of the above are
    # true, we assume it's a newsgroup, possibly associated with a literal
    # address.  For all mail addresses, we standardize on lowercase.
    if ($args[0] =~ m%/$%) {
        my $glob = $self->newsgroups_glob ($args[0]);
        push (@{$$self{newsgroups}{masks}}, $glob);
    } elsif ($args[0] =~ m%^/%) {
        my $groups = $$self{newsgroups}{groups};
        my $glob = $self->newsgroups_glob ($args[1]);
        open (GROUPS, "$args[0]")
            or $self->error ("Can't open group file $args[0]: $!");
        local $_;
        while (<GROUPS>) {
            my ($group) = split (' ', $_);
            $$self{newsgroups}{groups}{$_} = 1 if &$glob ($group);
        }
        close GROUPS;
    } else {
        my $group = $args[0];
        if (index ($args[1], '/') == 0) {
            my $glob = $self->newsgroups_glob (lc $args[1]);
            push (@{$$self{newsgroups}{patterns}}, $glob);
            push (@{$$self{newsgroups}{grouplist}}, $group);
        } elsif ($args[1]) {
            $$self{newsgroups}{addresses}{lc $args[1]} = $group;
        }
        $$self{newsgroups}{groups}{$group} = 1;
    }
}


############################################################################
# Post checks
############################################################################

# Rename both the Newsgroups and the Message-ID headers to
# X-Original-<header>.
sub newsgroups_orig {
    my $article = $_[0]{article};
    $article->rename_header ('message-id', 'x-original-message-id');
    $article->rename_header ('newsgroups', 'x-original-newsgroups');
}

# Now, we try to implement the logic described in the comment at the
# beginning of this file, which I won't repeat here.
sub newsgroups_mesg {
    my $self = shift;

    # If they didn't tell us a primary newsgroup, bitch at them.
    $self->error ('newsgroups module missing required argument')
        unless $$self{newsgroups}{main};

    # In the following, @newsgroups are the groups in the existing
    # Newsgroups header, if any; @mailgroups are the groups from the To and
    # Cc headers; and @groups are the groups we're actually going to post
    # to.
    my (@newsgroups, @mailgroups, @groups);
    my $article = $$self{article};
    my $main = $$self{newsgroups}{main};

    # What newsgroups did we get on an incoming Newsgroups line?
    @newsgroups = split (/(?:\s*,\s*)+/, $article->header ('newsgroups'));

    # What newsgroups did we get in the mail To/Cc headers?  This code is a
    # bit hard to read unless you're a LISP person.  The second map breaks
    # things up so that we're dealing with one address at a time, and the
    # first map tries to find an associated group.  This code has a *lot* of
    # problems still; it breaks down massively given the presence of commas
    # in comment fields in addresses.  We badly need real RFC 822 parsing,
    # not only for this but for lots of other things too.
    @mailgroups = map {
        my ($address) = /<(\S+)>/;
        ($address) = split unless $address;
        my $group = ($$self{newsgroups}{addresses}{lc $address});
        unless (defined $group) {
            my $patterns = $$self{newsgroups}{patterns};
            my $grouplist = $$self{newsgroups}{grouplist};
            my $index;
            for ($index = 0; $index < @$patterns; $index++) {
                if (&{$$patterns[$index]} (lc $address)) {
                    $group = $$grouplist[$index];
                    last;
                }
            }
        }
        defined $group ? ($group) : ();
    } map {
        split /(?:\s*,\s*)+/
    } $article->header ('to'), $article->header ('cc');

    # Now we start on the hard work.  Let's deal with the most pathological
    # case first, namely the case where we have a Newsgroups header.
    if (@newsgroups) {
        my %newsgroups = map { $_ => 1 } @newsgroups;

        # This is *really* confusing.
        #
        # After the first loop below, we'll have two more arrays.  @common
        # will contain all the newsgroups in common between @mailgroups and
        # @newsgroups, and @extra will contain all the groups in @mailgroups
        # and not in @newsgroups.  $seen will be true if $main was found in
        # @mailgroups and will contain the index into either @common or
        # @extra where $main can be found.
        #
        # If $main is in neither @mailgroups nor @newsgroups, the first
        # case, then rename Message-ID and Newsgroups and post to $main.
        #
        # If $main is in @mailgroups but isn't the first element of the
        # array it's in, then we aren't the primary instance.
        #
        # @newsgroups == @common is the case where @newsgroups is a subset
        # of @mailgroups.  If this is the case, we post to @mailgroups iff
        # $main is the first entry.  (Note that !$seen && $newsgroups{$main}
        # implies @newsgroups != @common, so we know $seen must be true in
        # this case.)
        #
        # Finally, if @newsgroups is not a subset of @mailgroups, we post to
        # either @newsgroups or @extra depending on which set $main is in,
        # and we rename Message-ID and Newsgroups if posting to @extra.
        # (Unless our associated group isn't in @mailgroups but there are
        # other groups in @mailgroups that are in @newsgroups, in which case
        # we let the instance that receives mail at one of the addresses we
        # recognize handle the posting.)
        my (@common, @extra, $seen);
        for (@mailgroups) {
            my $array = $newsgroups{$_} ? \@common : \@extra;
            push (@$array, $_);
            $seen = @$array if ($_ eq $main && !$seen);
        }
        if (!$seen && !$newsgroups{$main}) {
            @groups = ($main);
            $self->newsgroups_orig ();
        } elsif ($seen > 1 || (!$seen && @common)) {
            return 'Not primary instance';
        } elsif (@newsgroups != @common) {
            @groups = $newsgroups{$main} ? @newsgroups : @extra;
            $self->newsgroups_orig () unless $newsgroups{$main};
        } elsif ($main eq $mailgroups[0]) {
            @groups = @mailgroups;
        } else {
            return 'Not primary instance';
        }
    } else {
        my %mailgroups = map { $_ => 1 } @mailgroups;

        # Now for the case where we don't have a Newsgroups header.  This is
        # thankfully simpler.  If $main isn't in @mailgroups, post only to
        # it and rename headers.  Otherwise, post to @mailgroups iff $main
        # is the first element.
        if ($mailgroups{$main}) {
            return 'Not primary instance' unless ($mailgroups[0] eq $main);
            @groups = @mailgroups;
        } else {
            @groups = ($main);
            $self->newsgroups_orig ();
        }
    }

    # We have the list of groups to which we want to post.  Now we need to
    # make sure we're allowed to post to them all.  (We could save ourselves
    # some work here under some circumstances if we could keep track of
    # whether @groups came just from @mailgroups or not, but it's too much
    # hassle and doesn't take long here to just check again.)
  GROUP:
    for (@groups) {
        next if $$self{newsgroups}{groups}{$_};
        my $mask;
        for $mask (@{$$self{newsgroups}{masks}}) {
            next GROUP if &$mask ($_);
        }
        return "Invalid crossposted group $_";
    }

    # All done.  Set the Newsgroups header and return success.
    $article->set_headers (newsgroups => join (',', @groups));
    undef;
}

1;
