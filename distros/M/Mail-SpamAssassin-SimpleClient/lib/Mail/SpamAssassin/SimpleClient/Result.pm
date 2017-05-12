use strict;
use warnings;
package Mail::SpamAssassin::SimpleClient::Result;
{
  $Mail::SpamAssassin::SimpleClient::Result::VERSION = '0.102';
}
# ABSTRACT: the results of checking a message

use Carp ();


sub new {
  my ($class, $arg) = @_;

  bless $arg => $class;
}


sub is_spam { $_[0]->{is_spam} }


sub score { $_[0]->{score} }

sub threshold { $_[0]->{threshold} }


sub sa_version { $_[0]->{version} }


sub tests {
  my ($self) = @_;

  return keys %{ $self->{tests} };
}


sub test_scores {
  my ($self) = @_;

  return %{ $self->{tests} };
}


sub test_descriptions {
  my ($self) = @_;

  return %{ $self->{test_desc} };
}


sub email {
  $_[0]->{email}
}

1;

__END__

=pod

=head1 NAME

Mail::SpamAssassin::SimpleClient::Result - the results of checking a message

=head1 VERSION

version 0.102

=head1 METHODS

=head2 new

  my $result = Mail::SpamAssassin::SimpleClient::Result->new(\%arg);

This method returns a new Result object.  Don't call this method unless you are
Mail::SpamAssassin::SimpleClient.  (I<nota bene>, you are not.)

=head2 is_spam

This method returns a true or false value indicating whether the checked
message was found to be spam.

=head2 score

=head2 threshold

These methods return the message's score and the score that would be needed to
classify the message as spam.

=head2 sa_version

This method returns the version of SpamAssassin that checked the message.

=head2 tests

  my @test_names = $result->tests;

This method returns a list of tests against which the message matched.  Note
that not every test is an indicator of spamminess.  Some indicate hamminess.

=head2 test_scores

  my %test_score = $result->test_scores;

This method returns a list of name/value pairs.  The values are the number of
points (positive or negative) for which the test counts.  Since non-spam
reports do not elaborate on the number of points per test, the value for each
test on a non-spam result is undefined.

=head2 test_descriptions

  my %descriptions = $result->test_descriptions;

This method returns a list of name/value pairs.  The values are the
full description names for any tests run. Since non-spam reports do not
elaborate on individual tests run, the description for each test on a
non-spam result is undefined.

=head2 email

This method returns the email object included in the response.

=head1 AUTHOR

Ricardo Signes <rjbs@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by Ricardo Signes.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
