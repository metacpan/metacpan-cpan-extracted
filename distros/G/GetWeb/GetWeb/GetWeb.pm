# The GetWeb MailBot server software is copyright (c) 1996 SatelLife.
# All rights reserved. This program is free software; you can
# redistribute it and/or modify it under the same terms as Perl.

# Author: Rolf Nelson

package GetWeb;
$VERSION = '1.11';
sub Version { $VERSION }

package GetWeb::GetWeb;

use LWP::UserAgent;
use MailBot::MailBot;
use GetWeb::ProcMsg;
use GetWeb::Cmd;
use Carp;
use MailBot::Util;
#use LWP::Debug qw(+);

@ISA = qw( MailBot::MailBot );
use strict;

sub sDie
{
     croak "SYNTAX ERROR: ". shift;
}

sub d
{
    &MailBot::Util::debug(@_);
}

sub vProcess
{
    my $self = shift;
    my $incoming = shift;

    new GetWeb::ProcMsg($self,$incoming);
}

1;
