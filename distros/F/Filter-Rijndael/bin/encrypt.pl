#!/usr/bin/perl

use strict;
use warnings;
use utf8;

use Crypt::Rijndael;
use Digest::SHA qw( sha1_hex );

my $blocksize    = 16;
my $headersize   = 6;
my $fingerprint  = pack( 'C*', 0x00, 0x00, 0x00, 0x00, 0x00, 0x00 );

my $cipher = Crypt::Rijndael->new(
                pack( 'C*', 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00 ),
                Crypt::Rijndael::MODE_CBC()
);
my $module_name  = 'Filter::Rijndael';

die sprintf( "Usage: $0 <file>\n" ) if( ! scalar( @ARGV ) );

my $infile  = $ARGV[0];
my $outfile = $ARGV[1] // sprintf( '%s.pe', $infile );

if ( ! -T $infile ) {
    print "Skipping directory $infile\n" if( -d $infile );
    print "Skipping non-text $infile\n" if( ! -d $infile );
    exit;
}

my $module = "use $module_name;\n";
# Encrypt the file
{
    open( my $read_fh, '<', $infile ) || die sprintf( "Cannot open %s: %s\n", $infile, $! );
    open( my $write_fh, '>', $outfile ) || die sprintf( "Cannot open %s: %s\n", $outfile, $! );
    binmode $write_fh;

    # Check for "#!perl" line
    my $line = <$read_fh>;

    if( $line =~ /^#!/ ) {
        print $write_fh $line;
    } else {
        seek( $read_fh, 0, 0 );
    }

    print $write_fh $module;
    print $write_fh $fingerprint;

    my $block = '';
    while ( my $size = read( $read_fh, $block, $blocksize ) ) {
        # If data is not multiple of $blocksize ( 16 ) add "\n"
        while( $size % $blocksize ) {
            $block .= "\n";
            $size++;
        }

        print $write_fh $cipher->encrypt( $block );
    }
    close $write_fh;
    close $read_fh;
}

{
    undef $/;
    open( my $read_fh, '<', $outfile ) || die "Cannot open $outfile: $!\n";
    binmode $read_fh;
    my $file_contents = <$read_fh>;
    close( $read_fh );

    my $cksum = Digest::SHA::sha1_hex( substr( $file_contents, index( $file_contents, $module ) + length( $module ) + length( $fingerprint ) ) );
    substr( $file_contents, index( $file_contents, $module ) + length( $module ) + length( $fingerprint ), 0 ) = join('', map { chr( hex($_) ) } unpack( '(A2)*', $cksum ) );

    open( my $write_fh, '>', $outfile ) || die "Cannot open $outfile: $!\n";
    binmode $write_fh;
    print $write_fh $file_contents;
    close( $write_fh );
}
