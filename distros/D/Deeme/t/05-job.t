use Deeme::Obj -strict;
use Test::More;
use_ok("Deeme::Worker");
use_ok("Deeme::Job");
use Deeme::Job;
use Deeme::Worker;

# Normal event
my $e = Deeme::Worker->new();

my $called;
$e->add( test1 => sub { $called += $_[1]; } );
is $e->jobs("test1"), 1, ' 1 job for test1';
while ( $e->dequeue("test1") ) {
    $e->process(1);
}
is $e->jobs("test1"), 0, ' 0 jobs for test1';
is $called, 1, ' 1 job was processed';

while ( $e->dequeue("test1") ) {
    $e->process(1);
}
is $called, 1, ' no job was processed';

$e->add( test2 => sub { $called += $_[1]; } );

$e->add( test2 => sub { $called += $_[1]; } );

is $e->jobs("test2"), 2, ' 2 jobs for test2';

while ( my $Job = $e->dequeue("test2") ) {
    $Job->process(1);
}
is $called, 3, ' +2 job where processed';
while ( $e->dequeue("test2") ) {
    $e->process(1);
}

is $called, 3, ' no jobs where processed';
$called = 0;
$e->add( test2 => sub { $called += $_[1]; } );

$e->add( test2 => sub { $called += $_[1]; } );

while ( $e->dequeue("test2") ) {
    $e->process(1);
}

is $called, 2, ' 2 jobs where processed again';

$called = 0;
$e->add( test2 => sub { $called += $_[1]; } );

$e->add( test2 => sub { $called += $_[1]; } );
$e->dequeue_event("test2");
$e->process_all(1);
is $called, 2,
    ' 2 jobs where processed again with dequeue_event and process_all';

done_testing();
