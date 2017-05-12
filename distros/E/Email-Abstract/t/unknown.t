#!perl -T
use strict;

use Test::More;

plan tests => 4;

use_ok("Email::Abstract");

BEGIN {
  package Totally::Unknown::ToAll;
  @Totally::Unknown::ToAll::ISA = ('Totally::Unknown');
}

for my $class ('Totally::Unknown', 'Totally::Unknown::ToAll') {
  my $object = bless [] => $class;
  my $abs = eval { Email::Abstract->new($object); };
  like($@, qr/handle/, "exception on unknown object type");
}

open FILE, '<t/example.msg';
my $message = do { local $/; <FILE>; };
close FILE;

# Let's be generous and start with real CRLF, no matter what stupid thing the
# VCS or archive tools have done to the message.
$message =~ s/\x0a\x0d|\x0d\x0a|\x0d|\x0a/\x0d\x0a/g;

require Email::Simple;
my $simple = Email::Simple->new($message);

eval { Email::Abstract->cast($simple, 'Totally::Unknown::ToAll') };
like($@, qr/don't know/i, "can't cast an object to an unknown class");
