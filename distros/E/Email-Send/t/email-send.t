use Test::More tests => 18;
use strict;
$^W = 1;

use_ok 'Email::Send';
can_ok 'Email::Send', 'plugins', 'mailer_available', 'mailer',
                      'mailer_args', 'message_modifier', 'send', 'all_mailers';
use_ok $_ 
  for map { "Email::Send::$_" } qw(NNTP SMTP Qmail Sendmail);

can_ok $_, 'is_available', 'send'
  for map { "Email::Send::$_" } qw(NNTP SMTP Qmail Sendmail);

my $mailer = Email::Send->new();
isa_ok $mailer, 'Email::Send';

ok ! $mailer->mailer, "it has no defined mailer";
ok ! @{$mailer->mailer_args}, "and no mailer args";
ok ! $mailer->message_modifier, "and no message modifier";

$mailer->mailer('SMTP');
$mailer->mailer_args([Host => 'localhost']);
$mailer->message_modifier(sub {1});

is $mailer->mailer, 'SMTP', "we've set its mailer to smtp";
is $mailer->mailer_args->[1], 'localhost', "and set a mailer arg";
is ref($mailer->message_modifier), 'CODE', "and a message modifier";
is $mailer->message_modifier->(), 1, "and the message modifier can be called";
