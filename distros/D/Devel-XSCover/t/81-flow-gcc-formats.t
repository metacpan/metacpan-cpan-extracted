use 5.020;
use strict;
use warnings;
use Test::More;
use File::Spec ();
use JSON::PP ();
use Devel::XSCover::Flow ();

sub slurp {
    my $f = File::Spec->catfile(@_);
    open my $fh, '<', $f or die "$f: $!";
    local $/;
    return <$fh>;
}

my $json = JSON::PP->new->canonical;
my $flow = Devel::XSCover::Flow->new(dir => 't/fixtures/spike');
my $text = slurp(qw(t fixtures flow gcc Spike.flow.json));
my $g    = $flow->parse_gcc($text);

my $old = $json->decode($text);
$old->{format_version} = '1';
for my $f (@{ $old->{files} }) {
    for my $l (@{ $f->{lines} }) {
        delete $l->{block_ids};
        delete @{$_}{qw(source_block_id destination_block_id)} for @{ $l->{branches} };
    }
}
my $o = $flow->parse_gcc($json->encode($old));
is_deeply([ sort keys %{ $o->{files} } ], [ sort keys %{ $g->{files} } ], 'a json without block ids, as gcc wrote before format 2, names the same files');
is_deeply($o->{files}{'Spike.xs'}{36}, { blocks => {}, arcs => [], count => 3 }, 'with the count of a line but no blocks and no arcs');
is_deeply($flow->decisions($o), { map { $_ => [] } grep { !m{^/} } keys %{ $g->{files} } }, 'so no decision can be read from it, and every file says so');

my $split = $json->decode($text);
my ($xs)  = grep { $_->{file} eq 'Spike.xs' } @{ $split->{files} };
my ($i)   = grep { $xs->{lines}[$_]{line_number} == 36 } 0 .. $#{ $xs->{lines} };
my $line  = $xs->{lines}[$i];
my @parts = map {
    my $b = $_;
    +{ %$line, function_name => "part_$b", block_ids => [$b], branches => [ grep { $_->{source_block_id} == $b } @{ $line->{branches} } ] };
} @{ $line->{block_ids} };
splice @{ $xs->{lines} }, $i, 1, @parts;
is(scalar @parts, 2, 'the if line of both, listed once per block as gcc lists a line once per function');
my $joined = $flow->parse_gcc($json->encode($split))->{files}{'Spike.xs'}{36};
is_deeply($joined->{blocks}, $g->{files}{'Spike.xs'}{36}{blocks}, 'is one line of the graph with every block');
is_deeply([ sort { $a->[0] <=> $b->[0] || $a->[1] <=> $b->[1] } @{ $joined->{arcs} } ],
    [ sort { $a->[0] <=> $b->[0] || $a->[1] <=> $b->[1] } @{ $g->{files}{'Spike.xs'}{36}{arcs} } ], 'and every arc');
is($joined->{count}, 3, 'and the count');

is_deeply($flow->parse_gcc('{"format_version":"2"}'), { complete => 0, files => {} }, 'a json with no files is an empty graph');
my $sparse = $flow->parse_gcc('{"files":[{"file":"a.c"},{"file":"b.c","lines":[{"line_number":3},{"line_number":4,"count":2,"block_ids":[1],"branches":[{"source_block_id":1,"count":1},{"source_block_id":1,"destination_block_id":2,"count":1}]}]}]}');
is_deeply($sparse, { complete => 0, files => { 'b.c' => {
    3 => { blocks => {}, arcs => [], count => undef },
    4 => { blocks => { 1 => 1 }, arcs => [ [1, 2, 1] ], count => 2 },
} } }, 'a json with lists left out is read for what it has, and a branch without a destination is no arc');

done_testing;
