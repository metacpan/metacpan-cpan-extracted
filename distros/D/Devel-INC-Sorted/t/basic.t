use strict;
use warnings;

use Test::More tests => 12;

BEGIN {
	require_ok 'Devel::INC::Sorted';
	require lib;
}

my @orig_inc = @INC = qw(foo bar gorch);

ok( !tied(@INC), '@INC not tied' );

Devel::INC::Sorted->import(qw(inc_add_floating inc_unfloat_entry inc_float_entry untie_inc));

ok( tied(@INC), '@INC now tied' );

is_deeply( \@INC, \@orig_inc, "same contents as orig" );

inc_add_floating(my $floating_sub = sub { warn "my inc hook" });

is_deeply( \@INC, [ $floating_sub, @orig_inc ], "entry added to head" );

inc_add_floating(my $floating_path = "my_inc_entry");

is_deeply( \@INC, [ $floating_sub, $floating_path, @orig_inc ], "entry added to head" );

inc_unfloat_entry($floating_sub);

is_deeply( \@INC, [ $floating_path, $floating_sub, @orig_inc ], "entry unfloated" );

lib->import("blah");

is_deeply( \@INC, [ $floating_path, "blah", $floating_sub, @orig_inc ], "new entry prepended" );

inc_float_entry($floating_sub);

is_deeply( \@INC, [ $floating_path, $floating_sub, "blah", @orig_inc ], "entry floated over new entry" );

push @INC, "zot";

is_deeply( \@INC, [ $floating_path, $floating_sub, "blah", @orig_inc, "zot" ], "entry floated over new entry" );

untie_inc();

ok( !tied(@INC), "no longer tied" );
is_deeply( \@INC,  [ $floating_path, $floating_sub, "blah", @orig_inc, "zot" ], "still the same" );
