use Test::More tests => 6;

BEGIN { use_ok( 'HTML::TableParser' ); }

require './t/counts.pl';


{
  package Foo;
  sub new
  {
    my $this = shift;
    my $class = ref($this) || $this;

    my $self = {};
    bless $self, $class;
  }

  sub start { shift; &::start }
  sub end   { shift; &::end }
  sub hdr   { shift; &::hdr }
  sub row   { shift; &::row }
}

my $foo = Foo->new();

our %req = ( id => 'DEFAULT', class => 'Foo' );
run( %req );
