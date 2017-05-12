use Test::More tests => 15;
BEGIN { unshift @INC , '../lib' }
BEGIN { use_ok('Filter::Object::Simple') };

#########################

my %hash = ( 'abc' => 123, 
             'cba' => 456, );
my @array = (1,2,3,4,5);

ok( %hash.exists( 'abc' ) );
ok( %hash.defined( 'cba' ) );
ok( %hash.delete( 'abc' ) );
ok( %hash.keys() );
ok( %hash.values() );
ok( %hash.keys );
ok( %hash.values );

ok( @array.reverse() );
ok( @array.push(10) );
ok( @array.pop() );
ok( @array.unshift(10) );

ok( @array.grep({ !/1/ }) );
ok( @array.map({ 
        $_++; 
        }) 
);

ok( @array.splice(3) );

