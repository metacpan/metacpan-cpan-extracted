#!perl

use strict;
use warnings;

use FindBin;
use lib "$FindBin::Bin/lib";

use Test::More tests => 6;
use Test::Deep;

use Cwd;
use HTTP::Body;
use File::Spec::Functions;
use IO::File;
use PAML;
use File::Temp qw/ tempdir /;

my $path = catdir( getcwd(), 't', 'data', 'multipart' );

{
    my $uploads = uploads_for('001');

	{
		my ($volume,$directories,$file) = File::Spec->splitpath( $uploads->{upload2}{tempname} );	
		like(
			$file, qr/^.{10}\.pl$/,
			'tempname preserves .pl suffix'
		);
	}

	{
		my ($volume,$directories,$file) = File::Spec->splitpath( $uploads->{upload4}{tempname} );	
		unlike(
			$file, qr/^.{10}\..+$/,
			'tempname for upload4 has no suffix'
		);
	}

}

{
    my $uploads = uploads_for('006');

	{
		my ($volume,$directories,$file) = File::Spec->splitpath( $uploads->{upload2}{tempname} );	
		like(
			$file, qr/^.{10}\.pl$/,
			'tempname preserves .pl suffix with Windows filename'
		);
	}

}

{
    my $uploads = uploads_for('014');

	{
		my ($volume,$directories,$file) = File::Spec->splitpath( $uploads->{upload}{tempname} );	
		like(
			$file, qr/^.{10}\.foo\.txt$/,
			'tempname preserves .foo.txt suffix'
		);
	}

	{
		my ($volume,$directories,$file) = File::Spec->splitpath( $uploads->{upload2}{tempname} );	
		like(
			$file, qr/^.{10}\.txt$/,
			'tempname preserves .txt suffix when dir name has .'
		);
	}

	like(
		$uploads->{upload2}{tempname}, qr/[\\\/]\w+.txt$/,
		'tempname only gets extension from filename, not from a directory name'
	);

}

sub uploads_for {
    my $number = shift;

    my $headers = PAML::LoadFile( catfile( $path, "$number-headers.pml" ) );
    my $content = IO::File->new( catfile( $path, "$number-content.dat" ) );
    my $body    = HTTP::Body->new( $headers->{'Content-Type'}, $headers->{'Content-Length'} );
    my $tempdir = tempdir( 'XXXXXXX', CLEANUP => 1, DIR => File::Spec->tmpdir() );
    $body->tmpdir($tempdir);

    binmode $content, ':raw';

    while ( $content->read( my $buffer, 1024 ) ) {
        $body->add($buffer);
    }

    $body->cleanup(1);

    return $body->upload;
}
