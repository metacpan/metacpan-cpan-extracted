#!perl -w
use strict;
my %boxes;
BEGIN {
  %boxes = (
    'testmbox'      => "\x0a",
    'testmbox.mac'  => "\x0d",
    'testmbox.dos'  => "\x0d\x0a"
  )
}

use Test::More tests => 17 + 3 * keys %boxes;

use_ok("Email::Folder");

for my $box (sort keys %boxes) {
  my $folder;
  ok(
    $folder = Email::Folder->new("t/mboxes/$box", eol => $boxes{$box}),
    "opened $box"
  );

  my @messages = $folder->messages;
  is(@messages, 10, "grabbed 10 messages");

  my @subjects = sort map { $_->header('Subject') }  @messages;

  my @known = (
    'R: [p5ml] karie kahimi binge...help needed',
    'RE: [p5ml] Re: karie kahimi binge...help needed',
    'Re: January\'s meeting',
    'Re: January\'s meeting',
    'Re: January\'s meeting',
    'Re: [p5ml] karie kahimi binge...help needed',
    'Re: [p5ml] karie kahimi binge...help needed',
    'Re: [rt-users] Configuration Problem',
    '[p5ml] Re: karie kahimi binge...help needed',
    '[rt-users] Configuration Problem',
  );

  is_deeply(\@subjects, \@known, "they're the messages we expected");
}


my $folder;
ok($folder = Email::Folder->new('t/mboxes/testmbox.empty'), "opened testmbox.empty");
is($folder->messages, 0);

ok($folder = Email::Folder->new('t/mboxes/mboxcl2'), "opened mboxcl2");
my @messages = $folder->messages;

is(@messages, 3);
is_deeply( [ sort map { $_->header('Subject') } @messages ],
           [ 'Fifteenth anniversary of Perl.',
             'Re: Fifteenth anniversary of Perl.',
             'Re: Fifteenth anniversary of Perl.',
            ],
           "they're the messages we expected");

# mboxcl2 with a lying Content-Length header
ok($folder = Email::Folder->new('t/mboxes/mboxcl2.lies'), "opened mboxcl2.lies");
@messages = $folder->messages;

is(@messages, 3);
is_deeply( [ sort map { $_->header('Subject') } @messages ],
           [ 'Fifteenth anniversary of Perl.',
             'Re: Fifteenth anniversary of Perl.',
             'Re: Fifteenth anniversary of Perl.',
            ],
           "they're the messages we expected");

my $r = Email::Folder->new('t/mboxes/mboxcl2');
is( $r->next_message->header('Subject'), 'Fifteenth anniversary of Perl.',
    'iterate first message' );

# take the offset and close it
my $offset = $r->reader->tell;
undef $r;

ok( $r = Email::Folder->new('t/mboxes/mboxcl2', seek_to => $offset), "reopened");
is( $r->next_message->header('Subject'), 'Re: Fifteenth anniversary of Perl.',
    'second message' );

undef $r;

$r = Email::Folder->new('t/mboxes/mboxcl3');
my @m = $r->messages;
is @m, 2, 'there are two messages in the mbox mboxcl2';

is(
  $m[0]->header('X-Test'),
  'Just a bwahaha',
 'one more line after Content-Length'
);

is(
  $m[0]->header_names(),
  11,
  'with Content-Length all headers are in place'
);

is(
  $m[1]->header('X-Test'),
  'Just another bwahaha',
  'one more line after Lines'
);
is( $m[1]->header_names(), 11, 'with Lines all headers are in place' );
