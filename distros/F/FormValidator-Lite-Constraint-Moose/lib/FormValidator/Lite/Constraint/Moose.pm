package FormValidator::Lite::Constraint::Moose;
use strict;
use warnings;
use utf8;
use 5.008003;
use FormValidator::Lite::Constraint;
use Moose::Util::TypeConstraints ();

our $VERSION = '0.13';

my $get_constraint = Moose::Util::TypeConstraints->can('find_type_constraint');

my @types = Moose::Util::TypeConstraints->list_all_type_constraints();
for my $name (@types) {
    my $constraint = $get_constraint->($name);
    rule $name => sub {
        my $value = $_;
        
        $constraint->check($value) or do {
            return unless $constraint->has_coercion;
            
            $value = $constraint->coerce($value);
            
            return $constraint->check($value);
        };
    };
}

1;
__END__

=head1 NAME

FormValidator::Lite::Constraint::Moose - Use Moose's type constraints.

=head1 SYNOPSIS

  use FormValidator::Lite;
  FormValidator::Lite->load_constraints(qw/Moose/);

  my $validator = FormValidator::Lite->new(CGI->new("flg=1"));
  $validator->check(
     flg => ['Bool']
  );

  #if you wanna use your original constraints.
  use FormValidator::Lite;
  use Moose::Util::TypeConstraints;

  enum 'HttpMethod' => [qw(GET HEAD POST PUT DELETE)]; #you must load before load 'FormValidator::Lite->load_constraints(qw/Moose/)'

  FormValidator::Lite->load_constraints(qw/Moose/);

  my $validator = FormValidator::Lite->new(CGI->new("req_type=GET"));
  $validator->check(
     "req_type => ['HttpMethod']
  );


=head1 DESCRIPTION

This module provides Moose's type constraint as constraint rule of L<FormValidator::Lite>
If you want to know the constraint, see L<Moose::Util::TypeConstraints> for details.

=head1 AUTHOR

Hideaki Ohno E<lt>hide.o.j55 {at} gmail.comE<gt>

=head1 SEE ALSO

L<FormValidator::Lite>,L<Moose::Util::TypeConstraints>

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
