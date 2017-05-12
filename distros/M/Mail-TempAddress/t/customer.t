#! perl

BEGIN
{
    chdir 't' if -d 't';
    use lib '../lib', '../blib/lib', 'lib';
}

use strict;
use warnings;

use FakeIn;
use FakeMail;
use File::Path 'rmtree';

use Test::More tests => 30;

use_ok( 'Mail::TempAddress' ) or exit;

use Test::MockObject;
use Test::Exception;

use Mail::TempAddress::Addresses;

mkdir 'addresses';

END
{
    rmtree 'addresses' unless @ARGV;
}

my @mails;
Test::MockObject->fake_module( 'Mail::Mailer', new => sub ($@) {
    push @mails, FakeMail->new();
    $mails[-1];
});

diag( 'Create a new alias and subscribe another user' );

my $fake_glob = FakeIn->new( split(/\n/, <<'END_HERE') );
From: me@home
To: alias@there
Subject: *new*
Delivered-To: alias@there

END_HERE

my $ml = Mail::TempAddress->new( 'addresses', $fake_glob );
$ml->process();

my $count = @mails;
my $mail  = shift @mails;
is( $mail->To(),   'me@home',       '*new* list should reply to sender' );
is( $mail->From(), 'alias@there',   '... from the alias' );
like( $mail->Subject(),
    qr/Temporary address created/,  '... with a good subject' );

like( $mail->body(),
    qr/A new temporary address has been created for me\@home/,
                                    '... and a creation message' );

my $find_address = qr/([a-f0-9]+)\@there/;
my ($address) = $mail->body() =~ $find_address;
isnt( $address, undef,              '... providing the temporary address' );

diag( 'Sending a message to a temp address' );
$fake_glob = FakeIn->new( split(/\n/, <<"END_HERE") );
From: someone\@somewhere
To: $address\@there
Some-Header: foo
Subject: Hi there
Delivered-To: $address\@there

Here is
my message!!

END_HERE

$ml = Mail::TempAddress->new( 'addresses', $fake_glob );
$ml->process();

$mail = shift @mails;
is( $mail->To(), 'me@home',
    'message sent to temp addy should be resent to creator' );
is( $mail->Subject(), 'Hi there', '... with subject preserved' );
my $replyto = 'Reply-To';
my $alias   = $mail->$replyto();
like( $alias, qr/$address\+(\w+)\@there/,
    '... setting Reply-To to keyed alias' );
like( $mail->body(), qr/Here is.+my message!!/s,
    '... preserving message body' );

my $sh = 'Some-header';
is( $mail->$sh(), 'foo', '... preserving other headers' );

diag( 'Replying to a keyed alias' );

$fake_glob = FakeIn->new( split(/\n/, <<"END_HERE") );
From: me\@home
To: $alias
Another-Header: bar
Subject: Well hello!

I am responding
to
you
END_HERE

$ml = Mail::TempAddress->new( 'addresses', $fake_glob );
$ml->process();

$mail = shift @mails;
is( $mail->To(), 'someone@somewhere',
    'replying to resent message should respond to its sender' );
is( $mail->From(), "$address\@there", '... from temporary address' );
like( $mail->body(), qr/I am responding.+to.+you/s,
    '... with body' );
my $ah = 'Another-header';
is( $mail->$ah(), 'bar', '... preserving other headers' );

diag( 'Replying to a keyed alias in a Cc' );

$fake_glob = FakeIn->new( split(/\n/, <<"END_HERE") );
From: me\@home
To: some\@other
Cc: $alias
Delivered-To: $alias
Another-Header: bar
Subject: Well hello!

I am responding
to
you
indirectly
END_HERE

$ml = Mail::TempAddress->new( 'addresses', $fake_glob );
$ml->process();

$mail = shift @mails;
is( $mail->To(), 'someone@somewhere',
    'replying to resent message should respond to its sender' );
is( $mail->From(), "$address\@there", '... from temporary address' );
like( $mail->body(), qr/I am responding.+to.+you/s,
    '... with body' );
$ah = 'Another-header';
is( $mail->$ah(), 'bar', '... preserving other headers' );
my @cc = $mail->Cc();
is( @cc,     0,          '... except for Cc' );

diag( 'Expiration dates should work' );
$fake_glob = FakeIn->new( split(/\n/, <<'END_HERE') );
From: me@home
To: alias@there
Subject: *new*

Expires: 7d
END_HERE

$ml = Mail::TempAddress->new( 'addresses', $fake_glob );
$ml->process();

$mail         = shift @mails;
($address)    = $mail->body() =~ $find_address;
my $addresses = Mail::TempAddress::Addresses->new( 'addresses' );
$alias        = $addresses->fetch( $address );
ok( $alias->expires(),
    'sending expiration directive should set expires flag to true' );

$alias->{expires} = time() - 100;
$addresses->save( $alias, $address );

@mails = ();

$fake_glob = FakeIn->new( split(/\n/, <<END_HERE) );
From: me\@home
To: $address\@there
Subject:  probably too late

this message will not reach you in time
END_HERE

$ml = Mail::TempAddress->new( 'addresses', $fake_glob );
throws_ok { $ml->process() } qr/Invalid address/,
                 'mta should throw exception on expired address';
is( $! + 0, 100, '... setting $! to 100' ) or diag( "$address" );
is( @mails, 0,   '... sending no messages' );

diag( 'Descriptions should work' );
$fake_glob = FakeIn->new( split(/\n/, <<'END_HERE') );
From: me@home
To: alias@there
Subject: *new*

Description: my temporary address
END_HERE

$ml = Mail::TempAddress->new( 'addresses', $fake_glob );
$ml->process();

$mail         = shift @mails;
($address)    = $mail->body() =~ $find_address;

$fake_glob = FakeIn->new( split(/\n/, <<"END_HERE") );
From: you\@elsewhere
To: $address\@there
Subject: hello

Description: my temporary address
END_HERE

$ml = Mail::TempAddress->new( 'addresses', $fake_glob );
$ml->process();

$mail         = shift @mails;
my $desc_head = 'X-MTA-Description';
my $desc      = $mail->$desc_head();

is( $desc, 'my temporary address',
    'description header should be present in responses' );

diag( 'Respect multi-part messages' );

my $boundary = "=-o/TyUX3mnxrfgX+Lef56";

$fake_glob = FakeIn->new( split(/\n/, <<"END_HERE" ) );
Subject: attachment test
From: me\@home
To: $address\@there
Content-Type: multipart/mixed; boundary="$boundary"
Mime-Version: 1.0


--=-o/TyUX3mnxrfgX+Lef56
Content-Type: text/plain
Content-Transfer-Encoding: 7bit

hey there

-- 
my signature

--=-o/TyUX3mnxrfgX+Lef56
Content-Disposition: attachment; filename=hi.txt
Content-Type: text/plain; name=hi.txt; charset=
Content-Transfer-Encoding: 7bit

Hi there!

--=-o/TyUX3mnxrfgX+Lef56--
END_HERE
$ml = Mail::TempAddress->new( 'addresses', $fake_glob );
$ml->process();

$mail    = shift @mails;
my $body = $mail->body();
my $ct   = 'Content-type';
like( $mail->$ct(), qr!multipart/mixe!, 'should maintain content type header' );
like( $body, qr/hey there\n\n-- \nmy signature/,
    '... not adding extra newlines' );

diag( 'Not sending to other To or Cc addresses' );
$fake_glob = FakeIn->new( split(/\n/, <<"END_HERE") );
From: someone\@somewhere
To: $address\@there, someone\@elsewhere
Cc: another\@elsewhere
Subject: Don't Spam Me
Delivered-To: $address\@there

Here is
my message!!

END_HERE

$ml = Mail::TempAddress->new( 'addresses', $fake_glob );
$ml->process();

is( @mails, 1, 'resent message should go to only one recipient' );

$mail  = shift @mails;
my $cc = join(', ', $mail->Cc());
my $to = join(', ', $mail->To());
isnt( $cc, '<another@elsewhere>',        '... not preserving literal Cc' );
like( $to, qr/<$address\+(\w+)\@there>/, '... or literal To' );
