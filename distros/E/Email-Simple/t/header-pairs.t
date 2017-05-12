use Test::More tests => 3;
use strict;
$^W = 1;

use_ok 'Email::Simple';

my $email = Email::Simple->new(<<'__MESSAGE__');
From: casey@geeknest.example.com
X-Your-Face: your face is your face
To: drain@example.com
X-Your-Face: your face is my face
X-Your-Face: from california
Reply-To: xyzzy@plugh.example.net
X-Your-Face: to the new york islface
Subject: Message in a bottle

HELP!
__MESSAGE__

can_ok $email, 'header_names';

my @header_pairs = $email->header_pairs;
is_deeply(
  \@header_pairs,
  [
    'From',        'casey@geeknest.example.com',
    'X-Your-Face', 'your face is your face',
    'To',          'drain@example.com',
    'X-Your-Face', 'your face is my face',
    'X-Your-Face', 'from california',
    'Reply-To',    'xyzzy@plugh.example.net',
    'X-Your-Face', 'to the new york islface',
    'Subject',     'Message in a bottle',
  ],
  "header pairs came out properly",
);
