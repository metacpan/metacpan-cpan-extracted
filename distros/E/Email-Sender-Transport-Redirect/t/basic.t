#!perl

use strict;
use warnings;
use Test::More tests => 8;
use Data::Dumper;
use Email::Sender::Transport::Test;
use Email::Sender::Transport::Redirect;

my $transport_orig = Email::Sender::Transport::Test->new;

my $email = <<'EOF';
To:   Casey West <casey@example.com>
Cc: Stefan Hornburg <racke@example.com>
From: Casey West <casey@example.net>
Subject: This should never show up in my inbox

blah blah blah
EOF

my $transport = Email::Sender::Transport::Redirect
  ->new({ transport => $transport_orig,
          redirect_address => 'shop@nitesi.com'
        });


$transport->send($email);
{
    my @mails = $transport_orig->deliveries;
    ok(@mails == 1, "mail delivered");
    my $mail = shift @mails;
    # print Dumper $mail;
    is_deeply $mail->{envelope}->{to}, [ 'shop@nitesi.com' ], "envelope to set";
    is_deeply $mail->{successes}, [ 'shop@nitesi.com' ], "got successes";
    is_deeply $mail->{failures}, [], "no failure";
    my $obj = $mail->{email};
    is $obj->get_header('X-Intercepted-To'), 'Casey West <casey@example.com>',
      "x-intercept-to set";
    is $obj->get_header('X-Intercepted-Cc'), 'Stefan Hornburg <racke@example.com>',
      "x-intercept-cc set";
    is $obj->get_header('To'), 'shop@nitesi.com', "to header correct";
    is $obj->get_header('Cc'), 'shop@nitesi.com', "cc header replaced";
    diag $obj->as_string;
}
