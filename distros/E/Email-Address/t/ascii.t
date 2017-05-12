use strict;
use warnings;

use Test::More;

use Email::Address;
use Encode qw(decode);

my $ascii = q{admin@mozilla.org};
my $utf_8 = q{аdmin@mozilla.org};
my $text  = decode('utf-8', $utf_8, Encode::LEAVE_SRC);

my $ok_mixed  = qq{"$text" <$ascii>};
my $bad_mixed = qq{"$text" <$text>};

{
  my (@addr) = Email::Address->parse($ascii);
  is(@addr, 1, "an ascii address is a-ok");

  # ok( $ascii =~ $Email::Address::addr_spec, "...it =~ addr_spec");
}

{
  my (@addr) = Email::Address->parse($ok_mixed);
  is(@addr, 1, "a quoted non-ascii phrase is a-ok with ascii email");
}

{
  my (@addr) = Email::Address->parse($bad_mixed);
  is(@addr, 0, "a quoted non-ascii phrase is not okay with non-ascii email");
}

{
  my (@addr) = Email::Address->parse($utf_8);
  is(@addr, 0, "utf-8 octet address: not ok");

  # ok( $utf_8 !~ $Email::Address::addr_spec, "...it !~ addr_spec");
}

{
  my (@addr) = Email::Address->parse($text);
  is(@addr, 0, "unicode (decoded) address: not ok");

  # ok( $text =~ $Email::Address::addr_spec, "...it !~ addr_spec");
}

{
  my @addr = Email::Address->parse(qq{
    "Not ascii phras\x{e9}" <good\@email>,
    b\x{e3}d\@user,
    bad\@d\x{f6}main,
    not.bad\@again
  });
  is scalar @addr, 2, "correct number of good emails";
  is "$addr[0]", qq{"Not ascii phras\x{e9}" <good\@email>}, "expected email";
  is "$addr[1]", qq{not.bad\@again}, "expected email";
}

done_testing;
