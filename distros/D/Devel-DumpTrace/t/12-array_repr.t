use Devel::DumpTrace ':test';
use PadWalker;
use Test::More tests => 11;
use strict;
use warnings;
use vars qw($global @global %global $GLOBAL $g);
no warnings 'once';

# exercise the  Devel::DumpTrace::array_repr  function

my @a = (1,'foo','bar',*baz);
ok(array_repr(\@a)
   eq "1,'foo','bar',*main::baz", 'array repr')
  or diag array_repr(\@a); ### >= 01X

ok(array_repr([]) eq '', 'array_repr empty');
for my $elem (undef, 1, 'foo', *glob) {
  ok(array_repr([$elem]) eq dump_scalar($elem), 'array_repr single elem');
}
ok(array_repr([[1]]) eq '[1]', 'array_repr nested array');
ok(array_repr(undef) eq '', 'array_repr undef')
  or diag array_repr(undef);


{ 
  package Test::Object;
  sub new {
    my ($pkg, @list) = @_;
    bless [ @list ], $pkg;
  }
  sub method {
    my $self = shift;
    return join ':', @$self;
  }
}
my $object = new Test::Object(42,43,44);
my $dump_object = dump_scalar($object);
ok($dump_object =~ /^\[Test::Object: /, 'dump scalar object is labeled');
ok(array_repr($object) =~ /^Test::Object: /, 'array_repr(object) is labeled');
ok(array_repr($object) =~ /42,43,44/, 'array_repr(object) enumerates');

