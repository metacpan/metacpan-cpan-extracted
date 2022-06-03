#!perl
use Test2::V0;
plan tests => 1;

my @modules = <<'EOM' =~ m/([A-Z][A-Za-z0-9:]+)/g;
Language::Eforth
EOM

my $loaded = 0;
for my $m (@modules) {
    local $@;
    eval "require $m";
    if ($@) { bail_out("require failed '$m': $@") }
    $loaded++;
}

diag("Testing Language::Eforth $Language::Eforth::VERSION, Perl $], $^X");
is( $loaded, scalar @modules );
done_testing;
