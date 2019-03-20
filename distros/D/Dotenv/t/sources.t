use strict;
use warnings;
use Test::More;
use Path::Tiny;
use Dotenv;

my %expected = (
    Barbapapa   => 'pink',
    Barbabright => 'blue',
    Barbalib    => 'orange',
);

my @sources = (
    \ << 'EOT',
Barbabright = blue
Barbalib    =orange
export Barbapapa = pink
EOT
    [ 'Barbabright=blue', "Barbalib = orange\n   Barbapapa = pink    " ],
    \%expected,
    Path::Tiny->new('t/env/barb.env')->openr_utf8,
    do {
        my $io = IO::File->new( 't/env/barb.env', 'r' );
        $io->binmode(':utf8');
        $io;
    },
);

for my $source (@sources) {
    my %got = Dotenv->parse($source);
    is_deeply( \%got, \%expected, ref $source );
}

done_testing;

