#! perl

use v5.26;
use strict;

use Test::More tests => 5;
use JSON::Relaxed::Parser;
note("JSON::Relaxed version $JSON::Relaxed::VERSION\n");

# Spec say: Commas are optional between objects pairs and array items.

my $json = <<'EOD';
{
 buy: [milk, eggs, butter , `dog bones`,],
 tasks: [ {name:exercise, completed:false,}, {name:eat, completed:true,}, ],
}
EOD
my $p = JSON::Relaxed::Parser->new;
$p->booleans = [ 'F', 'T' ];
my $res = $p->parse($json);
my $xp = { buy => [ qw(milk eggs butter), "dog bones" ],
	   tasks => [ { name => "exercise", completed => 'F' },
		      { name => "eat", completed => 'T' } ]
	 };
is_deeply( $res, $xp, "commas between elements" );
diag($p->err_msg) if $p->is_error;

my $json = <<'EOD';
{
 buy: [milk eggs butter 'dog bones']
 tasks: [ {name:exercise completed:false} {name:eat completed:true} ]
}
EOD
$p = JSON::Relaxed::Parser->new( booleans => [qw(F T)] );
$res = $p->parse($json);
is_deeply( $res, $xp, "no commas between elements" );
diag($p->err_msg) if $p->is_error;

my $json = <<'EOD';
{
 buy: [ , milk eggs butter 'dog bones']
 tasks: [ {name:exercise completed:false} {name:eat completed:true} ]
}
EOD
$p = JSON::Relaxed::Parser->new( strict => 1, booleans => [qw(F T)] );
$p->croak_on_error = 0;
$res = $p->parse($json);
ok( !defined($res), "no leading comma" );
like($p->err_msg, qr/unexpected token in array/, "leading comma error" );

$p->strict = 0;
$res = $p->parse($json);
is_deeply( $res, $xp, "leading comma (no strict)" );
diag($p->err_msg) if $p->is_error;
