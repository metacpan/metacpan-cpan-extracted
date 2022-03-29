#!perl
use Test2::V0;

plan(1);

# TODO better way to bail out should the modules not load?
# Test2::Bundle::More claims "These are not necessary" for "use_ok"
# and friends
my @modules = <<'EOM' =~ m/([A-Z][A-Za-z0-9:]+)/g;
Logic::Expr::Parser
Logic::Expr
EOM

my $loaded = 0;
for my $m (@modules) {
    local $@;
    eval "require $m";
    if ($@) { bail_out("require failed '$m': $@") }
    $loaded++;
}

diag("Testing Logic::Expr $Logic::Expr::VERSION, Perl $], $^X");
is( $loaded, scalar @modules );
