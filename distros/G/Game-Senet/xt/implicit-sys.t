use strict;
use warnings;
use Test::More;
use Config;
use File::Spec;
use FindBin;

# NO NAME A WINDOWS PERL TAKES, plan_game_senet/09. Under PERL_IMPLICIT_SYS,
# which every Strawberry is, XSUB.h renames close, free, read, write and over
# a hundred more to PerlLIO_close and the like, which are function-like
# macros. A declaration `int (*free)(sen_board *)` survives, the name being
# followed by `)`; a call `A->free(b)` does not, and only the call breaks,
# which is how Frozen 0.01 reached CPAN. The list is read from this perl's own XSUB.h, whose
# block is there whether or not this perl was built with the layer, so a name
# a later perl adds is checked without this file changing.
#
# Windows' own headers take near, far and small as macros, so no identifier in
# the C is one of those either.

my $root = File::Spec->catdir($FindBin::Bin, File::Spec->updir);
my $xsub = File::Spec->catfile($Config{archlibexp}, 'CORE', 'XSUB.h');
open my $fh, '<', $xsub or BAIL_OUT("cannot read $xsub: $!");
my $text = do { local $/; <$fh> };
close $fh;

my ($block) = $text =~ /^#if defined\(PERL_IMPLICIT_SYS\) && !defined\(PERL_CORE\)\n(.*?)^#endif\s+\/\* PERL_IMPLICIT_SYS/ms;
ok(defined $block, "the PERL_IMPLICIT_SYS block of $xsub is found") or BAIL_OUT('no list of names, no check');
my %taken = map { $_ => 1 } $block =~ /^#\s*define\s+([a-z_][a-z_0-9]*)\b/mg;
cmp_ok(scalar keys %taken, '>', 50, scalar(keys %taken) . ' names, among them free, close and read')
    and ok($taken{free} && $taken{close} && $taken{read}, '  which they are');

sub source {
    my ($file) = @_;
    open my $in, '<', $file or die "cannot read $file: $!";
    my $c = do { local $/; <$in> };
    close $in;
    $c =~ s{/\*.*?\*/}{ }gs;
    $c =~ s{//[^\n]*}{}g;
    $c =~ s{"(?:\\.|[^"\\])*"}{""}g;
    return $c;
}

my $abi = source(File::Spec->catfile($root, 'include', 'sen_abi.h'));
my @members = $abi =~ /\(\s*\*\s*(\w+)\s*\)\s*\(/g;
cmp_ok(scalar @members, '>', 30, scalar(@members) . ' function members in the ABI table');
my @eaten = grep { $taken{$_} } @members;
is("@eaten", '', 'not one is a name XSUB.h renames, so no consumer meets it at a call');

my @files = map { File::Spec->catfile($root, $_) } 'Senet.xs', 'sen_engine.c', 'sen_moves.c', 'sen_search.c',
    'include/sen_abi.h';
for my $file (@files) {
    my $c = source($file);
    my @calls = grep { $taken{$_} } $c =~ /(?:->|\.)\s*(\w+)\s*\(/g;
    is("@calls", '', (File::Spec->abs2rel($file, $root)) . ': no member called by a renamed name');
    my @windows = $c =~ /\b(near|far|small)\b/g;
    is("@windows", '', '  and no identifier Windows takes');
}

done_testing();
