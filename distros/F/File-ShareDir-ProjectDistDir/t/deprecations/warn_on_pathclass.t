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
  if ( not eval "require $package;1" ) {
    plan skip_all => "$package required for this test";
    exit;
  }
}
plan tests => 2;
pass('Test requirements available');
my $err = Capture::Tiny::capture_stderr(
  sub {
    eval '
        package Foo;
        use File::ShareDir::ProjectDistDir q[:all], pathclass => 1;
    ';
  }
);
like( $err, qr/Path::Class support depecated/, "Deprecated support" );
