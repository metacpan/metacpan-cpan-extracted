package Langertha::Role::JSON;
# ABSTRACT: Role for JSON
our $VERSION = '0.500';
use Moose::Role;
use JSON::MaybeXS;
use Encode qw( encode_utf8 );

sub json { shift->_json }

sub decode_json_text {
  my ( $self, $text ) = @_;
  return undef unless defined $text;
  return $self->_json->decode(encode_utf8($text));
}



has _json => (
  is => 'ro',
  lazy_build => 1,
);
sub _build__json { JSON::MaybeXS->new( utf8 => 1, canonical => 1 ) }


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Langertha::Role::JSON - Role for JSON

=head1 VERSION

version 0.500

=head2 decode_json_text

    my $data = $engine->decode_json_text($perl_string);

Decodes a JSON string that is already a Perl-Unicode string (e.g. a value
pulled out of an already-decoded response tree, or a substring extracted
from assistant-produced text). The shared L<JSON::MaybeXS> instance is
configured with C<utf8 =E<gt> 1> and expects raw bytes, so this helper
UTF-8-encodes the text before delegating to it. Use this instead of
C<< $self->json->decode >> whenever the source is Perl-Unicode rather
than the raw HTTP body.

=head2 json

    my $data = $engine->json->decode($json_string);
    my $json_string = $engine->json->encode($data);

Returns the shared L<JSON::MaybeXS> instance configured with C<utf8> and
C<canonical> encoding. Used internally by L<Langertha::Role::HTTP> and
L<Langertha::Role::Streaming> for all JSON serialization.

=head1 SEE ALSO

=over

=item * L<Langertha::Role::HTTP> - HTTP role that requires this

=item * L<JSON::MaybeXS> - The JSON backend used

=back

=head1 SUPPORT

=head2 Issues

Please report bugs and feature requests on GitHub at
L<https://github.com/Getty/langertha/issues>.

=head2 IRC

Join C<#langertha> on C<irc.perl.org> or message Getty directly.

=head1 CONTRIBUTING

Contributions are welcome! Please fork the repository and submit a pull request.

=head1 AUTHOR

Torsten Raudssus <getty@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2026 by Torsten Raudssus L<https://raudssus.de/>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
