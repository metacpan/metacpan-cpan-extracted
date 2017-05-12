package FormValidator::Simple::Plugin::Trim;

use strict;
use warnings;

our $VERSION = '1.00';

use FormValidator::Simple::Constants;

sub TRIM {
  my ($self, $params, $args) = @_;

  s/^\s*(.*?)\s*$/$1/ms foreach (@$params);

  return (TRUE, $#$params ? $params : $params->[0] );
}

sub TRIM_LEAD {
  my ($self, $params, $args) = @_;

  $DB::single = 1;
  s/^\s+(.*)$/$1/ms foreach (@$params);

  return (TRUE, $#$params ? $params : $params->[0] );
}

sub TRIM_TRAIL {
  my ($self, $params, $args) = @_;

  s/^(.*?)\s+$/$1/ms foreach (@$params);

  return (TRUE, $#$params ? $params : $params->[0] );
}

sub TRIM_COLLAPSE {
  my ($self, $params, $args) = @_;

  for (@$params) {
    s/\s+/ /g;
    s/^\s*(.*?)\s*$/$1/ms;
  }

  return (TRUE, $#$params ? $params : $params->[0] );
}
1;

__END__

=head1 NAME

FormValidator::Simple::Plugin::Trim - Trim fields for FormValidator::Simple

=head1 SYNOPSIS

 use FormValidator::Simple qw/Trim/;

 my $query = CGI->new
 $query->param('int_param', "123 ");

 my $result = FormValidator::Simple->check( $query => [
  int_param => [ 'TRIM', 'INT' ]
 ] );

 $result->valid('int_param') == 123

=head1 DESCRIPTION

A group of validators for use with L<FormValidator::Simple> that will trim 
white space in differnet ways. Will always validate any data passed through 
them as valid.

=head1 VALIDATION COMMANDS

=head2 TRIM

Trim leading and trailing white space

=head2 TRIM_LEAD

Trim leading white space

=head2 TRIM_TRAIL

Trim trailing white space

=head2 TRIM_COLLAPSE

Trim leading and trailing white space, and collapse all whitespace
characters into a single space.

=head1 AUTHOR

Ash Berlin C<< <ash@cpan.org> >>

=head1 LICENSE

Free software. You can redistribute it and/or modify it under the same terms 
as perl itself.

=cut

