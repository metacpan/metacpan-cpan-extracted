package Math::Symbolic::Custom::Simplification;

use 5.006001;
use strict;
use warnings;
use Carp qw/cluck confess/;
use Math::Symbolic;

our $VERSION = '1.01';

our @Simplification_Stack;
our %Registered;

_reset();

sub _reset {
	@Simplification_Stack = (
		['Math::Symbolic::Operator', \&Math::Symbolic::Operator::simplify]
	);
	%Registered = (
		'Math::Symbolic::Operator' => 1
	);
}

sub register {
	my $class = shift;
	confess("Cannot register simplification routine when not called as class method.") if not defined $class;
	
	my $simp = eval "\\&${class}::simplify";
	if ($@ or not defined $simp or not ref $simp eq 'CODE') {
		my $msg = $@? "Error: $@" : '';
		confess("Could not find simplification routine as '${class}::simplify'.");
	}
	
	$Registered{$class}++;	
	push @Simplification_Stack, [$class, $simp];
	
	no strict; no warnings qw/redefine/;
	*Math::Symbolic::Operator::simplify = $simp;

	return 1;
}


sub unregister {
	my $class = shift;
	confess("Cannot unregister simplification routine when not called as class method.") if not defined $class;
	
	return 0 if not $Registered{$class};

	while (@Simplification_Stack and $class ne $Simplification_Stack[-1][0]) {
		my $this = pop @Simplification_Stack;
		$Registered{$this->[0]}--;
	};

	my $this = pop @Simplification_Stack;
	$Registered{$this->[0]}--;

	if (not @Simplification_Stack) {
		_reset();
		return 0;
	}
	
	no strict; no warnings qw/redefine/;
	*Math::Symbolic::Operator::simplify = $Simplification_Stack[-1][1];

	return 1;
}


1;
__END__

=head1 NAME

Math::Symbolic::Custom::Simplification - User defined simplification routines

=head1 SYNOPSIS

  package Math::Symbolic::Custom::MySimplification;
  
  use base 'Math::Symbolic::Custom::Simplification';
  
  sub simplify {
    my $tree = shift;
    # ... simplify tree ...
    return $simplified;
  }
  
  1;
  
  # Then, in another portion of your code.
  
  Math::Symbolic::Custom::MySimplification->register();
  
  # Code that uses MySimplification:
  # $tree->simplify() invokes
  # Math::Symbolic::Custom::MySimplification::simplify($tree).
  
  Math::Symbolic::Custom::MySimplification->unregister();
  
  # Code that uses the default simplification routines or whichever
  # simplification routines where registered before.

=head1 DESCRIPTION

This module is an extension to the Math::Symbolic module. A basic
familiarity with that module is required.

Math::Symbolic offers some builtin simplification routines. These, however,
are not capable of complex simplifications. This extension offers facilities
to override the default simplification routines through means of subclassing
this module. A subclass of this module is required to define a C<simplify>
object method that implements a simplification of Math::Symbolic trees.

There are two class methods to inherit: I<register> and I<unregister>.
Calling the C<register> method on your subclass registers your class as
providing the I<simplify> method that is invoked whenever C<simplify()> 
is called on a Math::Symbolic::Operator object.

Calling C<unregister> on your subclass restores whichever simplification
routines where in place before.

Several subsequent C<register()> and c<unregister()> calls on different
subclasses can be used to localize simplification routines.
The old routines are saved to a stack.

If there are several subclasses of this module, say C<MySimplification> and
C<MyOtherSimplification>, calling C<MySimplification->register()>, then
C<MyOtherSimplification->register()> will finally provide the
simplification routines of I<MyOtherSimplification>. Unregistering
I<MyOtherSimplification> revert to the routine from I<MySimplification>.

If you unregister out of order (i.e. in the above example if you
unregistered I<MySimplification> instead of I<MyOtherSimplification>),
all simplification routines up to and including the one you're unregistering
are removed and the one that was in effect before I<MySimplification> (here:
the default C<simplify()>) is restored.

=head2 EXPORT

This module does not export anything.

=head2 METHODS

=over 2

=item register

A class method to register the C<simplify()> subroutine of the class as the
new Math::Symbolic simplification rotuine.

=item unregister

A class method to unregister the aformentioned simplification routine.

=back

=head1 SEE ALSO

New versions of this module can be found on http://steffen-mueller.net or CPAN.

L<Math::Symbolic>

L<Math::Symbolic::Operator> which contains the default simplification routines.

L<Math::Symbolic::Custom> and L<Math::Symbolic::Custom::Base> for details on
enhancing Math::Symbolic.

=head1 AUTHOR

Steffen Müller, E<lt>symbolic-module at steffen-mueller dot net<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2005 by Steffen Müller

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.4 or,
at your option, any later version of Perl 5 you may have available.


=cut
