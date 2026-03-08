use Test2::V0;
use Loop::Util;

my @out;

{
	local $_;
	loop (3) {
		iffirst { push @out, "FIRST"; }
		ifodd {
			push @out, "ODD";
		}
		else {
			push @out, "EVEN";
		}
		ifeven {
			push @out, "EVEN";
		}
		else {
			push @out, "ODD";
		}
		iflast  { push @out, "LAST"; }
		push @out, $Loop::Util::ITERATION;
	}
}

is(
	\@out,
	[ "FIRST", "ODD", "ODD", 0, "EVEN", "EVEN", 1, "ODD", "ODD", "LAST", 2 ],
	"loop supports iffirst/ifodd/ifeven/iflast"
);

@out = ();
my $i = 0;
{
	local $_;
	loop (3) process_input();
}

is( \@out, [ "call:0", "call:1", "call:2" ], "single statement finite loop" );

@out = ();
{
	local $_;
	loop do { push @out, "inf:$Loop::Util::ITERATION"; last if $Loop::Util::ITERATION > 0; };
}

is( \@out, [ "inf:0", "inf:1" ], "single statement infinite loop" );

@out = ();
sub get_number { 5 }
{
	local $_;
	loop (get_number()) {
		push @out, $Loop::Util::ITERATION;
		last if $Loop::Util::ITERATION == 2;
		redo if $Loop::Util::ITERATION == 1 and @out < 4;
		next if $Loop::Util::ITERATION == 0;
		push @out, "seen:$Loop::Util::ITERATION";
	}
}

ok( scalar(@out) >= 4, "loop supports last/redo/next" );

my $nested_out = '';
loop (2) {
	loop (3) {
		$nested_out .= 'x';
	}
}
is( $nested_out, 'xxxxxx', 'nested loop works with localized iteration variable' );

my $e_inf = do {
	local $@;
	eval {
		{
			local $_;
			loop {
				iflast { 1 }
				last;
			}
		}
	};
	$@;
};

like( $e_inf, qr/iflast called outside for loop/, "iflast in infinite loop dies" );

my $e_no_paren = do {
	local $@;
	eval q{ loop 3 { 1 } };
	$@;
};

like( $e_no_paren, qr/(?:syntax error|loop count requires parentheses)/,
	"loop count without parentheses fails" );

my $stdout = qx{perl -Mblib -Ilib -MLoop::Util -E'loop(3) say "hi"'};
is( $stdout, "hi\nhi\nhi\n", "single statement finite loop works without trailing semicolon at EOF" );

sub process_input {
	push @out, "call:" . $i++;
}

done_testing;
