package FormValidator::Lite::Constraint::Mouse;
use strict;
use warnings;
use FormValidator::Lite::Constraint;
use Mouse::Util::TypeConstraints ();

our $VERSION = '0.05';

my $get_constraint = \&Mouse::Util::TypeConstraints::find_type_constraint;

my @types = Mouse::Util::TypeConstraints::list_all_type_constraints();
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

FormValidator::Lite::Constraint::Mouse - Use Mouse's type constraints.

=head1 SYNOPSIS

  use FormValidator::Lite;
  FormValidator::Lite->load_constraints(qw/Mouse/);

  my $validator = FormValidator::Lite->new(CGI->new("flg=1"));
  $validator->check(
     flg => ['Bool']
  );

  #if you wanna use your original constraints.
  use FormValidator::Lite;
  use Mouse::Util::TypeConstraints;

  enum 'HttpMethod' => qw(GET HEAD POST PUT DELETE); #you must load before load 'FormValidator::Lite->load_constraints(qw/Mouse/)'

  FormValidator::Lite->load_constraints(qw/Mouse/);

  my $validator = FormValidator::Lite->new(CGI->new("req_type=GET"));
  $validator->check(
     "req_type => ['HttpMethod']
  );


=head1 DESCRIPTION

This module provides Mouse's type constraint as constraint rule of L<FormValidator::Lite>
If you want to know the constraint, see L<Mouse::Util::TypeConstraints> for details.

=head1 AUTHOR

Hideaki Ohno E<lt>hide.o.j55 {at} gmail.comE<gt>

=head1 SEE ALSO

L<FormValidator::Lite>,L<Mouse::Util::TypeConstraints>

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
