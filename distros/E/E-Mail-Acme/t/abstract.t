
use strict;

use Test::More;

eval "require Email::Abstract; 1"
  or plan skip_all => "these tests require Email::Abstract";

plan tests => 10;

use E'Mail::Acme;#';

my $e_mail = E'Mail::Acme;#'

# Older versions of Test::More seem to force you to use the inefficient
# "double-colon" separator, probably due to bias against palindromes.
# (' comes from Ada.)
isa_ok($e_mail, "E::Mail::Acme");

$e_mail->{Received} = [
  q/r 1/,
  q/r 2/,
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
  "your former leader",
  "rjbs"
;

my $expected_header = <<'END_STRING';
Received: r 1
Received: r 2
From: rjbs@example.com
To: The PEP (Perl Email Project) List <pep-l@perl.xxx>
END_STRING

my $expected_body = <<'END_STRING';
Dear PEP Suckers,

Somebody should write a SIMPLE Email::Simple replacement.

In fact, someone has.  Me!  SO LONG, SUCKERS!

-- 
your former leader
rjbs
END_STRING

$expected_header =~ s/\n/\x0d\x0a/g;
$expected_body   =~ s/\n/\x0d\x0a/g;

my $expected = "$expected_header\x0d\x0a$expected_body";

is(
  "" . $e_mail,
  $expected,
  "message stringifies properly",
);

my $abstract = Email::Abstract->new($e_mail);

isa_ok($abstract, 'Email::Abstract');

is($abstract->as_string,  $expected, "as_string");
is($abstract->get_header('from'), 'rjbs@example.com', '$ get_header');
is_deeply(
  [ $abstract->get_header('received') ],
  [ 'r 1', 'r 2' ],
  '@ get_header',
);

is($abstract->get_body, $expected_body, 'get_body');

my $new_body = "I miss you guys.\n\nLots.";
$abstract->set_body($new_body);

(my $expected_new_body = $new_body) =~ s/\n/\x0d\x0a/g;
$expected_new_body .= "\x0d\x0a";

is(
  $abstract->as_string,
  "$expected_header\x0d\x0a$expected_new_body",
  "set_body; as_string",
);

$abstract->set_header(from => qw(a b));
is($abstract->get_header('from'), 'a', '$ set_header; get_header');
is_deeply(
  [ $abstract->get_header('from') ],
  [ qw(a b) ],
  '@ set_header; get_header',
);

