package MetaCPAN::Pod::HTML;
use Moo;

our $VERSION = '0.004000';
$VERSION =~ tr/_//d;

use namespace::clean;

extends 'Pod::Simple::XHTML';
with qw(
  Pod::Simple::Role::XHTML::HTML5
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

MetaCPAN::Pod::HTML - Format Pod as HTML for MetaCPAN

=head1 SYNOPSIS

  my $parser = MetaCPAN::Pod::HTML->new;
  $parser->link_mappings({
    'Pod::Simple::Subclassing' => '/pod/distribution/Pod-Simple/lib/Pod/Simple/Subclassing.pod',
  });
  $parser->output_string(\my $html);
  $parser->parse_string_document($pod);

=head1 DESCRIPTION

This is a subclass of L<Pod::Simple::XHTML> with improved header linking, link
overrides, errata included in the HTML, and producing HTML5. Used internally
by MetaCPAN.

=head1 ROLES

The behavior of this subclass is implemented through reusable roles:

=over 4

=item *

L<Pod::Simple::Role::XHTML::HTML5>

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

=head1 AUTHOR

haarg - Graham Knop (cpan:HAARG) <haarg@haarg.org>

=head1 CONTRIBUTORS

=over 4

=item *

Olaf Alders <olaf@wundersolutions.com>

=item *

Randy Stauner <randy@magnificent-tears.com>

=item *

Moritz Onken <onken@netcubed.de>

=item *

Grant McLean <grant@mclean.net.nz>

=back

=head1 COPYRIGHT

Copyright (c) 2017 the MetaCPAN::Pod::HTML L</AUTHOR> and L</CONTRIBUTORS>
as listed above.

=head1 LICENSE

This library is free software and may be distributed under the same terms
as perl itself. See L<http://dev.perl.org/licenses/>.

=cut
