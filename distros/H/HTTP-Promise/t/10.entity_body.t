#!/usr/bin/perl
BEGIN
{
    use strict;
    use warnings;
    use lib './lib';
    use vars qw( $DEBUG $CRLF );
    use Test2::V0;
    use Module::Generic::File qw( cwd file );
    use Scalar::Util;
    our $CRLF = "\015\012";
    our $DEBUG = exists( $ENV{AUTHOR_TESTING} ) ? $ENV{AUTHOR_TESTING} : 0;
};

use strict;
use warnings;

BEGIN
{
    use ok( 'HTTP::Promise::Entity' );
    use ok( 'HTTP::Promise::Body' );
    use ok( 'HTTP::Promise::Headers' );
};

my $output_dir = file( './t/testout', auto_remove => 0 );
my $testin_dir = file( './t/testin' );
if( !$output_dir->exists )
{
	$output_dir->mkdir(0755) or bail_out( "Could not creaet output directory $output_dir: " . $output_dir->error );
}

ok( $output_dir->exists, "$output_dir exists" );

# Check bodies:
my @bodies = (
	[ HTTP::Promise::Body::Scalar->new, 'HTTP::Promise::Body::Scalar' ],
	[ HTTP::Promise::Body::File->new( './t/testout/fbody' ), 'HTTP::Promise::Body::File' ],
	[ HTTP::Promise::Body::InCore->new, 'HTTP::Promise::Body::InCore' ],
);

my $buf;
my @lines;
my $line;
my $pos;
foreach my $ref ( @bodies )
{
    my( $body, $package ) = @$ref;
    SKIP:
    {
        isa_ok( $body => [$package] ) || do
        {
            diag( "Unable to create a ${package} object: ", $package->error ) if( $DEBUG && !defined( $body ) );
            skip( "Failed to instantiate a ${package} object", 1 );
        };
        my $io;
        my $class = ref( $body );

        # Open body for writing, and write stuff
        $io = $body->open( 'w+' );
        diag( "IO opened in read/write mode is: '", overload::StrVal( $io ), "'" ) if( $DEBUG );
        diag( "Unable to open body: ", $body->error ) if( $DEBUG && !defined( $io ) );
        ok( $io, "$class: opened for writing" );
        skip( "Failed to instantiate an filehandle for body.", 1 ) if( !$io );
        $io->print( "Line 1\nLine 2\nLine 3" );
        $io->close;
    
        # Open body for reading
        my $pos = $io->tell;
        diag( "Current position in file (read/write) is: '$pos'" ) if( $DEBUG );
        $io = $body->open( 'r' );
        diag( "\$io is '$io' (", overload::StrVal( $io ), "'" ) if( $DEBUG );
        $pos = $io->tell;
        diag( "Current position in file (read-only) is: '$pos'" ) if( $DEBUG );
        ok( $io, "$class: able to open body for reading?" );

        # Read all lines
        @lines = $io->getlines;
        diag( "\@lines contains ", scalar( @lines ), " lines and \$io is '$io' (", overload::StrVal( $io ), ") which can read? ", ( $io->can( 'can_read' ) && $io->can_read ? 'yes' : 'no' ) ) if( $DEBUG );
        diag( "\@lines contains: '", join( "', '", @lines ), "'" ) if( $DEBUG && !scalar( @lines ) );
        ok( ( ( $lines[0] eq "Line 1\n" ) && 
              ( $lines[1] eq "Line 2\n" ) &&
              ( $lines[2] eq "Line 3" )
            ),
            "$class: getlines method works?"
        );
      
        # Seek forward, read:
        $io->seek( 3, 0 );
        $io->read( $buf, 3 );
        is( $buf, 'e 1', "$class: seek(SEEK_START) plus read works?" );

        # Tell, seek, and read:
        $pos = $io->tell;
        $io->seek( -5, 1 );
        $pos = $io->tell;
        is( $pos, 1, "$class: tell and seek(SEEK_CUR) works?" );

        $io->read( $buf, 5 );
        is( $buf, 'ine 1', "$class: seek(SEEK_CUR) plus read works?" );

        # Read all lines, one at a time:
        @lines = ();
        $io->seek( 0, 0 );
        while( $line = $io->getline() )
        {
            push( @lines, $line )
        }
        ok( ( ( $lines[0] eq "Line 1\n" ) &&
              ( $lines[1] eq "Line 2\n" ) &&
              ( $lines[2] eq "Line 3" )
            ),
            "$class: getline works?"
        );
    
        # Done!
        $io->close;

        # Slurp lines:
        my $lines = $body->as_lines;
        ok( ( ( $lines->[0] eq "Line 1\n" ) &&
              ( $lines->[1] eq "Line 2\n" ) &&
              ( $lines->[2] eq "Line 3" )
            ),
            "$class: as_lines works?"
        );

        # Slurp string:
        my $str = $body->as_string;
        is( $str, "Line 1\nLine 2\nLine 3", "$class: as_string works?" );
    };
}

{

	# my $cwd = cwd();
	# ok( $output_dir->chdir, 'chdir to $output_dir to avoid clutter' );
	eval
	{
		my $body = HTTP::Promise::Body::File->new( " bad file " );
		diag( "Failed to create body file object for file \" bad file \": ", HTTP::Promise::Body::File->error ) if( $DEBUG && !defined( $body ) );
		my $fh;
		$fh = $body->open( 'w' ) || do
		{
		    diag( "Failed to open body for file \" bad file\": ", $body->error ) if( $DEBUG && !defined( $fh ) );
		};
		$fh->close;
		ok( -e( ' bad file ' ), 'file created with leading whitespace, as expected' );
		unlink( ' bad file ' );
	};
	# ok( $cwd->chdir, 'chdir back' );
	# ok( cwd(), $cwd, 'cwd' );
}

subtest "body incore" => sub
{
    my $body = HTTP::Promise::Body::InCore->new( "hi\n" );
    isa_ok( $body => ['HTTP::Promise::Body::InCore'] );
    my $fh = $body->open( 'r' );
    diag( "Error opening body: ", $body->error ) if( $DEBUG && !defined( $fh ) );
    my @ary = <$fh>;
    $fh->close;
    is( scalar( @ary ), 1 );
    is( $ary[0], "hi\n" );

    $body = HTTP::Promise::Body::InCore->new( \"hi\n" );
    isa_ok( $body => ['HTTP::Promise::Body::InCore'] );
    $fh = $body->open( 'r' );
    diag( "Error opening body: ", $body->error ) if( $DEBUG && !defined( $fh ) );
    @ary = <$fh>;
    $fh->close;
    is( scalar( @ary ), 1 );
    is( $ary[0], "hi\n" );

    $body = HTTP::Promise::Body::InCore->new( ["line 1\n", "line 2\n"] );
    isa_ok( $body => ['HTTP::Promise::Body::InCore'] );
    $fh = $body->open( 'r' );
    diag( "Error opening body: ", $body->error ) if( $DEBUG && !defined( $fh ) );
    @ary = <$fh>;
    $fh->close;
    is( scalar( @ary ), 2 );
    is( $ary[0], "line 1\n" );
    is( $ary[1], "line 2\n" );
};

subtest "build entity" => sub
{
    {
        local $SIG{__WARN__} = sub{ die( "caught warning: ", @_ ) };
        {   
             my $e = HTTP::Promise::Entity->build( path => "${testin_dir}/short.txt", debug => $DEBUG );
             diag( "Error instantiating HTTP::Promise::Entity object: ", HTTP::Promise::Entity->error ) if( $DEBUG && !defined( $e ) );
             my $name = 'short.txt';
             my $got;

             $got = $e->headers->mime_attr( 'content-type.name' );
             # diag( "Content-Type is '", $e->header( 'Content-Type' ), "' and content-type.name yielded '$got', double checking '", $e->headers->mime_attr( 'content-type.name' ), "'" ) if( $DEBUG );
             is( $got, $name, 'Path: with no Filename, got default content-type.name' );

             $got = $e->headers->mime_attr( 'content-disposition.filename' );
             is( $got, $name, 'Path: with no Filename, got default content-disposition.filename' );

             $got = $e->headers->recommended_filename;
             is( $got, $name, 'Path: with no Filename, got default recommended filename' );
        }
        { 
            my $e = HTTP::Promise::Entity->build(
                path => "${testin_dir}/short.txt",
                filename => undef,
                debug => $DEBUG
            );
            my $got = $e->headers->mime_attr( 'content-type.name' );
            ok( !$got, 'Path: with explicitly undef Filename, got no filename' );
            my $x = $e->as_string;
            my $desired = "Content-Type: text/plain${CRLF}${CRLF}" . <<EOT;
Dear «François Müller»,

As you requested, I have written the HTTP::Promise modules to support
the creation of HTTP multipart messages.

Jacques
EOT
            is( $x, $desired, 'Tested stringify' );
        }

        {
            my $e = HTTP::Promise::Entity->build(
                path => "${testin_dir}/short.txt",
                filename => 'foo.txt',
                debug => $DEBUG
            );
            my $got = $e->headers->mime_attr( 'content-type.name' );
            is( $got, "foo.txt", "Path: verified explicit 'Filename'" );
        }
        {
            my $e = HTTP::Promise::Entity->build( path => "${testin_dir}/mignonne-ronsard.txt" );
            my $got = $e->headers->mime_attr( 'content-type' );
            is( $got, 'text/plain', 'Type: default ok' );
        }
        {
            my $e = HTTP::Promise::Entity->build(
                path => "${testin_dir}/mignonne-ronsard.txt",
                type => 'text/foo'
            );
            my $got = $e->headers->mime_attr( 'content-type' );
            is( $got, 'text/foo', 'Type: explicit ok' );
        }
        {
            my $e = HTTP::Promise::Entity->build(
                path => "${testin_dir}/science-sans-conscience-rabelais.txt",
                encoding => 'suggest'
            );
            my $got = $e->headers->content_encoding;
            is( $got, undef, 'No encoding for small body' );
        }
        {
            my $e = HTTP::Promise::Entity->build(
                path => "${testin_dir}/short.txt",
                encoding => 'suggest'
            );
            my $got = $e->headers->content_encoding;
            is( $got, undef, '8bit characters suggests no encoding. This is not e-mail' );
        }
        {
            my $e = HTTP::Promise::Entity->build(
                type => 'image/png',
                path => "${testin_dir}/tengu.png",
                encoding => 'suggest'
            );
            my $got = $e->headers->content_encoding;
            is( $got, undef, 'No encoding suggested for images' );
        }
        {
            my $e = HTTP::Promise::Entity->build(
                path => "${testin_dir}/short.txt"
            );
            my $got = $e->headers->mime_attr( 'content-type.charset' );
            ok( !$got, 'Charset: default ok' );
        }
        {
            my $e = HTTP::Promise::Entity->build(
                path => "${testin_dir}/short.txt",
                charset => 'utf-8'
            );
            my $got = $e->headers->mime_attr( 'content-type.charset' );
            is( $got, 'utf-8', 'Charset: explicit' );
        }

        {
            my $e = HTTP::Promise::Entity->build(
                type => 'message/http',
                encoding => 'base64',
                data => "GET / HTTP/1.0${CRLF}Host: wwww.example.org${CRLF}${CRLF}Foo\n"
            );
            my $encoding = $e->headers->content_encoding;
            is( $encoding, undef, 'HTTP::Promise::Entity->build ignored encoding on message/http' );
        }

        {
            my $e = HTTP::Promise::Entity->build(
                type => 'message/global',
                encoding => 'gzip',
                data => "GET / HTTP/1.0${CRLF}Host: wwww.example.org${CRLF}${CRLF}Foo\n"
            );
            my $encoding = $e->headers->content_encoding;
            is( $encoding, 'gzip', 'HTTP::Promise::Entity->build did not ignore encoding for message/global' );
        }
        {
            my $e = HTTP::Promise::Entity->build(
                type => 'multipart/ALTERNATIVE',
                encoding => 'base64',
                data => "GET / HTTP/1.0${CRLF}Host: wwww.example.org${CRLF}${CRLF}Foo\n"
            );
            my $encoding = $e->headers->content_encoding;
            is( $encoding, undef, 'Encoding ignored for Content-Type multipart' );
        }
    }

    # Create the top-level, and set up the headers in a couple of different ways
    my $top = HTTP::Promise::Entity->build(
        type => 'multipart/mixed',
    );
    $top->headers->add( 'user-agent', 'MyAgent' );
    # Those are not used with HTTP, so probably should remove
    $top->preamble( [] );
    $top->epilogue( [] );

    # Attachment #0: a simple text document: 
    $top->attach( path => "${testin_dir}/short.txt" );

    # Attachment #1: a png file:
    $top->attach(
        path => "${testin_dir}/tengu.png",
        type => 'image/png',
        encoding => 'gzip, base64',
        disposition => 'attachment'
    );

    # Attachment #2: a document we'll create manually:
    my $attach = HTTP::Promise::Entity->new;
    $attach->headers( HTTP::Promise::Headers->new(
        X_Origin => 'fake',
        Content_encoding => 'quoted-printable',
        Content_type => 'text/plain',
    ) );
    $attach->body( HTTP::Promise::Body::Scalar->new );
    my $io = $attach->body->open( 'w' );
    $io->print( <<EOF
This  is the first line.
This is the middle.
This is the last.
EOF
    );
    $io->close;
    $top->add_part( $attach );

    # Attachment #3: a document we'll create, not-so-manually:
    my $LINE = "This is the first and last line, with no CR at the end.";
    $attach = $top->attach( data => $LINE );

    unlink( $output_dir->glob( 'entity.msg*' ) );

    my $body = $top->parts->index(0)->body;
    isa_ok( $body => ['HTTP::Promise::Body'], '->body returns the body object' );
    is( $body->length, 149, '$body->length: body size' );

    my $preamble_str = join( '', @{$top->preamble || []} );
    my $epilogue_str = join( '', @{$top->epilogue || []} );

    my $tmp = file( "${output_dir}/entity1.dat" );
    my $fh = $tmp->open( '>' ) || bail_out( "Unable to open temporary file '$tmp': ", $tmp->error );
    $top->print( $fh );
    $fh->close;
    ok( -s( "${output_dir}/entity1.dat" ), 'wrote msg1 to filehandle glob' );

    my $tmp2 = file( "${output_dir}/entity2.dat" );
    $fh = $tmp2->open( '>' ) || bail_out( "Unable to open temporary file '$tmp': ", $tmp2->error );
    my $oldfh = select( $fh );
    $top->print;
    select( $oldfh );
    $tmp2->close;
    ok( -s( "${output_dir}/entity2.dat" ), 'write msg2 to selected filehandle' );
    is( -s( "${output_dir}/entity1.dat" ), -s( "${output_dir}/entity2.dat" ), 'message files are same length' );
};

done_testing();

__END__

