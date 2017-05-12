use strict;
use warnings;

use Test::More;

# FILENAME: deprecate_path_class.t
# CREATED: 03/01/14 02:01:07 by Kent Fredric (kentnl) <kentfredric@gmail.com>
# ABSTRACT: Test for warnings about deprecated Path::Class

for my $package ('Capture::Tiny') {
  if ( not eval "require $package; ${package}->VERSION(0.12); 1" ) {
    plan skip_all => "$package 0.12 required for this test";
    exit;
  }
}
for my $package ('Path::Class') {
  if ( eval "require $package;1" ) {
    plan skip_all => "Test only run without $package installed";
    exit;
  }
}
plan tests => 5;
pass('Test requirements available');
my $ex;

sub test {

  package Foo;
  File::ShareDir::ProjectDistDir->import( q[:all], pathclass => 1 );
  1;
}

my $err = Capture::Tiny::capture_stderr(
  sub {
    require File::ShareDir::ProjectDistDir;
    delete $INC{'Path/Class.pm'};
    local $@ = undef;
    if ( not eval { test() } ) {
      $ex = $@;
    }
  }
);
like( $err, qr/Path::Class support depecated/, "warns about invocation" );
like( $err, qr/Path::Class is not installed/,  "warns if require failed" );
isnt( $ex, undef, "An exception was thrown" );
if ( $ex ne '' ) {
  like( $ex, qr/Can\'t locate Path\/Class\.pm/, "dies with core failure" );
}
else {
  fail("last exception was empty");
}
