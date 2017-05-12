use strict;
use warnings;
use FindBin qw($Bin);
use File::Spec::Functions;
use lib catfile( $Bin, 'lib' );
use Test::More tests => 4;
use Test::Exception;
use Test::MyUtil;
use Iterator::ToArray;

my $to_array = Iterator::ToArray->new( mk_iterator() );
isa_ok( $to_array, 'Iterator::ToArray' );
can_ok( $to_array, qw/new apply to_array/ );

throws_ok(
    sub {
        Iterator::ToArray->new(1);
    },
    qr/not a iterable object/,
    'die ok. not a iterable object'
);

lives_ok(
    sub {
        {
            package Hoge;
            sub new { bless {}, 'Hoge' }
            sub next {1}
        }
        Iterator::ToArray->new( Hoge->new );
    },
    'object has next mehtod',
);
