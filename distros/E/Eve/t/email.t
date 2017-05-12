# -*- mode: Perl; -*-
package EmailTest;

use parent qw(Eve::Test);

use strict;
use warnings;

use Test::More;

use Eve::EmailStub;
use Eve::Email;

sub test_send : Test(6) {
    my $from = 'exampler@example.com';
    my $mailer = Eve::Email->new(from => $from);

    my $mail_hash = {
        'first@example.com' => {
            'subject' => 'First subject',
            'body' => 'First body'
        },
        'second@example.com' => {
            'subject' => 'Second subject',
            'body' => 'Second body'
        }
    };

    for my $address (keys %{$mail_hash}) {
        $mailer->send(
            to => $address,
            subject => $mail_hash->{$address}->{'subject'},
            body => $mail_hash->{$address}->{'body'});

        my $delivery = Eve::EmailStub::get_delivery();
        my %headers = @{$delivery->{'email'}->[0]->{'header'}->{'headers'}};

        is(
            $delivery->{'envelope'}->{'to'}->[0],
            $address);
        is(
            $headers{'Subject'},
            $mail_hash->{$address}->{'subject'});
        is(
            $headers{'From'},
            $from);
    }
}

1;
