use strict;
use warnings;

use FindBin qw( $Bin );
use lib "$Bin/lib";

use Cwd qw( abs_path );
use File::Temp qw( tempdir );
use Test::AnyOf;
use Test::More 0.96;

use File::LibMagic;

{
    ## no critic (InputOutput::RequireCheckedSyscalls)
    skip 'This platform does not support symlinks', 1
        unless eval { symlink( q{}, q{} ); 1 };
    ## use critic

    my $dir       = tempdir( CLEANUP => 1 );
    my $link_file = "$dir/link-to-tiny.pdf";
    my $to        = abs_path($Bin) . '/samples/tiny.pdf';
    symlink $to => $link_file
        or die "Cannot create symlink to $to: $!";

    my $info = File::LibMagic->new( follow_symlinks => 1 )
        ->info_from_filename($link_file);

    if ( is( ref $info, 'HASH', 'info_from_filename returns hash' ) ) {
        is_deeply(
            [ sort keys %$info ],
            [qw[ description encoding mime_type mime_with_encoding ]],
            'info hash contains the expected keys'
        );
        is(
            $info->{description}, 'PDF document, version 1.4',
            'description'
        );
        is( $info->{mime_type}, 'application/pdf', 'mime type' );
        like(
            $info->{encoding},
            qr/^(?:binary|unknown|us-ascii)$/,
            'encoding',
        );
        like(
            $info->{mime_with_encoding},
            qr{^application/pdf; charset=(?:binary|unknown|us-ascii)$},
            'mime with charset'
        );
    }
}

{
    my $info
        = File::LibMagic->new()
        ->info_from_filename("$Bin/samples/tiny-pdf.gz");

    is_any_of(
        $info->{mime_type},
        [ 'application/gzip', 'application/x-gzip' ],
        'gzip file is application/gzip or application/x-gzip by default'
    );

    $info
        = File::LibMagic->new( uncompress => 1 )
        ->info_from_filename("$Bin/samples/tiny-pdf.gz");

    is(
        $info->{mime_type},
        'application/pdf',
        'gzip file is application/pdf when uncompressed'
    );
}

SKIP:
{
    skip 'The install libmagic does not support the max_bytes parameter', 1
        unless File::LibMagic->can('MAGIC_PARAM_BYTES_MAX');

    my $info
        = File::LibMagic->new( max_bytes => 1 )
        ->info_from_filename("$Bin/samples/tiny-pdf.gz");

    is(
        $info->{mime_type},
        'application/octet-stream',
        'gzip file is application/octet-stream when max bytes is set to 1'
    );
}

done_testing();
