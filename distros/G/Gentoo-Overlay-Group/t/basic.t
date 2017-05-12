use strict;
use warnings;

use Test::More;
use Test::Fatal;
use Gentoo::Overlay::Group;
use Test::Output qw( stderr_from );
use FindBin;

my $base = "$FindBin::Bin/../corpus";

my $e;

sub need_fail_ident {
  my ( $exception, $reason, $ident ) = @_;
  my $needs_diag = 0;
  if ( not isnt( $exception, undef, $reason . ': Exception is thrown' ) ) {
    note "Setting needs_diag";
    $needs_diag = 1;
  }
  if ( not $needs_diag ) {
    if ( not isa_ok( $exception, 'Gentoo::Overlay::Exceptions', $reason . ': Exception is an object' ) ) {
      note "setting needs_diag";
      $needs_diag = 1;
    }
  }
  else {
    fail( "FORCED FAIL:" . $reason . ': Exception is an object' );
  }
  if ( not $needs_diag ) {
    if ( not is( $exception->ident, $ident, $reason . ': Ident is \'' . $ident . '\'' ) ) {
      note "setting needs_diag";
      $needs_diag = 1;
    }
  }
  else {
    fail( "FORCED FAIL:" . $reason . ': Ident is \'' . $ident . '\'' );
  }
  if ($needs_diag) {
    diag($exception);
  }
}

my $g;

is(
  exception {
    $g = Gentoo::Overlay::Group->new();
  },
  undef,
  'Can initialize a group empty'
);

is(
  exception {
    $g = Gentoo::Overlay::Group->new();
    $g->add_overlay("$base/overlay_2");
  },
  undef,
  "Loading an overlay from a string path should work"
);

is(
  exception {
    $g = Gentoo::Overlay::Group->new();
    require Path::Tiny;
    $g->add_overlay( Path::Tiny::path("$base/overlay_2") );

  },
  undef,
  "Loading an overlay from a Path::Tiny path should work"
);

is(
  exception {
    $g = Gentoo::Overlay::Group->new();
    my $i = Gentoo::Overlay->new( path => "$base/overlay_2" );
    $g->add_overlay($i);
  },
  undef,
  "Loading an overlay from a Gentoo::Overlay should work"
);

need_fail_ident(
  exception {
    $g = Gentoo::Overlay::Group->new();
    my $i = Gentoo::Overlay->new( path => "$base/overlay_2" );
    $g->add_overlay($i);
    $g->add_overlay($i);
  },
  'Shouldn\'t be able to add the same overlay multiple times',
  'overlay exists',
);
is(
  exception {
    $g = Gentoo::Overlay::Group->new();
    my $i = Gentoo::Overlay->new( path => "$base/overlay_2" );
    $g->add_overlay($i);
    $g->add_overlay("$base/overlay_4");
    $g->add_overlay("$base/overlay_5");
  },
  undef,
  'Should be able to add multiple overlays',
);
need_fail_ident(
  exception {
    $g = Gentoo::Overlay::Group->new();
    $g->add_overlay(undef);
  },
  'Unrecognised input types should be rejected',
  'bad overlay type',
);

need_fail_ident(
  exception {
    $g = Gentoo::Overlay::Group->new();
    $g->add_overlay( Gentoo::Overlay::Group->new() );
  },
  'Unrecognised input types should be rejected',
  'bad overlay object type',
);

need_fail_ident(
  exception {
    $g = Gentoo::Overlay::Group->new();
    my $i = Gentoo::Overlay->new( path => "$base/overlay_2" );
    $g->add_overlay($i);
    $g->iterate( foo => sub { } );
  },
  'Bad iteration types should bail',
  'bad iteration method'
);

done_testing;

