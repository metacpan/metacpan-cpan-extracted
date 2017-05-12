package main;

use strict;
use Test::More;
use My::Filter;

BEGIN {
    plan (tests => 3);
}

my $tf = My::Filter->new(
	log_rejects => 0,
	strip_comments => 1,
);

is( $tf->on_start_document(1), undef, "empty callback methods created.");

$b = 'b';
$tf->on_open_tag(\$b);
is($b, 'strong', "callback method overridden in subclass.");

is( $tf->filter(qq|<b>wake up</b>|), qq|<strong>wake up</strong>|, "subclass triggerpoints working. text modified.");

