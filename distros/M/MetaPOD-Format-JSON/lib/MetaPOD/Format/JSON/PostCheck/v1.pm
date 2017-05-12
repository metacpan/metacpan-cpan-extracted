use strict;
use warnings;

package MetaPOD::Format::JSON::PostCheck::v1;
BEGIN {
  $MetaPOD::Format::JSON::PostCheck::v1::AUTHORITY = 'cpan:KENTNL';
}
{
  $MetaPOD::Format::JSON::PostCheck::v1::VERSION = '0.3.0';
}

# ABSTRACT: Handler for unrecognised tokens in C<JSON>


use Moo::Role;
use Carp qw( croak );


sub postcheck {
  my ( $self, $data, $result ) = @_;

  if ( keys %{$data} ) {
    croak 'Keys found not supported in this version: <' . ( join q{,}, keys %{$data} ) . '>';
  }
  return;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

MetaPOD::Format::JSON::PostCheck::v1 - Handler for unrecognised tokens in C<JSON>

=head1 VERSION

version 0.3.0

=head1 METHODS

=head2 C<postcheck>

Spec V1 Handling of unprocessed keys

    __SOME_CLASS__->postcheck({ any_key_makes_it_go_bang => 1 }, $metapod_result );

=begin MetaPOD::JSON v1.1.0

{
    "namespace":"MetaPOD::Format::JSON::PostCheck::v1",
    "interface":"role"
}


=end MetaPOD::JSON

=head1 AUTHOR

Kent Fredric <kentfredric@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by Kent Fredric <kentfredric@gmail.com>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
