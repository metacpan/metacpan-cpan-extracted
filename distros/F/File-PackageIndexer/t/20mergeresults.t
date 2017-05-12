use strict;
use warnings;

use Test::More tests => 2 + 7*2;
BEGIN { use_ok('File::PackageIndexer') };
use Data::Dumper;

my $indexer = File::PackageIndexer->new();
isa_ok($indexer, 'File::PackageIndexer');
$indexer->clean(0);

my @tests = (
  {
    name => 'one',
    code => <<'HERE',
package Foo;
sub foo {}
our @ISA = ("Baz");

package Bar;
use base 'Foo';
sub bar {}
HERE
    'cmp' => {
      Foo => {
        name => 'Foo', subs => {foo => 1},
        isa_cleared_at_runtime => 1, #isa_cleared_at_compiletime => 0,
        isa => ['Baz'], begin_isa => [],
        isa_push => ['Baz'], isa_unshift => [],
      },
      Bar => {
        name => 'Bar', subs => {bar => 1},
        #isa_cleared_at_runtime => 0, isa_cleared_at_compiletime => 0,
        isa => ['Foo'], begin_isa => ['Foo'],
        isa_push => [], isa_unshift => [],
      },
    },
  },

  {
    name => 'two',
    code => <<'HERE',
package Baz;
sub baz {}
use parent 'Foo';
push @ISA, 'Bar';
HERE
    'cmp' => {
      Foo => {
        name => 'Foo', subs => {foo => 1},
        isa_cleared_at_runtime => 1, #isa_cleared_at_compiletime => 0,
        isa => ['Baz'], begin_isa => [],
        isa_push => ['Baz'], isa_unshift => [],
      },
      Bar => {
        name => 'Bar', subs => {bar => 1},
        #isa_cleared_at_runtime => 0, isa_cleared_at_compiletime => 0,
        isa => ['Foo'], begin_isa => ['Foo'],
        isa_push => [], isa_unshift => [],
      },
      Baz => {
        name => 'Baz', subs => {baz => 1},
        #isa_cleared_at_runtime => 0, isa_cleared_at_compiletime => 0,
        isa => ['Foo', 'Bar'], begin_isa => ['Foo'],
        isa_push => ['Bar'], isa_unshift => [],
      },
    },
  },

  {
    name => 'three',
    code => <<'HERE',
package Buz;
sub buz {}
use parent 'Foo';
push @ISA, 'Bar';
unshift @ISA, 'Baz';
HERE
    'cmp' => {
      Foo => {
        name => 'Foo', subs => {foo => 1},
        isa_cleared_at_runtime => 1, #isa_cleared_at_compiletime => 0,
        isa => ['Baz'], begin_isa => [],
        isa_push => ['Baz'], isa_unshift => [],
      },
      Bar => {
        name => 'Bar', subs => {bar => 1},
        #isa_cleared_at_runtime => 0, isa_cleared_at_compiletime => 0,
        isa => ['Foo'], begin_isa => ['Foo'],
        isa_push => [], isa_unshift => [],
      },
      Baz => {
        name => 'Baz', subs => {baz => 1},
        #isa_cleared_at_runtime => 0, isa_cleared_at_compiletime => 0,
        isa => ['Foo', 'Bar'], begin_isa => ['Foo'],
        isa_push => ['Bar'], isa_unshift => [],
      },
      Buz => {
        name => 'Buz', subs => {buz => 1},
        #isa_cleared_at_runtime => 0, isa_cleared_at_compiletime => 0,
        isa => ['Baz', 'Foo', 'Bar'], begin_isa => ['Foo'],
        isa_push => ['Bar'], isa_unshift => ['Baz'],
      },
    },
  },

  {
    name => 'four',
    code => <<'HERE',
package Buz;
sub arg {}
HERE
    'cmp' => {
      Foo => {
        name => 'Foo', subs => {foo => 1},
        isa_cleared_at_runtime => 1, #isa_cleared_at_compiletime => 0,
        isa => ['Baz'], begin_isa => [],
        isa_push => ['Baz'], isa_unshift => [],
      },
      Bar => {
        name => 'Bar', subs => {bar => 1},
        #isa_cleared_at_runtime => 0, isa_cleared_at_compiletime => 0,
        isa => ['Foo'], begin_isa => ['Foo'],
        isa_push => [], isa_unshift => [],
      },
      Baz => {
        name => 'Baz', subs => {baz => 1},
        #isa_cleared_at_runtime => 0, isa_cleared_at_compiletime => 0,
        isa => ['Foo', 'Bar'], begin_isa => ['Foo'],
        isa_push => ['Bar'], isa_unshift => [],
      },
      Buz => {
        name => 'Buz', subs => {buz => 1, arg => 1},
        #isa_cleared_at_runtime => 0, isa_cleared_at_compiletime => 0,
        isa => ['Baz', 'Foo', 'Bar'], begin_isa => ['Foo'],
        isa_push => ['Bar'], isa_unshift => ['Baz'],
      },
    },
  },

  {
    name => 'five',
    code => <<'HERE',
package Buz;
sub urg {}
BEGIN { @ISA = () }
HERE
    'cmp' => {
      Foo => {
        name => 'Foo', subs => {foo => 1},
        isa_cleared_at_runtime => 1, #isa_cleared_at_compiletime => 0,
        isa => ['Baz'], begin_isa => [],
        isa_push => ['Baz'], isa_unshift => [],
      },
      Bar => {
        name => 'Bar', subs => {bar => 1},
        #isa_cleared_at_runtime => 0, isa_cleared_at_compiletime => 0,
        isa => ['Foo'], begin_isa => ['Foo'],
        isa_push => [], isa_unshift => [],
      },
      Baz => {
        name => 'Baz', subs => {baz => 1},
        #isa_cleared_at_runtime => 0, isa_cleared_at_compiletime => 0,
        isa => ['Foo', 'Bar'], begin_isa => ['Foo'],
        isa_push => ['Bar'], isa_unshift => [],
      },
      Buz => {
        name => 'Buz', subs => {buz => 1, arg => 1, urg => 1},
        #isa_cleared_at_runtime => 0,
        isa_cleared_at_compiletime => 1,
        isa => ['Baz', 'Bar'], begin_isa => [],
        isa_push => ['Bar'], isa_unshift => ['Baz'],
      },
    },
  },

  {
    name => 'six',
    code => <<'HERE',
package Buz;
BEGIN { @ISA = ('Fargle') }
use base 'Furgle';
unshift @ISA, 'Forgle';
push @ISA, 'RunningOutOfNames';
HERE
    'cmp' => {
      Foo => {
        name => 'Foo', subs => {foo => 1},
        isa_cleared_at_runtime => 1, #isa_cleared_at_compiletime => 0,
        isa => ['Baz'], begin_isa => [],
        isa_push => ['Baz'], isa_unshift => [],
      },
      Bar => {
        name => 'Bar', subs => {bar => 1},
        #isa_cleared_at_runtime => 0, isa_cleared_at_compiletime => 0,
        isa => ['Foo'], begin_isa => ['Foo'],
        isa_push => [], isa_unshift => [],
      },
      Baz => {
        name => 'Baz', subs => {baz => 1},
        #isa_cleared_at_runtime => 0, isa_cleared_at_compiletime => 0,
        isa => ['Foo', 'Bar'], begin_isa => ['Foo'],
        isa_push => ['Bar'], isa_unshift => [],
      },
      Buz => {
        name => 'Buz', subs => {buz => 1, arg => 1, urg => 1},
        #isa_cleared_at_runtime => 0,
        isa_cleared_at_compiletime => 1,
        isa => ['Forgle', 'Baz', 'Fargle', 'Furgle', 'Bar', 'RunningOutOfNames'], begin_isa => ['Fargle', 'Furgle'],
        isa_push => ['Bar', 'RunningOutOfNames'], isa_unshift => ['Forgle', 'Baz'],
      },
    },
  },


  {
    name => 'seven',
    code => <<'HERE',
package Buz;
@ISA = ();
push @ISA, 'Foo';
HERE
    'cmp' => {
      Foo => {
        name => 'Foo', subs => {foo => 1},
        isa_cleared_at_runtime => 1, #isa_cleared_at_compiletime => 0,
        isa => ['Baz'], begin_isa => [],
        isa_push => ['Baz'], isa_unshift => [],
      },
      Bar => {
        name => 'Bar', subs => {bar => 1},
        #isa_cleared_at_runtime => 0, isa_cleared_at_compiletime => 0,
        isa => ['Foo'], begin_isa => ['Foo'],
        isa_push => [], isa_unshift => [],
      },
      Baz => {
        name => 'Baz', subs => {baz => 1},
        #isa_cleared_at_runtime => 0, isa_cleared_at_compiletime => 0,
        isa => ['Foo', 'Bar'], begin_isa => ['Foo'],
        isa_push => ['Bar'], isa_unshift => [],
      },
      Buz => {
        name => 'Buz', subs => {buz => 1, arg => 1, urg => 1},
        isa_cleared_at_runtime => 1,
        isa_cleared_at_compiletime => 1,
        isa => ['Foo'], begin_isa => ['Fargle', 'Furgle'],
        isa_push => ['Foo'], isa_unshift => [],
      },
    },
  },
);

my $result = {};
foreach my $test (@tests) {
  my $name = $test->{name};
  my $code = $test->{code};
  my $ref = $test->{"cmp"};
  my $index = $indexer->parse($code);
  $result = File::PackageIndexer->merge_results($result, $index);
  is_deeply($result, $ref, "equivalence test: $name") or warn Dumper $result;
}


$result = {};
foreach my $test (@tests) {
  my $name = $test->{name};
  my $code = $test->{code};
  my $ref = $test->{"cmp"};
  my $index = $indexer->parse($code);
  File::PackageIndexer->merge_results_inplace($result, $index);
  is_deeply($result, $ref, "equivalence test inplace: $name") or warn Dumper $result;
}

