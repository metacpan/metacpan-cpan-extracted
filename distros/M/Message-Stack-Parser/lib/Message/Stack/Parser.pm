package Message::Stack::Parser;
{
  $Message::Stack::Parser::VERSION = '0.06';
}
use Moose::Role;

# ABSTRACT: A simple role for creating a Message::Stack from things


requires 'parse';


1;

__END__
=pod

=head1 NAME

Message::Stack::Parser - A simple role for creating a Message::Stack from things

=head1 VERSION

version 0.06

=head1 SYNOPSIS

  use Message::Stack::Parser::DataVerifier;

  my $dv = Data::Verifier->new;

  my $dv_results = $dv->verify;

  my $scope = 'login';
  # Pass a Data::Verifier::Results object to parse.
  my $ms = Message::Stack::Parser::DataVerifier->new->parse(
    Message::Stack->new,
    $scope,
    $dv_results
  );

=head1 DESCRIPTION

Message::Stack::Parser is a L<Moose> role that is used to implement a parser
for converting something into a L<Message::Stack>.  This role is nothing more
than a single required method.  The actual point of this dist is to package
some of the parsers separate from Message::Stack or the modules that may
do the conversion.  Those are L<Message::Stack::Parser::DataVerifier> and
L<Message::Stack::Parser::FormValidator>.

=head1 METHODS

=head2 parse ($stack, $scope, $results)

Adds messages from the provided C<$results> to the provided C<$stack> under
the C<$scope> that is passed in.  This is the only method you need to implement.

The C<$stack> must be provided so multiple things may be parsed into a single
stack.  The C<$scope> is used to keep multiple parsings separated.  How this
method works is completely up to the implementor, as the C<$results> argument
could be anything.

=head1 AUTHOR

Cory G Watson <gphat@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2012 by Cold Hard Code, LLC.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

