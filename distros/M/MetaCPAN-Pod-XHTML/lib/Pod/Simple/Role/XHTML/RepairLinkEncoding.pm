package Pod::Simple::Role::XHTML::RepairLinkEncoding;
use Moo::Role;

our $VERSION = '0.003001';
$VERSION =~ tr/_//d;

use HTML::Entities qw(decode_entities encode_entities);
use URL::Encode qw(url_encode_utf8);

use namespace::clean;

around resolve_pod_page_link => sub {
  my $orig = shift;
  my $self = shift;
  local $self->{__resolving_link} = 1;
  $self->$orig(@_);
};

around end_item_text => sub {
  my $orig = shift;
  my $self = shift;
  local $self->{__in_end_item_text} = 1;
  $self->$orig(@_);
};

around _end_head => sub {
  my $orig = shift;
  my $self = shift;
  local $self->{__in_end_head} = 1;
  $self->$orig(@_);
  my $index_entry = $self->{'to_index'}[-1];

  # the index entry added by default has the id of the link target, and uses
  # it directly as a URL fragment. we need to re-encode it to a proper form.
  $index_entry->[1] = encode_entities(
    url_encode_utf8( decode_entities( $index_entry->[1] ) ) );
};

around idify => sub {
  my $orig = shift;
  my $self = shift;
  my ($text, $not_unique) = @_;

  $text = decode_entities($text)
    if $self->{__in_end_item_text} || $self->{__in_end_head};
  $text =~ s/<[^>]+>//g
    if $self->{__in_end_item_text};

  my $id = $self->$orig($text, $not_unique);

  $id = url_encode_utf8($id)
    if $self->{__resolving_link};

  $id = encode_entities($id);
  return $id;
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

L<Pod::Simple> (until at least 3.43) doesn't handle encoding of section links
correctly if they contain any characters that need to be entity encoded. It
doesn't understand that ids and link fragments need to be encoded differently.

Applying this role will repair this, allowing any id generation routine to be
used. It must be applied after any role that modifies the C<idify> method.

This role should usually not be used directly. A future version of
L<Pod::Simple> will fix this, but until then it is used internally by
L<Pod::Simple::Role::XHTML::WithAccurateTargets>.

=head1 SUPPORT

See L<MetaCPAN::Pod::XHTML> for support and contact information.

=head1 AUTHORS

See L<MetaCPAN::Pod::XHTML> for authors.

=head1 COPYRIGHT AND LICENSE

See L<MetaCPAN::Pod::XHTML> for the copyright and license.

=cut

