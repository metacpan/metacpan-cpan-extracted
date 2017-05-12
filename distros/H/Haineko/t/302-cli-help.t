use lib qw|./lib ./blib/lib|;
use strict;
use warnings;
use Haineko::CLI::Help;
use Test::More;

my $modulename = 'Haineko::CLI::Help';
my $pkgmethods = [ 'new', 'version', 'which' ];
my $objmethods = [ 
    'stdin', 'stdout', 'stderr', 'r', 'v', 'e', 'p',
    'makepf', 'readpf', 'removepf', 'add', 'mesg',
];
my $testobject = $modulename->new( 
    'verbose' => 2,
    'runmode' => 2,
);

isa_ok $testobject, $modulename;
can_ok $modulename, @$pkgmethods;
can_ok $testobject, @$objmethods;

CLASS_METHODS: {
    ok $modulename->which('ls');
}

INSTANCE_METHODS: {

    for my $e ( 'option', 'example', 'subcommand' ) {
        isa_ok( $testobject->params->{ $e }, 'ARRAY' );
        is( scalar @{ $testobject->params->{ $e } }, 0 );

        $testobject->add( [ 'neko' => 'nyaa' ], $e );
        is( scalar @{ $testobject->params->{ $e } }, 2 );

        $testobject->add( [ 'nyaa' => 'neko' ], substr($e,0,1) );
        is( scalar @{ $testobject->params->{ $e } }, 4 );
    }

    isa_ok $testobject->add( [ 'mike' => 'neko' ], 'cat' ), 'HASH';
    isa_ok $testobject->add(undef), 'HASH';
    isa_ok $testobject->add('cat'), 'HASH';
    isa_ok $testobject->add( {} ),  'HASH';
}

done_testing;
__END__
