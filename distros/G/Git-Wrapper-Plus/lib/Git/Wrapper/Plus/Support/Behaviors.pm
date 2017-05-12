use 5.006;    # our
use strict;
use warnings;

package Git::Wrapper::Plus::Support::Behaviors;

our $VERSION = '0.004011';

# ABSTRACT: Database of Git Behavior Support

our $AUTHORITY = 'cpan:KENTNL'; # AUTHORITY

use Moo qw( extends );
extends 'Git::Wrapper::Plus::Support::RangeDictionary';























sub BUILD {
  my ($self) = @_;
  $self->add_range(
    'add-updates-index' => {
      'min'      => '1.5.0',
      'min_tag'  => '1.5.0-rc0',
      'min_sha1' => '366bfcb68f4d98a43faaf17893a1aa0a7a9e2c58',
    },
  );
  $self->add_range(
    'can-checkout-detached' => {
      'min'      => '1.5.0',
      'min_tag'  => '1.5.0-rc1',
      'min_sha1' => 'c847f537125ceab3425205721fdaaa834e6d8a83',
    },
  );
  $self->add_range(
    '2-arg-cat-file' => {
      'min_sha1' => 'bf0c6e839c692142784caf07b523cd69442e57a5',
      'min_tag'  => '0.99',
      'min'      => '0.99',
    },
  );
  return $self;
}

no Moo;
1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Git::Wrapper::Plus::Support::Behaviors - Database of Git Behavior Support

=head1 VERSION

version 0.004011

=head1 SUPPORTED BEHAVIORS

=head2 C<add-updates-index>

Prior to 1.5.0-rc0, git add did not update the index, and was only for the initial addition.

Subsequent adds were done with C<git update-index>

=head2 C<can-checkout-detached>

Prior to 1.5.0-rc1, C<git checkout SHA1> simply failed, instead of giving a detached head.

=head2 C<2-arg-cat-file>

Very early on, C<git cat-file TYPE SHA1> was not supported, but this support was added
between the initial commit, and 0.99

=for Pod::Coverage::TrustPod BUILD

=head1 AUTHOR

Kent Fredric <kentnl@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by Kent Fredric <kentfredric@gmail.com>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
