use Test::More tests => 1;

my $module  = "HTML::LinkFilter";
eval "use $module";
my @methods = qw(
    new
    change  tags  html
);

can_ok( $module, @methods );

