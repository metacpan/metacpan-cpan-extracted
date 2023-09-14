#! perl

use v5.10;
use strict;
use warnings;

use Test2::V0 '!float';
use Data::Dump 'pp';

use Image::DS9;

BEGIN {
    skip_all 'No PDL; skipping'
      unless Image::DS9::HAVE_PDL();
}

use PDL;

use Test::Lib;
use My::Util;

my $ds9 = start_up();
$ds9->frame( 'deleteall' );
$ds9->frame( 'new' );

my $x = zeroes( 20, 20 )->rvals;

subtest 'PDL' => sub {
    for my $attr ( {}, { new => 1 }, { mask => 1 } ) {
        ok( lives { $ds9->array( $x, $attr ) }, 'attr: ' . pp( $attr ) )
          or note_res_error( $ds9 );
    }
};

subtest 'raw' => sub {
    my $p    = $x->get_dataref;
    my @dims = $x->dims;
    for my $attr ( {}, { new => 1 }, { mask => 1 } ) {
        my %attr = ( xdim => $dims[0], ydim => $dims[1], bitpix => -64, %$attr );
        ok( lives { $ds9->array( $$p, \%attr ) }, 'attr: ' . pp( \%attr ) )
          or note_res_error( $ds9 );
    }
};

my $p = $x->get_dataref;

my @dims = $x->dims;
ok( lives { $ds9->array( $$p, { xdim => $dims[0], ydim => $dims[1], bitpix => -64 } ) },
    'raw array' )
  or note $@;

done_testing;
