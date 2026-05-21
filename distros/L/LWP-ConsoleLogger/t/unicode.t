use strict;
use warnings;

use File::Temp               qw( tempfile );
use LWP::ConsoleLogger       ();
use LWP::ConsoleLogger::Easy qw( debug_ua );
use LWP::UserAgent           ();
use Log::Dispatch            ();
use Path::Tiny               qw( path );
use Test::More import => [qw( done_testing is ok like subtest )];
use Test::Warnings;

my $url   = 'file:///' . path('t/test-data/unicode.html')->absolute;
my $smile = "\x{1F604}";                                               # 😄

subtest 'body content with unicode renders correctly via Code logger' => sub {
    my @captured;
    my $logger = Log::Dispatch->new(
        outputs => [
            [
                'Code',
                min_level => 'debug',
                code      => sub {
                    my %args = @_;
                    push @captured, $args{message};
                },
            ],
        ],
    );

    my $mech = LWP::UserAgent->new;
    my $cl   = debug_ua($mech);
    $cl->logger($logger);

    my $res = $mech->get($url);
    is( $res->code, 200, 'fetched unicode.html' );

    my $all = join "\n", @captured;
    like( $all, qr/\Q$smile\E/, '😄 present in captured output' );
};

subtest 'no Wide character warnings when writing to a File output' => sub {
    my ( undef, $tmp ) = tempfile( UNLINK => 1 );

    my $logger = Log::Dispatch->new(
        outputs => [
            [
                'File',
                min_level => 'debug',
                filename  => $tmp,
                binmode   => ':encoding(UTF-8)',
            ],
        ],
    );

    my $mech = LWP::UserAgent->new;
    my $cl   = debug_ua($mech);
    $cl->logger($logger);

    # Test::Warnings (use'd at top of file) will fail the test if any warning
    # fires during the run.
    my $res = $mech->get($url);
    is( $res->code, 200, 'fetched unicode.html for file output test' );

    my $bytes = path($tmp)->slurp_raw;
    like( $bytes, qr/\xF0\x9F\x98\x84/, '😄 UTF-8 bytes present in log file' );
};

done_testing;
