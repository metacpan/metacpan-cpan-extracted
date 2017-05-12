use strict;
use warnings;
use Test::More tests => 8;
use Test::Exception;
use FindBin;
use lib "$FindBin::Bin/lib";
use Gearman::Driver;
use POE;
use Gearman::Driver::Test::Loader::Empty;

{
    my $e = Gearman::Driver::Test::Loader::Empty->new();

    isa_ok( $e, 'Gearman::Driver::Test::Loader::Empty', 'Role works' );

    lives_ok { $e->namespaces( [qw(Gearman::Driver::Test::Live)] ) } 'namespaces method/attribute';

    is_deeply( [ $e->get_namespaces ], [qw(Gearman::Driver::Test::Live)], 'get_namespaces method/attribute' );

    lives_ok {
        $e->wanted(
            sub {
                return 1 if /Begin|Max|Spread/;
                return 0;
            }
        );
    }
    'wanted method/attribute';

    lives_ok { $e->load_namespaces } 'load_namespaces method/attribute';

    is_deeply(
        [ $e->get_modules ],
        [
            'Gearman::Driver::Test::Live::BeginEnd', 'Gearman::Driver::Test::Live::MaxIdleTime',
            'Gearman::Driver::Test::Live::Spread'
        ],
        'get_modules method/attribute'
    );
}

{
    my $e = Gearman::Driver::Test::Loader::Empty->new();
    $e->namespaces( [qw(Gearman::Driver::Test::Live::Prefix)] );
    lives_ok { $e->load_namespaces } 'load_namespaces method/attribute';
    is_deeply( [ $e->get_modules ], ['Gearman::Driver::Test::Live::Prefix'], 'loading a module directly works' );
}
