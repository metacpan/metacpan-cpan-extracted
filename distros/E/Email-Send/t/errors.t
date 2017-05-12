use Test::More tests => 7;
use strict;
$^W = 1;

use lib 't/lib';

BEGIN { use_ok('Email::Send', 'Test'); }

{ # undef message
  my $rv = send;
  ok(!$rv, "sending with no message is false");
  like("$rv", qr/no message found/i, "correct error message");
}

{ # broken mailers in mailer_available
  { # mailer module that won't load
    my $sender = Email::Send->new;

    my $rv = $sender->mailer_available("Test::Email::Send::Won't::Exist");
    
    ok(!$rv, "failed to load mailer (doesn't exist)"),
    like("$rv", qr/can't locate/i, "and got correct exception");
  }

  { # mailer module that won't load
    my $sender = Email::Send->new;

    my $rv = $sender->mailer_available("BadMailer");
    
    ok(!$rv, "failed to load mailer BadMailer"),
    like("$rv", qr/doesn't report avail/i, "and got correct failure");
  }
}
