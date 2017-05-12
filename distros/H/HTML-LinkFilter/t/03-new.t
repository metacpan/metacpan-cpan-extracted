use Test::More tests => 1;

my $module = "HTML::LinkFilter";
eval "use $module";

new_ok( $module );

