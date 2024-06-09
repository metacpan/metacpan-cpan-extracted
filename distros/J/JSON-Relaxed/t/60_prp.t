#! perl

use v5.26;
use strict;

use Test::More tests => 7;
use JSON::Relaxed;
note("JSON::Relaxed version $JSON::Relaxed::VERSION\n");

# PRP extensions.

my $json = <<'EOD';
# PRP extensions.
buy.now: [milk, eggs, butter , dog.bones]
and { more = 1 less = 2 }
booleans : [ 0 1 false true off on ]
EOD

# Use combined keys.
my $p = JSON::Relaxed::Parser->new( croak_on_error => 0,
				    prp => 1 );
my $res = $p->parse($json);
my $xp = { buy => { now => [ qw(milk eggs butter), "dog.bones" ] },
	   and => { less => 2, more => 1 },
	   booleans => [ 0, 1, qw( false true false true ) ]
	 };
is_deeply( $res, $xp, "prp" );
diag($p->err_msg) if $p->is_error;
$res = $p->parse($json);
ok( !$res->{booleans}->[$_], "!bools$_ (".$res->{booleans}->[$_].")" ) for 0,2,4;
ok( !!$res->{booleans}->[$_], "!!bools$_ (".$res->{booleans}->[$_].")" ) for 1,3,5;


