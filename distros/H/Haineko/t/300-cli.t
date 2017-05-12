use lib qw|./lib ./blib/lib|;
use strict;
use warnings;
use Haineko::CLI;
use Test::More;

my $modulename = 'Haineko::CLI';
my $pkgmethods = [ 'new', 'version', 'which' ];
my $objmethods = [ 
    'stdin', 'stdout', 'stderr', 'r', 'v', 'e', 'p',
    'makepf', 'readpf', 'removepf', 'makerf', 'removerf',
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
    is $modulename->which('neko'), q();
    ok $modulename->which('ls');
    is $modulename->which(), q();
    ok $modulename->version;
    isa_ok $testobject->new, 'Haineko::CLI';

    is $modulename->help, q();
    for my $e ( 'option', 'subcommand', 'example' ) {
        isa_ok $modulename->help( $e ), 'ARRAY';
        isa_ok $modulename->help( substr( $e, 0, 1 ) ), 'ARRAY';
    }
}

INSTANCE_METHODS: {
    $testobject->makepf;
    ok -e $testobject->pidfile;
    ok -f $testobject->pidfile;
    ok -s $testobject->pidfile;
    like $testobject->pidfile, qr|\A/tmp/haineko-make-test-\d+[.]pid\z|;

    $testobject->makerf( [ 1, 2, 3 ] );
    ok -e $testobject->runfile;
    ok -f $testobject->runfile;
    ok -s $testobject->runfile;
    like $testobject->runfile, qr|\A/tmp/haineko-make-test-\d+[.]sh\z|;

    is $testobject->v, 2;
    is $testobject->v(4), 4;
    is $testobject->r, 2;
    is $testobject->r(4), 4;

    isa_ok $testobject->started, 'Time::Piece';
    ok $testobject->started->epoch;
    ok $testobject->started->ymd;

    isa_ok $testobject->stream, 'HASH';
    like $testobject->stdin, qr|\d|;
    like $testobject->stdout, qr|\d|;
    like $testobject->stderr, qr|\d|;

    isa_ok $testobject->logging, 'HASH';
    is $testobject->logging->{'disabled'}, 1;
    is $testobject->logging->{'facility'}, 'local2';

    ok $testobject->command;
    ok $testobject->readpf;

    $testobject->removepf;
    ok( ! -e $testobject->pidfile );

    $testobject->removerf;
    ok( ! -e $testobject->runfile );

    is $testobject->e, 0;
    ok $testobject->e( 'E', 1 );

    is $testobject->p, 0;
    is $testobject->p( 'P', 0 ), 0;
}

done_testing;
__END__
