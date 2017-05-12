use strict; use warnings;
package Jq;
our $VERSION = '0.01';

use IPC::Run qw(run timeout);
use JSON;

use Exporter 'import';
our @EXPORT = qw(jq);

sub jq {
    my ($filter, @data) = @_;
    my @jq = ('jq', "$filter");
    my ($in, $out, $err);
    for my $value (@data) {
        $in .= JSON::encode_json($value) . "\n";
    }
    run \@jq, \$in, \$out, \$err, timeout(10)
        or die "jq: $?, $err";
    my $result = JSON::decode_json("[$out]");

    return wantarray ? @$result : $result->[0];
}

1;
