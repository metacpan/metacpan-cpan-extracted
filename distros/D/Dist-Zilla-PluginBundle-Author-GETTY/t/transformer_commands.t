use strict;
use warnings;
use Test::More;

use Pod::Elemental;
use Pod::Elemental::Transformer::Pod5;
use Pod::Elemental::Transformer::Author::GETTY;

sub transformed {
  my ($pod) = @_;
  my $doc = Pod::Elemental->read_string($pod);
  Pod::Elemental::Transformer::Pod5->new->transform_node($doc);
  Pod::Elemental::Transformer::Author::GETTY->new->transform_node($doc);
  return [ map { $_->command . ' ' . $_->content =~ s/\s+$//r }
           grep { $_->isa('Pod::Elemental::Element::Pod5::Command') } @{ $doc->children } ];
}

# Every command the bundle's COMMANDS documentation lists must be transformed,
# or it reaches the built module as an unknown POD command.
for my $cmd (qw(attr method func opt env hook example resource event)) {
  is_deeply(
    transformed("=pod\n\n=$cmd name\n\nText.\n"),
    [ 'head2 name' ],
    "=$cmd becomes =head2",
  );
}

is_deeply(
  transformed("=pod\n\n=seealso L<Some::Module>\n\nText.\n"),
  [ 'head1 SEE ALSO' ],
  '=seealso is replaced by its fixed heading; a link on the command line is not kept',
);

done_testing;
