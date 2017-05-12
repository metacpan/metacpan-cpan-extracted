#!perl

use strict;
use warnings;

use FindBin;
use lib "$FindBin::Bin/lib";

use Test::More tests => 3;
use Test::Deep;

use Cwd;
use HTTP::Body;
use File::Spec::Functions;
use IO::File;
use PAML;
use File::Temp qw/ tempdir /;

my $path = catdir( getcwd(), 't', 'data', 'multipart' );

{
  $HTTP::Body::MultiPart::basename_regexp = qr/(\.\w+(?:\.\w+)*)$/;

    my $uploads = uploads_for('015');

	{
		my ($volume,$directories,$file) = File::Spec->splitpath( $uploads->{upload}{tempname} );	
		like(
			$file, qr/^.{10}\.tar\.gz\.Z$/,
			'tempname preserves .tar.gz.Z suffix'
		);
	}

  {
    my ($volume,$directories,$file) = File::Spec->splitpath( $uploads->{upload2}{tempname} );  
    like(
      $file, qr/^.{10}\.png$/,
      'tempname preserves .png suffix'
    );
  }

  {
    my ($volume,$directories,$file) = File::Spec->splitpath( $uploads->{upload3}{tempname} );  
    like(
      $file, qr/^.{10}\.txt$/,
      'tempname preserves .txt suffix'
    );
  }

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
