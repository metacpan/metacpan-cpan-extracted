#!perl -w

use strict ;

use Test ;

# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

######################### We start with some black magic to print on failure.

my $loaded ;

END {
   print "not ok 1\n" unless $loaded ;
}

use Eesh qw( :all ) ;

my @tests ;

sub r {
   my $v = e_recv( @_ ) ;
   return defined $v ? $v : '<undef>' ;
}

sub eesh {
   my $cmd = "eesh -ewait '$_[0]'" ;
   my $r = `$cmd` ;
   chomp $r ;
   $r ;
}


sub eesh_list {
   my $cmd = "eesh -ewait '$_[0]'" ;
   join( ',', map { s/^\s*// ; chomp ; $_ } split( /\n/, `$cmd` ) ) ;
}

my @backgrounds ;
my @windows ;


BEGIN {

my $got_eesh ;

eval {
   $got_eesh = eesh( 'window_list' ) ;
} ;

@tests = (

sub {
   $loaded = 1 ;
   ok( 1 ) ;
},

sub { e_open() ; ok( 1 ) ; },

(
   map {
      (
         sub { e_send( 'nop' ) ; ok( 1 ) },
	 sub { ok( r(),        'nop' ) },
	 sub { ok( r( 'nop' ), 'nop' ) },
      )
   } (1..4)
),

sub { my $rs = e_recv( { non_blocking => 1 } ) ; ok( 1 ) },

sub {
   @windows = e_window_list ;
   ok( @windows > 0 ) ;
},

map { $got_eesh ? $_ : sub { skip( 1, 1 ) } } (
   sub { ok( join( ',', @windows ), eesh_list( 'window_list' ) ) },

   ##
   ## backgrounds
   sub {
      @backgrounds = e_backgrounds ;
      ok( join( ',', @backgrounds ), eesh_list( 'background' ) )
   },

   sub { 
      e_set_background( 'Eesh_test_foo', 'bg.tile' => 1 ) ;
      my $v = e_background 'Eesh_test_foo' ;
      ok( $v->{'bg.tile'}, 1 ) ;
   },

   sub {
      e_delete_background( 'Eesh_test_foo' ) ;
      sleep 1 ;
      my $v = e_recv { non_blocking => 1 } ;
      ok( defined $v ? $v : '', '' ) ;
   },

),

sub { ok( (e_internal_list( 'Eesh_foo' ))[0], qr/^Error/ ) },
sub { ok( (e_list_class(    'Eesh_foo' ))[0], qr/^Error/ ) },

sub { e_list_themes ; ok( 1 ) },
sub { e_modules;      ok( 1 ) },

sub { ok( join( ',', Eesh::_clip_ids( ' 0bca :', '432134' ) ), '0bca,432134' )},

sub { ok( e_fileno ) },

sub { ok( e_focused, qr/[0-9a-fA-F]/ ) },
sub { ok( e_focused, e_set_focus( '?' ) ) },

sub { ok( e_win_op( $windows[0], 'iconify', '?' ), qr/yes|no/ ) },

) ;

plan tests => scalar( @tests ) ;

}


$_->() for ( @tests ) ;

######################### End of black magic.

# Insert your test code below (better if it prints "ok 13"
# (correspondingly "not ok 13") depending on the success of chunk 13
# of the test code):

