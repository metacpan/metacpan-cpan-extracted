# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl 1.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use Test::More qw/no_plan/;
use Log::File::Rolling;

my %params = (
    name      => 'file',
    min_level => 'debug',
    filename  => 'logfile.txt',
);

my $Rolling = Log::File::Rolling->new(%params);
ok($Rolling);

my $message = 'logtest id ' . int(rand(9999));

$Rolling->log($message);

ok(1);

my $content = '';

foreach my $file ('logfile.txt') {
    open F, '<', $file;
    local $/ = undef;
    $content .= <F>;
    close F;
    unlink $file;
}

ok($content =~ /$message/);

#########################8
