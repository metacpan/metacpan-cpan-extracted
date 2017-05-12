# IO::Callback 1.08 t/constructor-args.t
# Check that invalid constructor args are caught
# Check that extra constructor args are passed on to the callback

use strict;
use warnings;

use Test::More;
use Test::NoWarnings;
use Test::Exception;

use IO::Callback;

my $fh_src = IO::Callback->new('<', sub {});

my %constructor_source = (
    package => 'IO::Callback',
    object  => $fh_src,
);

my @extra_constructor_args = (
    [],
    [[]],
    [{}],
    [0],
    [[0]],
    [[1,2,3]],
    [undef],
    [[undef]],
    [1, 2, 3],
    [undef, undef, undef],
    [{}, [], {}, \$fh_src],
);
my $consarg;

sub read_callback {
    is flat(@_), flat(@$consarg), "flattened constructor args consistent";
    return;
}

plan tests => 2 * (@extra_constructor_args + 10) + 1;

while ( my ($src_name, $src) = each %constructor_source ) {
    foreach my $c (@extra_constructor_args) {
        $consarg = $c;
        IO::Callback->new("<", \&read_callback, @$consarg)->getc;
    }

    my $res;

    throws_ok { $res = $src->new }
      q{/^mode missing in IO::Callback::new at /}, "$src_name no mode no sub";

    throws_ok { $res = $src->new(undef) }
      q{/^mode missing in IO::Callback::new at /}, "$src_name undef mode no sub";

    throws_ok { $res = $src->new('r') }
      q{/^invalid mode "r" in IO::Callback::new at /}, "$src_name invalid mode no sub";

    throws_ok { $res = $src->new(undef, undef) }
      q{/^mode missing in IO::Callback::new at /}, "$src_name undef mode undef sub";

    throws_ok { $res = $src->new('r', undef) }
      q{/invalid mode "r" in IO::Callback::new at /}, "$src_name invalid mode undef sub";

    throws_ok { $res = $src->new('r', 'not a coderef') }
      q{/^invalid mode "r" in IO::Callback::new at /}, "$src_name invalid mode invalid sub";

    throws_ok { $res = $src->new('r', sub {}) }
      q{/^invalid mode "r" in IO::Callback::new at /}, "$src_name invalid mode valid sub";

    throws_ok { $res = $src->new('<') }
      q{/^coderef missing in IO::Callback::new at /}, "$src_name valid mode no sub";

    throws_ok { $res = $src->new('<', undef) }
      q{/^coderef missing in IO::Callback::new at /}, "$src_name valid mode undef sub";

    throws_ok { $res = $src->new('<', 1) }
      q{/^non-coderef second argument in IO::Callback::new at /}, "$src_name valid mode invalid sub";
}

sub flat {
    return join ",", map { defined() ? "{$_}" : "undef" } @ARGV;
}

