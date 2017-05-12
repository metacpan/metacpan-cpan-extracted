# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl 6currentsymlink.t'

#########################

use Test::More qw/no_plan/;
use Log::File::Rolling;

my $curr_symlink_filename = 'currsym';

my %params = (
    name      => 'file',
    min_level => 'debug',
    filename  => 'logfile.%Y-%m-%d.txt',
    current_symlink => $curr_symlink_filename,
);

my $Rolling = Log::File::Rolling->new(%params);
ok($Rolling);

my $message = 'logtest id ' . int(rand(9999));

$Rolling->log($message);

my @logfiles = glob("logfile.2*");

ok(scalar(@logfiles) == 1 or scalar(@logfiles) == 2);

my $content = '';

foreach my $file (@logfiles) {
    open F, '<', $file;
    local $/ = undef;
    $content .= <F>;
    close F;
}

ok($content =~ /$message/);

my $content2 = '';

{
    open F, '<', $curr_symlink_filename;
    local $/ = undef;
    $content2 .= <F>;
    close F;
}

ok($content2 =~ /$message/);

foreach my $file (@logfiles) {
    unlink $file;
}

unlink $curr_symlink_filename;
