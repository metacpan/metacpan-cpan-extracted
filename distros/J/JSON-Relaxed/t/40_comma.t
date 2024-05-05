#! perl

use v5.26;

use Test::More tests => 4;
use JSON::Relaxed 0.063;
note("JSON::Relaxed version $JSON::Relaxed::VERSION\n");

# Spec say: Commas are optional between objects pairs and array items.

my $json = <<'EOD';
{
 buy: [milk, eggs, butter , `dog bones`,],
 tasks: [ {name:exercise, completed:false,}, {name:eat, completed:true,}, ],
}
EOD
my $p = JSON::Relaxed::Parser->new;
my $res = $p->parse($json);
my $xp = { buy => [ qw(milk eggs butter), "dog bones" ],
	   tasks => [ { name => "exercise", completed => 0 },
		      { name => "eat", completed => 1 } ]
	 };
is_deeply( $res, $xp, "commas between elements" );
diag($p->err_msg) if $p->is_error;

my $json = <<'EOD';
{
 buy: [milk eggs butter 'dog bones']
 tasks: [ {name:exercise completed:false} {name:eat completed:true} ]
}
EOD
$p = JSON::Relaxed::Parser->new;
$res = $p->parse($json);
is_deeply( $res, $xp, "no commas between elements" );
diag($p->err_msg) if $p->is_error;

my $json = <<'EOD';
{
 buy: [ , milk eggs butter 'dog bones']
 tasks: [ {name:exercise completed:false} {name:eat completed:true} ]
}
EOD
$p = JSON::Relaxed::Parser->new;
$p->croak_on_error = 0;
$res = $p->parse($json);
ok( !defined($res), "no leading comma" );
like($p->err_msg, qr/unexpected token in array/, "leading comma error" );
