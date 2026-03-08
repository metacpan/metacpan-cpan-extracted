use 5.014000;
use strict;
use warnings;

package Loop::Util;

our $AUTHORITY = 'cpan:TOBYINK';
our $VERSION   = '0.001000';

# These are dynamically scoped by the rewritten loop keywords.
our ( $LOOPKIND, $LENGTH, $ITERATION );

my @ALL_KEYWORDS = qw( loop iffirst iflast ifodd ifeven __IX__ );
my %VALID = map { $_ => 1 } @ALL_KEYWORDS;

sub import {
	my ( $class, @keywords ) = @_;

	if ( !@keywords ) {
		@keywords = @ALL_KEYWORDS;
	}

	for my $keyword ( @keywords ) {
		die "Unknown Loop::Util keyword '$keyword'"
			if not exists $VALID{ $keyword };
	}

	my %enabled = map { $_ => 1 } @keywords;

	for my $keyword ( @ALL_KEYWORDS ) {
		if ( exists $enabled{ $keyword } ) {
			$^H{ "Loop::Util/$keyword" } = 1;
		}
		else {
			delete $^H{ "Loop::Util/$keyword" };
		}
	}
}

require XSLoader;
XSLoader::load( __PACKAGE__, $VERSION );

__PACKAGE__
__END__

=pod

=encoding utf-8

=head1 NAME

Loop::Util - loop helper keywords

=head1 SYNOPSIS

  use Loop::Util;
  
  my @array = qw(foo bar baz quux);
  
  for my $item (@array) {
  
    iffirst {
      print "Items\n";
      print "-" x length($item), "\n";
    }
    
    print "$item\n";
    
    iflast {
      print "-" x length($item), "\n";
      print "Count: ", scalar(@array), "\n";
    }
  }

=head1 DESCRIPTION

This module adds statement keywords:

=over 4

=item * C<loop BLOCK>, C<loop (EXPR) BLOCK>

C<loop> introduces new loop forms.

  loop { ... }
  loop(3) { ... }
  loop(get_number()) { ... }

C<loop> also supports a single-statement form:

  loop process_input();
  loop(3) process_input();

Parentheses are required around the loop count expression. If no count is
given, the loop is infinite, but C<last> can be used to jump out of the
loop. (The C<next> and C<redo> keywords also work as expected.)

=item * C<iffirst [LABEL] BLOCK [else BLOCK]>

Runs C<BLOCK> only on the first loop iteration; if an C<else> block is present
it runs for subsequent iterations.

When C<LABEL> is present, C<iffirst> checks that labeled loop context instead
of the innermost loop. This is useful in nested loops:

  OUTER: loop(2) {
    loop(3) {
      iffirst OUTER { say "hi" }
    }
  }

C<iffirst> works in C<loop{}> loops, and also in C<for>/C<foreach> loops over
arrays and lists. Calling C<iffirst> in other loop kinds throws a runtime
error.

=item * C<iflast [LABEL] BLOCK [else BLOCK]>

Runs C<BLOCK> only on the last loop iteration; if an C<else> block is present
it runs for not-last iterations.

When C<LABEL> is present, C<iflast> checks that
labeled loop context instead of the
innermost loop.

C<iflast> works in finite C<loop{}> loops, and also in C<for>/C<foreach>
loops over arrays and lists. Calling C<iflast> in other loop kinds throws a
runtime error.

=item * C<ifodd [LABEL] BLOCK [else BLOCK]>

Runs C<BLOCK> for odd-numbered iterations (1st, 3rd, 5th...).
If an C<else> block is present, it runs on even-numbered iterations.

Note that if you loop through an array, the first iteration (an odd
iteration) has index number 0 (an even number).

When C<LABEL> is present, C<ifodd> checks that
labeled loop context instead of the
innermost loop.

C<ifodd> works in C<loop{}> loops, and also in C<for>/C<foreach> loops over
arrays and lists. Calling C<ifodd> in other loop kinds throws a runtime
error.

=item * C<ifeven [LABEL] BLOCK [else BLOCK]>

Runs C<BLOCK> for even-numbered iterations (2nd, 4th, 6th...).
If an C<else> block is present, it runs on odd-numbered iterations.

Note that if you loop through an array, the first iteration (an odd
iteration) has index number 0 (an even number).

When C<LABEL> is present, C<ifeven> checks that
labeled loop context instead of the
innermost loop.

C<ifeven> works in C<loop{}> loops, and also in C<for>/C<foreach> loops over
arrays and lists. Calling C<ifeven> in other loop kinds throws a runtime
error.

=item * C<__IX__>

Psuedo-constant that returns the current zero-based index of the
loop.

It should work for C<loop{}> loops as well as  C<for>/C<foreach> loops
over arrays or lists. In other contexts where no index can be determined,
it returns C<undef>.

=back

=head1 BUGS

Please report any bugs to
L<https://github.com/tobyink/p5-loop-util/issues>.

=head1 SEE ALSO

L<Acme::Loopy>, L<Syntax::Keyword::Loop>.

=head1 AUTHOR

Toby Inkster E<lt>tobyink@cpan.orgE<gt>.

=head1 COPYRIGHT AND LICENCE

This software is copyright (c) 2026 by Toby Inkster.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 DISCLAIMER OF WARRANTIES

THIS PACKAGE IS PROVIDED "AS IS" AND WITHOUT ANY EXPRESS OR IMPLIED
WARRANTIES, INCLUDING, WITHOUT LIMITATION, THE IMPLIED WARRANTIES OF
MERCHANTIBILITY AND FITNESS FOR A PARTICULAR PURPOSE.

