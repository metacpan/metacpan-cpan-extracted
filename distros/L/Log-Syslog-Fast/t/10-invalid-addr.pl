# adapted from issue text in https://github.com/athomason/Log-Syslog-Fast/pull/13

use Test::More tests => 3;

use File::Temp;

sub next_fh {
    my $want = shift;
    my $fh = File::Temp->new;
    return fileno $fh;
}

is(next_fh, 3, 'no excess filehandles at start');

my $invalid_addr = 'fe80::aede:48ff:fe00:1122'; # ipv6 link-local, should fail
eval {
    $CLASS->new(
        LOG_UDP,
        $invalid_addr,
        514,
        Log::Syslog::Constants::get_facility('NEWS'),
        Log::Syslog::Constants::get_severity('INFO'),
        'hostname',
        ''
    );
};
like($@, qr/Invalid argument/, 'invalid address caught');

is(next_fh, 3, 'no excess filehandles after new() exception');

1;
