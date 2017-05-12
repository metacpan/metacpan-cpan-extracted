use Test::More tests => 36;

use strict;
use warnings;

use_ok( 'Image::TextMode::SAUCE' );

{
    my $sauce = Image::TextMode::SAUCE->new;
    my $file  = 't/core/data/file-nocomments.src';

    open( my $fh, '<', $file ) or die $!;
    my $expect_write = do { local $/; <$fh> };
    $sauce->read( $fh );
    close( $fh );

    isa_ok( $sauce, 'Image::TextMode::SAUCE' );

    my %expected = (
        has_sauce     => 1,
        author        => 'Test Author',
        title         => 'Test Title',
        group         => 'Test Group',
        datatype_id   => 1,
        filetype_id   => 7,
        datatype      => 'Character',
        filetype      => 'Source',
        date          => 20080915,
        tinfo1_name   => undef,
        tinfo2_name   => undef,
        tinfo3_name   => undef,
        tinfo4_name   => undef,
        flags         => 'None',
        comment_count => 0,
    );

    for my $method ( keys %expected ) {
        is( $sauce->$method, $expected{ $method }, $method );
    }

    my $output = '';
    open( $fh, '>', \$output );
    $sauce->write( $fh );
    close( $fh );

    is( $output, $expect_write, 'write()' );
}

{
    my $sauce = Image::TextMode::SAUCE->new;
    my $file  = 't/core/data/file-comments.src';

    open( my $fh, '<', $file ) or die $!;
    my $expect_write = do { local $/; <$fh> };
    $sauce->read( $fh );
    close( $fh );

    isa_ok( $sauce, 'Image::TextMode::SAUCE' );

    my %expected = (
        has_sauce     => 1,
        author        => 'Test Author',
        title         => 'Test Title',
        group         => 'Test Group',
        datatype_id   => 1,
        filetype_id   => 7,
        datatype      => 'Character',
        filetype      => 'Source',
        date          => 20080915,
        tinfo1_name   => undef,
        tinfo2_name   => undef,
        tinfo3_name   => undef,
        tinfo4_name   => undef,
        flags         => 'None',
        comment_count => 2,
    );

    for my $method ( keys %expected ) {
        is( $sauce->$method, $expected{ $method }, $method );
    }

    is_deeply( $sauce->comments, [ 'Test', 'Comments' ] );

    my $output = '';
    open( $fh, '>', \$output );
    $sauce->write( $fh );
    close( $fh );

    is( $output, $expect_write, 'write()' );
}
