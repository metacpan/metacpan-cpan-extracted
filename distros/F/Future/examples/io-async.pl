use IO::Async::Loop 0.56; # Already has Future support built-in ;)

my $loop = IO::Async::Loop->new;

my $timer = $loop->delay_future( after => 3 );
print "Awaiting 3 seconds...\n";

$timer->get;
print "Done\n";
