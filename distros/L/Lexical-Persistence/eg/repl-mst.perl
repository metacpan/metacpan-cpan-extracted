#!/usr/bin/env perl

# A brief REPL (read/eval/print loop) by Matt S. Trout.

use strict;
use warnings;

use Term::ReadLine;
use Lexical::Persistence;

my $term = new Term::ReadLine 'Perl REPL';

my $prompt = '$ ';

my $OUT = $term->OUT || \*STDOUT;

my $lp = Lexical::Persistence->new();

while ( defined (my $line = $term->readline($prompt)) ) {

	print "\n", next unless $line =~ /\S/;

	# Re-declare all the lexicals we've previously seen.  Lexicals
	# accumulate in the "_" context from one call to the next.

	my $sub = eval(
		qq!sub { \n!.
		join('', map { "my $_;\n" } keys %{$lp->get_context('_')}).
		${line}.qq!\n}\n!
	);

	my @res;

	if ($@) {
		warn "Compile error: $@";
	} else {
		@res = eval { $lp->call($sub); };
		warn "Runtime error: $@" if $@;
	}

	print $OUT "@res" unless $@;
	$term->addhistory($line);
}

__END__

1) poerbook:~/projects/lex-per/eg% perl repl-mst.perl
$ my $x = "declared and initialized in eval #1";
declared and initialized in eval #1
$ "evaluated in eval #2: $x";
evaluated in eval #2: declared and initialized in eval #1
$ exit
1) poerbook:~/projects/lex-per/eg%
