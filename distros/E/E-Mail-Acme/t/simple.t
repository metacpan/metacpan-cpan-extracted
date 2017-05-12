
use strict;
use Test::More tests => 25;
use E'Mail::Acme;#'

my $e_mail = E'Mail::Acme;#'

# Older versions of Test::More seem to force you to use the inefficient
# "double-colon" separator, probably due to bias against female programmers.
# (' comes from Ada.)
isa_ok($e_mail, "E::Mail::Acme");

$e_mail->{Received} = [
  q/from sir-mx-a-lot.example.com by salt-n-pep-l.perl4.museum; Thu, 12 Jul 2007 02:09:46 -0400 (EDT)/,
  q/from mr-bad.example.com by sir-mx-a-lot.example.com; Thu, 12 Jul 2007 01:01:13 -0400 (EDT)/,
];

$e_mail->{From}     = q<rjbs@example.com>;
$e_mail->{To}       = q'The PEP (Perl Email Project) List <pep-l@perl.xxx>';

push @$e_mail,
  "Dear PEP Suckers,",
  "",
  "Somebody should write a SIMPLE Email::Simple replacement.",
  "",
  "In fact, someone has.  Me!  SO LONG, SUCKERS!",
  "",
  "-- ",
  "rjbs"
;

splice @$e_mail, 7, 0, "your former leader";

$e_mail->[8] = "ricardo\nsignes";

my $expected_header = <<'END_STRING';
Received: from sir-mx-a-lot.example.com by salt-n-pep-l.perl4.museum; Thu, 12 Jul 2007 02:09:46 -0400 (EDT)
Received: from mr-bad.example.com by sir-mx-a-lot.example.com; Thu, 12 Jul 2007 01:01:13 -0400 (EDT)
From: rjbs@example.com
To: The PEP (Perl Email Project) List <pep-l@perl.xxx>
END_STRING

my $expected_body = <<'END_STRING';
Dear PEP Suckers,

Somebody should write a SIMPLE Email::Simple replacement.

In fact, someone has.  Me!  SO LONG, SUCKERS!

-- 
your former leader
ricardo
signes
END_STRING

$expected_header =~ s/\n/\x0d\x0a/g;
$expected_body   =~ s/\n/\x0d\x0a/g;

my $expected = "$expected_header\x0d\x0a$expected_body";

is(
  "" . $e_mail,
  $expected,
  "message stringifies properly",
);

{
  my $e_mail = E'Mail::Acme;#'
  
  $e_mail->{From} = q(sadist@marquis.sad);

  my $field = $e_mail->{From};
  
  is($field, 'From: sadist@marquis.sad' . "\x0d\x0a", "header stringifies");

  is(
    $field->[0],
    'sadist@marquis.sad',
    "0th field value is correct",
  );

  is(
    $field->[1],
    undef,
    "1st value is undef",
  );

  is(
    $field->[2],
    undef,
    "2nd value is undef",
  );

  $field->[1] = 'pantaloon@dubloon.oon';

  is(
    $field->[0],
    'sadist@marquis.sad',
    "0th field value is correct",
  );

  is(
    $field->[1],
    'pantaloon@dubloon.oon',
    "1st field value is correct",
  );

  is(
    $field->[2],
    undef,
    "2nd value is undef",
  );

  splice @$field, 1, 0, "dude";

  is(
    $field->[0],
    'sadist@marquis.sad',
    "0th field value is correct",
  );

  is(
    $field->[1],
    'dude',
    "1st field value is correct",
  );

  is(
    $field->[2],
    'pantaloon@dubloon.oon',
    "1st field value is correct",
  );

  is(
    $field->[3],
    undef,
    "2nd value is undef",
  );

  splice @$field, 0, 1, "dude";

  is(
    $field->[0],
    'dude',
    "0th field value is correct",
  );

  is(
    $field->[1],
    'dude',
    "1st field value is correct",
  );

  is(
    $field->[2],
    'pantaloon@dubloon.oon',
    "1st field value is correct",
  );

  is(
    $field->[3],
    undef,
    "2nd value is undef",
  );
  
  @$e_mail = "Hey, dude.\nWhat's up?";

  is_deeply(
    [ @$e_mail ],
    [ "Hey, dude.", "What's up?" ],
    "direct assignment to lines",
  );

  push @$e_mail, "-- \nrjbs\n";

  is_deeply(
    [ @$e_mail ],
    [ "Hey, dude.", "What's up?", "-- ", "rjbs" ],
    "then pushed real good",
  );

  is($e_mail->[-1], "rjbs", "last line is correct");

  # print $e_mail "manager, e-mail enterprises";
  # is($e_mail->[-1], "manager, e-mail enterprises", "print to push");

  is_deeply($e_mail->[ @$e_mail ], [], "message is single-part");

  my $part = E'Mail::Acme;#'
  $part->{'content-type'} = "text/plain";
  push @$part, "This is plain text.";

  push @$e_mail, $part;

  is_deeply($e_mail->[ @$e_mail ], [ $part ], "message subparts are ok");
}

{
  $e_mail = E'Mail::Acme;#'

  my $foo = $e_mail->{foo} = [ 1, 2, 3, 4 ];

  is_deeply(
    [ @{ $e_mail->{foo} } ],
    [ 1, 2, 3, 4 ],
    "simple set/get headers",
  );

  splice @$foo, 1, 2, 5;

  is_deeply(
    [ @{ $e_mail->{foo} } ],
    [ 1, 5, 4 ],
    "splice the middle",
  );
}

{
  $e_mail = E'Mail::Acme;#'

  my $foo = $e_mail->{bar};

  @$foo = ( 1, 2, 3, 4 );

  is_deeply(
    [ @{ $e_mail->{bar} } ],
    [ 1, 2, 3, 4 ],
    "simple set/get headers",
  );
}
