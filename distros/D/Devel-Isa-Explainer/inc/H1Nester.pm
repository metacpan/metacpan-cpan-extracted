use 5.006;
use strict;
use warnings;

package inc::H1Nester;

# ABSTRACT: Custom Nester for keeping regions in H1s

# AUTHORITY

use Moose;
with 'Pod::Weaver::Role::Transformer';

use namespace::autoclean;

use Pod::Elemental::Selectors -all;
use Pod::Elemental::Transformer::Nester;

sub transform_document {
  my ( $self, $document ) = @_;

  my $nester = Pod::Elemental::Transformer::Nester->new(
    {
      top_selector => s_command( [qw(head1)] ),
      content_selectors => [ s_flat, s_command( [qw(head2 head3 head4 over item back for begin)] ), ],
    }
  );

  $nester->transform_node($document);

  return;
}

__PACKAGE__->meta->make_immutable;

1;

