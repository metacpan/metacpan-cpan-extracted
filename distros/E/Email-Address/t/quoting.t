#!perl
use strict;

use Email::Address;
use Test::More tests => 13;

my $phrase = q{jack!work};
my $email  = 'jack@work.com';

my $ea = Email::Address->new($phrase, $email);

is(
  $ea->format,
  q{"jack!work" <jack@work.com>},
  'we automatically quote a phrase with ! in it',
);

is($ea->phrase, $phrase, "the phrase method returns the right thing");

my ($ea2) = Email::Address->parse($ea->format);

is(
  $ea2->format,
  q{"jack!work" <jack@work.com>},
  'round trip format the previously parsed email',
);

is($ea2->phrase, $phrase, "the phrase method returns the right thing");

my ($ea3) = Email::Address->parse(q{jack!work <jack@work.com>});

is(
  $ea3->format,
  q{"jack!work" <jack@work.com>},
  'given an email with an unquoted !, we quote when formatting',
);

is($ea3->phrase, $phrase, "the phrase method returns the right thing");

{
    my $B = chr 0x5C; # \
    my $phrase = qq{jack "$B" robinson};
    my $ea = Email::Address->new($phrase, 'jack@work.com');
    is $ea->phrase, $phrase, "phrase round trips via ->new";
    is $ea->format, qq{"jack $B"$B$B$B" robinson" <jack\@work.com>};

    my ($addr) = Email::Address->parse( $ea->format );
    is($addr->format, $ea->format, "round trip safely");
}

is(
  Email::Address->new('X', 'Y@example.mil', 'Z')->format,
  q{"X" <Y@example.mil> (Z)},
  'we parenthesize comments',
);

is(
  Email::Address->new('X', 'Y@example.mil', '0')->format,
  q{"X" <Y@example.mil> (0)},
  'we parenthesize comments',
);

is(
  Email::Address->new(undef, 'Y@example.mil', '0')->format,
  q{<Y@example.mil> (0)},
  'we do not provide an empty phrase',
);

is(
  Email::Address->new('', 'Y@example.mil', '0')->format,
  q{<Y@example.mil> (0)},
  'we do not provide an empty phrase',
);
