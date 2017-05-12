use strict;
use warnings;
use Test::More;

plan skip_all => "hangs currently";

use AnyEvent;
use Message::Passing::Input::Freeswitch;
use Message::Passing::Output::Test;

my $cv = AnyEvent->condvar;
my $output = Message::Passing::Output::Test->new(
    cb => sub { $cv->send },
);
my $input = Message::Passing::Input::Freeswitch->new(
    hostname => "localhost",
    secret => "FxRU%-gW?g9RxNJ{);qt",
    output_to => $output,
);
ok $input;

my $t = AnyEvent->timer(after => 3000, cb => sub { $cv->croak("Timed out waitinf for events") });

$cv->recv;
undef $t;

ok $output->message_count >= 1;

done_testing;

