#! perl

use v5.26;
use strict;

use Test::More tests => 3;
use JSON::Relaxed;
note("JSON::Relaxed version $JSON::Relaxed::VERSION\n");

# Extension (combined_keys): a.b:c -> a:{b:c}

my $json = "{ buy.now: [milk, eggs, butter , dog.bones] }";

# Use combined keys.
my $p = JSON::Relaxed::Parser->new;
my $res = $p->parse($json);
my $xp = { buy => { now => [ qw(milk eggs butter), "dog.bones" ] } };
is_deeply( $res, $xp, "combined keys" );
diag($p->err_msg) if $p->is_error;

# But not if strict;
$p->strict = 1;
$res = $p->parse($json);
$xp = { "buy.now" => [ qw(milk eggs butter), "dog.bones" ] };
is_deeply( $res, $xp, "no combined keys (strict)" );
diag($p->err_msg) if $p->is_error;

# Not without combined_keys option.
$p = JSON::Relaxed::Parser->new( combined_keys => 0 );
$res = $p->parse($json);
is_deeply( $res, $xp, "no combined keys (no combined keys)" );
diag($p->err_msg) if $p->is_error;
