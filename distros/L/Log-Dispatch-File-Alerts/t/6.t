# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl 1.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use Test::More;
BEGIN { plan tests => 11 };
use Log::Dispatch;
use Log::Dispatch::File::Alerts;
ok(1); # If we made it this far, we're ok.

#########################1

my $dispatcher = Log::Dispatch->new;
ok($dispatcher);

#########################2

my %params = (
    name      => 'file',
    min_level => 'debug',
    filename  => 'logfile%d{!!}.txt',
);

my $Alert = Log::Dispatch::File::Alerts->new(%params);
ok($Alert);

#########################3

$dispatcher->add($Alert);

ok(1);

#########################4

my $message1 = 'logtest id ' . int(rand(9999));
my $message2 = 'logtest id ' . int(rand(9999));

$dispatcher->log( level   => 'info', message => $message1 );
$dispatcher->log( level   => 'info', message => $message2 );

ok(1);

#########################5

$dispatcher = $Alert = undef;

ok(1);

#########################6

my @logfiles = glob("logfile01.txt");

ok(scalar(@logfiles) == 1);

#########################7

my $content = '';

foreach my $file (@logfiles) {
	open F, '<', $file;
	local $/ = undef;
	$content .= <F>;
	close F;
	unlink $file;
}

ok($content =~ /$message1/);

#########################8

@logfiles = glob("logfile02.txt");

ok(scalar(@logfiles) == 1);

#########################9

$content = '';

foreach my $file (@logfiles) {
	open F, '<', $file;
	local $/ = undef;
	$content .= <F>;
	close F;
	unlink $file;
}

ok($content =~ /$message2/);

#########################10

@logfiles = glob("logfile*.txt");

is(scalar(@logfiles), 0, 'no stray files left');

#########################11

