use strict;
use warnings;

use FindBin;
use lib "$FindBin::RealBin/../../../lib", "$FindBin::RealBin/../../lib";

use Git::Lint::Test;
use Test::Deep;
use Test::Exception;

my $class = 'Git::Lint::Check::Message';
use_ok( $class );

HAPPY_PATH: {
    note( 'happy path' );

    my $file = 'good_summary_blank_body';
    my $path = 'data/messages';

    my $file_path = "$FindBin::RealBin/../../$path/$file";

    my $lines_arref = $class->message( file => $file_path );

    my $expected = [
        'summary',
        '',
        'body',
    ];

    cmp_deeply( $lines_arref, $expected, 'return was the expected filestructure and content' );
}

EXCEPTION: {
    note( 'exception' );

    my %input = ( file => 'filename' );
    foreach my $required ( keys %input ) {
        local $input{ $required };
        my $stored = delete $input{ $required };

        my $plugin = $class->new();
        dies_ok( sub { $plugin->message( %input ) }, "dies if missing $required" );
        like( $@, qr/^$required is a required argument/, 'exception matches expected' );
    }

    my $plugin = $class->new();
    dies_ok( sub { $plugin->message( %input ) }, 'dies if unable to open file' );
    like( $@, qr/open: filename/, 'exception matches expected' );
}

done_testing;
