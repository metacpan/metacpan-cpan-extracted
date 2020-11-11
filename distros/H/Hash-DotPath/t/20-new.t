use Test::More;
use Modern::Perl;
use Data::Printer alias => 'pdump';
use Hash::DotPath;

########################################################

my $init = {
    a => 1,
    b => 2,	
};

my $dot = Hash::DotPath->new($init);
isa_ok( $dot, 'Hash::DotPath' );
is_deeply($init, $dot->toHashRef);

$dot = Hash::DotPath->new;
isa_ok( $dot, 'Hash::DotPath' );
is_deeply({}, $dot->toHashRef);

$dot = Hash::DotPath->new( $init, delimiter => '~' );
isa_ok( $dot, 'Hash::DotPath' );
is_deeply($init, $dot->toHashRef);

$dot = Hash::DotPath->new( delimiter => '~' );
isa_ok( $dot, 'Hash::DotPath' );
is_deeply({}, $dot->toHashRef);

done_testing();

#########################################################
