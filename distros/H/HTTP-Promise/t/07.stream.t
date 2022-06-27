#!/usr/local/bin/perl
BEGIN
{
    use strict;
    use warnings;
    use lib './lib';
    use vars qw( $DEBUG );
    use Test2::V0;
    use Module::Generic::File qw( file tempfile );
    use Module::Generic::Scalar;
    our $DEBUG = exists( $ENV{AUTHOR_TESTING} ) ? $ENV{AUTHOR_TESTING} : 0;
    eval
    {
        require IO::Compress::Gzip;
        require IO::Uncompress::Gunzip;
    };
    use constant HAS_GZIP => ( $@ ? 0 : 1 );
    eval
    {
        require IO::Compress::Bzip2;
        require IO::Uncompress::Bunzip2;
    };
    use constant HAS_BZIP2 => ( $@ ? 0 : 1 );
    eval
    {
        require IO::Compress::Deflate;
        require IO::Uncompress::Inflate;
    };
    use constant HAS_DEFLATE => ( $@ ? 0 : 1 );
    use constant HAS_INFLATE => ( $@ ? 0 : 1 );
    eval
    {
        require IO::Compress::Zip;
        require IO::Uncompress::Unzip;
    };
    use constant HAS_ZIP => ( $@ ? 0 : 1 );
};

use strict;
use warnings;

BEGIN
{
    use ok( 'HTTP::Promise::Stream' );
};

# Test with the source stream as:
# 1) scalar reference
# 2) glob
# 3) code reference
# 4) file path
# all of the above
# a) encoded
# b) decoded
# c) no encoding

my $string = q{Hello world!};
my $encoded = {};
# Using scalar reference with encode
subtest "encode scalar" => sub
{
    my $s1 = HTTP::Promise::Stream->new( \$string );
    SKIP:
    {
        skip( "gzip compression/decompression module is not installed.", 1 ) if( !HAS_GZIP );
        isa_ok( $s1, ['HTTP::Promise::Stream'] );
        my $gziped = $s1->encode({ encoding => 'gzip' });
        ok( $gziped, 'encode -> gzip' );
        diag( "Gzip error: ", $s1->error ) if( $DEBUG && !$gziped );
        my $un_gzipped;
        IO::Uncompress::Gunzip::gunzip( \$gziped => \$un_gzipped );
        is( $un_gzipped, $string, 'encode -> gzip (check)' );
        $encoded->{gzip} = $gziped if( $un_gzipped eq $string );
    };

    SKIP:
    {
        skip( "bzip2 compression/decompression module is not installed.", 1 ) if( !HAS_BZIP2 );
        my $bziped = $s1->encode({ encoding => 'bzip2' });
        ok( $bziped, 'encode -> bzip2' );
        diag( "Bzip2 error: ", $s1->error ) if( $DEBUG && !$bziped );
        my $un_bziped;
        IO::Uncompress::Bunzip2::bunzip2( \$bziped => \$un_bziped );
        is( $un_bziped, $string, 'encode -> bzip2 (check)' );
        $encoded->{bzip2} = $bziped if( $un_bziped eq $string );
    };

    SKIP:
    {
        skip( "deflate compression/decompression module is not installed.", 1 ) if( !HAS_DEFLATE );
        my $deflated = $s1->encode({ encoding => 'deflate' });
        ok( $deflated, 'encode -> deflate' );
        diag( "Deflate error: ", $s1->error ) if( $DEBUG && !$deflated );
        my $un_deflated;
        IO::Uncompress::Inflate::inflate( \$deflated => \$un_deflated );
        is( $un_deflated, $string, 'encode -> deflate (check)' );
        $encoded->{deflate} = $deflated if( $un_deflated eq $string );
    };

    SKIP:
    {
        skip( "zip compression/decompression module is not installed.", 1 ) if( !HAS_ZIP );
        my $ziped = $s1->encode({ encoding => 'zip' });
        ok( $ziped, 'encode -> zip' );
        diag( "Zip error: ", $s1->error ) if( $DEBUG && !$ziped );
        my $un_ziped;
        IO::Uncompress::Unzip::unzip( \$ziped => \$un_ziped );
        is( $un_ziped, $string, 'encode -> zip (check)' );
        $encoded->{zip} = $ziped if( $un_ziped eq $string );
    };
};

# Using glob with encode
subtest "encode glob" => sub
{
    my $scalar = Module::Generic::Scalar->new( \$string );
    diag( "Scalar reference is '$scalar' (", overload::StrVal( $scalar ), ")." ) if( $DEBUG );
    my $fh = $scalar->open( { debug => $DEBUG } );
    diag( "Error opening scalar reference: ", $scalar->error ) if( $DEBUG && !defined( $fh ) );
    diag( "File handle is '$fh' (", overload::StrVal( $fh ), ")." ) if( $DEBUG );
    my $s2 = HTTP::Promise::Stream->new( $fh );
    diag( "Error instantiating a new stream object: ", HTTP::Promise::Stream->error ) if( $DEBUG && !defined( $s2 ) );
    my $string2 = join( '', $fh->getlines );
    $fh->seek(0,0);
    diag( "Data to gzip is: '$string2'" ) if( $DEBUG );

    my $rv;
    
    SKIP:
    {
        skip( "gzip compression/decompression module is not installed.", 1 ) if( !HAS_GZIP );
        isa_ok( $s2, ['HTTP::Promise::Stream'] );
        my $gziped = $s2->encode({ encoding => 'gzip' });
        ok( $gziped, 'encode -> gzip' );
        diag( "Gzip error: ", $s2->error ) if( $DEBUG && !defined( $gziped ) );
        my $un_gzipped;
        $rv = IO::Uncompress::Gunzip::gunzip( \$gziped => \$un_gzipped );
        is( $un_gzipped, $string2, 'encode -> gzip (check)' );
        $fh->seek(0,0);
    };

    SKIP:
    {
        skip( "gzip compression/decompression module is not installed.", 1 ) if( !HAS_BZIP2 );
        my $bziped = $s2->encode({ encoding => 'bzip2' });
        ok( $bziped, 'encode -> bzip2' );
        diag( "Bzip2 error: ", $s2->error ) if( $DEBUG && !defined( $bziped ) );
        my $un_bziped;
        $rv = IO::Uncompress::Bunzip2::bunzip2( \$bziped => \$un_bziped );
        is( $un_bziped, $string2, 'encode -> bzip2 (check)' );
        diag( "Failed to bunzip2 encoded data: $IO::Uncompress::Bunzip2::Bunzip2Error" ) if( $DEBUG && !defined( $rv ) );
        $fh->seek(0,0);
    };

    SKIP:
    {
        skip( "gzip compression/decompression module is not installed.", 1 ) if( !HAS_DEFLATE );
        my $deflated = $s2->encode({ encoding => 'deflate' });
        ok( $deflated, 'encode -> deflate' );
        diag( "Deflate error: ", $s2->error ) if( $DEBUG && !$deflated );
        my $un_deflated;
        $rv = IO::Uncompress::Inflate::inflate( \$deflated => \$un_deflated );
        is( $un_deflated, $string2, 'encode -> deflate (check)' );
        $fh->seek(0,0);
    };

    SKIP:
    {
        skip( "gzip compression/decompression module is not installed.", 1 ) if( !HAS_ZIP );
        my $ziped = $s2->encode({ encoding => 'zip' });
        ok( $ziped, 'encode -> zip' );
        diag( "Zip error: ", $s2->error ) if( $DEBUG && !$ziped );
        my $un_ziped;
        $rv = IO::Uncompress::Unzip::unzip( \$ziped => \$un_ziped );
        is( $un_ziped, $string2, 'encode -> zip (check)' );
    };
};

subtest "encode file" => sub
{
    my $f = tempfile( extension => '.txt' );
    $f->open( '>', { binmode => 'utf8', autoflush => 1 }) || 
        bail_out( "Unable to open temporary file in write mode: " . $f->error, 12 );
    $f->print( $string );
    $f->seek(0,0);
    is( $f->size, length( $string ), "temp file created with data inside" );
    my $s3 = HTTP::Promise::Stream->new( $f, debug => $DEBUG );
    diag( "Error getting stream object: ", HTTP::Promise::Stream->error ) if( $DEBUG && !$s3 );
    
    my $rv;
    SKIP:
    {
        skip( "gzip compression/decompression module is not installed.", 1 ) if( !HAS_GZIP );
        isa_ok( $s3, ['HTTP::Promise::Stream'] );
        my $gziped = $s3->encode({ encoding => 'gzip' });
        ok( $gziped, 'encode -> gzip' );
        diag( "Gzip error: ", $s3->error ) if( $DEBUG && !$gziped );
        my $un_gzipped;
        $rv = IO::Uncompress::Gunzip::gunzip( \$gziped => \$un_gzipped );
        is( $un_gzipped, $string, 'encode -> gzip (check)' );
    };

    SKIP:
    {
        skip( "gzip compression/decompression module is not installed.", 1 ) if( !HAS_BZIP2 );
        my $bziped = $s3->encode({ encoding => 'bzip2' });
        ok( $bziped, 'encode -> bzip2' );
        diag( "Bzip2 error: ", $s3->error ) if( $DEBUG && !$bziped );
        my $un_bziped;
        $rv = IO::Uncompress::Bunzip2::bunzip2( \$bziped => \$un_bziped );
        is( $un_bziped, $string, 'encode -> bzip2 (check)' );
        diag( "Failed to bunzip2 encoded data: $IO::Uncompress::Bunzip2::Bunzip2Error" ) if( $DEBUG && !defined( $rv ) );
    };

    SKIP:
    {
        skip( "gzip compression/decompression module is not installed.", 1 ) if( !HAS_DEFLATE );
        my $deflated = $s3->encode({ encoding => 'deflate' });
        ok( $deflated, 'encode -> deflate' );
        diag( "Deflate error: ", $s3->error ) if( $DEBUG && !$deflated );
        my $un_deflated;
        $rv = IO::Uncompress::Inflate::inflate( \$deflated => \$un_deflated );
        is( $un_deflated, $string, 'encode -> deflate (check)' );
    };

    SKIP:
    {
        skip( "gzip compression/decompression module is not installed.", 1 ) if( !HAS_ZIP );
        my $ziped = $s3->encode({ encoding => 'zip' });
        ok( $ziped, 'encode -> zip' );
        diag( "Zip error: ", $s3->error ) if( $DEBUG && !$ziped );
        my $un_ziped;
        $rv = IO::Uncompress::Unzip::unzip( \$ziped => \$un_ziped );
        is( $un_ziped, $string, 'encode -> zip (check)' );
    };
};

subtest "decode scalar" => sub
{
    my $string2;
    SKIP:
    {
        skip( "gzip compression/decompression module is not installed.", 1 ) if( !HAS_GZIP );
        my $s_gzip = HTTP::Promise::Stream->new( \$encoded->{gzip} );
        isa_ok( $s_gzip, ['HTTP::Promise::Stream'] );
        $string2 = $s_gzip->decode({ encoding => 'gzip' });
        is( $string2 => $string, 'decode -> gzip (check)' );
    };

    SKIP:
    {
        skip( "gzip compression/decompression module is not installed.", 1 ) if( !HAS_BZIP2 );
        my $s_bzip2 = HTTP::Promise::Stream->new( \$encoded->{bzip2} );
        isa_ok( $s_bzip2, ['HTTP::Promise::Stream'] );
        $string2 = $s_bzip2->decode({ encoding => 'bzip2' });
        is( $string2 => $string, 'decode -> bzip2 (check)' );
    };

    SKIP:
    {
        skip( "gzip compression/decompression module is not installed.", 1 ) if( !HAS_DEFLATE );
        my $s_inflate = HTTP::Promise::Stream->new( \$encoded->{deflate} );
        isa_ok( $s_inflate, ['HTTP::Promise::Stream'] );
        $string2 = $s_inflate->decode({ encoding => 'inflate' });
        is( $string2 => $string, 'decode -> inflate (check)' );
    };

    SKIP:
    {
        skip( "gzip compression/decompression module is not installed.", 1 ) if( !HAS_ZIP );
        my $s_zip = HTTP::Promise::Stream->new( \$encoded->{zip} );
        isa_ok( $s_zip, ['HTTP::Promise::Stream'] );
        $string2 = $s_zip->decode({ encoding => 'zip' });
        is( $string2 => $string, 'decode -> zip (check)' );
    };
};

my $encoded_file = {};
my $encoded_fh = {};
for( qw( gzip bzip2 deflate zip ) )
{
    SKIP:
    {
        no strict 'refs';
        skip( "$_ compression/decompression module is not installed.", 1 ) if( !&{"HAS_\U$_\E"} );
        my $encoding = ( $_ eq 'deflate' ? 'inflate' : $_ );
        my $f = $encoded_file->{ $encoding } = tempfile( extension => ".$_" );
        diag( "Creating temp file \"$f\" for decode $encoding" ) if( $DEBUG );
        $f->open( '+>', { binmode => 'raw', autoflush => 1 } );
        $f->write( $encoded->{ $_ } );
        $f->seek(0,0);
        $encoded_fh->{ $encoding } = $f->filehandle;
    };
}

subtest "decode glob" => sub
{
    for( qw( gzip bzip2 inflate zip ) )
    {
        SKIP:
        {
            no strict 'refs';
            skip( "$_ compression/decompression module is not installed.", 1 ) if( !&{"HAS_\U$_\E"} );
            my $f = $encoded_fh->{ $_ };
            diag( "Creating stream for encoding $_ with glob $f" ) if( $DEBUG );
            my $s = HTTP::Promise::Stream->new( $f );
            isa_ok( $s => 'HTTP::Promise::Stream' );
            my $decoded = $s->decode({ encoding => $_ });
            is( $decoded => $string, "decode -> $_ (check)" );
        };
    }
};

subtest "decode file" => sub
{
    for( qw( gzip bzip2 inflate zip ) )
    {
        SKIP:
        {
            no strict 'refs';
            skip( "$_ compression/decompression module is not installed.", 1 ) if( !&{"HAS_\U$_\E"} );
            my $f = $encoded_file->{ $_ };
            my $s = HTTP::Promise::Stream->new( $f );
            isa_ok( $s => 'HTTP::Promise::Stream' );
            my $decoded = $s->decode({ encoding => $_ });
            is( $decoded => $string, "decode -> $_ (check)" );
        };
    }
};

subtest "read" => sub
{
    for my $dec ( qw( gzip bzip2 inflate zip ) )
    {
        SKIP:
        {
            no strict 'refs';
            skip( "$_ compression/decompression module is not installed.", 1 ) if( !&{"HAS_\U${dec}\E"} );
            my $s = HTTP::Promise::Stream->new( $encoded_file->{ $dec }, decoding => $dec, debug => $DEBUG );
            isa_ok( $s => ['HTTP::Promise::Stream'] );
            my $buf = '';
            my $len = $s->read( $buf );
            diag( "Error reading data: ", $s->error ) if( $DEBUG && !defined( $len ) );
            ok( $len, 'read -> string' );
            is( $buf, $string, "read decode($dec) -> string data match" );
            is( $len, length( $string ), "string decode($dec) -> data length" );
    
            # read to scalar reference
            my $s1 = HTTP::Promise::Stream->new( $encoded_file->{ $dec }, decoding => $dec, debug => $DEBUG );
            isa_ok( $s1 => ['HTTP::Promise::Stream'] );
            $buf = '';
            $len = $s1->read( \$buf );
            diag( "Error reading data: ", $s1->error ) if( $DEBUG && !defined( $len ) );
            ok( $len, "read decode($dec) -> scalar reference" );
            is( $buf, $string, "read decode($dec) -> scalar reference data match" );
            is( $len, length( $string ), 'scalar reference -> data length' );
    
            # read to glob
            my $s2 = HTTP::Promise::Stream->new( $encoded_file->{ $dec }, decoding => $dec, debug => $DEBUG );
            isa_ok( $s2 => ['HTTP::Promise::Stream'] );
            $encoded_file->{ $dec }->seek(0,0);
            my $tmpfile = tempfile(extension => '.txt');
            diag( "Using temporary file '$tmpfile'" ) if( $DEBUG );
            my $io = $tmpfile->open( '+>' );
            $len = $s2->read( $io );
            diag( "Error reading data: ", $s2->error ) if( $DEBUG && !defined( $len ) );
            $buf = $tmpfile->content->join( '' )->scalar;
            is( $buf, $string, "read decode($dec) -> glob data match" );
            is( $len, length( $string ), "glob decode($dec) -> data length" );
            $tmpfile->remove;
    
            # read to file
            my $s3 = HTTP::Promise::Stream->new( $encoded_file->{ $dec }, decoding => $dec, debug => $DEBUG );
            isa_ok( $s3 => ['HTTP::Promise::Stream'] );
            $encoded_file->{ $dec }->seek(0,0);
            $tmpfile = tempfile(extension => '.txt');
            diag( "Using temporary file '$tmpfile'" ) if( $DEBUG );
            $len = $s3->read( $tmpfile );
            diag( "Error reading data: ", $s3->error ) if( $DEBUG && !defined( $len ) );
            $tmpfile->open;
            $buf = $tmpfile->content->join( '' )->scalar;
            is( $buf, $string, "read decode($dec) -> file data match" );
            is( $len, length( $string ), "file decode($dec) -> data length" );
            $tmpfile->remove;
    
            # read to code reference
            my $s4 = HTTP::Promise::Stream->new( $encoded_file->{ $dec }, decoding => $dec, debug => $DEBUG );
            isa_ok( $s4 => ['HTTP::Promise::Stream'] );
            $encoded_file->{ $dec }->seek(0,0);
            $tmpfile = tempfile(extension => '.txt');
            $tmpfile->open( '+>' );
            my $code = sub
            {
                $tmpfile->print( $_[0] );
            };
            $len = $s4->read( $code );
            diag( "Error reading data: ", $s4->error ) if( $DEBUG && !defined( $len ) );
            $buf = $tmpfile->content->join( '' )->scalar;
            is( $buf, $string, "read decode($dec) -> code data match" );
            is( $len, length( $string ), "file decode($dec) -> data length" );
            $tmpfile->remove;
        };
    }
};

subtest "write" => sub
{
    my $done = {};
    my $check = {};
    my $datafile;
    for my $enc ( qw( gzip bzip2 deflate zip ) )
    {
        SKIP:
        {
            no strict 'refs';
            skip( "$_ compression/decompression module is not installed.", 1 ) if( !&{"HAS_\U${enc}\E"} );
            # my $enc = 'gzip';
            my $tmpfile = tempfile(extension => '.txt');
            my $enc_file = ( $enc eq 'deflate' ? $encoded_file->{inflate} : $encoded_file->{ $enc } );
            $enc_file->close;
    
            # String
            my $s = HTTP::Promise::Stream->new( $tmpfile, encoding => $enc, debug => $DEBUG );
            isa_ok( $s => ['HTTP::Promise::Stream'] );
            my $len = $s->write( $string );
            diag( "Error writing to stream: ", $s->error ) if( $DEBUG && !defined( $len ) );
            $check->{ $enc } = $enc_file->load( binmode => 'raw' );
            $done->{ $enc }  = $tmpfile->load( binmode => 'raw' );
    #         is( $done->{ $enc } => $check->{ $enc }, "write string -> encode($enc)" ) || do
    #         {
    #             diag( "Original data is:\n", $s->dump_hex( $check->{ $enc } ), "\nagainst encoded data:\n", $s->dump_hex( $done->{ $enc } ) );
    #         };
            my $buf;
            my $s2 = HTTP::Promise::Stream->new( \$done->{ $enc }, decoding => $enc );
            $s2->read( \$buf );
            is( $buf => $string, "write string -> encode($enc)" );
        
            is( $len => length( $string ), "write string length" );
            $tmpfile->remove;
    
            # scalar reference
            $tmpfile = tempfile(extension => '.txt');
            $s = HTTP::Promise::Stream->new( $tmpfile, encoding => $enc, debug => $DEBUG );
            isa_ok( $s => ['HTTP::Promise::Stream'] );
            $len = $s->write( \$string );
            diag( "Error writing to stream: ", $s->error ) if( $DEBUG && !defined( $len ) );
            $done->{ $enc }  = $tmpfile->load( binmode => 'raw' );
            # is( $done->{ $enc } => $check->{ $enc }, "write scalar reference -> encode($enc)" );
            $s2 = HTTP::Promise::Stream->new( \$done->{ $enc }, decoding => $enc );
            $buf = '';
            $s2->read( \$buf );
            is( $buf => $string, "write scalar reference -> encode($enc)" );
        
            is( $len => length( $string ), "write scalar reference -> length" );
            $tmpfile->remove;
    
            $tmpfile = tempfile(extension => '.txt');
            $s = HTTP::Promise::Stream->new( $tmpfile, encoding => $enc, debug => $DEBUG );
            isa_ok( $s => ['HTTP::Promise::Stream'] );
            my $code = sub
            {
                return( $string );
            };
            $len = $s->write( $code );
            diag( "Error writing to stream: ", $s->error ) if( $DEBUG && !defined( $len ) );
            $done->{ $enc }  = $tmpfile->load( binmode => 'raw' );
            # is( $done->{ $enc } => $check->{ $enc }, "write code -> encode($enc)" );
            $s2 = HTTP::Promise::Stream->new( \$done->{ $enc }, decoding => $enc );
            $buf = '';
            $s2->read( \$buf );
            is( $buf => $string, "write code -> encode($enc)" );
            is( $len => length( $string ), "write code -> length" );
            $tmpfile->remove;
    
            $tmpfile = tempfile(extension => '.txt');
            my $fh = Module::Generic::Scalar->new( \$string )->open;
            $s = HTTP::Promise::Stream->new( $tmpfile, encoding => $enc, debug => $DEBUG );
            isa_ok( $s => ['HTTP::Promise::Stream'] );
            $len = $s->write( $fh );
            diag( "Error writing to stream: ", $s->error ) if( $DEBUG && !defined( $len ) );
            $done->{ $enc }  = $tmpfile->load( binmode => 'raw' );
            # is( $done->{ $enc } => $check->{ $enc }, "write glob -> encode($enc)" );
            $s2 = HTTP::Promise::Stream->new( \$done->{ $enc }, decoding => $enc );
            $buf = '';
            $s2->read( \$buf );
            is( $buf => $string, "write glob -> encode($enc)" );
            is( $len => length( $string ), "write glob -> length" );
            $tmpfile->remove;
    
            $tmpfile = tempfile(extension => '.txt');
            $datafile = tempfile(extension => '.txt');
            $datafile->open( '>' );
            $datafile->print( $string );
            $datafile->close;
            $s = HTTP::Promise::Stream->new( $tmpfile, encoding => $enc, debug => $DEBUG );
            isa_ok( $s => ['HTTP::Promise::Stream'] );
            diag( "\$s->write( $datafile ) -> $tmpfile" ) if( $DEBUG );
            $len = $s->write( $datafile );
            diag( "Error writing to stream: ", $s->error ) if( $DEBUG && !defined( $len ) );
            $done->{ $enc }  = $tmpfile->load( binmode => 'raw' );
            # is( $done->{ $enc } => $check->{ $enc }, "write file -> encode($enc)" );
            $s2 = HTTP::Promise::Stream->new( \$done->{ $enc }, decoding => $enc );
            $buf = '';
            $s2->read( \$buf );
            is( $buf => $string, "write file -> encode($enc)" );
            is( $len => length( $string ), "write file -> length" );
            #$tmpfile->remove;
            #$datafile->remove;
        };
    }
};

$encoded_file->{ $_ }->remove for( keys( %$encoded_file ) );

done_testing();

__END__

