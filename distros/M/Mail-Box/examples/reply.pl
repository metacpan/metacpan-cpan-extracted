#!/usr/bin/perl

# Demonstration on how to create a reply based on some message in
# some folder.
#
# Usage:
#      ./reply.pl folder messagenr [signaturefile]
#
# This code can be used and modified without restriction.
# Mark Overmeer, <mailbox@overmeer.net>, 9 nov 2001

use warnings;
use strict;
use lib '..', '.';

use Mail::Box::Manager 2.00;
use Mail::Message::Body::Lines;
use Mail::Message::Construct;

#
# Get the command line arguments.
#

die "Usage: $0 folderfile messagenr [signaturefile]\n"
    unless @ARGV==3 || @ARGV==2;

my ($filename, $msgnr, $sigfile) = @ARGV;

# You may create different kinds of objects to store body data, but
# usually the ::Lines object is ok.  If you handle a body as 'reply'
# does, you want fast access to the separate lines.  Preferably use
# ::File when the data is binary, and ::String when it is to be
# converted as a whole.  Each type will work, but the performance will
# differ.

my $bodytype = 'Mail::Message::Body::Lines';

#
# Open the folder
#

my $mgr    = Mail::Box::Manager->new;

my $folder = $mgr->open
   ( $filename
   , extract => 'LAZY'   # never take the body unless needed
   );                    #  which saves memory and time.

die "Cannot open $filename: $!\n"
    unless defined $folder;

#
# Get the message to reply to
#

die "There are only ",scalar $folder->messages, " messages in $filename.\n"
   if $msgnr > $folder->messages;

my $orig = $folder->message($msgnr);

#
# Create the reply prelude.
# The default only produces the replyPrelude line, but we extend it
# a little.
#

my $prelude = <<'PRELUDE';
Dear friend,

This automatically produced message is just a reply on yours.  Please
do not be disturbed.  Best wishes, Me, myself, and I.

PRELUDE

$prelude .= $orig->replyPrelude($orig->get('From'));  # The usual quote line.

#
# The postlude is appended after the inlined source text.  It is
# less visible than the prelude, because the quoted source text
# may be very long.  However, when include is ATTACH on NO, the
# body is turned into one line, so this will be neat.
#

my $postlude = <<'POST';

Herewith, I reply to your message, and I intend to ignore it completely
unless you plan to complain to my boss about that.

 See you (hope not)

POST

#
# Create a new signature
#

my $signature;
if(defined $sigfile)
{   $signature = $bodytype->new
      ( mime_type => 'text/x-vCard'
      , file      => $sigfile
      );
}
else
{   $signature = $bodytype->new(mime_type => 'text/x-vCard', data => <<'SIG');
This is my signature.  It is attached, in case we create
a multipart reply, and inlined otherwise.
SIG
}

#
# Create reply
# The original signature is stripped, the message is quoted, and a
# new signature is added.
#

my $reply = $orig->reply
 ( prelude   => $prelude
 , postlude  => $postlude
 , signature => $signature
 );


# And now
$reply->print;
# or $reply->send;

$folder->close;
