#!perl
use 5.006;
use Test2::V0;

my @modules = <<'EOM' =~ m/([A-Z][A-Za-z0-9:]+)/g;
Game::Marad
EOM

my $loaded = 0;
for my $m (@modules) {
    local $@;
    eval "require $m";
    if ($@) { bail_out("require failed '$m': $@") }
    $loaded++;
}

diag("Testing Game::Marad $Game::Marad::VERSION, Perl $], $^X");
is( $loaded, scalar @modules );

done_testing 1
