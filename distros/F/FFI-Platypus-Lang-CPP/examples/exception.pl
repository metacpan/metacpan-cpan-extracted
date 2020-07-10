use strict;
use warnings;

package Foo;

use FFI::Platypus 1.00;
use FFI::Platypus::Memory qw( malloc free );

my $ffi = FFI::Platypus->new( api => 1 );
$ffi->lang('CPP');
$ffi->lib('./exception.so');

$ffi->custom_type( Foo => {
  native_type => 'opaque',
  perl_to_native => sub { ${ $_[0] } },
  native_to_perl => sub { bless \$_[0], 'Foo' },
});

$ffi->attach( [ 'Foo_new'        => 'new'      ] => []       => 'Foo' );
$ffi->attach( [ 'Foo_delete'     => 'DESTROY'  ] => ['Foo']  => 'void' );
$ffi->attach( [ 'Foo::get_bar()' => 'get_bar'  ] => ['Foo']  => 'int'  );
$ffi->attach( [ 'Foo_set_bar'    => '_set_bar' ] => ['Foo','int']
                                                             => 'void' );

sub set_bar
{
  my($self, $value) = @_;
  $self->_set_bar($value);
  my $error = FooException->get_exception;
  die $error if $error;
}

package FooException;

use overload '""' => sub { "exception: " . $_[0]->message . "\n" };

$ffi->custom_type( FooException => {
  native_type => 'opaque',
  perl_to_native => sub { ${ $_[0] } },
  native_to_perl => sub {
    defined $_[0]
    ? (bless \$_[0], 'FooException')
    : ();
  },
});

$ffi->attach(
  [ 'Foo_get_exception' => 'get_exception' ] => [] => 'FooException'
);

$ffi->attach(
  [ 'FooException::message()' => 'message' ] => ['FooException'] => 'string'
);

package main;

my $foo = Foo->new;

print $foo->get_bar, "\n";  # 0
$foo->set_bar(22);
print $foo->get_bar. "\n";  # 22

$foo->set_bar(-2);
