package Pod::Simple::Role::XHTML::WithLinkMappings;
use Moo::Role;

our $VERSION = '0.004000';
$VERSION =~ tr/_//d;

use HTML::Entities qw(decode_entities encode_entities);
use URL::Encode qw(url_encode_utf8);

use namespace::clean;

has link_mappings => ( is => 'rw' );

around resolve_pod_page_link => sub {
  my $orig = shift;
  my $self = shift;
  my $module = shift;
  if (defined $module) {
    my $link_map = $self->link_mappings || {};
    my $link = $link_map->{$module};
    $module = $link
      if defined $link;
  }
  $self->$orig($module, @_);
};

1;
__END__

=head1 NAME

Pod::Simple::Role::XHTML::WithLinkMappings - Map module links to alternate URLs

=head1 SYNOPSIS

  package MyPodParser;
  use Moo;
  extends 'Pod::Simple::XHTML';
  with 'Pod::Simple::Role::XHTML::WithLinkMappings';

  my $parser = MyPodParser->new;
  $parser->link_mappings({
    'Pod::Simple::Subclassing' => 'distribution/Pod-Simple/lib/Pod/Simple/Subclassing.pod',
  });
  $parser->output_string(\my $html);
  $parser->parse_string_document($pod);

=head1 DESCRIPTION

This role will allow mapping links in Pod to alternate locations, rather than
using the module name directly.

=head1 ATTRIBUTES

=head2 link_mappings

A hashref of link sources to targets.

  $parser->link_mappings({
    'Pod::Simple::Subclassing' => 'distribution/Pod-Simple/lib/Pod/Simple/Subclassing.pod',
  });

The resulting link is still combined with
L<perldoc_url_prefix|Pod::Simple::XHTML/perldoc_url_prefix> and
L<perldoc_url_postfix|Pod::Simple::XHTML/perldoc_url_postfix>.

=head1 SUPPORT

See L<MetaCPAN::Pod::HTML> for support and contact information.

=head1 AUTHORS

See L<MetaCPAN::Pod::HTML> for authors.

=head1 COPYRIGHT AND LICENSE

See L<MetaCPAN::Pod::HTML> for the copyright and license.

=cut
