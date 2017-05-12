use strict;
use warnings;
use lib 't';
require 'test-util.pl';
use Test::More;
use Encode;
use Encode::JP::Emoji;

# http://creation.mb.softbank.jp/web/web_pic_01.html

my $encode = 'x-sjis-emoji-softbank2g-pp';

my $sample = {
    "\x{E001}" => "\x1B\$G!\x0F",
    "\x{E02E}" => "\x1B\$GN\x0F",
    "\x{E101}" => "\x1B\$E!\x0F",
    "\x{E12E}" => "\x1B\$EN\x0F",
    "\x{E201}" => "\x1B\$F!\x0F",
    "\x{E22E}" => "\x1B\$FN\x0F",
    "\x{E301}" => "\x1B\$O!\x0F",
    "\x{E328}" => "\x1B\$OH\x0F",
    "\x{E401}" => "\x1B\$P!\x0F",
    "\x{E427}" => "\x1B\$PG\x0F",
    "\x{E501}" => "\x1B\$Q!\x0F",
    "\x{E51E}" => "\x1B\$Q>\x0F",
};

my @keys = sort {$a cmp $b} keys %$sample;

plan tests => 2 + 2 * @keys;

foreach my $utf8S (@keys) {
    my $utf8H = sprintf '%04X' => ord $utf8S;
    my $sjisS = $sample->{$utf8S};
    my $sjisA = encode($encode, $utf8S);
    is(shex($sjisA), shex($sjisS), "$utf8H decode");
}

foreach my $utf8S (@keys) {
    my $utf8H = sprintf '%04X' => ord $utf8S;
    my $sjisS = $sample->{$utf8S};
    my $utf8B = decode($encode, $sjisS);
    is(shex($utf8B), shex($utf8S), "$utf8H decode");
}

my $pages = [qw( G E F O P Q )];

{
    my $utf8J = join "" => @keys;
    my $sjisJ = join "" => map {$sample->{$_}} @keys;
    $sjisJ =~ s/(\x1B\$\Q$_\E.)\x0F\x1B\$\Q$_\E(.\x0F)/$1$2/g foreach @$pages;

    my $utf8C = $utf8J;
    my $sjisA = encode($encode, $utf8C);
    is(ohex($sjisA), ohex($sjisJ), "joined encode");

    my $sjisC = $sjisJ;
    my $utf8B = decode($encode, $sjisC);
    is(shex($utf8B), shex($utf8J), "joined decode");
}
