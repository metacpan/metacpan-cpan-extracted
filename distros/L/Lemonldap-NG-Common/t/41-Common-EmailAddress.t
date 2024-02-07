use warnings;

# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl Lemonldap-NG-Manager.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use Test::More tests => 3;
BEGIN { use_ok('Lemonldap::NG::Common::EmailAddress') }

my $name = 'my name';
my $mail = 'test@domain.com';
my $format_email;

ok(
  $format_email = format_email($name, $mail),
  "calling format_email function"
);

ok(
  $format_email eq "\"$name\" <$mail>",
  "testing formatted email value"
);
