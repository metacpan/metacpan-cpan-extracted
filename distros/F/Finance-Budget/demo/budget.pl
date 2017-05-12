#!/usr/bin/perl -Tw

use strict;
use warnings;
use Finance::Budget;

my $budget = Finance::Budget->new(
    {   days            => 365,
        opening_balance => 123.01,
        date_format     => '[%a %b %d, %Y]',
        markup_callback => sub {
            my ($event_hr) = @_;
            if ( $event_hr->{date}->printf('%d') == 1 )
            {
                $event_hr->{string}
                    = sprintf "\x{1B}[1;32m%s\x{1B}[0m",
                    $event_hr->{string};
            }
            return $event_hr->{string};
        },
        transaction_types => [
            {   category   => 'PAYCHECK',
                amount     => 1234.56,
                recurrence => '0:0:2*4:0:0:0', # every second Thursday
            },
            {   category   => 'Visa',
                amount     => -100.00,
                recurrence => '0:1*0:0:0:0:0', # first of every month
            },
            {   category   => 'Cox',
                amount     => -101.01,
                recurrence => '0:1*0:15:0:0:0', # fifteenth of every month
            },
            {   category   => 'Mortgage',
                amount     => -1000.10,
                recurrence => '0:1*0:0:0:0:0',
            },
            {   category   => 'Water',
                amount     => -150.00,
                recurrence => '0:3*0:1:0:0:0', # first of every third month
            },
        ],
        exceptions      => [
            {   category => 'Visa',
                amount   => 0.00,
                date     => '12/20/2016',
            },
            {   category => 'Cox',
                amount   => 0.00,
                date     => '01/01/2017',
            },
            {   category => 'Mortgage',
                amount   => 0.00,
                date     => '01/01/2017',
            },
        ],
        recent_history => [
            qq{"Date","No.","Description","Debit","Credit"},
            qq{"12/28/2016","","ACH Trans - Big Plastic","100.00",""},
            qq{"12/27/2016","","ACH Trans - COX CABLE","101.01",""},
            qq{"12/26/2016","","ACH Trans - US BANK MTG","1000.10",""},
            qq{"12/01/2016","","ACH Trans - Waters R Us","150.00",""},
            qq{"12/22/2016","","Deposit - Employer Inc","","1234.56"},
        ],
        categorizer => {
            'PAYCHECK' => [
                qr{ employer \s inc }xmsi
            ],
            'Visa' => [
                qr{ big \s plastic }xmsi
            ],
            'Cox' => sub {
                return $_[0]->{description} =~ m{ cox \s cable }xmsi
                    || $_[0]->{description} =~ m{ cox \s communications }xmsi;
            },
            'Mortgage' => [
                qr{ us \s bank \s mtg }xmsi
            ],
            'Water' => [
                qr{ waters \s r \s us }xmsi
            ],
        }
    }
);

while ( my $transaction = $budget->next() )
{
    print "$transaction\n";
}

__END__
