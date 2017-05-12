#! perl -T

use strict;
use warnings;

use lib 't/lib';

use FakeIn;
use FakeMail;
use File::Path 'rmtree';

use Test::More tests => 73;
use Test::MockObject;

mkdir 'alias';

END
{
    rmtree 'alias' unless @ARGV;
}

my @mails;
Test::MockObject->fake_module( 'Mail::Mailer', new => sub {
    push @mails, FakeMail->new();
    $mails[-1];
});

diag( 'Create a new alias and subscribe another user' );

my $fake_glob = FakeIn->new( split(/\n/, <<'END_HERE') );
From: me@home.com
To: alias@there.biz
Subject: *new*

you@elsewhere
END_HERE

use_ok( 'Mail::SimpleList' ) or exit;

my $ml = Mail::SimpleList->new( 'alias', $fake_glob );
$ml->process();

my $count = @mails;
my $mail  = shift @mails;
is( $mail->To(),   'you@elsewhere',    '*new* list should notify added users' );
is( $mail->From(), 'me@home.com',          '... from the list creator' );
like( $mail->Subject(),
    qr/Added to alias/,                '... with a good subject' );
my $replyto = 'Reply-To';
ok( $mail->$replyto(),                 '... replying to the alias' );

like( $mail->body(),
    qr/You have been subscribed .+ by me\@home.com/,
                                       '... with a subscription message' );

$mail = shift @mails;
is( $mail->To(), 'me@home.com',       '*new* in subject should respond to sender' );
like( $mail->Subject(),
    qr/^Created list/,            '... with success subject' ); 

like( $mail->body(),
    qr/^Mailing list created.  Post to /,
                                  '... and body' );

ok( $mail->body() =~ /Post to (alias\+(.+)\@.+)\./,
                                  '... containing alias id' );

my ($alias_add, $alias_id) = ($1, $2);
ok( $ml->storage->exists( $alias_id ),
                                  '... creating alias file' );

my $alias = $ml->storage->fetch( $alias_id );
ok( $alias, 'alias should be fetchable' );
is_deeply( $alias->members(),
    [ 'me@home.com', 'you@elsewhere' ], '... adding the correct members' );
is( $alias->owner(), 'me@home.com',          '... and the owner' );
is( $count, 2,                           '... sending only two messages' );

diag( "Send a message to the alias '$alias_add'" );

$fake_glob = FakeIn->new( split(/\n/, <<END_HERE) );
From: me\@home.com
To: someone\@there.biz
Delivered-To: $alias_add
Subject: Hi there

hi there
you guys
END_HERE

$ml = Mail::SimpleList->new( 'alias', $fake_glob );
$ml->process();

$count = @mails;
$mail  = shift @mails;
is_deeply( $mail->Bcc(),[ 'me@home.com', 'you@elsewhere' ],
                                  'message sent to alias should Bcc everyone' );
is( $mail->From(),    'me@home.com',         '... keeping from address' );
is( $mail->To(),      $alias_add,        '... keeping To address as the alias');
is( $mail->Subject(), 'Hi there',        '... saving the subject' );
ok( ! $mail->CC(),                       '... removing all CC addresses' );

like( $mail->body(), qr/hi there/,       '... sending the message body' );
like( $mail->body(), qr/you guys/,       '... multiple lines' );
like( $mail->body(), qr/To unsubscribe/, '... appending unsubscribe message' );
is( $mail->$replyto(), $alias_add,       '... setting Reply-To to alias' );
is( $count, 1,                           '... sending only to subscribers' );

diag( "Remove an address from the alias" );

$fake_glob = FakeIn->new( split(/\n/, <<END_HERE) );
From: you\@elsewhere
To: $alias_add
Subject: *UNSUBSCRIBE*

END_HERE

$ml = Mail::SimpleList->new( 'alias', $fake_glob );
$ml->process();

$alias = $ml->storage->fetch( $alias_id );
is_deeply( $alias->members(), [ 'me@home.com' ],
    'unsubscribing should remove an address from the alias' );

$count = @mails;
$mail  = shift @mails;
is( $mail->To(), "you\@elsewhere",        '... responding to user' );
like( $mail->Subject(), qr/Remove from /, '... with remove subject' );

is( $mail->body(),'Unsubscribed you@elsewhere successfully.',
                                          '... and a success message' );
is( $count, 1,                            '... sending one message' );

diag( "Set an expiration date" );

$fake_glob = FakeIn->new( split(/\n/, <<'END_HERE') );
From: me@home.com
To: alias@there.biz
Subject: *new*

Expires: 7d

you@elsewhere
he.is@his.place
she@hers
END_HERE

$ml = Mail::SimpleList->new( 'alias', $fake_glob );
$ml->process();

# should be the reply
$count = @mails;
$mail  = pop @mails;
my $regex = qr/Post to (alias\+(.+)\@.+)\./;
like( $mail->body(), $regex,
                       'new aliases with expiration date should be creatable' );

($alias_add, $alias_id) = $mail->body() =~ $regex;
$alias = $ml->storage->fetch( $alias_id );

ok( $alias->expires(), '... setting expiration on the alias to true' );

is_deeply( $alias->members(),
    [ 'me@home.com', 'you@elsewhere', 'he.is@his.place', 'she@hers' ],
                       '... and collecting mail addresses properly' );
is( $count, 4,         '... sending a message to creator and each subscriber' );

$alias->{expires} = time() - 100;
$ml->storage->save( $alias, $alias_id );

$fake_glob = FakeIn->new( split(/\n/, <<END_HERE) );
From: me\@home.com
To: $alias_add
Subject:  probably too late

this message will not reach you in time
END_HERE

@mails = ();

$ml = Mail::SimpleList->new( 'alias', $fake_glob );
$ml->process();

$count = @mails;
$mail  = shift @mails;
is( $mail->To(), 'me@home.com',                   '... responding to user' );
like( $mail->Subject(), qr/expired/,          '... with expired in subject' );

is( $mail->body(), 'This alias has expired.', '... and an expiration message' );
is( $count, 1,                                '... sending one message' );

diag( 'Create a closed alias' );

$fake_glob = FakeIn->new( split(/\n/, <<'END_HERE') );
From: me@home.com
To: alias@there.biz
Subject: *new*

Closed: yes

you@there.biz
END_HERE

$ml = Mail::SimpleList->new( 'alias', $fake_glob );
$ml->process();

# should be the reply
$count = @mails;
$mail  = pop @mails;
$regex = qr/Post to (alias\+(.+)\@.+)\./;
like( $mail->body(), $regex, 'new closed alias should be creatable' );

($alias_add, $alias_id) = $mail->body() =~ $regex;
$alias = $ml->storage->fetch( $alias_id );
ok( $alias->closed(), '... and should be marked as closed' );
is( $count, 2,        '... sending two messages' );

$fake_glob = FakeIn->new( split(/\n/, <<END_HERE) );
From: not\@list
To: $alias_add
Subject: hi there

You shouldn't receive this.
END_HERE

@mails = ();
$ml = Mail::SimpleList->new( 'alias', $fake_glob );
$ml->process();

$count = @mails;
$mail  = shift @mails;
is( $mail->To(), 'not@list',                '... responding to user' );
like( $mail->Subject(), qr/closed/,         '... with closed in subject' );

is( $mail->body(),
    'This alias is closed to non-members.', '... and a closed list message' );
is( $count, 1,                              '... sending one message' );

diag( 'Create a non-adding alias' );

$fake_glob = FakeIn->new( split(/\n/, <<'END_HERE') );
From: me@home.com
To: alias@there.biz
Subject: *new*

Auto_add: no

END_HERE

$ml = Mail::SimpleList->new( 'alias', $fake_glob );
$ml->process();

# should be the reply
$count = @mails;
$mail  = shift @mails;
$regex = qr/Post to (alias\+(.+)\@.+)\./;
like( $mail->body(), $regex, 'new no auto-add alias should be creatable' );
is( $count, 1,               '... sending one message' );
($alias_add) = $mail->body() =~ /$regex/;

$fake_glob = FakeIn->new( split(/\n/, <<END_HERE) );
From: me\@home.com
To: $alias_add
CC: you\@there.biz
Subject: hello

Hello, here is a message for you.
END_HERE

@mails = ();
$ml = Mail::SimpleList->new( 'alias', $fake_glob );
$ml->process();

($alias_add, $alias_id) = $mail->body() =~ /$regex/;
$alias                  = $ml->storage->fetch( $alias_id );

is_deeply( $alias->members(), [ 'me@home.com' ],
                           'posting to alias should not add copied addresses' );

$count = @mails;
$mail  = shift @mails;
is( $mail->Cc(), 'you@there.biz',
                           '... but should keep them on the list' );
is_deeply( $mail->Bcc(),
    [ 'me@home.com' ],         '... along with alias subscribers' );
is( $count, 1,             '... sending only one message' );

$fake_glob = FakeIn->new( split(/\n/, <<END_HERE) );
From: me\@home.com
To: alias\@there.biz
Subject: *clone* $alias_add

Auto_add: 1
Name: clonetest
END_HERE

@mails = ();
$ml = Mail::SimpleList->new( 'alias', $fake_glob );
$ml->process();

my $old_id = $alias_id;
$count     = @mails;
$mail      = shift @mails;
(undef, $alias_id) = $mail->body() =~ /$regex/
    or diag "Alias not cloned; tests will fail\n";

my $oldalias = $alias;
$alias       = $ml->storage->fetch( $alias_id );

is_deeply( $alias->members(), $oldalias->members(),
                                    'cloning a list should clone its members' );
is( $alias_id, 'clonetest',         '... setting its name, if given' );
ok( $alias->auto_add(),             '... processing directives' );
is( $mail->To(),     'me@home.com',     '... responding to cloner' );
is( $alias->owner(), 'me@home.com',     '... setting owner to cloner' );
like( $mail->Subject(),
    qr/Cloned alias $old_id/,       '... marking clone in subject' );
is( $count, 1,                      '... sending one message' );

diag( 'Set an alias description' );

$fake_glob = FakeIn->new( split(/\n/, <<'END_HERE') );
From: me@home.com
To: alias@there.biz
Subject: *new*

Description: This alias is about cheese.

you@home.com

END_HERE

$ml = Mail::SimpleList->new( 'alias', $fake_glob );
$ml->process();

$mail = shift @mails;
like( $mail->body(), qr/You have been subscribed .+This alias is about /s,
    'Description directive should be added to subscription notice' );

# fetch alias sent to creator
$mail = shift @mails;
($alias_add, $alias_id) = $mail->body() =~ /$regex/;

diag( "Preserve headers when sending messages" );

$fake_glob = FakeIn->new( split(/\n/, <<END_HERE) );
From: me\@home.com
To: $alias_add
Subject: test header
Message-Id: 12tiemyshoe34shutthedoor
Delivered-To: $alias_add

END_HERE

$ml = Mail::SimpleList->new( 'alias', $fake_glob );
$ml->process();

$mail   = shift @mails;
my $mid = 'Message-id';
is( $mail->$mid(), '12tiemyshoe34shutthedoor',
    'message headers should be preserved' );
my $dto = 'Delivered-To';
isnt( $mail->$dto(), $alias_add,
    '... but Delivered-To should be removed' );

diag( 'Create a new alias with a given name' );

$fake_glob = FakeIn->new( split(/\n/, <<'END_HERE') );
From: me@home.com
To: alias@there.biz
Subject: *new*

Name: anewname
END_HERE

$ml = Mail::SimpleList->new( 'alias', $fake_glob );
$ml->process();

$mail = shift @mails;
ok( $ml->storage->exists( 'anewname' ),
    'creating new list with Name directive should create alias of that name' );
like( $mail->body(), qr/Post to alias\+anewname\@there.biz/,
    '... setting post address correctly' );

diag( 'Ask for help' );
$fake_glob = FakeIn->new( split(/\n/, <<'END_HERE' ) );
From: me@hoome
To: alias@there.biz
Subject: *help*

END_HERE

$ml = Mail::SimpleList->new( 'alias', $fake_glob );
$ml->process();
$mail = shift @mails;
like( $mail->body(), qr/USING LISTS/, 
    'help command should return USING LISTS' );
like( $mail->body(), qr/DIRECTIVES/, 
    '... and DIRECTIVES sections from docs' );
is( $mail->To(), "me\@hoome", '... replying to sender' );

diag( 'Obey signature delimiter' );
$fake_glob = FakeIn->new( split(/\n/, <<'END_HERE' ) );
From: me@home.com
To: alias@there.biz
Subject: *new*

you@work
-- 
Description: This alias is about cheese.
you@home.com
END_HERE

$ml = Mail::SimpleList->new( 'alias', $fake_glob );
$ml->process();
$count = @mails;
is( $count, 2,           '... should generate only 2 mails' );

unlike( $mails[0]->body(),
    qr/alias is about/,  '... ignoring commands after signature delimiter' );

my @recipients = sort map { $_->To() } @mails;
is_deeply( \@recipients, [ 'me@home.com', 'you@work' ],
                         '... only adding the addresses before the delimiter' );

diag( 'Respect multi-part messages' );

my $top_mail = Email::MIME->new( <<END_HERE );
Subject: attachment test
From:    me\@home.com
To:      $alias_add
END_HERE

my $greet    = Email::MIME->create(
    attributes => {
        encoding     => '7bit',
        content_type => 'text/plain',
    },
    body => "hey there\n\n--\nmy signature\n",
);

my $hi_file  = Email::MIME->create(
    attributes => {
        encoding     => '7bit',
        filename     => 'hi.txt',
        content_type => 'text/plain',

    },
    body => "Hi there!\n"
);

$top_mail->parts_set( [ $greet, $hi_file ] );

$fake_glob = FakeIn->new( split(/\n/, $top_mail->as_string() ));
@mails     = ();
$ml = Mail::SimpleList->new( 'alias',  $fake_glob );
$ml->process();

$count = @mails;
is( $count, 1,           '... should generate only one mail' );
my $ct = 'Content-type';
like( $mails[0]->$ct(),  qr|multipart/mixed|, '... maintaining content type' );

# get multiparts but strip out delimiter bits
my $message = Email::MIME->new( $mails[0]->raw_message() );
my @parts   = $message->parts();

is( @parts, 3,                               '... adding a signature part' );
like( $parts[-1]->body(),
    qr/\n-- \nTo unsubscribe/, '... as the last element' );
