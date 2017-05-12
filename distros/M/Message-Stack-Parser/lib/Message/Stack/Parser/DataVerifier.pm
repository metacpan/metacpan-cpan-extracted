package Message::Stack::Parser::DataVerifier;
{
  $Message::Stack::Parser::DataVerifier::VERSION = '0.06';
}
use Moose;

# ABSTRACT: Add messages to a Message::Stack from a Data::Verifier results

with 'Message::Stack::Parser';

use Message::Stack::Message;


sub parse {
    my ($stack, $scope, $results) = @_;

    foreach my $f ($results->missings) {
        $stack->add(Message::Stack::Message->new(
            msgid   => "missing_$f",
            scope   => $scope,
            subject => $f,
            level   => 'error'
        ));
    }

    foreach my $f ($results->invalids) {
        $stack->add(Message::Stack::Message->new(
            msgid   => "invalid_$f",
            scope   => $scope,
            subject => $f,
            level   => 'error',
            params  => [ $results->get_original_value($f), $results->get_field($f)->reason ],
        ));
    }

    return $stack;
}

1;

__END__
=pod

=head1 NAME

Message::Stack::Parser::DataVerifier - Add messages to a Message::Stack from a Data::Verifier results

=head1 VERSION

version 0.06

=head1 SYNOPSIS

  use Message::Stack::Parser::DataVerifier;

  my $dv = Data::Verifier->new;

  my $dv_results = $dv->verify;

  my $scope = 'login';

  # Pass a Data::Verifier::Results object to parse.
  my $ms = Message::Stack->new;
  Message::Stack::Parser::DataVerifier::parse(
    $ms,
    $scope,
    $dv_results
  );

  # and now $ms has messages based on $dv_results

=head1 DESCRIPTION

This class will add a message to the provided L<Message::Stack> for every
missing or invalid field in a L<Data::Verifier::Result>.

=head1 MAPPING

The fields are mapped from Data::Verifier into a Message in the following way:

=head2 Missing Fields

=over 4

=item B<msgid> = C<"missing_$fieldname">

=item B<scope> = The passed in scope

=item B<subject> = C<$fieldname>

=item B<level> = 'error'

=back

=head2 Invalid Fields

=over 4

=item B<msgid> = C<"invalid_$fieldname">

=item B<scope> = The passed in scope

=item B<subject> = C<$fieldname>

=item B<level> = 'error'

=item B<params> = The original value (that provided by the user) for the field.

=back

=head1 METHODS

=head2 parse ($stack, $scope, $results)

Adds messages from the provided C<$results> to the provided C<$stack> under
the C<$scope> that is passed in.

=head1 AUTHOR

Cory G Watson <gphat@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2012 by Cold Hard Code, LLC.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

