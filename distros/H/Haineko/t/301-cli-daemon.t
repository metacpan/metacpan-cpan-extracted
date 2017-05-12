use lib qw|./lib ./blib/lib|;
use strict;
use warnings;
use Haineko::CLI::Daemon;
use Test::More;

my $modulename = 'Haineko::CLI::Daemon';
my $pkgmethods = [ 'options', 'default', 'new', 'version', 'which' ];
my $objmethods = [ 
    'stdin', 'stdout', 'stderr', 'r', 'v', 'e', 'p',
    'makepf', 'readpf', 'removepf', 'run', 'ctrl',
];
my $testobject = $modulename->new( 
    'pidfile' => '/tmp/haineko-make-test-'.$$.'.pid',
    'verbose' => 2,
    'runmode' => 2,
);

isa_ok $testobject, $modulename;
can_ok $modulename, @$pkgmethods;
can_ok $testobject, @$objmethods;

CLASS_METHODS: {
    ok( $modulename->which('ls') );
    my $v = undef;

    $v = $modulename->options;
    isa_ok( $v, 'HASH' );

    $v = $modulename->default;
    isa_ok( $v, 'HASH' );
}

INSTANCE_METHODS: {
    is( $testobject->run, 0 );
    is( $testobject->ctrl, undef );
    is( $testobject->parseoptions, 1 );

    my $v = undef;
    $v = $testobject->help('o');
    isa_ok( $v, 'ARRAY' );

    $v = $testobject->help('s');
    isa_ok( $v, 'ARRAY' );

    $v = $testobject->help('e');
    isa_ok( $v, 'ARRAY' );

    $v = $testobject->help();
    is( $v, undef );
}

done_testing;
__END__
