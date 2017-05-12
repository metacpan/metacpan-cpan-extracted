use Test::More tests => 11;
use strict;
$^W = 1;

use lib 't/lib';


BEGIN { $Email::Send::__plugin_exclusion = qr/Jifty/ }
BEGIN { use_ok('Email::Send', 'Test'); }

my $sender  = Email::Send->new;
my @mailers = $sender->all_mailers;

ok(
  @mailers > 2, # we'll never unbundle Sendmail or SMTP
  "we found at least a couple mailers",
);

my $ok = 1;
my @mailer_pkgs;
for my $mailer (@mailers) {
  my $invocant = $sender->_mailer_invocant($mailer) or $ok = 0;
  push @mailer_pkgs, $invocant unless Scalar::Util::blessed($invocant);
}

ok($ok, "all mailers are valid mailers");

ok(
  grep({ $_ eq 'Email::Send::OK' } @mailer_pkgs),
  "we found the OK sender (from t/lib)",
);

ok(
  ! grep({ $_ eq 'Email::Send::Unavail' } @mailer_pkgs),
  "the unavailable (t/lib) sender isn't available",
);

my $message = <<'END_MESSAGE';
From: rjbs@whitehouse.gov
To: hdp@kremlin.su
Subject: this wall

Tear it down.
END_MESSAGE

{ 
  # This will let us use try_all without actually trying all.
  $sender->{_plugin_list} = { Test => 'Email::Send::Test' };

  my $rv = $sender->send($message);
  ok($rv, "we can send a message via 'try all mailers' method");
  is(
    Email::Send::Test->emails,
    1,
    "and it's sent to the (only) mailer available",
  );
}

{ 
  # This will let us use try_all without actually trying all.
  $sender->{_plugin_list} = { Test => 'Email::Send::Fail' };

  my $rv = $sender->send($message);
  ok(!$rv, "we couldn't send when the only choice fails");
  like("$rv", qr/unable to send/i, "and we got the expected error message");
}

{
  my $rv = send(Unavail => $message);

  ok(!$rv, "we can't send to an unavailable mailer");
  like("$rv", qr/never available/i, "and we get its unavailable failure");
}
