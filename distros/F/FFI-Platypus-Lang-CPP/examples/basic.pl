use strict;
use warnings;

package Foo;

use FFI::Platypus 1.00;
use FFI::Platypus::Memory qw( malloc free );

my $ffi = FFI::Platypus->new( api => 1 );
$ffi->lang('CPP');
$ffi->lib('./basic.so');

$ffi->custom_type( Foo => {
  native_type => 'opaque',
  perl_to_native => sub { ${ $_[0] } },
  native_to_perl => sub { bless \$_[0], 'Foo' },
});

$ffi->attach( [ 'Foo::Foo()'     => '_new'     ] => ['Foo']  => 'void' );
$ffi->attach( [ 'Foo::~Foo()'    => '_DESTROY' ] => ['Foo']  => 'void' );
$ffi->attach( [ 'Foo::get_bar()' => 'get_bar'  ] => ['Foo']  => 'int'  );
$ffi->attach( [ 'Foo::set_bar(int)'
                                 => 'set_bar'  ] => ['Foo','int']
                                                             => 'void' );

my $size = $ffi->function('Foo::_size()' => [] => 'int')->call;

sub new
{
  my($class) = @_;
  my $ptr = malloc $size;
  my $self = bless \$ptr, $class;
  _new($self);
  $self;
}

sub DESTROY
{
  my($self) = @_;
  _DESTROY($self);
  free($$self);
}

package main;

my $foo = Foo->new;

print $foo->get_bar, "\n";  # 0
$foo->set_bar(22);
print $foo->get_bar. "\n";  # 22
