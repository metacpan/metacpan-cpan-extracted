use strict;
use warnings;
use Test::More tests => 37;
use Test::Exception;

use lib '../lib';
BEGIN { chdir 't' if -d 't' }
# preparations
my $null_onegram = [(0)x256];
my $null_bigram = [(0)x65536];

# tests

use_ok('File::FormatIdentification::RandomSampling');
my $obj = new_ok('File::FormatIdentification::RandomSampling');
note "empty";
is_deeply( $obj->bytegram(), [$null_onegram, $null_bigram], "bytegram(), empty");
is_deeply( $obj->calc_histogram(), {
    bigram => [ 0, 1, 2, 3, 4, 5, 6, 7],
    onegram => [ 0, 1, 2, 3, 4, 5, 6, 7]
}, "calc_histogram(), empty");
ok(! $obj->is_uniform(), "is_uniform(), empty");
ok(! $obj->is_empty(), "is_empty(), empty");
ok(! $obj->is_text(), "is_text(), empty");
ok(! $obj->is_video(), "is_video(), empty");
is( $obj->calc_type(), "undef", "calc_type(), empty");
note "bytegrams";
ok($obj->init_bytegrams(), "init_bytegrams()");
is_deeply( $obj->{bytegram}, [$null_onegram, $null_bigram], "init_bytegrams(), internals");
is_deeply( $obj->calc_histogram(), {
        bigram => [ 0, 1, 2, 3, 4, 5, 6, 7],
        onegram => [ 0, 1, 2, 3, 4, 5, 6, 7]
    }, "calc_histogram()");
my $buffer = pack("C", 0);
ok($obj->update_bytegram($buffer), "update_bytegram(0)");
is_deeply( $obj->calc_histogram(), {
        bigram => [ 0, 1, 2, 3, 4, 5, 6, 7],
        onegram => [ 0, 1, 2, 3, 4, 5, 6, 7]
    }, "calc_histogram()");
$buffer = pack("C", 255);
ok($obj->update_bytegram($buffer), "update_bytegram(255)");
is_deeply( $obj->calc_histogram(), {
        bigram => [ 0, 1, 2, 3, 4, 5, 6, 7],
        onegram => [ 0, 255, 1, 2, 3, 4, 5, 6]
    }, "calc_histogram()");
ok($obj->init_bytegrams(), "init_bytegrams(), again");
is_deeply( $obj->{bytegram}, [$null_onegram, $null_bigram], "init_bytegrams(), internals again");
note "recognition checks";
$buffer = pack("C*", (0)x512);
ok($obj->update_bytegram($buffer), "update_bytegram(), 512 zero bytes");
is_deeply( $obj->calc_histogram(), {
    bigram => [ 0, 1, 2, 3, 4, 5, 6, 7],
    onegram => [ 0, 1, 2, 3, 4, 5, 6, 7]
}, "calc_histogram(), 512 zero bytes");
ok(! $obj->is_uniform(), "is_uniform(), 512 zero bytes");
ok($obj->is_empty(), "is_empty(), 512 zero bytes");
ok(! $obj->is_text(), "is_text(), 512 zero bytes");
ok(! $obj->is_video(), "is_video(), 512 zero bytes");
is( $obj->calc_type($buffer), "empty", "calc_type(), 512 zero bytes");

ok($obj->init_bytegrams(), "init_bytegrams(), again");
{
    my @rnd;
    foreach my $i (0 .. 511) {
        push @rnd, pack("C*", int($i % 256)); #pseudo random
    }
    $buffer = join('', @rnd);
}
ok($obj->update_bytegram($buffer), "update_bytegram(), 512 random bytes");
ok($obj->is_uniform(), "is_uniform(), 512 random bytes");
ok(! $obj->is_empty(), "is_empty(), 512 random bytes");
ok(! $obj->is_text(), "is_text(), 512 random bytes");
ok(! $obj->is_video(), "is_video(), 512 random bytes");
#is( $obj->calc_type( $buffer ), "random/encrypted/compressed", "calc_type(), 512 random bytes");
my $text =<<LOREM;
Lorem ipsum dolor sit amet, consetetur sadipscing elitr, sed diam nonumy eirmod tempor invidunt ut labore et dolore
magna aliquyam erat, sed diam voluptua. At vero eos et accusam et justo duo dolores et ea rebum. Stet clita kasd
gubergren, no sea takimata sanctus est Lorem ipsum dolor sit amet. Lorem ipsum dolor sit amet, consetetur sadipscing
elitr, sed diam nonumy eirmod tempor invidunt ut labore et dolore magna aliquyam erat, sed diam voluptua. At vero eos
et accusam et justo duo dolores et ea rebum. Stet clita kasd gubergren, no sea takimata sanctus est Lorem ipsum dolor
sit amet.
LOREM
$buffer = substr $text, 0, 512;
ok($obj->init_bytegrams(), "init_bytegrams(), again");
ok($obj->update_bytegram($buffer), "update_bytegram(), 512 text bytes");
ok(!$obj->is_uniform(), "is_uniform(), 512 text bytes");
ok(! $obj->is_empty(), "is_empty(), 512 text bytes");
ok($obj->is_text(), "is_text(), 512 text bytes");
# TODO: at the moment only 0x6d will checked, which matches also for text: ok(! $obj->is_video(), "is_video(), 512 text bytes");
is( $obj->calc_type( $buffer ), "text", "calc_type(), 512 text bytes");

__END__