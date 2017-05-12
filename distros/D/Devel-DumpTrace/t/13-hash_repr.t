use Devel::DumpTrace ':test';
use PadWalker;
use Test::More tests => 9;
use strict;
use warnings;
use vars qw($global @global %global $GLOBAL $g);
no warnings 'once';

# exercise the  Devel::DumpTrace::hash_repr  function

my %a = (1,'foo','bar',*baz);
my $hash_repr = hash_repr(\%a);
ok($hash_repr eq "1=>'foo';'bar'=>*main::baz"
   || $hash_repr eq "'bar'=>*main::baz;1=>'foo'", 'hash_repr(ref)');

ok(hash_repr( {} ) eq '', 'hash_repr empty');
for my $elem (1, 'foo') {
  my $dump_elem = dump_scalar($elem);
  ok(hash_repr( {$elem,$elem} ) eq "$dump_elem=>$dump_elem",
     'hash_repr single elem')
    or diag(hash_repr( {$elem,$elem} ));
}
ok(hash_repr( {foo=>[1]} ) eq "'foo'=>[1]", 'hash_repr nested array');
ok(hash_repr(undef) eq '', 'hash_repr undef');


{ 
  package Test::Object;
  sub new {
    my ($pkg, $value) = @_;
    bless { attr => $value }, $pkg;
  }
  sub method {
    my $self = shift;
    return reverse $self->{attr};
  }
}
my $object = new Test::Object(42);
my $dump_object = dump_scalar($object);
ok($dump_object =~ /^\{Test::Object: /, 'dump scalar object is labeled');
ok(hash_repr($object) =~ /^Test::Object: /, 'hash_repr(object) is labeled');
ok(hash_repr($object) =~ /'attr'=>42/, 'hash_repr(object) is enumerated');
