use Test::More;
BEGIN {
  if (eval "use PPI;1") {
    plan tests => 12;
  } else {
    plan skip_all => "PPI not available\n";
  }
}
use strict;
use warnings;
use vars qw($global @global %global $GLOBAL $g);
use Devel::DumpTrace::PPI ':test';
use PadWalker;

# exercise the  Devel::DumpTrace::dump_scalar  function

ok(dump_scalar(4) eq "4", 'dump scalar int') or diag(dunp_scalar(4));
ok(dump_scalar(3.1415) eq "3.1415", 'dump scalar float')
	or diag(dump_scalar(3.1415));
ok(dump_scalar("0E0") eq "0E0", 'dump scalar sci')
	or diag(dump_scalar(0E0));
ok(dump_scalar("word") eq "'word'", 'dump scalar text')
	or diag(dump_scalar("word"));
ok(dump_scalar([1,'foo']) eq "[1,'foo']", 'dump scalar ARRAY ref')
	or diag(dump_scalar([1,'foo']));
my $ds = dump_scalar( {a=>2, b=>'bar'} );
ok($ds eq "{'a'=>2;'b'=>'bar'}"
	|| $ds eq "{'b'=>'bar';'a'=>2}",
   'dump scalar HASH ref') or diag(dump_scalar({a=>2,b=>'bar'}));
ok(dump_scalar(sub { my $foo=42 }) =~ /^CODE/,
   'dump scalar CODE ref');

my $u = 42;
ok(dump_scalar(\$u) =~ /^SCALAR/, 'dump scalar SCALAR ref');
ok(dump_scalar(undef) eq 'undef', 'dump scalar undef');

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
ok($dump_object =~ /'attr'=>42/, 'dump scalar object is expanded');

ok(dump_scalar("foo\n\"bar") eq "\"foo\\n\\\"bar\"",
   'dump scalar string with escapes');
