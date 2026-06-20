package Destructure::Declare;

use 5.014;
use strict;
use warnings;

our $VERSION = '0.01';

require XSLoader;
XSLoader::load('Destructure::Declare', $VERSION);

sub import   { $^H{'Destructure::Declare'} = 1 }
sub unimport { delete $^H{'Destructure::Declare'} }

1;

__END__

=head1 NAME

Destructure::Declare - lexically scoped structural destructuring C<let>

=head1 SYNOPSIS

	use Destructure::Declare;

	let [$first, $second, @rest]         = $aref;     # arrayref + slurpy tail
	let {name => $n, age => $a}          = $href;     # hashref by key
	let {id => $id, %rest}               = $href;     # hashref + remaining keys
	let ($x, $y, @more)                  = @list;     # list-context destructure
	let [$head, [$x, $y], %opts]         = $nested;   # nested patterns
	let {id => $id, tags => [$t, @more]} = $record;   # mixed nesting
	let [$status, $body = '']            = $pair;     # per-slot default (//)
	let [$a, undef, $c]                  = $triple;   # holes (skip a slot)

=head1 DESCRIPTION

C<Destructure::Declare> installs a C<let> keyword that parses an entire
C<let PATTERN = EXPR;> construct at B<compile time> and lowers it to ordinary
pad lexical declarations with direct element access. All parsing happens once,
at compile time - nothing of the parser remains at runtime.

=head2 Semantics

=over 4

=item * A C<[ ... ]> pattern treats the right-hand side as an B<arrayref>; a
C<{ ... }> pattern treats it as a B<hashref>; a C<( ... )> pattern destructures
the right-hand side as a B<list> (evaluated in list context), like
C<my (...) = LIST> but with the extra powers below. The right-hand side is
evaluated exactly once.

=item * The names introduced are real C<my> lexicals, visible for the rest of
the enclosing block.

=item * C<$x = DEFAULT> supplies a default applied with C<//> (used when the
slot is missing or C<undef>). The default expression is evaluated lazily.

=item * C<undef> in a pattern position is a hole: that slot is skipped.

=item * A trailing slurpy must be the last element. In an array or list pattern
C<@rest> captures the positional tail (and C<%rest> captures that tail as
key/value pairs); in a hash pattern C<%rest> captures every key not already
named.

=back

=head1 AUTHOR

LNATION, C<< <email@lnation.org> >>

=head1 LICENSE AND COPYRIGHT

This software is Copyright (c) 2026 by LNATION <email@lnation.org>.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
