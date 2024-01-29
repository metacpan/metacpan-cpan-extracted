#!perl
use 5.24.0;
use warnings;
use Test2::V0;

my @modules = <<'EOM' =~ m/([A-Z][A-Za-z0-9:]+)/g;
Game::PlatformsOfPeril
EOM

my $loaded = 0;
for my $m (@modules) {
    local $@;
    eval "require $m";
    if ($@) { bail_out("require failed '$m': $@") }
    $loaded++;
}

diag(
    "Testing Game::PlatformsOfPeril $Game::PlatformsOfPeril::VERSION, Perl $], $^X"
);
is( $loaded, scalar @modules );
done_testing;
