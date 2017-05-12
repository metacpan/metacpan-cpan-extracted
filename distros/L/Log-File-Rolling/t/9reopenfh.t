# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl 1.t'

#########################

use Test::More;
eval "
use Test::Fork; ";
plan skip_all => "Test::Fork required for this test" if $@;
plan 'no_plan';

use Log::File::Rolling;

my %params = (
    name      => 'file',
    min_level => 'debug',
    filename  => 'logfile.txt',
);

my $Rolling = Log::File::Rolling->new(%params);
ok($Rolling);

my @message = map {'logtest id ' . int(rand(9999))} 1 .. 3;

my $initial_fileno = fileno $Rolling->{fh};
$Rolling->log(message => $message[0]);
my $parent_fileno = fileno $Rolling->{fh};
is( $parent_fileno, $initial_fileno, "initial log call doesn't reopen" );
fork_ok( 2, sub {
    $Rolling->log($message[1]);
    my $child_fileno = fileno $Rolling->{fh};
    isnt( $child_fileno, $parent_fileno, "logging in child reopens" );
    $Rolling = undef;
    ok(1);
});
$Rolling->log(message => $message[2]);
my $_parent_fileno = fileno $Rolling->{fh};
is( $_parent_fileno, $parent_fileno, "logging in parent does not reopen" );

foreach my $file ('logfile.txt') {
    unlink $file;
}
