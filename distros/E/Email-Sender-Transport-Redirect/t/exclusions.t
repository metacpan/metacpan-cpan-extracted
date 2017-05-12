#!perl

use strict;
use warnings;
use Test::More tests => 24;
use Data::Dumper;
use Email::Sender::Transport::Test;
use Email::Sender::Transport::Redirect;

{
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
              redirect_address => { to => 'shop@nitesi.com',
                                    exclude => ['racke@example.com'] }
            });

    $transport->send($email, { to  => [qw/casey@example.com racke@example.com/]});
    # print Dumper($transport);
    my @mails = $transport_orig->deliveries;
    ok(@mails == 1, "mail delivered");
    my $mail = shift @mails;
    # print Dumper $mail;
    is_deeply $mail->{envelope}->{to}, [qw/shop@nitesi.com racke@example.com/];
    is_deeply $mail->{successes}, [qw/shop@nitesi.com racke@example.com/ ], "got successes";
    is_deeply $mail->{failures}, [], "no failure";
    my $obj = $mail->{email};
    is $obj->get_header('X-Intercepted-To'), 'Casey West <casey@example.com>',
      "x-intercept-to set";
    is $obj->get_header('X-Intercepted-Cc'), 'Stefan Hornburg <racke@example.com>',
      "x-intercept-cc set";
    is $obj->get_header('To'), 'shop@nitesi.com', "to header correct";
    is $obj->get_header('Cc'), 'racke@example.com', "cc header replaced with the bare mail";
    diag $obj->as_string;
}
{
    my $transport_orig = Email::Sender::Transport::Test->new;

    my $email = <<'EOF';
To:   Casey West <casey@example.com>
Cc: Stefan Hornburg <racke@example.org>
From: Casey West <casey@example.net>
Subject: This should never show up in my inbox

blah blah blah
EOF

    my $transport = Email::Sender::Transport::Redirect
      ->new({ transport => $transport_orig,
              redirect_address => { to => 'shop@nitesi.com',
                                    exclude => ['*@example.org'] }
            });

    $transport->send($email, { to => [qw/casey@example.com racke@example.org/] });
    # print Dumper($transport);
    my @mails = $transport_orig->deliveries;
    ok(@mails == 1, "mail delivered");
    my $mail = shift @mails;
    # print Dumper $mail;
    is_deeply $mail->{envelope}->{to}, [qw/shop@nitesi.com racke@example.org/ ], "envelope to set";
    is_deeply $mail->{successes}, [qw/shop@nitesi.com racke@example.org/ ], "got successes";
    is_deeply $mail->{failures}, [], "no failure";
    my $obj = $mail->{email};
    is $obj->get_header('X-Intercepted-To'), 'Casey West <casey@example.com>',
      "x-intercept-to set";
    is $obj->get_header('X-Intercepted-Cc'), 'Stefan Hornburg <racke@example.org>',
      "x-intercept-cc set";
    is $obj->get_header('To'), 'shop@nitesi.com', "to header correct";
    is $obj->get_header('Cc'), 'racke@example.org', "cc header replaced with the bare mail";
    diag $obj->as_string;
}

{
    my $transport_orig = Email::Sender::Transport::Test->new;

    my $email = <<'EOF';
To:   Casey West <casey@example.com>
Cc: Stefan Hornburg <racke@example.org>
From: Casey West <casey@example.net>
Subject: This should never show up in my inbox

blah blah blah
EOF

    my $transport = Email::Sender::Transport::Redirect
      ->new({ transport => $transport_orig,
              redirect_address => { to => 'shop@nitesi.com',
                                    exclude => ['casey@example.com', '*@example.org'] }
            });

    $transport->send($email, { to => [qw/casey@example.com racke@example.org/] });
    # print Dumper($transport);
    my @mails = $transport_orig->deliveries;
    ok(@mails == 1, "mail delivered");
    my $mail = shift @mails;
    # print Dumper $mail;
    is_deeply $mail->{envelope}->{to}, [qw/casey@example.com racke@example.org/], "envelope to set";
    is_deeply $mail->{successes}, [qw/casey@example.com racke@example.org/], "got successes";
    is_deeply $mail->{failures}, [], "no failure";
    my $obj = $mail->{email};
    is $obj->get_header('X-Intercepted-To'), 'Casey West <casey@example.com>',
      "x-intercept-to set";
    is $obj->get_header('X-Intercepted-Cc'), 'Stefan Hornburg <racke@example.org>',
      "x-intercept-cc set";
    is $obj->get_header('To'), 'casey@example.com', "to header correct";
    is $obj->get_header('Cc'), 'racke@example.org', "cc header replaced with the bare mail";
    diag $obj->as_string;
}
