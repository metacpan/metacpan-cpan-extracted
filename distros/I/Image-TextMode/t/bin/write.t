use strict;
use warnings;

use Test::More tests => 3;

use_ok( 'Image::TextMode::Format::Bin' );

{
    my $file  = 'test1.bin';
    my $input = slurp( "t/bin/data/${file}" );

    my $bin = Image::TextMode::Format::Bin->new;
    $bin->read( "t/bin/data/${file}" );

    isa_ok( $bin, 'Image::TextMode::Format::Bin' );

    my $output;
    open( my $fh, '>', \$output );
    $bin->write( $fh );
    close( $fh );

    is( $output, $input, 'roundtrip write()' );
}

sub slurp {
    my ( $file ) = @_;
    open( my $fh, $file );
    binmode( $fh );
    my $content = do { local $/; <$fh>; };
    close( $fh );
    return $content;
}
