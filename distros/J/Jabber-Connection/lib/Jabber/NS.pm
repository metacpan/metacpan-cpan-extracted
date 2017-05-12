package Jabber::NS;

# $Id: NS.pm,v 1.1.1.1 2001/09/21 17:20:54 dj Exp $

=head1 NAME

Jabber::NS - Jabber namespaces

=head1 SYNOPSIS

  use Jabber::NS qw(<some tag>);
  print NS_AUTH;  

=head1 DESCRIPTION

Jabber::NS is simply a load of constants that reflect Jabber
namespace constants (and other things). These can be imported
into your program with the C<use> statement. These namespace
constants are based on those specified in the lib/lib.h file
in the Jabber server source.

By default, nothing is imported - specify one or more tags or
individual constants in the C<use> statement as shown in the
SYNOPSIS.

=head1 TAGs

The tags are:

=over 4

=item stream

Stream namespaces, such as B<jabber:client>. 

=item iq

IQ namespaces, such as B<jabber:iq:auth>.

=item x

X namespaces, such as B<jabber:x:oob>.

=item misc

Miscellaneous namespaces, such as the w3c one for XHTML.

=item flags

Various flags, such as r_HANDLED, used by Jabber::Connection.

=item all

You can use this to bring in all the namespaces that
this module offers.

=back

Don't forget to prefix these tag names with a colon, e.g.:

  use Jabber::NS qw(:iq :x);

=cut 

use strict;

# stream
use constant NS_CLIENT     => 'jabber:client';
use constant NS_SERVER     => 'jabber:server';
use constant NS_ACCEPT     => 'jabber:component:accept';

# iq
use constant NS_AUTH       => 'jabber:iq:auth';
use constant NS_REGISTER   => 'jabber:iq:register';
use constant NS_ROSTER     => 'jabber:iq:roster';
use constant NS_AGENT      => 'jabber:iq:agent';
use constant NS_AGENTS     => 'jabber:iq:agents';
use constant NS_VERSION    => 'jabber:iq:version';
use constant NS_TIME       => 'jabber:iq:time';
use constant NS_PRIVATE    => 'jabber:iq:private';
use constant NS_SEARCH     => 'jabber:iq:search';
use constant NS_OOB        => 'jabber:iq:oob';
use constant NS_ADMIN      => 'jabber:iq:admin';
use constant NS_FILTER     => 'jabber:iq:filter';
use constant NS_AUTH_0K    => 'jabber:iq:auth:0k';
use constant NS_BROWSE     => 'jabber:iq:browse';
use constant NS_CONFERENCE => 'jabber:iq:conference';
use constant NS_GATEWAY    => 'jabber:iq:gateway';
use constant NS_LAST       => 'jabber:iq:last';
use constant NS_RPC        => 'jabber:iq:rpc';

# x
use constant NS_OFFLINE    => 'jabber:x:offline';
use constant NS_DELAY      => 'jabber:x:delay';
use constant NS_XOOB       => 'jabber:x:oob';
use constant NS_EVENT      => 'jabber:x:event';
use constant NS_SIGNED     => 'jabber:x:signed';
use constant NS_ENCRYPTED  => 'jabber:x:encrypted';
use constant NS_ENVELOPE   => 'jabber:x:envelope';
use constant NS_EXPIRE     => 'jabber:x:expire';

# misc
use constant NS_VCARD      => 'vcard-temp';
use constant NS_XHTML      => 'http://www.w3.org/1999/xhtml';

use constant IQ_GET        => 'get';
use constant IQ_SET        => 'set';
use constant IQ_ERROR      => 'error';
use constant IQ_RESULT     => 'result';

# flags
use constant r_HANDLED     => '!jabber-connection-handled!';


use Exporter;
use vars qw/@ISA @EXPORT_OK %EXPORT_TAGS/;
@ISA=qw(Exporter);

%EXPORT_TAGS = (
  'stream' => [qw(NS_CLIENT NS_SERVER NS_ACCEPT)],
  'iq'     => [qw(NS_AUTH NS_REGISTER NS_ROSTER NS_AGENT
                  NS_AGENTS NS_VERSION NS_TIME NS_PRIVATE
                  NS_SEARCH NS_OOB NS_ADMIN NS_FILTER NS_AUTH_0K 
                  NS_BROWSE NS_CONFERENCE NS_GATEWAY NS_LAST NS_RPC)],
  'x'      => [qw(NS_OFFLINE NS_DELAY NS_XOOB NS_EVENT
                  NS_SIGNED NS_ENCRYPTED NS_ENVELOPE NS_EXPIRE)],
  'misc'   => [qw(NS_VCARD NS_XHTML IQ_GET IQ_SET IQ_ERROR IQ_RESULT)],
  'flags'  => [qw(r_HANDLED)],
);

my $con;
push @EXPORT_OK, @$con while (undef, $con) = each %EXPORT_TAGS;


$EXPORT_TAGS{'all'} = \@EXPORT_OK;

=head1 SEE ALSO

Jabber::NodeFactory, Jabber::Connection

=head1 AUTHOR

DJ Adams

=head1 VERSION

early

=head1 COPYRIGHT

This module is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

1;
