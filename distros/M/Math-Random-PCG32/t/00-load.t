#!perl
use 5.14.0;
use Test2::V0;

my @modules = <<'EOM' =~ m/([A-Z][A-Za-z0-9:]+)/g;
Math::Random::PCG32
EOM

my $loaded = 0;
for my $m (@modules) {
    local $@;
    eval "require $m";
    if ($@) { bail_out("require failed '$m': $@") }
    $loaded++;
}

diag("Testing Math::Random::PCG32 $Math::Random::PCG32::VERSION, Perl $], $^X");
is( $loaded, scalar @modules );

done_testing 1
