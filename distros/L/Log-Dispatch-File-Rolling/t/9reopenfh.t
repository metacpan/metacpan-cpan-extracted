# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl 1.t'

#########################

use Test::More;
eval "
use Test::Fork; ";
plan skip_all => "Test::Fork required for this test" if $@;
plan tests => 12;

use Log::Dispatch;
use Log::Dispatch::File::Rolling;
ok(1); # If we made it this far, we're ok.

#########################1

my $dispatcher = Log::Dispatch->new;
ok($dispatcher);

#########################2

my %params = (
    name      => 'file',
    min_level => 'debug',
    filename  => 'logfile.txt',
);

my $Rolling = Log::Dispatch::File::Rolling->new(%params);
ok($Rolling);

#########################3

$dispatcher->add($Rolling);

ok(1);

#########################4

my @message = map {'logtest id ' . int(rand(9999))} 1 .. 3;

my $initial_fileno = fileno $Rolling->{fh};
$dispatcher->log( level   => 'info', message => $message[0] );
my $parent_fileno = fileno $Rolling->{fh};
is( $parent_fileno, $initial_fileno, "initial log call doesn't reopen" );
fork_ok( 2, sub {
    $dispatcher->log( level => 'info', message => $message[1] );
    my $child_fileno = fileno $Rolling->{fh};
    isnt( $child_fileno, $parent_fileno, "logging in child reopens" );
    $dispatcher = $Rolling = undef;
    ok(1);
});
$dispatcher->log( level   => 'info', message => $message[2] );
my $_parent_fileno = fileno $Rolling->{fh};
is( $_parent_fileno, $parent_fileno, "logging in parent does not reopen" );

ok(1);

#########################5

$dispatcher = $Rolling = undef;

ok(1);

#########################6

my @logfiles = glob('logfile*.txt');

ok(scalar(@logfiles) == 1 or scalar(@logfiles) == 2);

#########################7

foreach my $file (@logfiles) {
	unlink $file;
}
