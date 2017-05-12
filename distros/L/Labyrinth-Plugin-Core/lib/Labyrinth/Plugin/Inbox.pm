package Labyrinth::Plugin::Inbox;

use warnings;
use strict;

our $VERSION = '5.19';

=head1 NAME

Labyrinth::Plugin::Inbox - Inbox plugin handler for Labyrinth

=head1 DESCRIPTION

Contains all the inbox/message handling functionality for the Labyrinth
framework.

Note that although this module was originally used to alert changes within
the content management framework, the methods within have been little used.
As such, they are being looked at with a view to redesigning in the future.

The intention with approval and decline, is to hook into the appropriate
plugin to promote the specified item, such as an article, news item or event.
This functionality would only be used by publishers to review items submittd
by writers/editors.

=cut

# -------------------------------------
# Library Modules

use base qw(Labyrinth::Plugin::Base);

use Labyrinth::DBUtils;
use Labyrinth::Inbox;
use Labyrinth::Variables;

# -------------------------------------
# The Subs

=head1 PUBLIC INTERFACE METHODS

=over 4

=item InboxCheck

Provide a count of messages in the inbox.

=item InboxView

Provide a list of message headers in the inbox.

=item MessageView

Read a specific message.

=item MessageApprove

Approve the action of a specific message.

=item MessageDecline

Decline the action of a specific message.

=back

=cut

sub InboxCheck {
    return  if($tvars{user}->{name} eq 'guest');
    my $folders = AccessAllFolders($tvars{loginid},PUBLISHER);
    my $areas = AccessAllAreas();
    my @rows = $dbi->GetQuery('array','CountInbox',
                    {areas=>$areas,folders=>$folders});
    $tvars{inbox} = $rows[0]->[0] || 0;
}

sub InboxView {
    return  if($tvars{user}->{name} eq 'guest');
    my $folders = AccessAllFolders($tvars{loginid},PUBLISHER);
    my $areas = AccessAllAreas();
    my @rows = $dbi->GetQuery('array','ReadInbox',
                    {areas=>$areas,folders=>$folders});
    $tvars{inbox} = scalar(@rows);
    $tvars{data}  = \@rows  if(@rows);
}

sub MessageView {
    return  if($tvars{user}->{name} eq 'guest');
    my @rows = $dbi->GetQuery('hash','ReadMessage', $cgiparams{message});
    $tvars{data}  = \@rows  if(@rows);
}

sub MessageApprove {
    return  if($tvars{user}->{name} eq 'guest');
    MessageApproval(1,$tvars{loginid},$cgiparams{message});
}

sub MessageDecline {
    return  if($tvars{user}->{name} eq 'guest');
    MessageApproval(0,$tvars{loginid},$cgiparams{message});
}

1;

__END__

=head1 SEE ALSO

L<Labyrinth>

=head1 AUTHOR

Barbie, <barbie@missbarbell.co.uk> for
Miss Barbell Productions, L<http://www.missbarbell.co.uk/>

=head1 COPYRIGHT & LICENSE

  Copyright (C) 2002-2015 Barbie for Miss Barbell Productions
  All Rights Reserved.

  This module is free software; you can redistribute it and/or
  modify it under the Artistic License 2.0.

=cut
