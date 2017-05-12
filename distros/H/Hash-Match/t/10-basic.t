use Test::More 0.98;
use Test::Exception;
use if $ENV{RELEASE_TESTING}, 'Test::Warnings';

use_ok('Hash::Match');

subtest "single key rule" => sub {

    my $m = Hash::Match->new( rules => { k => '1' } );
    isa_ok($m, 'Hash::Match');

    ok !$m->( {} ), 'fail';

    ok $m->( { k => 1 } ),  'match';
    ok !$m->( { k => 2 } ), 'fail';
    ok !$m->( { j => 1 } ), 'fail';
};

subtest "single key -not rule" => sub {
    my $m = Hash::Match->new( rules => { -not => { k => '1' } } );
    isa_ok($m, 'Hash::Match');

    ok !$m->( { k => 1 } ), 'fail';
    ok $m->( { k => 2 } ),  'match';
    ok $m->( { j => 1 } ),  'match';
};

subtest "single key -notall rule" => sub {
    my $m = Hash::Match->new( rules => { -notall => { k => '1' } } );
    isa_ok($m, 'Hash::Match');

    ok !$m->( { k => 1 } ), 'fail';
    ok $m->( { k => 2 } ),  'match';
    ok $m->( { j => 1 } ),  'match';
};

subtest "two key -not rule" => sub {
    my $m = Hash::Match->new( rules => { -not => { k => '1', j => 1 } } );
    isa_ok($m, 'Hash::Match');

    ok $m->( { k => 1 } ),  'match';
    ok $m->( { k => 2 } ),  'match';
    ok $m->( { j => 1 } ),  'match';
    ok $m->( { j => 2 } ),  'match';
    ok !$m->( { k => 1, j => 1 } ),  'fail';
};

subtest "two key -notall rule" => sub {
    my $m = Hash::Match->new( rules => { -notall => { k => '1', j => 1 } } );
    isa_ok($m, 'Hash::Match');

    ok $m->( { k => 1 } ),  'match';
    ok $m->( { k => 2 } ),  'match';
    ok $m->( { j => 1 } ),  'match';
    ok $m->( { j => 2 } ),  'match';
    ok !$m->( { k => 1, j => 1 } ),  'fail';
};

subtest "use -not []" => sub {
    my $m = Hash::Match->new( rules => { -not => [ k => '1', j => 1 ] } );
    isa_ok($m, 'Hash::Match');

    ok !$m->( { k => 1 } ), 'fail';
    ok $m->( { k => 2 } ),  'match';
    ok !$m->( { j => 1 } ), 'fail';
    ok $m->( { j => 2 } ),  'match';
    ok !$m->( { k => 1, j => 1 } ),  'fail';
};

subtest "use -notany []" => sub {
    my $m = Hash::Match->new( rules => { -notany => [ k => '1', j => 1 ] } );
    isa_ok($m, 'Hash::Match');

    ok !$m->( { k => 1 } ), 'fail';
    ok $m->( { k => 2 } ),  'match';
    ok !$m->( { j => 1 } ), 'fail';
    ok $m->( { j => 2 } ),  'match';
    ok !$m->( { k => 1, j => 1 } ),  'fail';
};

subtest "use -notany {}" => sub {
    my $m = Hash::Match->new( rules => { -notany => { k => '1', j => 1 } } );
    isa_ok($m, 'Hash::Match');

    ok !$m->( { k => 1 } ), 'fail';
    ok $m->( { k => 2 } ),  'match';
    ok !$m->( { j => 1 } ), 'fail';
    ok $m->( { j => 2 } ),  'match';
    ok !$m->( { k => 1, j => 1 } ),  'fail';
};

subtest "regex match value (all)" => sub {
    my $m = Hash::Match->new( rules => { k => '1', j => qr/\d/, } );
    isa_ok($m, 'Hash::Match');

    ok !$m->( { k => 1 } ), 'fail';
    ok !$m->( { k => 2 } ), 'fail';
    ok !$m->( { j => 1 } ), 'fail';
    ok $m->( { k => 1, j => 3 } ),  'match';
};

subtest "regex match value (any)" => sub {
    my $m = Hash::Match->new( rules => [ k => '1', j => qr/\d/, ] );
    isa_ok($m, 'Hash::Match');

    ok $m->( { k => 1 } ), 'match';
    ok !$m->( { k => 2 } ), 'fail';
    ok $m->( { j => 1 } ), 'match';
    ok $m->( { k => 1, j => 3 } ),  'match';
};

subtest "regex match value (explicit -or)" => sub {
    my $m = Hash::Match->new( rules => { -or => { k => '1', j => qr/\d/, } } );
    isa_ok($m, 'Hash::Match');

    ok $m->( { k => 1 } ), 'match';
    ok !$m->( { k => 2 } ), 'fail';
    ok $m->( { j => 1 } ), 'match';
    ok $m->( { k => 1, j => 3 } ),  'match';
};

subtest "regex match value (explicit -any)" => sub {
    my $m = Hash::Match->new( rules => { -any => { k => '1', j => qr/\d/, } } );
    isa_ok($m, 'Hash::Match');

    ok $m->( { k => 1 } ), 'match';
    ok !$m->( { k => 2 } ), 'fail';
    ok $m->( { j => 1 } ), 'match';
    ok $m->( { k => 1, j => 3 } ),  'match';
};

subtest "regex match value (explicit -or)" => sub {
    my $m = Hash::Match->new( rules => {
        k => '1', -or => [ j => qr/\d/, i => qr/x/, ], } );
    isa_ok($m, 'Hash::Match');

    ok !$m->( { k => 1 } ), 'fail';
    ok !$m->( { k => 2 } ), 'fail';
    ok !$m->( { j => 1 } ), 'fail';
    ok $m->( { k => 1, j => 3 } ),  'match';
    ok $m->( { k => 1, i => 'wxyz' } ),  'match';
    ok !$m->( { k => 1, i => 'abc' } ),  'fail';
};


subtest "regex match value (explicit -any)" => sub {
    my $m = Hash::Match->new( rules => {
        k => '1', -any => [ j => qr/\d/, i => qr/x/, ], } );
    isa_ok($m, 'Hash::Match');

    ok !$m->( { k => 1 } ), 'fail';
    ok !$m->( { k => 2 } ), 'fail';
    ok !$m->( { j => 1 } ), 'fail';
    ok $m->( { k => 1, j => 3 } ),  'match';
    ok $m->( { k => 1, i => 'wxyz' } ),  'match';
    ok !$m->( { k => 1, i => 'abc' } ),  'fail';
};

subtest "regex match value (explicit -and)" => sub {
    my $m = Hash::Match->new( rules => [
        k => '1', -and => { j => qr/\d/, } ] );
    isa_ok($m, 'Hash::Match');

    ok $m->( { k => 1 } ), 'match';
    ok !$m->( { k => 2 } ), 'fail';
    ok $m->( { j => 1 } ), 'match';
    ok $m->( { k => 1, j => 3 } ),  'match';
};

subtest "regex match value (explicit -all)" => sub {
    my $m = Hash::Match->new( rules => [
        k => '1', -all => { j => qr/\d/, } ] );
    isa_ok($m, 'Hash::Match');

    ok $m->( { k => 1 } ), 'match';
    ok !$m->( { k => 2 } ), 'fail';
    ok $m->( { j => 1 } ), 'match';
    ok $m->( { k => 1, j => 3 } ),  'match';
};

subtest "regex match value (explicit -and)" => sub {
    my $m = Hash::Match->new( rules => [
        k => '1', -and => [ j => qr/\d/, ] ] );
    isa_ok($m, 'Hash::Match');

    ok $m->( { k => 1 } ), 'match';
    ok !$m->( { k => 2 } ), 'fail';
    ok $m->( { j => 1 } ), 'match';
    ok $m->( { k => 1, j => 3 } ),  'match';
};

subtest "regex match value (explicit -all)" => sub {
    my $m = Hash::Match->new( rules => [
        k => '1', -all => [ j => qr/\d/, ] ] );
    isa_ok($m, 'Hash::Match');

    ok $m->( { k => 1 } ), 'match';
    ok !$m->( { k => 2 } ), 'fail';
    ok $m->( { j => 1 } ), 'match';
    ok $m->( { k => 1, j => 3 } ),  'match';
};

subtest "regex match value (explicit -and)" => sub {
    my $m = Hash::Match->new( rules => [
        k => '1', -and => { j => qr/\d/, i => qr/x/ } ] );
    isa_ok($m, 'Hash::Match');

    ok $m->( { k => 1 } ), 'match';
    ok !$m->( { k => 2 } ), 'fail';
    ok !$m->( { j => 1 } ), 'fail';
    ok $m->( { k => 1, j => 3 } ),  'match';
    ok !$m->( { k => 2, i => 'xyz' } ),  'fail';
    ok $m->( { k => 2, j => 6, i => 'xyz' } ),  'match';
};


subtest "regex match value (explicit -all)" => sub {
    my $m = Hash::Match->new( rules => [
        k => '1', -all => { j => qr/\d/, i => qr/x/ } ] );
    isa_ok($m, 'Hash::Match');

    ok $m->( { k => 1 } ), 'match';
    ok !$m->( { k => 2 } ), 'fail';
    ok !$m->( { j => 1 } ), 'fail';
    ok $m->( { k => 1, j => 3 } ),  'match';
    ok !$m->( { k => 2, i => 'xyz' } ),  'fail';
    ok $m->( { k => 2, j => 6, i => 'xyz' } ),  'match';
};

subtest "sub match (key exists)" => sub {
    my $m = Hash::Match->new( rules => { k => sub {1} } );
    isa_ok($m, 'Hash::Match');

    ok $m->( { k => 1 } ),  'match';
    ok $m->( { k => 2 } ),  'match';
    ok !$m->( { j => 1 } ), 'fail';
};

subtest "sub match" => sub {
    my $m = Hash::Match->new( rules => { k => sub { $_[0] <= 2 } } );
    isa_ok($m, 'Hash::Match');

    ok $m->( { k => 1 } ),  'match';
    ok $m->( { k => 2 } ),  'match';
    ok !$m->( { k => 3 } ), 'fail';
    ok !$m->( { j => 1 } ), 'fail';
};

subtest "undef value match" => sub {
    my $m = Hash::Match->new( rules => { k => '1', j => undef } );
    isa_ok($m, 'Hash::Match');

    ok $m->( { k => 1, j => undef } ),  'match';
    ok !$m->( { k => 1 } ), 'fail';
    ok !$m->( { j => undef } ), 'fail';
};

subtest "undef value match" => sub {
    my $m = Hash::Match->new( rules => [ k => '1', j => undef ] );
    isa_ok($m, 'Hash::Match');

    ok $m->( { k => 1, j => undef } ),  'match';
    ok $m->( { k => 1 } ), 'match';
    ok $m->( { j => undef } ), 'match';
    ok !$m->( { k => undef } ), 'fail';
};

subtest "regex key match" => sub {
    my $m = Hash::Match->new( rules => [ qr/^k/ => 1, ] );
    isa_ok($m, 'Hash::Match');

    ok $m->( { k_a => 1, k_b => 2 } ),  'match';
    ok !$m->( { k_a => 3, k_b => 2 } ), 'fail';
    ok !$m->( { j_a => 1, j_b => 1 } ), 'fail';

};

subtest "any key match" => sub {
    my $m = Hash::Match->new( rules => [ sub { 1 } => 1, ] );
    isa_ok($m, 'Hash::Match');

    ok $m->( { k_a => 1, k_b => 2 } ),  'match';
    ok !$m->( { k_a => 3, k_b => 2 } ), 'fail';
    ok $m->( { j_a => 1 } ), 'match';

};

subtest "sub key match" => sub {
    my $m = Hash::Match->new( rules => [ sub { my $k = shift; $k =~ /k/; } => 1, ] );
    isa_ok($m, 'Hash::Match');

    ok $m->( { k_a => 1, k_b => 2 } ),  'match';
    ok !$m->( { k_a => 3, k_b => 2 } ), 'fail';
    ok !$m->( { j_a => 1, j_b => 1 } ), 'fail';

};

subtest "regex key match (-or)" => sub {
    my $m = Hash::Match->new( rules => { -or => [ qr/^k/ => 1, ] } );
    isa_ok($m, 'Hash::Match');

    ok $m->( { k_a => 1, k_b => 2 } ),  'match';
    ok !$m->( { k_a => 3, k_b => 2 } ), 'fail';
};

subtest "regex key match (-any)" => sub {
    my $m = Hash::Match->new( rules => { -any => [ qr/^k/ => 1, ] } );
    isa_ok($m, 'Hash::Match');

    ok $m->( { k_a => 1, k_b => 2 } ),  'match';
    ok !$m->( { k_a => 3, k_b => 2 } ), 'fail';
};

subtest "regex key match (-and)" => sub {
    my $m = Hash::Match->new( rules => { -and => [ qr/^k/ => 1, ] } );
    isa_ok($m, 'Hash::Match');

    ok $m->( { k_a => 1, k_b => 1 } ),  'match';
    ok !$m->( { k_a => 1, k_b => 2 } ), 'fail';
    ok !$m->( { k_a => 3, k_b => 2 } ), 'fail';
};


subtest "regex key match (-all)" => sub {
    my $m = Hash::Match->new( rules => { -all => [ qr/^k/ => 1, ] } );
    isa_ok($m, 'Hash::Match');

    ok $m->( { k_a => 1, k_b => 1 } ),  'match';
    ok !$m->( { k_a => 1, k_b => 2 } ), 'fail';
    ok !$m->( { k_a => 3, k_b => 2 } ), 'fail';
};

subtest "exceptions" => sub {

    throws_ok sub {
	my $m = Hash::Match->new( rules => { badkey => { k => '1' } } );
    }, qr/Unsupported key: 'badkey'/, "unrecognized key";

    my $foo = bless {}, 'Foo';

    throws_ok sub {
	my $m = Hash::Match->new( rules => { k => $foo } );
    }, qr/Unsupported type: 'Foo'/, "unrecognized key";


    throws_ok sub {
	my $m = Hash::Match->new( rules => [ qr/k/ => $foo ] );
    }, qr/Unsupported type: 'Foo'/, "unrecognized key";


};

done_testing;
