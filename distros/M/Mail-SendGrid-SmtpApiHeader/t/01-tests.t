#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 4;
use JSON;

BEGIN {
    use_ok('Mail::SendGrid::SmtpApiHeader') or die "Can't load Mail::SendGrid::SmtpApiHeader";
}


sub main {
    my $header = Mail::SendGrid::SmtpApiHeader->new();
    isa_ok($header, 'Mail::SendGrid::SmtpApiHeader');

    $header->addTo('isaac@example', 'tim@example', 'jose@example');
    $header->addSubVal('-name-', 'Isaac', 'Tim', 'Jose');
    $header->addSubVal('-time-', '4pm', '1pm', '2pm');

    $header->setCategory("initial");

    $header->addFilterSetting('footer', 'enable', 1);
    $header->addFilterSetting('footer', "text/plain", "Thank you for your business");

    $header->addFilterSetting(test =>
        foo => 1,
        bar => 2,
    );

    my $string = $header->as_string;
    ok($string =~ /^X-SMTPAPI: (.*)$/s, "as_string format");
    my $json_payload = $1 || '';

    # Undo the mail formatting
    $json_payload =~ s/\n  //g;

    my $payload = JSON->new->decode($json_payload);
    my $wanted = {
        to => ['isaac@example', 'tim@example', 'jose@example'],
        sub => {
            '-name-' => ['Isaac', 'Tim', 'Jose'],
            '-time-' => ['4pm', '1pm', '2pm'],
        },
        category => 'initial',
        filters => {
            footer => {
                settings => {
                    enable       => 1,
                    'text/plain' => "Thank you for your business",
                },
            },
            test => {
                settings => {
                    foo => 1,
                    bar => 2,
                },
            },
        },
    };

    is_deeply($wanted, $payload, "as_string content");

    return 0;
}


exit main() unless caller;

