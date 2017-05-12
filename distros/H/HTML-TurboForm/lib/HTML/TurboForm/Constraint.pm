package HTML::TurboForm::Constraint;
use warnings;
use strict;
use base qw/ Class::Accessor /;
__PACKAGE__->mk_accessors( qw/ params request type name text / );

sub message{
  my ($self)=@_;
  
  return $self->text;
}


1;


__END__

=head1 HTML::TurboForm::Constraint

Base Class for formconstraints

=head1 SYNOPSIS

$form->addconstraint(...);

=head1 DESCRIPTION

Straight forward so no need for much documentation.
See HTML::TurboForm doku for mopre details.

=head1 METHODS

=head2 message

Arguments: none

returns error message of constraint

=head1 AUTHOR

Thorsten Domsch, tdomsch@gmx.de

=cut