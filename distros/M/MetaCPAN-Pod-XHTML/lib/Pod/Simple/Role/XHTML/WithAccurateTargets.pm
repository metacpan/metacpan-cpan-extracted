package Pod::Simple::Role::XHTML::WithAccurateTargets;
use Moo::Role;

our $VERSION = '0.003002';
$VERSION =~ tr/_//d;

use Pod::Simple::XHTML ();

use namespace::clean;

sub idify {
  my ( $self, $t, $not_unique ) = @_;

  $t =~ s/^\s+//;
  $t =~ s/\s+$//;
  $t =~ s/[\s-]+/-/g;

  return $t
    if $not_unique;

  my $ids = $self->{ids};
  my $i = '';
  $i++ while $ids->{"$t$i"}++;
  return "$t$i";
}

with 'Pod::Simple::Role::XHTML::RepairLinkEncoding'
  if !defined &Pod::Simple::XHTML::decode_entities;

1;
__END__

=head1 NAME

Pod::Simple::Role::XHTML::WithAccurateTargets - Use more accurate link targets

=head1 SYNOPSIS

  package MyPodParser;
  with 'Pod::Simple::Role::XHTML::WithAccurateTargets';

  my $parser = MyPodParser->new;
  $parser->output_string(\my $html);
  $parser->parse_string_document($pod);

=head1 DESCRIPTION

The normal targets used by L<Pod::Simple::XHTML> are heavily filtered, meaning
heading that are primarily symbolic (such as C<@_> in L<perlvar>) can't be
usefully linked externally.  Link targets will be added using minimal filtering,
which will also be used for linking to external pages.

=head1 SUPPORT

See L<MetaCPAN::Pod::XHTML> for support and contact information.

=head1 AUTHORS

See L<MetaCPAN::Pod::XHTML> for authors.

=head1 COPYRIGHT AND LICENSE

See L<MetaCPAN::Pod::XHTML> for the copyright and license.

=cut
