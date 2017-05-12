#!/usr/bin/env perl
use warnings;
use strict;
use Jifty::Test::Dist tests => 14;

use Jifty::Test::WWW::Mechanize;

my $server  = Jifty::Test->make_server;

isa_ok($server, 'Jifty::TestServer');

my $URL     = $server->started_ok;
my $mech    = Jifty::Test::WWW::Mechanize->new();

$mech->get_ok('/');

$mech->no_warnings_ok;

Jifty::Test->setup_mailbox;
$mech->get_ok('/dereference-error.html');
$mech->warnings_like(qr/View error: (Not a HASH reference|Can't coerce array into hash)/);

my @emails = Jifty::Test->messages;
is(@emails, 1);
my $email = Email::MIME->new($emails[0]->as_string);

like($email->body_str, qr{Error in /.*/share/web/templates/dereference-error.html, line 4}, "error location");
like($email->body_str, qr{Not a HASH reference|Can't coerce array into hash}, "error message");
like($email->body_str, qr{/.*/share/dist/Jifty/web/templates/autohandler, line \d+}, "stack trace");
like($email->body_str, qr{HTTP_USER_AGENT: Test-WWW-Mechanize}, "environment");

is($email->header("To"), 'errors@example.com');
is($email->header("From"), 'server@example.com');
is($email->header("Subject"), 'Sound the alarm!');

