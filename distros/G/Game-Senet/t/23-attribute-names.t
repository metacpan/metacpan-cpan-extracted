use strict;
use warnings;
use Test::More;
use File::Spec;

# AN ACCESSOR EATS AN XSUB OF THE SAME NAME IN SILENCE. Phase 01 found it: a
# private attribute `_pieces` on Game::Senet::Engine replaced the XSUB
# `_pieces`, and the board's pieces read back as the constructor's argument.
# Every attribute of every class is checked here against every XSUB name in
# Senet.xs.

my $xs = File::Spec->catfile('Senet.xs');
open my $fh, '<', $xs or die "cannot read $xs: $!";
my %xsub;
while (my $line = <$fh>) {
    $xsub{$1} = 1 if $line =~ /\A([A-Za-z_]\w*)\(/;
}
close $fh;
cmp_ok(scalar(keys %xsub), '>', 40, scalar(keys %xsub) . ' XSUBs read from Senet.xs');

my @bad;
for my $pm ('lib/Game/Senet.pm', glob('lib/Game/Senet/*.pm')) {
    open my $in, '<', $pm or die "cannot read $pm: $!";
    while (my $line = <$in>) {
        last if $line =~ /\A__END__/;
        push @bad, "$pm: has $1" if $line =~ /\Ahas (\w+) =>/ && $xsub{$1};
    }
}
is("@bad", '', 'no attribute shares a name with an XSUB');

done_testing();
