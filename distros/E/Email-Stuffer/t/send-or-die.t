use v5.12.0;
use warnings;

use Test::More;
use Email::Stuffer;
use Email::Sender::Transport::Test ();

my $message = <<'END_MESSAGE';
From: sender@test.example.com
To: recipient@nowhere.example.net
Subject: this message is going nowhere fast

Dear Recipient,

  You will never receive this.

-- 
sender
END_MESSAGE

{
  package Email::Sender::Transport::TestFail;
  use Moo;
  extends 'Email::Sender::Transport::Test';

  sub delivery_failure {
    my ($self, $email, $env) = @_;
    return Email::Sender::Failure->new('bad sender')
      if $env->{from} =~ /^reject@/;
    return;
  }

  sub recipient_failure {
    my ($self, $rcpt) = @_;

    if ($rcpt =~ /^fault@/) {
      return Email::Sender::Failure->new({
        message    => 'fault',
        recipients => [ $rcpt ],
      });
    }

    if ($rcpt =~ /^tempfail@/) {
      return Email::Sender::Failure::Temporary->new({
        message    => 'tempfail',
        recipients => [ $rcpt ],
      });
    }

    if ($rcpt =~ /^permfail@/) {
      return Email::Sender::Failure::Permanent->new({
        message    => 'permfail',
        recipients => [ $rcpt ],
      });
    }

    return;
  }

  no Moo;
}

my $test = Email::Sender::Transport::Test->new;

#####################################################################
# test send_or_die function
{

  my $rv = Email::Stuffer->from       ( 'Adam Kennedy<adam@phase-n.com>')
                         ->to         ( 'adam@phase-n.com'              )
                         ->subject    ( 'Hello To:!'                    )
                         ->text_body  ( 'Success'                       )
                         ->transport  ( $test                           )
                         ->send_or_die;
  ok( $rv, 'we expect to succeed' );
  is( $test->delivery_count, 1, 'Sent one email' );
}

{
  my $fail_test = Email::Sender::Transport::TestFail->new();
  my $rv2 = eval {
    my $rv = Email::Stuffer->from   ( 'fault@example.com'             )
                       ->to         ( 'fault@example.com'             )
                       ->subject    ( 'Should fail'                   )
                       ->text_body  ( 'Fail and die'                  )
                       ->transport  ( $fail_test                      )
                       ->send_or_die;
    print "Fail rv: $rv";
    return $rv;
  };

  my $error = $@;
  is($rv2, undef, 'died as expected');
  isa_ok($error, 'Email::Sender::Failure');
}

done_testing;
