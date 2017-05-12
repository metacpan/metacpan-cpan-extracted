use strict;
use warnings;

use Test::More;
use Test::Fatal;
use Gentoo::Overlay;
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

need_fail_ident(
  exception {
    my $overlay = Gentoo::Overlay->new();
  },
  'Objects need a path',
  'path parameter required'
);

is(
  exception {
    my $overlay = Gentoo::Overlay->new( path => "$base/overlay_0" );
  },
  undef,
  "Providing path => Success"
);

need_fail_ident(
  exception {
    Gentoo::Overlay->new( path => "$base/overlay_0" )->_profile_dir;
  },
  'Need a profile dir',
  'no profile directory',
);

is(
  exception {
    Gentoo::Overlay->new( path => "$base/overlay_1" )->_profile_dir;
  },
  undef,
  'Having a profile dir => Success'
);

need_fail_ident(
  exception {
    Gentoo::Overlay->new( path => "$base/overlay_1" )->name;
  },
  'Need a repo_name file',
  'no repo_name',
);

is(
  exception {
    Gentoo::Overlay->new( path => "$base/overlay_2" )->name;
  },
  undef,
  'Having a repo_name file => Success'
);

is( Gentoo::Overlay->new( path => "$base/overlay_2" )->name, 'overlay_2', '->name is right' );
my $stderr;
my %cats;
is(
  exception {
    $stderr = stderr_from {
      %cats = Gentoo::Overlay->new( path => "$base/overlay_2" )->categories;
    };
  },
  undef,
  'call to categories lives'
);
like( $stderr, qr/No category file/, 'categories without indices warn' );
is_deeply( [ sort keys %cats ], [ sort qw( fake-category) ], 'Good discovered categories' );
{
  local $Gentoo::Overlay::Exceptions::WARNINGS_ARE = qw( fatal );

  need_fail_ident(
    exception {
      %cats = Gentoo::Overlay->new( path => "$base/overlay_2" )->categories;
    },
    'call to categories without a categories file fatals when asked to',
    'no category file',
  );

}
need_fail_ident(
  exception {
    %cats = Gentoo::Overlay->new( path => "$base/overlay_3" )->categories;
  },
  'call to categories w/ missing category dies',
  'missing category',
);

is(
  exception {
    $stderr = '';
    $stderr = stderr_from {
      %cats = Gentoo::Overlay->new( path => "$base/overlay_4" )->categories;
    };

  },
  undef,
  'Proper category tree doesn\'t die'
);
is( $stderr, '', 'No output was made to stderr' );
is_deeply( [ sort keys %cats ], [ sort qw( fake-category fake-category-2) ], 'Good discovered categories' );

done_testing;

