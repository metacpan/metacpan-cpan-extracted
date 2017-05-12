#!/usr/bin/perl

# Demonstration on how to use create complex messages from building
# bricks.
#
# This code can be used and modified without restriction.
# Mark Overmeer, <mailbox@overmeer.net>, 16 nov 2001

use warnings;
use strict;
use lib '..', '.';
use Mail::Box::Manager 2.00;

# Not needed for the build method, which is demonstrated here, but
# for the structures used to create the demonstration.
use Mail::Message::Body;

#
# Get the command line arguments.
#

die "Usage: $0 outfile\n"
    unless @ARGV == 1;

my $outfile = shift @ARGV;

#
# There are many ways you can add data to new messages.  Below is
# a example which uses files which may not be available on you machine.
# Modify the names for your system.
#

my $anybody = Mail::Message::Body->new(data => <<'A_FEW_LINES');
Just a few lines to show that you
can add prepared bodies to the message
which is built.
A_FEW_LINES

my $vcard = Mail::Message::Body->new
 ( mime_type => 'text/x-vcard', data => <<'SIG');
This is a signature.  It has a different type.
SIG

#
# The next part is what I want to demonstrate
#

my $message = Mail::Message->build
 ( From          => 'me@example.com'
 , To            => 'you@demosite.net'
 , 'In-Reply-To' => '<iwufd87.sfu76k>'

 , data          => <<'FIRST_PART'
This is the first part of the multi-part message which will be created.
If only one source of data is specified, a single part message is
produced.
FIRST_PART

 , file          => '/etc/passwd'
 , file          => '/usr/src/linux/Documentation/logo.gif'
 , attach        => $anybody
 , attach        => $vcard
 );

#
# The message is ready to be printed, transmitted, and/or added to
# a folder.
#

die "Cannot create $outfile: $!\n"
   unless open OUT, '>', $outfile;

$message->print(\*OUT);

# $message->send;
# $folder->addMessage($message);
