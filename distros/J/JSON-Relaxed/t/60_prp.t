#! perl

use v5.26;
use strict;

use Test::More tests => 1;
use JSON::Relaxed;
note("JSON::Relaxed version $JSON::Relaxed::VERSION\n");

# PRP extensions.

my $json = <<'EOD';
# PRP extensions.
buy.now: [milk, eggs, butter , dog.bones]
and { more = 1 less = 2 }
EOD

# Use combined keys.
my $p = JSON::Relaxed::Parser->new( croak_on_error => 0,
				    prp => 1 );
my $res = $p->parse($json);
my $xp = { buy => { now => [ qw(milk eggs butter), "dog.bones" ] },
	   and => { less => 2, more => 1 }
	 };
is_deeply( $res, $xp, "prp" );
diag($p->err_msg) if $p->is_error;

