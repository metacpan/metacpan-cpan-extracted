package MetaCPAN::Pod::XHTML;
use Moo;

our $VERSION = '0.004000';
$VERSION =~ tr/_//d;

use namespace::clean;

extends 'Pod::Simple::XHTML';
with qw(
  Pod::Simple::Role::XHTML::WithLinkMappings
  Pod::Simple::Role::XHTML::WithExtraTargets
  Pod::Simple::Role::XHTML::WithAccurateTargets
  Pod::Simple::Role::XHTML::WithErrata
  Pod::Simple::Role::XHTML::WithHighlightConfig
  Pod::Simple::Role::StripVerbatimIndent
);

sub BUILD {
  my $self = shift;
  $self->anchor_items(1);
}

1;
__END__

=head1 NAME

MetaCPAN::Pod::XHTML - Format Pod as HTML for MetaCPAN

=head1 SYNOPSIS

  my $parser = MetaCPAN::Pod::XHTML->new;
  $parser->link_mappings({
    'Pod::Simple::Subclassing' => '/pod/distribution/Pod-Simple/lib/Pod/Simple/Subclassing.pod',
  });
  $parser->output_string(\my $html);
  $parser->parse_string_document($pod);

=head1 DESCRIPTION

This is a subclass of Pod::Simple::XHTML with improved header linking, link
overrides, and errata included in the HTML.  Used internally by MetaCPAN.

=head1 ROLES

The behavior of this subclass is implemented through reusable roles:

=over 4

=item *

L<Pod::Simple::Role::XHTML::WithLinkMappings>

=item *

L<Pod::Simple::Role::XHTML::WithExtraTargets>

=item *

L<Pod::Simple::Role::XHTML::WithAccurateTargets>

=item *

L<Pod::Simple::Role::XHTML::WithErrata>

=item *

L<Pod::Simple::Role::XHTML::WithHighlightConfig>

=item *

L<Pod::Simple::Role::StripVerbatimIndent>

=back

=head1 DEFAULTS

=over 4

=item anchor_items

By default, anchor_items is set to true.

=back

=head1 SUPPORT

See L<MetaCPAN::Pod::HTML> for support and contact information.

=head1 AUTHORS

See L<MetaCPAN::Pod::HTML> for authors.

=head1 COPYRIGHT AND LICENSE

See L<MetaCPAN::Pod::HTML> for the copyright and license.

=cut
