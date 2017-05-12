use strict;
use Test::More tests => 13;

use_ok('Gtk2::Ex::FormFactory');

my $context = Gtk2::Ex::FormFactory::Context->new (
	default_get_prefix => "g_",
	default_set_prefix => "s_",
);

ok ($context->get_default_get_prefix eq 'g_', "default_get_prefix");
ok ($context->get_default_set_prefix eq 's_', "default_get_prefix");

my $o1 = MyObj->new ( foo => "1foo_$$", bar => "1bar_$$" );
my $o2 = MyObj->new ( foo => "2foo_$$", bar => "2bar_$$" );

ok ( $context->add_object ( name => "o1", object => $o1 ), "add_object1" );
ok ( $context->add_object ( name => "o2", object => $o2 ), "add_object2" );
ok ( $context->get_object("o1") eq $o1, "get_object" );

my $o3 = MyObj->new ( foo => "3foo_$$", bar => "2bar_$$" );

ok ( $context->set_object(o1 => $o3),   "set_object" );
ok ( $context->get_object("o1") eq $o3, "set_object verify" );
ok ( $context->set_object(o1 => $o1),   "set_object change back" );

ok ( $context->get_proxy("o1")->get_attr("foo") eq "1foo_$$", "get_attr" );

ok ( $context->get_proxy("o1")->set_attrs (
  {
    foo => "1bla",
    bar => "1foo"
  },
), "set_attrs");

ok ( $context->get_proxy("o1")->get_attr("foo") eq "1bla", "set_attr verify foo");
ok ( $context->get_proxy("o1")->get_attr("bar") eq "1foo", "set_attr verify bar");

package MyObj;

sub g_foo { shift->{foo}         }
sub g_bar { shift->{bar}         }
sub s_foo { shift->{foo} = $_[1] }
sub s_bar { shift->{bar} = $_[1] }

sub new {
  my $class = shift;
  my %par = @_;
  my ($foo, $bar) = @par{'foo','bar'};
  my $self = bless { foo => $foo, bar => $bar }, $class;
  return $self;
}
