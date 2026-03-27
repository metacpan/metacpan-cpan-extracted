package Pod::Simple::Role::XHTML::RepairLinkEncoding;
use Moo::Role;

our $VERSION = '0.004001';
$VERSION =~ tr/_//d;

use namespace::clean;

around encode_url => sub {
  my $orig = shift;
  my $self = shift;
  my ($string) = @_;
  utf8::encode($string);
  $self->$orig($string);
};

1;
__END__

=head1 NAME

Pod::Simple::Role::XHTML::RepairLinkEncoding - Repair encoding of section links

=head1 SYNOPSIS

  package MyPodParser;
  with 'Pod::Simple::Role::XHTML::RepairLinkEncoding';

  my $parser = MyPodParser->new;
  $parser->output_string(\my $html);
  $parser->parse_string_document($pod);

=head1 DESCRIPTION

L<Pod::Simple> (until at least 3.47) doesn't handle encoding of section link
correctly if they contain non-ASCII characters. It will do "percent" encoding,
but does not first encode as bytes, so it generates invalid sequences. The
fragments generated from section links must be encoded as UTF-8 before being
percent encoded.

Applying this role will repair this, generating the correct fragments.

This role should usually not be used directly. A future version of
L<Pod::Simple> will fix this, but until then it is used internally by
L<Pod::Simple::Role::XHTML::WithAccurateTargets>.

=head1 SUPPORT

See L<MetaCPAN::Pod::HTML> for support and contact information.

=head1 AUTHORS

See L<MetaCPAN::Pod::HTML> for authors.

=head1 COPYRIGHT AND LICENSE

See L<MetaCPAN::Pod::HTML> for the copyright and license.

=cut

