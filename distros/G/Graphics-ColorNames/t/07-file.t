#!/usr/bin/perl

use strict;

use Test::More;
use Test::Exception;

use File::Spec::Functions qw/ rel2abs /;

use_ok( 'Graphics::ColorNames', 3.2, qw( hex2tuple tuple2hex ) );

my $file = './t-etc/rgb.txt';

throws_ok {
    tie my %colors, 'Graphics::ColorNames', $file;
} qr/Unknown color scheme/, 'relative pathnames rejected (TIE)';

throws_ok {
    my $po = Graphics::ColorNames->new($file);
} qr/Unknown color scheme/, 'relative pathnames rejected (OO)';

tie my %colors, 'Graphics::ColorNames', rel2abs($file);
ok tied %colors, 'is tied';

is scalar(keys %colors), 6, 'expected number of colors';

my $count = 0;
foreach my $name ( keys %colors ) {
    my @RGB = hex2tuple( $colors{$name} );
    $count++, if ( tuple2hex(@RGB) eq $colors{$name} );
}
ok( $count == keys %colors );

foreach my $name (qw( one two three four five six)) {
    ok( exists $colors{$name} );
}

done_testing;
