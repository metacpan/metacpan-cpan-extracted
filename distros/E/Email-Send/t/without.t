use Test::More;;
use strict;
$^W = 1;

use lib 't/lib';

BEGIN {
  plan skip_all => "see t/lib/Without.pm for prereqs for these tests"
    unless eval "use Without 'Email::Abstract'; 1;";

  plan tests => 3;

  use_ok('Email::Send', 'Test');
}

{ # unknown message type
  my $message = bless \(my $x = 0), "Mail::Ain't::Known";
  my $rv = send(Test => $message);
  ok(!$rv, "sending with unknown message class is false");

  # I don't like this error.  We found something, we just don't know what.
  # -- rjbs, 2006-07-06
  like("$rv", qr/no message found/i, "expected error message");
}
