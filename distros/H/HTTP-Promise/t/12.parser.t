#!/usr/bin/perl
BEGIN
{
    use strict;
    use warnings;
    use lib './lib';
    use vars qw( $DEBUG );
    use Test2::V0;
    # use Devel::Confess;
    use Module::Generic::File qw( cwd file );
    use Module::Generic::Scalar::IO;
    use Scalar::Util;
    our $DEBUG = exists( $ENV{AUTHOR_TESTING} ) ? $ENV{AUTHOR_TESTING} : 0;
};

use strict;
use warnings;

BEGIN
{
    use ok( 'HTTP::Promise::Parser' );
};

subtest 'parsing requests' => sub
{
    my $requests =
    [
        <<EOT,
POST /some/where HTTP/1.1
User-Agent: Mozilla/5.0 (Macintosh; Intel Mac OS X x.y; rv:42.0) Gecko/20100101 Firefox/42.0
Host: www.example.com
Content-Type: application/x-www-form-urlencoded
Content-Length: 41
Accept-Language: en-us
Accept-Encoding: gzip, deflate
Connection: Keep-Alive

id=1234567890&content=hello&param=foo.bar
EOT
        { headers => HTTP::Promise::Headers->new(
            User_Agent      => 'Mozilla/5.0 (Macintosh; Intel Mac OS X x.y; rv:42.0) Gecko/20100101 Firefox/42.0',
            Host            => 'www.example.com',
            Content_Type    => 'application/x-www-form-urlencoded',
            Content_Length  => 41,
            Accept_Language => 'en-us',
            Accept_Encoding => 'gzip, deflate',
            Connection      => 'Keep-Alive',
        ), method => 'POST', uri => URI->new( '/some/where' ), version => version->parse( '1.1' ) },
        'request #1',
    ];

    while( my( $message, $expected, $test ) = splice( @$requests, 0, 3 ) )
    {
        my $p = HTTP::Promise::Parser->new( debug => $DEBUG );
        my $io = Module::Generic::Scalar::IO->new( \$message ) || 
            bail_out( Module::Generic::File::IO->error );
        my $ent = $p->parse( $io ) || do
        {
            diag( "Error parsing test $test: ", $p->error ) if( $DEBUG );
            fail( $test );
            next;
        };
        isa_ok( $ent => ['HTTP::Promise::Entity'] );
    }
};

done_testing();

__END__

