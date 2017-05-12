use strict;
use warnings;
use Test::More;
use Data::Dumper;

use Message::Passing::Filter::Mangle;
use Message::Passing::Output::Test;

my @data = (
    [   'Passthrough filter of scalar messages',
        sub {
            return shift;
        },
        'test message',
        'test message',
    ],
    [   'Passthrough filter of hashref message',
        sub {
            return shift;
        },
        { message => 'test message' },
        { message => 'test message' },
    ],
    [   'All filter of scalar messages',
        sub {
            return;
        },
        'test message',
        undef,
    ],
    [   'All filter of hashref message',
        sub {
            return;
        },
        { message => 'test message' },
        undef,
    ],
    [   'Mangle filter of scalar messages',
        sub {
            my $message = shift;

            return $message . ' from me';
        },
        'test message',
        'test message from me',
    ],
    [   'Mangle filter of hashref message',
        sub {
            my $message = shift;

            $message->{from} = 'me';

            return $message;
        },
        { message => 'test message' },
        { message => 'test message', from => 'me' },
    ],
);

foreach my $datum (@data) {
    my ( $name, $filter_function, $input, $exp ) = @$datum;
    my $out = Message::Passing::Output::Test->new;
    my $in  = Message::Passing::Filter::Mangle->new(
        filter_function => $filter_function,
        output_to       => $out,
    );
    $in->consume($input);
    my ($output) = $out->messages;
    is_deeply $output, $exp, $name
        or diag "Got " . Dumper($output) . " expected " . Dumper($exp);
}

done_testing;

