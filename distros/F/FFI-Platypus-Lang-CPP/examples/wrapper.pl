use strict;
use warnings;

package Foo;

use FFI::Platypus 1.00;
use FFI::Platypus::Memory qw( malloc free );

my $ffi = FFI::Platypus->new( api => 1 );
$ffi->lang('CPP');
$ffi->lib('./wrapper.so');

$ffi->custom_type( Foo => {
  native_type => 'opaque',
  perl_to_native => sub { ${ $_[0] } },
  native_to_perl => sub { bless \$_[0], 'Foo' },
});

$ffi->attach( [ 'Foo_new'        => 'new'      ] => []       => 'Foo' );
$ffi->attach( [ 'Foo_delete'     => 'DESTROY'  ] => ['Foo']  => 'void' );
$ffi->attach( [ 'Foo::get_bar()' => 'get_bar'  ] => ['Foo']  => 'int'  );
$ffi->attach( [ 'Foo::set_bar(int)'
                                 => 'set_bar'  ] => ['Foo','int']
                                                             => 'void' );

package main;

my $foo = Foo->new;

print $foo->get_bar, "\n";  # 0
$foo->set_bar(22);
print $foo->get_bar. "\n";  # 22
