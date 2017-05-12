use Test::More tests => 2;

BEGIN {
  use_ok( 'Lingua::Abbreviate::Hierarchy' );
  use_ok( 'Lingua::Ab::H' );
}

diag(
  "Testing Lingua::Abbreviate::Hierarchy $Lingua::Abbreviate::Hierarchy::VERSION"
);
