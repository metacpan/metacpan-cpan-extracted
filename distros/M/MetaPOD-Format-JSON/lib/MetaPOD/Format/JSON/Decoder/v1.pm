use strict;
use warnings;

package MetaPOD::Format::JSON::Decoder::v1;
BEGIN {
  $MetaPOD::Format::JSON::Decoder::v1::AUTHORITY = 'cpan:KENTNL';
}
{
  $MetaPOD::Format::JSON::Decoder::v1::VERSION = '0.3.0';
}

# ABSTRACT: C<JSON> to Structure translation layer


use Moo::Role;
use Try::Tiny qw( try catch );


sub decode {
  my ( $self, $data ) = @_;
  require JSON;
  my $return;
  try {
    $return = JSON->new->decode($data);
  }
  catch {
    require MetaPOD::Exception::Decode::Data;
    MetaPOD::Exception::Decode::Data->throw(
      {
        internal_message   => $_,
        data               => $data,
        previous_exception => $_,
      }
    );
  };
  return $return;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

MetaPOD::Format::JSON::Decoder::v1 - C<JSON> to Structure translation layer

=head1 VERSION

version 0.3.0

=head1 METHODS

=head2 C<decode>

Spec V1 C<JSON> Decoder

    my $hash = _SOME_CLASS_->decode( $json_string );

=begin MetaPOD::JSON v1.1.0

{
    "namespace":"MetaPOD::Format::JSON::Decoder::v1",
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
