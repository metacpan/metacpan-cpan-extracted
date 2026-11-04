use 5.020;
use strict;
use warnings;
use Test::More;
use File::Spec ();
use Devel::XSCover::Gcov ();
use Devel::XSCover::Flow ();

sub slurp {
    my $f = File::Spec->catfile(@_);
    open my $fh, '<', $f or die "$f: $!";
    local $/;
    return <$fh>;
}

sub gcov { Devel::XSCover::Gcov->new(silent => 1)->parse(slurp(@_)) }

sub sorted {
    my ($lines) = @_;
    return { map { my $l = $lines->{$_}; $_ => { %$l, arcs => [ sort { $a->[0] cmp $b->[0] || $a->[1] cmp $b->[1] } @{ $l->{arcs} } ] } } keys %$lines };
}

my $dump  = slurp(qw(t fixtures flow llvm Spike.flow.txt));
my $files = gcov(qw(t fixtures gcov llvm Spike.gcov.txt));
my $flow  = Devel::XSCover::Flow->new(dir => 't/fixtures/spike');
my $g     = $flow->parse_llvm($dump, $files);
my @named = sort grep { !m{^/} } keys %{ $g->{files} };
is_deeply(\@named, ['Spike.c', 'Spike.xs', 'include/spike.h', 'xs/more.xs'], 'with the gcov text every file index has a name');

my $alone = $flow->parse_llvm($dump);
is_deeply([ sort grep { !m{^/} } keys %{ $alone->{files} } ], ['Spike.c', 'Spike.xs', 'include/spike.h'],
    'without the gcov text an index no function starts in has no file and its lines are left out');
is_deeply(sorted($alone->{files}{'Spike.xs'}), sorted($g->{files}{'Spike.xs'}), 'the files named by their functions are read the same');

my %many = %$files;
for my $other (gcov(qw(t fixtures gcov gcc Spike.gcov.txt)), gcov(qw(t fixtures gcov llvm helper.gcov.txt)), gcov(qw(t fixtures gcov gcc manual.gcov.txt))) {
    $many{$_} //= $other->{$_} for keys %$other;
}
$many{'src/stub.c'} = {};
my @more = (7, 15, 23, 31);
is_deeply({ map { my $f = $_; $f => [ grep { $many{$f}{lines}{$_} } @more ] } 'src/helper.c', 'tmp.c', '/usr/include/stdio.h' },
    { 'src/helper.c' => [7, 15], 'tmp.c' => [15], '/usr/include/stdio.h' => [] }, 'the extra files: two share lines with more.xs, one shares none');
my $crowd = $flow->parse_llvm($dump, \%many);
is_deeply([ sort grep { !m{^/} } keys %{ $crowd->{files} } ], \@named,
    'among many files the one sharing most of the lines of an index names it, files sharing fewer or none are passed over');
is_deeply(sorted($crowd->{files}{'xs/more.xs'}), sorted($g->{files}{'xs/more.xs'}), 'and more.xs reads the same as from its own gcov text');

done_testing;
