package Math::SymbolicX::Calculator::Command;

use 5.006;
use strict;
use warnings;
use Carp qw/croak/;

our $VERSION = '0.02';

use vars qw/@CMDS/;

# load the command classes.
BEGIN {
    @CMDS = qw(
        Assignment
        Transformation
        DerivativeApplication
        Insertion
    );
    foreach (@CMDS) {
        eval "require Math::SymbolicX::Calculator::Command::$_;";
        die "Could not load Math::SymbolicX::Calculator::Command::$_. Error: $@"
          if $@;
    }
}

=encoding utf8

=head1 NAME

Math::SymbolicX::Calculator::Command - Base class for Calculator commands

=head1 SYNOPSIS

  use Math::SymbolicX::Calculator;
  my $calc = Math::SymbolicX::Calculator->new();
  
  # setup formula to be a Math::Symbolic tree or a transformation...
  
  my $assignment = $calc->new_command(
    type => 'Assignment', symbol => 'foo', object => $formula,
  );
  
  $calc->execute($assignment);

=head1 DESCRIPTION

This class is a base class for commands to the a
L<Math::SymbolicX::Calculator> object. Various commands are implemented as
subclasses. See below for a list of core Commands and their usage.

=head1 AVAILABLE COMMANDS

=head2 Assignment

L<Math::SymbolicX::Calculator::Command::Assignment> is an assignment 
of a formula or transformation to a symbol table slot.

Parameters to the constructor:

  symbol => the symbol name to assign to
  object => Math::Symbolic tree or
            Math::Symbolic::Custom::Transformation to assign
            to the symbol

Execution of this command returns the following list:
C<$sym, '==', $func> where C<$sym> is the name of the modified symbol
and C<$func> is its new value.

=head2 Transformation

L<Math::SymbolicX::Calculator::Command::Transformation> is a transformation
application to a formula stored in a symbol table slot.

Parameters to the constructor:

  symbol  => the name of the symbol to modify
  trafo   => Math::Symbolic::Custom::Transformation object to apply
  shallow => boolean: Set this to true to apply shallowly or to
             false to apply recursively (default)

Execution of this command returns the following list:
C<$sym, '==', $func> where C<$sym> is the name of the modified symbol
and C<$func> is its new value.

=head2 Insertion

L<Math::SymbolicX::Calculator::Command::Insertion> is a replacement
of all variables in a formula (in a symbol table slot) by what's found
in the symbol table under the corresponding variable names.

Parameters to the constructor:

  symbol => the name of the symbol to modify
  optional:
  what   => the name of the variable to replace with its symbol
            table value or '*' for everything
            Defaults to everything.

Execution of this command returns the following list:
C<$sym, '==', $func> where C<$sym> is the name of the modified symbol
and C<$func> is its new value.

=head2 DerivativeApplication

L<Math::SymbolicX::Calculator::Command::DerivativeApplication>
is the application of all derivatives in a function in a
symbol table slot.

Parameters to the constructor:

  symbol => the name of the symbol to modify
  optional:
  level  => the number of nested derivatives to apply.
            Defaults to all/any (undef).

Execution of this command returns the following list:
C<$sym, '==', $func> where C<$sym> is the name of the modified symbol
and C<$func> is its new value.

=head1 METHODS

=cut

=head2 new

Returns a new Command object. Takes named parameters. The only
universally mandatory parameter is the C<type> of the command to 
create. All paramaters are passed thorugh to the constructed
of the implementing subclass. That means if C<type> is C<Assignment>,
then C<new> will call
C<Math::SymbolicX::Calculator::Command::Assignment->new()>
with its arguments.

=cut


sub new {
    my $proto = shift;
    my $class = ref($proto)||$proto;

    my %args = @_;

    croak("Need 'type' argument to " . __PACKAGE__ . "->new()")
      if not defined $args{type};
    $class .= "::" . $args{type};
    return $class->new(@_);
}


1;
__END__

=head1 SEE ALSO

L<Math::SymbolicX::Calculator>,
L<Math::SymbolicX::Calculator::Interface::Shell>

L<Math::Symbolic>, L<Math::Symbolic::Custom::Transformation>

=head1 AUTHOR

Steffen Müller, E<lt>smueller@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2006, 2013 by Steffen Müller

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.6 or,
at your option, any later version of Perl 5 you may have available.

=cut

