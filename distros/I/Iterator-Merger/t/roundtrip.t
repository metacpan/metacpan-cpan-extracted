use strict;
use warnings;
use Test::More;

plan tests => 8+3*16*14*2;

require_ok 'Iterator::Merger';
eval {Iterator::Merger->import(':all')};
is($@, '');
is(\&imerge, \&Iterator::Merger::imerge);
is(\&imerge_num, \&Iterator::Merger::imerge_num);
is(\&imerge_raw, \&Iterator::Merger::imerge_raw);

my @ref_lex = sort ('', map {pack N => 1+int 100_000*rand} (1..50));
my @ref = sort {$a <=> $b} (0, map {1+int 100_000*rand} (1..50));

eval {imerge(sub{}, 1)};
like($@, '/^arguments must be CODE references or filehandles at /');
eval {imerge_num(sub{}, 1)};
like($@, '/^arguments must be CODE references or filehandles at /');
eval {imerge_raw(sub{}, 1)};
like($@, '/^arguments must be CODE references or filehandles at /');

for my $lex (-1, 0, 1) {
	for my $nb_ite (0..15) {
		for my $i (1..10, 'identical lists', 'with empty iterator at the begining', 'with empty iterator at the end', 'with empty iterator in the middle') {
			my @lists = map {
				$i eq 'identical lists'
				?
					$lex
					?
					[@ref_lex]
					:
					[@ref]
				:
					$lex
					?
					[sort ('', map {pack N => 1+int 100_000*rand} (1..(1+int 100*rand)))]
					:
					[sort {$a <=> $b} (0, map {1+int 100_000*rand} (1..(1+int 100*rand)))]
			} (1..$nb_ite);
			
			if ($i eq 'with empty iterator at the begining') {
				$lists[0] = [];
			}
			elsif ($i eq 'with empty iterator at the end') {
				$lists[$nb_ite-1] = [] if $nb_ite>1;
			}
			elsif ($i eq 'with empty iterator in the middle') {
				$lists[$nb_ite/2] = [];
			}		
			
			my @expect = map {@$_} @lists;
			
			if ($lex==1) {
				@expect = sort @expect;
			}
			elsif ($lex==0) {
				@expect = sort {$a <=> $b} @expect;
			}
			# unsorted if $lex == -1
						
			my @iterators = map {
				my $list = $_;
				sub{
					die "expected scalar context, got void context from ", caller unless defined wantarray;
					die "expected scalar context, got list context from ", caller if wantarray;
					shift @$list
				}
			} @lists;

			my ($ite, $name) = do {
				if ($lex==1) {
					(imerge(@iterators), 'imerge')
				}
				elsif ($lex==0) {
					(imerge_num(@iterators), 'imerge_num')
				}
				else {
					(imerge_raw(@iterators), 'imerge_raw')
				}
			};
			
			my @has;
			while (defined(my $next = $ite->())) {
				push @has, $next;
			}
			is_deeply(\@has, \@expect, "$name $nb_ite iterators, test '$i'");
			is(scalar(grep {defined} map {$ite->()} (1..100)), 0, "remains undef when exhausted");
		}
	}
}

