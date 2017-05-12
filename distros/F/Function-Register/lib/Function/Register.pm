package Function::Register;
# $Id: Register.pm,v 1.2 2004/05/21 05:18:19 cwest Exp $
use strict;

use vars qw[$VERSION %REGISTRIES %REGISTRANTS];
$VERSION = (qw$Revision: 1.2 $)[1];

=head1 NAME

Function::Register - Create Function Registries and Register Functions

=head1 SYNOPSIS

  package Company::Employee;
  use Function::Register;
  set_register 'Type';
  
  sub employee_type {
      my $self = shift;
      for ( @Type ) {
          my $retval = $_->($self);
          return $retval if $retval;
      }
      return;
  }


  # meanwhile, in some other package
  package Company::Employee::Executive;
  use Function::Register 'Company::Employee';

  register Type => \&is_cto;
  register Type => \&is_ceo;
  
  sub is_cto { ... }
  sub is_ceo { ... }

  # meanwhile, in your program
  use Company::Employee;
  use Company::Employee::Executive;
  
  my $employee = Company::Employee->new( title => "CEO", ... );
  print $employee->employee_type;

=head1 DESCRIPTION

This module allows you to declare registers in your namespace, and update
registers in other modules.

=head2 Exports

There are two ways to use this modules.

=over 4

=item As the Registry

  use Function::Register;

As the registry you simply use the module without any arguments. This will
export the C<set_register> function. It will also create a default register
in your namespace called C<@REGISTER>.

=item As the Registrant

  use Function::Register qw[Some::NameSpace];

As the registrant you use the module with a single argument. This will
export the C<register> function. It will remember what namespace you
want to add to each time you call C<register>.

=back

=cut

sub import {
    my ($class, $registry) = @_;
    if ( $registry ) {
        my $registrant = caller;
        $REGISTRANTS{$registrant} = $registry;
        _export( $registrant, 'register' );
    } else {
        _export( scalar(caller()), 'set_register' );
        @_ = ();
        goto &set_register;
    }
}

=head2 Functions

=over 4

=item set_registry

  set_registry 'Name';

This function creates a new register in your namespace. A register is a
package array of the same name. The call above creates an array, C<@Name>,
in your namespace.

=cut

sub set_register($) {
    my $registry = shift() || 'REGISTER';
    my $package  = caller;
    $REGISTRIES{$package}->{$registry} = 1;
    my @reg;
    no strict 'refs';
    *{"$package\::$registry"} = \@reg;
}

=item register

  register sub { ... };
  register Name => \&function_ref;

This function registeres functions in the namespace you've declared
as your registrant. If a single argument is given the function is
added to the default registry. If two arguments are given, the first
is the name of of the register and the second is a function.

This function returns a false value if it was unable to add the
function to the register. This may be because the register name
does not exist, or the function argument isn't a code reference.

If C<register> is successful it returns true.

  die "Couldn't add to register"
    unless register \&some_func;

=back

=cut

sub register($;$) {
    my $reg = 'REGISTER';
    my $func;
    if ( @_ == 2) {
        ($reg, $func) = @_;
    } else {
        ($func) = @_;
    }
    return unless ref($func) eq 'CODE';
    return unless exists $REGISTRIES{$REGISTRANTS{caller()}}->{$reg};
    my $registry = join '::', $REGISTRANTS{caller()}, $reg;
    no strict 'refs';
    unshift @{"$registry"}, $func;
}

sub _export {
    my ($package, $name) = @_;
    no strict 'refs';
    *{"$package\::$name"} = \&{"$name"};
}

1;

__END__

=head1 SEE ALSO

For a more OO and "do it all for me behind my back" approach, see
L<Module::Pluggable>.

L<perl>.

=head1 AUTHOR

Casey West, <F<casey@geeknest.com>>.

=head1 COPYRIGHT

  Copyright (c) 2004 Casey West.  All rights reserved.
  This module is free software; you can redistribute it and/or modify it
  under the same terms as Perl itself.

=cut
