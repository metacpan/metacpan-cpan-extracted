use lib qw|./lib ./blib/lib|;
use strict;
use warnings;
use Haineko::CLI::Password;
use Test::More;

my $modulename = 'Haineko::CLI::Password';
my $pkgmethods = [ 'options', 'new', 'version' ];
my $objmethods = [ 
    'stdin', 'stdout', 'stderr', 'r', 'v', 'e', 'p',
    'makepf', 'readpf', 'removepf', 'make', 'validate',
];
my $testobject = $modulename->new( 
    'verbose' => 2,
    'runmode' => 1,
);

isa_ok $testobject, $modulename;
can_ok $modulename, @$pkgmethods;
can_ok $testobject, @$objmethods;

CLASS_METHODS: {
    my $v = $modulename->options;
    isa_ok( $v, 'HASH' );
}

INSTANCE_METHODS: {

    my $v = undef;
    ok( $testobject->parseoptions );
    $testobject->{'params'}->{'password'} = 'haineko22';
    $testobject->r(1);
    $v = $testobject->make;
    ok( $v, $v );
    like( $v, qr|{SSHA}| );

    $testobject->{'params'}->{'username'} = 'shironeko';
    $testobject->r(1);
    $v = $testobject->make;
    ok( $v, $v );
    like( $v, qr|\Ashironeko: '{SSHA}| );

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


