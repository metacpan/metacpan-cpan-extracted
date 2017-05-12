use Test::More 'no_plan';

use strict;
use warnings;

use_ok 'Email::MIME::Attachment::Stripper';
use Email::MIME;

open IN, 't/Mail/attached4' or die "Can't read mail";
my $message = do { local $/; <IN>; };

my $msg = Email::MIME->new($message);
isa_ok($msg => 'Email::MIME');
is($msg->parts, 1);

my $strp = Email::MIME::Attachment::Stripper->new($msg);
isa_ok($strp,'Email::MIME::Attachment::Stripper');

my $detached = $strp->message;
isa_ok( $detached, 'Email::MIME' );

my @attachments = $strp->attachments;

TODO: {
  local $TODO = 'Nested MIME parts are incorrectly handled';
  is(scalar(@attachments),2,'attachment count');
}
