#!perl

use strict;
use warnings;

use Capture::Tiny qw/capture/;
use Dist::Zilla::Tester;
use Test::More 0.88;
use Path::Class 0.26;
use Try::Tiny;

my $corpus = 'corpus/DZ';

## Tests start here

dzil_not_released("defaults: no resources");

dzil_released(
  "all resources provided; defaults required",
  {
    with => { map { $_ => 1 } qw/repository bugtracker homepage/ },
  }
);

dzil_released(
  "only repository and bugtracker provided; defaults required",
  {
    with => { map { $_ => 1 } qw/repository bugtracker/ },
  }
);

dzil_not_released(
  "only repository and bugtracker provided; homepage required",
  {
    with => { map { $_ => 1 } qw/repository bugtracker/ },
    check => { homepage => 1 },
  }
);

dzil_released(
  "only repository provided; bugtracker not required",
  {
    with => { repository => 1 },
    check => { bugtracker => 0 },
  }
);

#--------------------------------------------------------------------------#
# fixture subs
#--------------------------------------------------------------------------#

sub dzil_released     { _dzil_test( 1, @_ ) }
sub dzil_not_released { _dzil_test( 0, @_ ) }

sub _dzil_test {
  my ( $should_release, $label, $args ) = @_;

  subtest $label => sub {
    my $tzil;
    try {
      $tzil = Dist::Zilla::Tester->from_config(
        { dist_root => $corpus },
        { add_files => { 'source/dist.ini' => gen_dist_ini($args) } },
      );
      ok( $tzil, "created test dist" );

      capture { $tzil->release };
    }
    finally {
      my $err = shift || '';
      if ($should_release) {
        is( $err, "", "did not see missing resources warning" );
        ok(
          grep( {/fake release happen/i} @{ $tzil->log_messages } ),
          "FakeRelease happened",
        );
      }
      else {
        like(
          $err,
          qr/META resources not specified/i,
          "saw missing resources warning",
        );
        ok(
          !grep( {/fake release happen/i} @{ $tzil->log_messages } ),
          "FakeRelease did not happen",
        );
      }
    }
    }
}

sub gen_dist_ini {
  my ($args) = @_;
  $args->{with}  ||= {};
  $args->{check} ||= {};

  my $meta = {
  bugtracker => <<'HERE',
bugtracker.web    = https://rt.cpan.org/Public/Dist/Display.html?Name=Foo
HERE
  repository => <<'HERE',
repository.url    = git://github.com/zzz/p5-foo.git
repository.web    = http://github.com/zzz/p5-foo
repository.type   = git
HERE
  homepage => <<'HERE',
homepage          = http://foo.example.com
HERE
  };

  my $dist_ini = <<'HERE';
name    = Foo
version = 1.23
author  = foobar
license = Perl_5
abstract = Test Library
copyright_holder = foobar
copyright_year   = 2009

[@Filter]
bundle = @Basic
remove = ExtraTests
remove = TestRelease
remove = ConfirmRelease
remove = UploadToCPAN

[FakeRelease]

[CheckMetaResources]
HERE

  for my $k ( keys %{ $args->{check} } ) {
    $dist_ini .= "$k = $args->{check}{$k}\n";
  }

  $dist_ini .= "\n";

  if ( keys %{ $args->{with} } ) {
    $dist_ini .= "[MetaResources]\n";
    for my $k ( keys %{ $args->{with} } ) {
      $dist_ini .= "$meta->{$k}";
    }
  }

  return $dist_ini;
}

done_testing;
