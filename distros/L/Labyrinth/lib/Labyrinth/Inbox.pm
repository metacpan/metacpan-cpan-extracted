package Labyrinth::Inbox;

use warnings;
use strict;

use vars qw($VERSION @ISA %EXPORT_TAGS @EXPORT @EXPORT_OK);
$VERSION = '5.32';

=head1 NAME

Labyrinth::Inbox - Inbox Handler for Labyrinth

=head1 SYNOPSIS

  use Labyrinth::Inbox;

  MessageSend(%hash);
  MessageApproval($status,$messageid);

=head1 DESCRIPTION

The Inbox package contains generic functions used for Inbox and Message
handling.

Currently the full functionality of this package is unused. It was originally
developed to store updates for articles, news, events, etc that were submitted
as part of the workflow process.

At some point this will be reviewed and either deleted or reworked to better
fit the workflow process.

=head1 EXPORT

  MessageSend
  MessageApproval

=cut

# -------------------------------------
# Export Details

require Exporter;
@ISA = qw(Exporter);
@EXPORT    = ( qw( MessageSend MessageApproval ) );

# -------------------------------------
# Library Modules

use Labyrinth::Globals;
use Labyrinth::DBUtils;
use Labyrinth::Variables;

# -------------------------------------
# Variables

# -------------------------------------
# The Subs

=head1 FUNCTIONS

=over 4

=item MessageSend(%hash)

Hash table entries should contain:

  my %hash = (
    folder => $folder,
    area   => $area,
    item   => $item,
    title  => $title,
    body   => $body
    url    => $url
  );

=cut

sub MessageSend {
    my %hash = @_;

    $dbi->DoQuery('AddMessage', $hash{folder},  $hash{area},
                                $hash{item},    $hash{title},
                                $hash{body},    $hash{url},
                                formatDate(0),  $tvars{loginid});
}

=item MessageApproval($status,$messageid)

Record informational messages to Inbox Log.

=cut

sub MessageApproval {
    my ($status,$messageid) = @_;
    $tvars{status} = $status;

    my @rows = $dbi->GetQuery('hash','ReadMessage', $messageid);
    return  unless(@rows);

    my $action = $rows[0]->{area}.'::Approval';
    $tvars{message} = $rows[0];
    &$action;
}

1;

__END__

=back

=head1 SEE ALSO

  Labyrinth

=head1 AUTHOR

Barbie, <barbie@missbarbell.co.uk> for
Miss Barbell Productions, L<http://www.missbarbell.co.uk/>

=head1 COPYRIGHT & LICENSE

  Copyright (C) 2002-2015 Barbie for Miss Barbell Productions
  All Rights Reserved.

  This module is free software; you can redistribute it and/or
  modify it under the Artistic License 2.0.

=cut
