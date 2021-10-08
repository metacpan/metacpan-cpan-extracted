package MyTest::Utils;

use Test2::V0;
use Test2::API qw[ context ];

use Exporter 'import';

our @EXPORT_OK = qw( drain );

sub drain {
    my ( $iter, $max, $sentinel ) = @_;

    my $cnt = 0;
    eval {
        if ( defined $sentinel ) {
            1 while $sentinel != <$iter> && ++$cnt < $max + 1;
        }
        else {
            1 while defined <$iter> && ++$cnt < $max + 1;
        }
    };

    my $err = $@;

    my $ctx = context();

    is( $cnt, $max, "not enough or too few iterations" );

    $ctx->release;

    die $@ if $@
}

1;
