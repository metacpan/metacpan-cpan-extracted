#!/usr/bin/env perl

use 5.8.0;
use strict;
use warnings;
use utf8;

use ExtUtils::MakeMaker qw(:DEFAULT);
use File::Spec;

my $euv = $ExtUtils::MakeMaker::VERSION;
$euv =~ s/_//g;
die sprintf( " [*] Your MakeMaker is a outdated [%s]. Please update to at least %s\n", $ExtUtils::MakeMaker::VERSION, '6.3004' ) if( $euv < 6.3004 );

if( ! -f 'Rijndael.h' ) {
    print "#" x 44 . "\n" . "#" x 44 . "\n";
    print "## Generating a new KEY and HEADER string ##\n";
    print "#" x 44 . "\n" . "#" x 44 . "\n";

    my $keys = {
        header => join(', ', map { sprintf( '0x%s', $_ ) } map { unpack "H*", chr(rand(256)) } 1..6 ),
        key    => join(', ', map { sprintf( '0x%s', $_ ) } map { unpack "H*", chr(rand(256)) } 1..32 ),
    };

    {
        open( my $fh, '>', 'Rijndael.h' );
        print $fh sprintf( "static unsigned char HEADER[] = { %s };\n", $keys->{header} );
        print $fh sprintf( "static unsigned char KEY[] = { %s };\n", $keys->{key} );
        close( $fh );
    }

    {
        undef $/;
        open( my $read_fh, '<', File::Spec->catfile( 'bin', 'encrypt.pl' ) ) || die "Cannot open file: $!\n";
        binmode $read_fh;
        my $file_contents = <$read_fh>;
        close( $read_fh );

        my $locations = { first => { 'pack' => index( $file_contents, 'pack' ) } };
        $locations->{first}->{eol} = index( $file_contents, "\n", $locations->{first}->{'pack'} );
        $locations->{second}->{'pack'} = index( $file_contents, 'pack', $locations->{first}->{eol} );
        $locations->{second}->{'eol'} = index( $file_contents, "\n", $locations->{second}->{'pack'} );

        substr( $file_contents, $locations->{second}->{'pack'}, $locations->{second}->{eol} - $locations->{second}->{'pack'}) = sprintf( "pack( 'C*', %s ),", $keys->{key} );
        substr( $file_contents, $locations->{first}->{'pack'}, $locations->{first}->{eol} - $locations->{first}->{'pack'} ) = sprintf( "pack( 'C*', %s );", $keys->{header} );

        open( my $write_fh, '>', File::Spec->catfile( 'bin', 'encrypt.pl' ) );
        print $write_fh $file_contents;
        close( $write_fh );
    }
}

# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME         => 'Filter::Rijndael',
    VERSION_FROM => File::Spec->catfile( 'lib', 'Filter', 'Rijndael.pm' ), # finds $VERSION
    PREREQ_PM    => {
            'File::Spec'         => 0,
            'Test::More'         => 0,
            'Filter::Util::Call' => 1.08,
            'Digest::SHA'        => 0,
            'Crypt::Rijndael'    => 0,
        },
    LIBS         => [''], # e.g., '-lzlib'
    DEFINE       => '-DBYPASS', # e.g., '-DBYPASS'
    INC          => '', # e.g., '-I/usr/include/other'
    SIGN         => 1,
#    LINKTYPE     => 'static',
#    MAP_TARGET   => 'sperl',
);
