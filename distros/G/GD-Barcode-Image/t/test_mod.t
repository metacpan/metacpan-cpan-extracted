# test GD::Barcode::Image
use Test::More tests => 5;
use strict;

# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl -Ilib Foo.t'

BEGIN { use_ok('GD::Barcode::Image') };

my ($gdbcim, $image);
#-----------------------
$gdbcim = GD::Barcode::Image->new( "Code39", "ABC123" );
ok( defined($gdbcim), 'new() works, created Code39 barcode' );
ok( defined($gdbcim->{gd_barcode}), '  and object has GD::Barcode member');

$image = $gdbcim->plot_imagick( NoText => 0, Height => 100 );
ok( defined($image), 'plot_imagick() works' );

$image = $gdbcim->plot_gd( NoText => 1, Height => 100 );
ok( defined($image), 'plot_gd() works' );
#-----------------------
