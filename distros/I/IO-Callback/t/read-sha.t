# IO::Callback 1.08 t/read-sha.t
# Check that IO::Callback inter-operates with Digest::SHA

use strict;
use warnings;

use Test::More;
BEGIN {
    eval 'use Digest::SHA';
    plan skip_all => 'Digest::SHA required' if $@;
    plan skip_all => "Bad Digest::SHA"
        if Digest::SHA->VERSION eq '5.89'
        || Digest::SHA->VERSION eq '5.90';
    plan tests => 2;
}
use Test::NoWarnings;

use IO::Callback;

my $block = "foo\n" x 1000;
my $lines = 0;
my $fh = IO::Callback->new('<', sub {
    return if $lines++ >= 1000;
    return $block;
});

my $digest = Digest::SHA->new(256)->addfile($fh)->hexdigest;
is( $digest, "df1c1217e3256c67362044595cfe27918f43b25287721174c96726c078e3ecbe", "digest as expected" );

