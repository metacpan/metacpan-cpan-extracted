use strict;
use warnings;
use utf8;
use Test::More;
use Log::Pony;

$SIG{__DIE__} = sub {
    print STDOUT @_;
    exit 1;
};
my $buf;
{
    local *STDERR;
    open *STDERR, '>', \$buf;
    my $logger = Log::Pony->new(log_level => 'DEBUG');
    $logger->info("YAY");
}
like $buf, qr{\A\d{4}-\d\d-\d\dT\d\d:\d\d:\d\d \[INFO\] YAY at t.04_standard_process.t line 16\n\z};

done_testing;

