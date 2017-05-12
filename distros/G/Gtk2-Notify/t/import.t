#!perl

use strict;
use warnings;
use Test::More tests => 10;

ok(  try_load(),     'use without args'               );
ok(  try_load(0.01), 'use with recent version number' );
ok( !try_load(9.21), 'use with newer version number'  );

ok( !Gtk2::Notify->is_initted, 'not initted yet' );

ok( !try_load('-init'), 'use with invalid -init' );
like( $@, qr/^-init requires the application name/, 'good error message' );

ok( try_load('-init', '"test"'), 'proper use with -init' );
ok( Gtk2::Notify->is_initted,  'initialized properly'  );

ok(  try_load(0.01, '-init', '"test"'), 'use with version and -init' );
ok(  try_load('-init', '"test"', 0.01), 'use with -init and version' );

sub try_load {
    my (@imports) = @_;
    my $module = 'Gtk2::Notify';
    my $imports = join(', ', @imports);

    eval <<"USE";
use $module $imports;
USE

    return !$@;
}
