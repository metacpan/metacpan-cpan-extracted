# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl 1.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use Test;
BEGIN { plan tests => 8 };
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

my $message = 'logtest id ' . int(rand(9999));

$dispatcher->log( level   => 'info', message => $message );

ok(1);

#########################5

$dispatcher = $Rolling = undef;

ok(1);

#########################6

my @logfiles = glob('logfile*.txt');

ok(scalar(@logfiles) == 1 or scalar(@logfiles) == 2);

#########################7

my $content = '';

foreach my $file (@logfiles) {
	open F, '<', $file;
	local $/ = undef;
	$content .= <F>;
	close F;
	unlink $file;
}

ok($content =~ /$message/);

#########################8
