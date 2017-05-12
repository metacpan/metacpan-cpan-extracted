use strict;
use warnings;
use Test::More tests => 1;
use Log::Any::Adapter qw(Stdout);

{
    open my $fh, ">", \my $buf;
    local *STDOUT = $fh;
    my $log = Log::Any->get_logger();
    $log->debug("to stdout");
    like( $buf, qr/^to stdout\n$/, "stdout" );
}
