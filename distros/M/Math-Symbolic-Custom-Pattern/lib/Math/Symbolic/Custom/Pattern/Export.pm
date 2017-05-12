package Math::Symbolic::Custom::Pattern::Export;

use 5.006001;
use strict;
use warnings;
use Carp qw/cluck confess/;

use Math::Symbolic qw/parse_from_string/;
use Math::Symbolic::Custom::Base;
BEGIN {*import = \&Math::Symbolic::Custom::Base::aggregate_import}

our $VERSION = '2.01';

=encoding utf8

=head1 NAME

Math::Symbolic::Custom::Pattern::Export - Export method to MS::Custom

=head1 SYNOPSIS

  use Math::Symbolic::Custom::Pattern;
  
  # later:
  my $pattern = $tree->to_pattern();
  # and even later:
  $another_tree->is_of_form($pattern);

=head1 DESCRIPTION

This module is an extension to the Math::Symbolic module. A basic
familiarity with that module is required. 

Please have a look at the Math::Symbolic::Custom::Pattern module first.
This is an internal module only. It manages to add two new methods to all
Math::Symbolic objects: C<is_of_form> and C<to_pattern>. It uses the
Math::Symbolic::Custom mechanism for that.

=head2 EXPORT

In a way, this module exports the C<is_of_form> and C<to_pattern> methods to
Math::Symbolic::Base. Please look at L<Math::Symbolic::Custom>.

=cut

our $Aggregate_Export = [qw/is_of_form to_pattern/];

=head2 Math::Symbolic method is_of_form

This method can be called on any Math::Symbolic tree. First argument must be
a pattern. Returns true if the pattern matches the tree and false if not.
As with the C<match()> method on Math::Symbolic::Custom::Pattern objects,
the true value returned reflects the way the pattern matched. Please see
L<Math::Symbolic::Custom::Pattern> for details.

The pattern may either be a Math::Symbolic::Custom::Pattern object (fastest)
or a Math::Symbolic tree representing a pattern (decent speed, since only the
pattern object needs to be constructed) or a string to be parsed as a
Math::Symbolic tree (very slow since the string has to be parsed).

For details on patterns, please refer to the documentation of
Math::Symbolic::Custom::Pattern.

This method always throws fatal errors since returning a boolean is used for
valid, non-error return values. Therefore, if you plan to pass unvalidated
objects or strings to be parsed, consider wrapping calls to this method in
C<eval {}> blocks. (Note that C<eval BLOCK> is the safer brother of
the much despised C<eval STRING>. See L<perlfunc>.)

=cut

sub is_of_form {
	my $self = shift;
	my $proto = shift;

	# argument checking
	confess("is_of_form() must be called on Math::Symbolic tree.")
	  if not ref($self) =~ /^Math::Symbolic/;
	confess("is_of_form() requires a Math::Symbolic tree, a string to be parsed as a tree, or a Math::Symbolic::Custom::Pattern as first argument.")
	  if ref($proto) and not ref($proto) =~ /^Math::Symbolic/;
	
	# parse as tree
	if (not ref($proto)) {
		$proto = parse_from_string($proto);
		confess("First argument to is_of_form() was treated as a string. That string could not be parsed as a Math::Symbolic tree.") if not defined $proto;
	}

	if (
		not UNIVERSAL::isa($proto, 'Math::Symbolic::Custom::Pattern')
		and ref($proto) =~ /^Math::Symbolic/
	) {
		$proto = Math::Symbolic::Custom::Pattern->new($proto);
		confess("Could not generate pattern from Math::Symbolic tree.")
		  if not defined $proto;
	}
	
	return $proto->match($self);
}

=head2 Math::Symbolic method to_pattern

Generates a Math::Symbolic::Custom::Pattern object from the Math::Symbolic
tree C<to_pattern> is called on. The pattern can be used with the
C<is_of_form()> method or like any other Math::Symbolic::Custom::Pattern
object. (See that package for details on patterns.)

=cut

sub to_pattern {
	my $self = shift;
	# argument checking
	confess("to_pattern() must be called on Math::Symbolic tree.")
	  if not ref($self) =~ /^Math::Symbolic/;
	return Math::Symbolic::Custom::Pattern->new($self);
}

1;
__END__

=head1 SEE ALSO

New versions of this module can be found on http://steffen-mueller.net or CPAN.

L<Math::Symbolic::Custom::Pattern> for details on usage.

L<Math::Symbolic>

L<Math::Symbolic::Custom> and L<Math::Symbolic::Custom::Base> for details on
enhancing Math::Symbolic.

=head1 AUTHOR

Steffen Müller, E<lt>symbolic-module at steffen-mueller dot netE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2005, 2006, 2013 by Steffen Müller

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.4 or,
at your option, any later version of Perl 5 you may have available.


=cut
