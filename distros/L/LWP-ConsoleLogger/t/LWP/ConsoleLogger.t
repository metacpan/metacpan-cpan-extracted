use strict;
use warnings;

use HTTP::Request;
use LWP::ConsoleLogger;
use LWP::UserAgent;
use Path::Tiny qw( path );
use Test::Fatal qw( exception );
use Test::Most;
use URI::file;
use WWW::Mechanize;

my @mech = (
    LWP::UserAgent->new( cookie_jar => {} ),
    WWW::Mechanize->new( autocheck  => 0 ),
);
my $logger = LWP::ConsoleLogger->new( dump_content => 1, dump_text => 1 );
ok( $logger, 'logger compiles' );

foreach my $mech (@mech) {
    $mech->default_header(
        'Accept-Encoding' => scalar HTTP::Message::decodable() );
    is( exception { get_local_file($mech) }, undef, 'GET lives' );
}

$logger->content_pre_filter(
    sub {
        my $content      = shift;
        my $content_type = shift;
        diag "Content-Type: $content_type";

        if ( $content
            =~ m{<!-- \s header \s ends \s -->(.*)<!-- \s footer \s begins \s -->}gmxs
        ) {
            return $1;
        }
        return $content;
    }
);

$mech[0]->get( uri_for_file('content-regex.html') );

sub get_local_file {
    my $mech = shift;
    $mech->add_handler(
        'response_done',
        sub { $logger->response_callback(@_) }
    );
    $mech->add_handler(
        'request_send',
        sub { $logger->request_callback(@_) }
    );

    $mech->get( uri_for_file('foo.html') );
}

sub uri_for_file {
    my $path = path( 't', 'test-data', shift );
    return URI::file->new( $path->absolute );
}

done_testing();
