use v5.14.0;
use warnings;
package JMAP::Tester::Role::Result 0.104;
# ABSTRACT: the kind of thing that you get back for a request

use Moo::Role;

use JMAP::Tester::Abort ();

use namespace::clean;

#pod =head1 OVERVIEW
#pod
#pod This is the role consumed by the class of any object returned by JMAP::Tester's
#pod C<request> method.  Its only guarantee, for now, is an C<is_success> method,
#pod and a C<response_payload> method.
#pod
#pod =cut

requires 'is_success';
requires 'response_payload';

#pod =method assert_successful
#pod
#pod This method returns the result if it's a success and otherwise aborts.
#pod
#pod =cut

sub assert_successful {
  my ($self) = @_;

  return $self if $self->is_success;

  my $str = $self->can('has_ident') && $self->has_ident
          ? $self->ident
          : "JMAP failure";

  die JMAP::Tester::Abort->new($str);
}

#pod =method assert_successful_set
#pod
#pod   $result->assert_successful_set($name);
#pod
#pod This method is equivalent to:
#pod
#pod   $result->assert_successful->sentence_named($name)->as_set->assert_no_errors;
#pod
#pod C<$name> must be provided.
#pod
#pod =cut

sub assert_successful_set {
  my ($self, $name) = @_;
  $self->assert_successful->sentence_named($name)->as_set->assert_no_errors;
}

#pod =method assert_single_successful_set
#pod
#pod   $result->assert_single_successful_set($name);
#pod
#pod This method is equivalent to:
#pod
#pod   $result->assert_successful->single_sentence($name)->as_set->assert_no_errors;
#pod
#pod C<$name> may be omitted, in which case the sentence name is not checked.
#pod
#pod =cut

sub assert_single_successful_set {
  my ($self, $name) = @_;
  $self->assert_successful->single_sentence($name)->as_set->assert_no_errors;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

JMAP::Tester::Role::Result - the kind of thing that you get back for a request

=head1 VERSION

version 0.104

=head1 OVERVIEW

This is the role consumed by the class of any object returned by JMAP::Tester's
C<request> method.  Its only guarantee, for now, is an C<is_success> method,
and a C<response_payload> method.

=head1 PERL VERSION

This library should run on perls released even a long time ago.  It should
work on any version of perl released in the last five years.

Although it may work on older versions of perl, no guarantee is made that the
minimum required version will not be increased.  The version may be increased
for any reason, and there is no promise that patches will be accepted to
lower the minimum required perl.

=head1 METHODS

=head2 assert_successful

This method returns the result if it's a success and otherwise aborts.

=head2 assert_successful_set

  $result->assert_successful_set($name);

This method is equivalent to:

  $result->assert_successful->sentence_named($name)->as_set->assert_no_errors;

C<$name> must be provided.

=head2 assert_single_successful_set

  $result->assert_single_successful_set($name);

This method is equivalent to:

  $result->assert_successful->single_sentence($name)->as_set->assert_no_errors;

C<$name> may be omitted, in which case the sentence name is not checked.

=head1 AUTHOR

Ricardo SIGNES <cpan@semiotic.systems>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2016 by Fastmail Pty. Ltd.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
