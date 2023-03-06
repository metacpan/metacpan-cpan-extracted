#!perl
use 5.006;
use Test2::V0;

plan 1;

my @modules = <<'EOM' =~ m/([A-Z][A-Za-z0-9:]+)/g;
Game::RaycastFOV
EOM

my $loaded = 0;
for my $m (@modules) {
    local $@;
    eval "require $m";
    if ($@) { bail_out("require failed '$m': $@") }
    $loaded++;
}

diag("Testing Game::RaycastFOV $Game::RaycastFOV::VERSION, Perl $], $^X");
is( $loaded, scalar @modules );
