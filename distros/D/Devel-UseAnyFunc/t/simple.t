use strict;
use Test;
BEGIN { plan tests => 11 }

require Devel::UseAnyFunc;
ok(1); 

{
  package Foo;
  $INC{'Foo.pm'} = __FILE__;
  sub foo { "foo" }
}

{
  package Bar;
  $INC{'Bar.pm'} = __FILE__;
  sub foo { "bar" }
}

ok( Devel::UseAnyFunc->import( 'foo', Foo => 'foo', Bar => 'foo' ) );
ok( ref UNIVERSAL::can( 'main', 'foo' ) );
ok( foo() eq 'foo' );

ok( Devel::UseAnyFunc->import( 'bar', Bar => 'foo', Foo => 'foo' ) );
ok( ref UNIVERSAL::can( 'main', 'bar' ) );
ok( bar() eq 'bar' );

ok( Devel::UseAnyFunc->import( 'baz', Baz => 'foo', Foo => 'foo' ) );
ok( ref UNIVERSAL::can( 'main', 'baz' ) );
ok( baz() eq 'foo' );

ok( ! eval { Devel::UseAnyFunc->import( 'baz', Baz => 'foo' ) } );
