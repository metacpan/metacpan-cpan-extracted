use strict;
use warnings;
BEGIN {
  $ENV{DEVEL_CONFESS_OPTIONS} = '';
}
use Carp ();
use Carp::Heavy ();
use Test::More defined &Carp::format_arg
  ? (tests => 5)
  : (skip_all => 'Dump option not supported on ancient carp');

use Devel::Confess qw(dump);

sub Foo::foo {
  die "error";
}

sub Bar::bar {
  Foo::foo(@_);
}

sub Baz::baz {
  Bar::bar(@_);
}

eval { Baz::baz([1]) };
like $@, qr/Foo::foo\(\[1\]\)/, 'references are dumped in arguments';

eval { Baz::baz(["yarp\nnarp"]) };
like $@, qr/Foo::foo\(\["yarp\\nnarp"\]\)/, 'newlines are dumped in escaped form';

Devel::Confess->import('dump');
eval { Baz::baz([[[[]]]]) };
like $@, qr/Foo::foo\(\[\[\['ARRAY\(0x\w+\)'\]\]\]\)/, 'dump option limits depth to 3';

Devel::Confess->import('dump1');
eval { Baz::baz([[[[]]]]) };
like $@, qr/Foo::foo\(\['ARRAY\(0x\w+\)'\]\)/, 'dump1 option limits depth to 1';

Devel::Confess->import('dump0');
eval { Baz::baz([[[[]]]]) };
like $@, qr/Foo::foo\(\[\[\[\[\]\]\]\]\)/, 'dump0 option does not limit depth';
