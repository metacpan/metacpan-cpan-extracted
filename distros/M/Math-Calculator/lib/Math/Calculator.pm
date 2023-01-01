use strict;
use warnings;
package Math::Calculator 1.023;
# ABSTRACT: a multi-stack calculator class

#pod =head1 SYNOPSIS
#pod
#pod  use Math::Calculator;
#pod
#pod  my $calc = Math::Calculator->new;
#pod
#pod  $calc->push(10, 20, 30);
#pod  $calc->add;
#pod  $calc->root; # 1.0471285480509  (50th root of 10)
#pod
#pod =head1 DESCRIPTION
#pod
#pod Math::Calculator is a simple class representing a stack-based calculator.  It
#pod can have an arbitrary number of stacks.
#pod
#pod =method new
#pod
#pod This class method returns a new Math::Calculator object with one stack
#pod ("default").
#pod
#pod =cut

sub new {
	bless {
		stacks => { default => [] },
		current_stack => 'default'
	} => shift
}

#pod =method current_stack
#pod
#pod   $calc->current_stack($stackname)
#pod
#pod This method sets the current stack to the named stack.  If no stack by the
#pod given name exists, one is created and begins life empty.  Stack names are
#pod strings of word characters.  If no stack name is given, or if the name is
#pod invalid, the stack selection is not changed.
#pod
#pod The name of the selected stack is returned.
#pod
#pod =cut

sub current_stack {
	my ($self, $stack) = @_;

	return $self->{current_stack} unless $stack and $stack =~ /^\w+$/;
	$self->{stacks}{$stack} = [] unless defined $self->{stacks}{$stack};
	$self->{current_stack} = $stack;
}

#pod =method stack
#pod
#pod   $calc->stack($stackname)
#pod
#pod This method returns a (array) reference to the stack named, or the current
#pod selected stack, if none is named.
#pod
#pod =cut

sub stack { $_[0]->{stacks}->{$_[1] ? $_[1] : $_[0]->current_stack} }

#pod =method top
#pod
#pod   $calc->top
#pod
#pod This method returns the value of the top element on the current stack without
#pod altering the stack's contents.
#pod
#pod =cut

sub top   { (shift)->stack->[-1] }

#pod =method clear
#pod
#pod   $calc->clear
#pod
#pod This clears the current stack, setting it to C<()>.
#pod
#pod =cut

sub clear { @{(shift)->stack} = (); }

#pod =method push
#pod
#pod   $calc->push(@elements);
#pod
#pod C<push> pushes the given elements onto the stack in the order given.
#pod
#pod =method push_to
#pod
#pod   $calc->push_to($stackname, @elements)
#pod
#pod C<push_to> is identical to C<push>, but pushes onto the named stack.
#pod
#pod =cut

sub push { ## no critic
  push @{(shift)->stack}, @_;
}
sub push_to { CORE::push @{(shift)->stack(shift)}, @_; }

#pod =method pop
#pod
#pod   $calc->pop($howmany)
#pod
#pod This method pops C<$howmany> elements off the current stack, or one element, if
#pod C<$howmany> is not defined.
#pod
#pod =method pop_from
#pod
#pod   $calc->pop_from($stack, $howmany);
#pod
#pod C<pop_from> is identical to C<pop>, but pops from the named stack.  C<$howmany>
#pod defaults to 1.
#pod
#pod =cut

sub pop { ## no critic
  splice @{$_[0]->stack}, - (defined $_[1] ? $_[1] : 1);
}
sub pop_from { splice @{$_[0]->stack($_[1])}, - (defined $_[2] ? $_[2] : 1); }

#pod =method from_to
#pod
#pod   $calc->from_to($from_stack, $to_stack, [ $howmany ])
#pod
#pod This pops a value from one stack and pushes it to another.
#pod
#pod =cut

sub from_to { $_[0]->push_to($_[2], $_[0]->pop_from($_[1], $_[3])) }

#pod =method dupe
#pod
#pod   $calc->dupe;
#pod
#pod C<dupe> duplicates the top value on the current stack.  It's identical to C<<
#pod $calc->push($calc->top) >>.
#pod
#pod =cut

sub dupe { $_[0]->push( $_[0]->top ); }

#pod =method _op_two
#pod
#pod   $calc->_op_two($coderef)
#pod
#pod This method, which is only semi-private because it may be slightly refactored
#pod or renamed in the future (possibly to operate on I<n> elements), pops two
#pod elements, feeds them as parameters to the given coderef, and pushes the result.
#pod
#pod =cut

# sub _op_two { $_[0]->push( $_[1]->( $_[0]->pop(2) ) ); $_[0]->top; }

sub _op_two { ($_[0]->_op_n(2, $_[1]))[-1] }
sub _op_n {
	$_[0]->push(my @r = $_[2]->( $_[0]->pop($_[1]) ));
	wantarray ? @r : $r[-1]
}

#pod =method twiddle
#pod
#pod This reverses the position of the top two elements on the current stack.
#pod
#pod =cut

sub twiddle  { (shift)->_op_two( sub { $_[1], $_[0] } ); }

#pod =method add
#pod
#pod  x = pop; y = pop;
#pod  push x + y;
#pod
#pod This pops the top two values from the current stack, adds them, and pushes the
#pod result.
#pod
#pod =method subtract
#pod
#pod  x = pop; y = pop;
#pod  push x - y;
#pod
#pod This pops the top two values from the current stack, subtracts the second from
#pod the first, and pushes the result.
#pod
#pod =method multiply
#pod
#pod  x = pop; y = pop;
#pod  push x * y;
#pod
#pod This pops the top two values from the current stack, multiplies them, and
#pod pushes the result.
#pod
#pod =method divide
#pod
#pod  x = pop; y = pop;
#pod  push x / y;
#pod
#pod This pops the top two values from the current stack, divides the first by the
#pod second, and pushes the result.
#pod
#pod =cut

sub add      { (shift)->_op_two( sub { (shift) + (shift) } ); }
sub subtract { (shift)->_op_two( sub { (shift) - (shift) } ); }
sub multiply { (shift)->_op_two( sub { (shift) * (shift) } ); }
sub divide   { (shift)->_op_two( sub { (shift) / (shift) } ); }

#pod =method modulo
#pod
#pod  x = pop; y = pop;
#pod  push x % y;
#pod
#pod This pops the top two values from the current stack, computes the first modulo
#pod the second, and pushes the result.
#pod
#pod =method raise_to
#pod
#pod  x = pop; y = pop;
#pod  push x ** y;
#pod
#pod This pops the top two values from the current stack, raises the first to the
#pod power of the second, and pushes the result.
#pod
#pod =method root
#pod
#pod  x = pop; y = pop;
#pod  push x ** (1/y);
#pod
#pod This pops the top two values from the current stack, finds the I<y>th root of
#pod I<x>, and pushes the result.
#pod
#pod =method sqrt
#pod
#pod This method pops the top value from the current stack and pushes its square
#pod root.
#pod
#pod =cut

## no critic Subroutines::ProhibitBuiltinHomonyms
sub modulo   { (shift)->_op_two( sub { (shift) % (shift) } ); }
sub sqrt     { my ($self) = @_; $self->push(2); $self->root; }
## use critic
sub raise_to { (shift)->_op_two( sub { (shift) **(shift) } ); }
sub root     { (shift)->_op_two( sub { (shift)**(1/(shift)) } ); }

#pod =method quorem
#pod
#pod =method divmod
#pod
#pod This method pops two values from the stack and divides them.  It pushes the
#pod integer part of the quotient, and then the remainder.
#pod
#pod =cut

sub _quorem  { my ($n,$m) = @_; (int($n/$m), $n % $m) }
sub quorem   { (shift)->_op_n(2, \&_quorem ); }
sub divmod   { (shift)->_op_n(2, \&_quorem ); }

#pod =head1 TODO
#pod
#pod I'd like to write some user interfaces to this module, probably by porting
#pod Math::RPN, writing a dc-alike, and possibly a simple Curses::UI interface.
#pod
#pod I want to add BigInt and BigFloat support for better precision.
#pod
#pod I'd like to make Math::Calculator pluggable, so that extra operations can be
#pod added easily.
#pod
#pod =head1 SEE ALSO
#pod
#pod =for :list
#pod * L<Math::RPN>
#pod * L<Parse::RPN>
#pod
#pod =head1 THANKS
#pod
#pod Thanks, also, to Duan TOH.  I spent a few days giving him a crash course in
#pod intermediate Perl and became interested in writing this class when I used it as
#pod a simple example of how objects in Perl work.
#pod
#pod =cut

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Math::Calculator - a multi-stack calculator class

=head1 VERSION

version 1.023

=head1 SYNOPSIS

 use Math::Calculator;

 my $calc = Math::Calculator->new;

 $calc->push(10, 20, 30);
 $calc->add;
 $calc->root; # 1.0471285480509  (50th root of 10)

=head1 DESCRIPTION

Math::Calculator is a simple class representing a stack-based calculator.  It
can have an arbitrary number of stacks.

=head1 PERL VERSION

This library should run on perls released even a long time ago.  It should work
on any version of perl released in the last five years.

Although it may work on older versions of perl, no guarantee is made that the
minimum required version will not be increased.  The version may be increased
for any reason, and there is no promise that patches will be accepted to lower
the minimum required perl.

=head1 METHODS

=head2 new

This class method returns a new Math::Calculator object with one stack
("default").

=head2 current_stack

  $calc->current_stack($stackname)

This method sets the current stack to the named stack.  If no stack by the
given name exists, one is created and begins life empty.  Stack names are
strings of word characters.  If no stack name is given, or if the name is
invalid, the stack selection is not changed.

The name of the selected stack is returned.

=head2 stack

  $calc->stack($stackname)

This method returns a (array) reference to the stack named, or the current
selected stack, if none is named.

=head2 top

  $calc->top

This method returns the value of the top element on the current stack without
altering the stack's contents.

=head2 clear

  $calc->clear

This clears the current stack, setting it to C<()>.

=head2 push

  $calc->push(@elements);

C<push> pushes the given elements onto the stack in the order given.

=head2 push_to

  $calc->push_to($stackname, @elements)

C<push_to> is identical to C<push>, but pushes onto the named stack.

=head2 pop

  $calc->pop($howmany)

This method pops C<$howmany> elements off the current stack, or one element, if
C<$howmany> is not defined.

=head2 pop_from

  $calc->pop_from($stack, $howmany);

C<pop_from> is identical to C<pop>, but pops from the named stack.  C<$howmany>
defaults to 1.

=head2 from_to

  $calc->from_to($from_stack, $to_stack, [ $howmany ])

This pops a value from one stack and pushes it to another.

=head2 dupe

  $calc->dupe;

C<dupe> duplicates the top value on the current stack.  It's identical to C<<
$calc->push($calc->top) >>.

=head2 _op_two

  $calc->_op_two($coderef)

This method, which is only semi-private because it may be slightly refactored
or renamed in the future (possibly to operate on I<n> elements), pops two
elements, feeds them as parameters to the given coderef, and pushes the result.

=head2 twiddle

This reverses the position of the top two elements on the current stack.

=head2 add

 x = pop; y = pop;
 push x + y;

This pops the top two values from the current stack, adds them, and pushes the
result.

=head2 subtract

 x = pop; y = pop;
 push x - y;

This pops the top two values from the current stack, subtracts the second from
the first, and pushes the result.

=head2 multiply

 x = pop; y = pop;
 push x * y;

This pops the top two values from the current stack, multiplies them, and
pushes the result.

=head2 divide

 x = pop; y = pop;
 push x / y;

This pops the top two values from the current stack, divides the first by the
second, and pushes the result.

=head2 modulo

 x = pop; y = pop;
 push x % y;

This pops the top two values from the current stack, computes the first modulo
the second, and pushes the result.

=head2 raise_to

 x = pop; y = pop;
 push x ** y;

This pops the top two values from the current stack, raises the first to the
power of the second, and pushes the result.

=head2 root

 x = pop; y = pop;
 push x ** (1/y);

This pops the top two values from the current stack, finds the I<y>th root of
I<x>, and pushes the result.

=head2 sqrt

This method pops the top value from the current stack and pushes its square
root.

=head2 quorem

=head2 divmod

This method pops two values from the stack and divides them.  It pushes the
integer part of the quotient, and then the remainder.

=head1 TODO

I'd like to write some user interfaces to this module, probably by porting
Math::RPN, writing a dc-alike, and possibly a simple Curses::UI interface.

I want to add BigInt and BigFloat support for better precision.

I'd like to make Math::Calculator pluggable, so that extra operations can be
added easily.

=head1 SEE ALSO

=over 4

=item *

L<Math::RPN>

=item *

L<Parse::RPN>

=back

=head1 THANKS

Thanks, also, to Duan TOH.  I spent a few days giving him a crash course in
intermediate Perl and became interested in writing this class when I used it as
a simple example of how objects in Perl work.

=head1 AUTHOR

Ricardo SIGNES <cpan@semiotic.systems>

=head1 CONTRIBUTORS

=for stopwords Ricardo SIGNES Signes

=over 4

=item *

Ricardo SIGNES <rjbs@codesimply.com>

=item *

Ricardo Signes <rjbs@semiotic.systems>

=back

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2005 by Ricardo SIGNES.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
