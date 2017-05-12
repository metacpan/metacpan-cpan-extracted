# crosspost.al -- Limit crossposts and followups.  -*- perl -*-
# $Id: crosspost.al,v 0.1 1997/12/26 06:31:59 eagle Exp $
#
# Copyright 1997 by Russ Allbery <rra@stanford.edu>
#
# This program is free software; you may redistribute it and/or modify it
# under the same terms as Perl itself.  This is a News::Gateway module and
# requires News::Gateway to be used.

# @@ Interface:  ['crosspost', 'followup']

package News::Gateway;

############################################################################
# Configuration directives
############################################################################

# We take two directives, crosspost and followup.  The former sets limits on
# crossposting, the latter sets limits on where followups can go.  Each
# directive takes one of three keywords:  "max" followed by a number
# specifying a maximum number of groups, "remove" followed by a group name
# that is removed from the crosspost or followups, and "reject" followed by
# a group name that causes the message to be rejected if that group is
# crossposted to or if followups would go to it.
sub crosspost_conf {
    my ($self, $directive, $command, $argument) = @_;
    if ($command eq 'max') {
        $$self{crosspost}{$directive . $command} = $argument;
    } else {
        push (@{$$self{crosspost}{$directive . $command}}, $argument);
    }
}


############################################################################
# Message rewrites
############################################################################

# Check the message to make sure that it complies with the various limits
# and group exclusions, and possibly trim out groups if so instructed.
sub crosspost_mesg {
    my $self = shift;
    my $info = $$self{crosspost};
    my @newsgroups = split (/,/, $$self{article}->header ('newsgroups'));

    # Check the newsgroups list for anything that should be removed or which
    # would cause a rejection.
    @newsgroups = map {
        my $group = $_;
        for (@{$$info{crosspostreject}}) {
            return "Invalid crosspost to $group" if ($_ eq $group);
        }
        (grep { $group eq $_ } @{$$info{crosspostremove}}) ? () : $group;
    } @newsgroups;

    # Now get our followups.  We do this afterwards, since it may just be a
    # copy of the Newsgroups header, which we could have just modified.
    my $followups = $$self{article}->header ('followup-to');
    my @followups;
    if ($followups) {
        @followups = split (/,/, $followups);
    } else {
        @followups = @newsgroups;
    }

    # Check the followups for the same thing.
    @followups = map {
        my $group = $_;
        for (@{$$info{followupreject}}) {
            return "Followups would go to $group" if ($_ eq $group);
        }
        (grep { $group eq $_ } @{$$info{followupremove}}) ? () : $group;
    } @followups;

    # Check the maximum crosspost and followup restrictions, if there are
    # any.
    if ($$info{crosspostmax} && $$info{crosspostmax} < @newsgroups) {
        return 'Excessively crossposted';
    } elsif ($$info{followupmax} && $$info{followupmax} < @followups) {
        return 'Followups would go to too many groups';
    }

    # Now, set the headers to the new value.  We suppress the Followup-To
    # header if it has the same content as the Newsgroups header.
    my $newsgroups = join (',', @newsgroups);
    $followups = join (',', @followups);
    $$self{article}->set_headers (newsgroups => $newsgroups);
    if ($followups eq $newsgroups) {
        $$self{article}->drop_headers ('followup-to');
    } else {
        $$self{article}->set_headers ('followup-to' => $followups);
    }

    # Return success.
    undef;
}

1;
