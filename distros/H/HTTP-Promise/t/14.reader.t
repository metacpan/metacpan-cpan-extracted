#!/usr/bin/perl
BEGIN
{
    use strict;
    use warnings;
    use lib './lib';
    use vars qw( $DEBUG );
    use Test2::V0;
    use Module::Generic::File qw( file );
    our $DEBUG = exists( $ENV{AUTHOR_TESTING} ) ? $ENV{AUTHOR_TESTING} : 0;
};

use strict;
use warnings;

use ok( 'HTTP::Promise::IO' );

my $d = file( __FILE__ )->parent->child( 'testin' );
my $f = $d->child( 'post-multipart-form-data-02.txt' ) || bail_out( $d->error );
my $io = $f->open( '<', { binmode => 'raw' } ) || bail_out( $f->error );
my $reader = HTTP::Promise::IO->new( $io, debug => $DEBUG ) || bail_out( HTTP::Promise::IO->error );

my $data = $reader->read_until_in_memory( qr/\015?\012\015?\012/, include => 1 );
diag( "Error reading to get headers: ", $reader->error ) if( $DEBUG && !defined( $data ) );
diag( "Header data returned are:\n$data" ) if( $DEBUG );
is( $data, <<EOT );
POST /test HTTP/1.1
Host: www.csm-testcenter.org
User-Agent: Mozilla/5.0 (Macintosh; Intel Mac OS X 10.15; rv:100.0) Gecko/20100101 Firefox/100.0
Accept: text/html,application/xhtml+xml,application/xml;q=0.9,image/avif,image/webp,*/*;q=0.8
Accept-Language: fr-FR,en-GB;q=0.8,fr;q=0.6,en;q=0.4,ja;q=0.2
Accept-Encoding: gzip, deflate, br
Content-Type: multipart/form-data; boundary=---------------------------40260073931083483614643569375
Content-Length: 79784
Origin: http://www.csm-testcenter.org
DNT: 1
Connection: keep-alive
Referer: http://www.csm-testcenter.org/
Upgrade-Insecure-Requests: 1
Sec-Fetch-Dest: document
Sec-Fetch-Mode: navigate
Sec-Fetch-Site: cross-site
Sec-Fetch-User: ?1

EOT
$io->seek(0,0);
$reader->buffer->reset;
$data = $reader->read_until_in_memory( qr/\015?\012\015?\012/, exclude => 1 );
is( $data, q{POST /test HTTP/1.1
Host: www.csm-testcenter.org
User-Agent: Mozilla/5.0 (Macintosh; Intel Mac OS X 10.15; rv:100.0) Gecko/20100101 Firefox/100.0
Accept: text/html,application/xhtml+xml,application/xml;q=0.9,image/avif,image/webp,*/*;q=0.8
Accept-Language: fr-FR,en-GB;q=0.8,fr;q=0.6,en;q=0.4,ja;q=0.2
Accept-Encoding: gzip, deflate, br
Content-Type: multipart/form-data; boundary=---------------------------40260073931083483614643569375
Content-Length: 79784
Origin: http://www.csm-testcenter.org
DNT: 1
Connection: keep-alive
Referer: http://www.csm-testcenter.org/
Upgrade-Insecure-Requests: 1
Sec-Fetch-Dest: document
Sec-Fetch-Mode: navigate
Sec-Fetch-Site: cross-site
Sec-Fetch-User: ?1} );
use ok( 'HTTP::Promise::Parser' );
my $p = HTTP::Promise::Parser->new( debug => $DEBUG );
my $def = $p->parse_request_headers( "$data\n\n" ) || bail_out( $p->error );
my $headers = $def->{headers};
my $ct = $headers->content_type;
diag( "Headers length '$def->{length}' and Content-Type is '$ct'" ) if( $DEBUG );
my $h = $headers->new_field( 'Content-Type' => $ct );
my $boundary = $h->boundary;
is( $boundary, '---------------------------40260073931083483614643569375' );

my $trash = $reader->read_until_in_memory( qr/--${boundary}\015?\012/, include => 1 );
diag( "Found start data '$trash'" ) if( $DEBUG );
my $bytes = -1;
my $buff;
while( defined( $bytes ) && $bytes != 0 )
{
    my $hdr = $reader->read_until_in_memory( qr/\015?\012\015?\012/, include => 1 );
    if( length( $hdr ) )
    {
        diag( "Found part headers: '$hdr'" ) if( $DEBUG );
        $def = $p->parse_headers( $hdr );
        diag( "$def->{length} bytes of headers parsed." ) if( $DEBUG );
        my $ph = $def->{headers};
        diag( "Headers found for this part are: '", join( "', '", $ph->header_field_names ), "'" ) if( $DEBUG );
        my $dispo = $ph->new_field( 'Content-Disposition' => $ph->content_disposition );
        diag( "Part name is '", $dispo->name, "'" ) if( $DEBUG );
    }
    my $data = '';
    while( $bytes = $reader->read_until( $buff, 1024, { string => qr/\015?\012--${boundary}(?:\-{2})?\015?\012/, ignore => 1 } ) )
    {
        $data .= $buff;
        last if( $bytes < 0 );
    }
    diag( "$bytes bytes returned. Got ", length( $data ), " bytes of part data." ) if( $DEBUG );
    diag( "Data is: '$data'" ) if( $DEBUG && length( $data ) < 512 );
    # my $delim = $reader->getline;
    # diag( "Got the part delimiter '$delim'" ) if( $DEBUG );
}

done_testing();

__END__

