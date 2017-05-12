use Test::More tests => 16;
use strict;
$^W = 1;

BEGIN {
    use_ok 'Email::Reply';
    use_ok 'Email::Simple';
    use_ok 'Email::Simple::Creator';
    use_ok 'Email::MIME::Modifier';
    use_ok 'Email::Address';
}

my $response = <<__RESPONSE__;
Welcome to Earth!
__RESPONSE__

my $simple = Email::Simple->create(
    header => [
        To      => Email::Address->new(undef, 'casey@geeknest.com'),
        From    => 'alien@titan.saturn.sol',
        Subject => 'Ping',
    ],
    body => <<__MESSAGE__ );
Are you out there?


-- 
The New Ones
__MESSAGE__

my $reply = reply to => $simple, body => $response;

$reply->header_set(Date => ());

like(
  $reply->header('from'),
  qr{casey\@geeknest\.com},
  "correct from on reply",
);

like(
  $reply->header('to'),
  qr{alien\@titan\.saturn\.sol},
  "correct to on reply",
);

is(
  $reply->header('subject'),
  'Re: Ping',
  'correct subject',
);

like(
  $reply->body,
  qr{^> Are you out there\?}sm,
  'correct subject',
);

$simple->header_set(Date => ());
$simple->header_set(Cc => 'martian@mars.sol, "Casey" <human@earth.sol>');
$simple->header_set('Message-ID' => '1232345@titan.saturn.sol');
my $complex = reply to         => $simple,
                    from       => Email::Address->new('Casey West', 'human@earth.sol'),
                    all        => 1,
                    self       => 1,
                    attach     => 1,
                    top_post   => 1,
                    keep_sig   => 1,
                    prefix     => '%% ',
                    attrib     => 'Quoth the raven:',
                    body       => $response;
$complex->header_set(Date => ());
$complex->header_set('Content-ID' => ());
$complex->boundary_set('boundary42');

$complex->parts_set([
  map { $_->header_set(Date => ()); $_ } $complex->parts
]);

$complex->parts_set([
  map { $_->header_set('Content-ID' => ()); $_ } $complex->parts
]);

is($complex->parts, 2, "one reply part, one original part");

like(
  ($complex->parts)[1]->header('content-type'),
  qr{^message/rfc822},
  'the second part is the original, rfc822-style',
);

like $complex->header('from'), qr/human\@earth\.sol/, "correct from";

like $complex->header('in-reply-to'),
     qr/1232345\@titan\.saturn\.sol/,
     "correct from";

$complex->header_set('Message-ID' => '4506957@earth.sol');

my $replyreply = reply to => $complex, body => $response;

like $replyreply->header('from'),
     qr/alien\@titan\.saturn\.sol/,
     "correct from";

like $replyreply->header('in-reply-to'),
     qr/4506957\@earth\.sol/,
     "correct from";

$replyreply->header_set(Date => ());

my $string = $replyreply->as_string;
$string =~ s/\x0d\x0a/\n/g;

like $string, qr{"?Casey West"? wrote:\Q
> Welcome to Earth!
> 
> Quoth the raven:
> %% Are you out there?
> %% 
> %% 
> %% -- 
> %% The New Ones
\E}, "flat reply contains quoted body";

