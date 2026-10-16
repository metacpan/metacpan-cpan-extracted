use strict;
use warnings;
use Test::More;
use FindBin;
use File::Spec;

# THE SYNOPSIS RUNS AS WRITTEN. Each module's SYNOPSIS is pulled out of its POD
# and run; one that names a variable it does not make is given what it needs
# first. What it prints goes to the null device, not an in-memory handle,
# which one smoker has failed to decode.

my %GIVEN = (
    'Game::Sternhalma::Result' => 'my $game = Game::Sternhalma->new; $game->resign(1);',
    'Game::Sternhalma::Error'  => '',
);

for my $module (qw(Game::Sternhalma Game::Sternhalma::Bot Game::Sternhalma::Engine Game::Sternhalma::Notation
                   Game::Sternhalma::Layout Game::Sternhalma::Result Game::Sternhalma::Error)) {
    (my $file = $module) =~ s{::}{/}g;
    open my $fh, '<', "$FindBin::Bin/../lib/$file.pm" or die "$file.pm: $!";
    my $pod = do { local $/; <$fh> };
    my ($synopsis) = $pod =~ /^=head1 SYNOPSIS\n(.*?)^=head1/ms;
    ok(defined $synopsis && $synopsis =~ /\S/, "$module has a SYNOPSIS");
    my $code = join "\n", map { s/^    //r } grep { /^    / || /^\s*$/ } split /\n/, $synopsis // '';
    open my $capture, '>', File::Spec->devnull or die "the null device: $!";
    my $old = select $capture;
    my $ok = eval "package Synopsis::Run; use strict; use warnings; use Game::Sternhalma; " . ($GIVEN{$module} // "") . " $code; 1";
    my $err = $@;
    select $old;
    ok($ok, "  and it runs") or diag $err;
}

done_testing();
