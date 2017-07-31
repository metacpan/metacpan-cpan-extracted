#!/usr/bin/perl

use strict;
use warnings;
use MIME::Lite;

# MIME::Lite is a Perl module for constructing MIME messages,
# as well as sending messages on their way.
#
# This sample script attempts to construct a message using
# MIME::Lite, generate a DKIM signature for that message, then
# insert the DKIM signature into the MIME::Lite message, and
# use MIME::Lite to send the message.
#
# The result is a partial success. Some of the MIME::Lite headers
# get moved above the DKIM-Signature header, which may be
# problematic. I haven't tested it.
#
my $msg;

    ### Create the multipart "container":
    $msg = MIME::Lite->new(
        From    =>'me@myhost.com',
        To      =>'you@yourhost.com',
        Cc      =>'some@other.com, some@more.com',
        Subject =>'A message with 2 parts...',
        Type    =>'multipart/mixed'
    );

    ### Add the text message part:
    ### (Note that "attach" has same arguments as "new"):
    $msg->attach(
        Type     =>'TEXT',
        Data     =>"Here's the GIF file you wanted"
    );

    ### Add the image part:
    $msg->attach(
        Type        =>'image/gif',
        Path        =>'aaa000123.gif',
        Filename    =>'logo.gif',
        Disposition => 'attachment'
    );

### Add a DKIM signature
use Mail::DKIM::Signer;
my $dkim = Mail::DKIM::Signer->new(
		Algorithm => "rsa-sha1",
		Method => "relaxed",
		Domain => "myhost.com",
		Selector => "mx1",
		KeyFile => "./private.key",
		);
my $raw_data = $msg->as_string;
$raw_data =~ s/\n/\015\012/gs;
$dkim->PRINT($raw_data);
$dkim->CLOSE;
my $sig = $dkim->signature;
my ($header_name, $header_content) = split /:\s*/, $sig->as_string, 2;
unshift @{$msg->{Header}}, [ $header_name, $header_content ];

print $msg->as_string;

