#!/usr/bin/env perl
#
# Test conversions between Mail::Message and MIME::Entity
#
# MIME::Parser::Filer produces msg-????-1.txt files in the
# test directory :(
#

use strict;
use warnings;

use Mail::Message;
use Mail::Message::Test;

use Test::More;


BEGIN
{   # MIME::Entity requires a VERSION on MailTools modules, but
    # MailTools is version-less in my devel environment, hence
    # MIME::Entity is "not found" without the next lines.
    $Mail::Internet::VERSION ||= '2.21';
    $Mail::Field::VERSION    ||= '2.21';
    $Mail::Head::VERSION     ||= '2.21';
    $Mail::Header::VERSION   ||= '2.21';

    eval { require MIME::Entity };
    if($@)
    {   plan skip_all => "requires MIME::Entity";
        exit 0;
    }

    require Mail::Message::Convert::MimeEntity;
    plan tests => 28;
}

my $me   = MIME::Entity->build
 ( From          => 'mailtools@overmeer.net'
 , To            => 'the users'
 , Subject       => 'use Mail::Box'
 , 'In-Reply-To' => '<023984hjlur29420@sruoiu.nl>'
 , 'X-Again'     => 'repeating header'
 , 'X-Again'     => 'repeating header again'
 , 'X-Again'     => 'repeating header and again'
 , Data          => [ <DATA> ]
 );
close DATA;

ok($me);

my $convert = Mail::Message::Convert::MimeEntity->new;
ok($convert);

#
# Convert MIME::Entity to Mail::Message
#

my $msg = $convert->from($me);
ok($msg);

my $head = $msg->head;
ok($head);

# MIME::Entity makes a mess on the headers: not usefull to test the
# order of the returned.

my @from  = $head->get('From');
cmp_ok(@from, "==", 1);

my @again = $head->get('X-again');
# cmp_ok(@again, "==", 3);   # Should be 3, but bug in MIME::Entity
cmp_ok(@again, "==", 1);      # Wrong, but to check improvements in ME

my $body  = $msg->body;
ok($body);

my @lines = $body->lines;
cmp_ok(@lines, "==", 6);
is($lines[-1], "use it anymore!\n");

#
# Convert message back to a MIME::Entity
#

my $back = $convert->export($msg);
ok(defined $back);
$head    = $back->head;

is($head->get('to'), "the users\n");

@from    = $head->get('from');
cmp_ok(@from, "==", 1);

@again   = $head->get('x-again');
cmp_ok(@again, "==", 1);

$body = $back->bodyhandle;
ok($body);

@lines = $body->as_lines;
cmp_ok(@lines, "==", 6);

$back->purge;
$me->purge;

#
# and now: MULTIPARTS!  Convert MIME::Entity to Mail::Message
#

$me = MIME::Entity->build
 ( From => 'me', To => 'you', Type => 'multipart/mixed'
 , Subject => 'Test mp conv'
 , Data => [ "Some\n", "Lines\n" ]
 );
$me->preamble( [ "Pre1\n", "Pre2\n" ]);
$me->attach(Data => [ "First part\n" ] );
$me->attach(Data => [ "Second part\n" ] );
$me->epilogue( [ "Epi1\n", "Epi2\n" ]);

$msg = $convert->from($me);
ok(defined $msg);
ok($msg->isMultipart);

my @parts = $msg->parts;
cmp_ok(@parts, "==", 2);
isa_ok($msg, 'Mail::Message');
isa_ok($parts[0], 'Mail::Message::Part');
isa_ok($parts[1], 'Mail::Message::Part');

$body = $msg->body;
cmp_ok($body->preamble->nrLines, "==", 2);
cmp_ok($body->epilogue->nrLines, "==", 2);
#$msg->print(\*STDERR);

$me->purge;

#
# Convert MULTIPART message back to a MIME::Entity
#

$me = $convert->export($msg);
#$me->print;
isa_ok($me, 'MIME::Entity');
ok($me->is_multipart);
@parts = $me->parts;
cmp_ok(@parts, "==", 2);
isa_ok($parts[0], 'MIME::Entity');
isa_ok($parts[1], 'MIME::Entity');

$me->purge;

1;

__DATA__
MIME::Entity is written by Eriq, and extends Mail::Internet with many
new capabilities, like multipart bodies.  Actually, although it says
to extend, it more or less reimplements most methods and conflicts
with the other.  Even the Mail::Internet constructor does not work:
only the build() can be used to safely construct a message.  Do not
use it anymore!
