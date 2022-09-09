#!/usr/bin/env perl

use strict;
use warnings;

use Test::More;
use Test::FailWarnings;
use Test::Fatal;

use JavaScript::QuickJS;

my %legit = (
    max_stack_size => 123456,
    memory_limit => 567887,
    gc_threshold => 1234,
);

my $err = exception { JavaScript::QuickJS->new(%legit) };

ok( !$err, 'new(): no error' );

$err = exception { JavaScript::QuickJS->new()->configure(%legit) };

ok( !$err, 'configure(): no error' );

$err = exception { JavaScript::QuickJS->new( haha => 2, zaza => 7 ) };
like($err, qr<haha.*zaza>, 'new() reports unknowns');

$err = exception { JavaScript::QuickJS->new()->configure( haha => 2, zaza => 7 ) };
like($err, qr<haha.*zaza>, 'configure() reports unknowns');

for my $key (sort keys %legit) {
    my $err = exception {
        JavaScript::QuickJS->new( $key => -$legit{$key} );
    };

    ok($err, "new($key): error on negative");

    $err = exception {
        JavaScript::QuickJS->new()->configure( $key => -$legit{$key} );
    };

    ok($err, "configure($key): error on negative");
}

done_testing;

1;
