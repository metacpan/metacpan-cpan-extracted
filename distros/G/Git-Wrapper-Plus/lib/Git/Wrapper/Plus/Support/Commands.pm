use 5.006;    # our
use strict;
use warnings;

package Git::Wrapper::Plus::Support::Commands;

our $VERSION = '0.004011';

# ABSTRACT: Database of command support data

our $AUTHORITY = 'cpan:KENTNL'; # AUTHORITY

use Moo qw( extends );

extends 'Git::Wrapper::Plus::Support::RangeDictionary';
























































sub BUILD {
  my ($self) = @_;
  $self->add_range(
    'for-each-ref' => {
      'min'      => '1.4.4',
      'min_tag'  => '1.4.4-rc1',
      'min_sha1' => '9f613ddd21cbd05bfc139d9b1551b5780aa171f6',
    },
  );
  $self->add_range(
    'init' => {
      'min'      => '1.5.0',
      'min_tag'  => '1.5.0-rc1',
      'min_sha1' => '515377ea9ec6192f82a2fa5c5b5b7651d9d6cf6c',
    },
  );
  $self->add_range(
    'update-cache' => {
      'min'      => '0.99',
      'min_tag'  => '0.99',
      'min_sha1' => 'e83c5163316f89bfbde7d9ab23ca2e25604af290',
      'max'      => '1.0.0',
      'max_tag'  => '1.0.0',
      'max_sha1' => 'ba922ccee7565c949b4db318e5c27997cbdbfdba',
    },
  );
  $self->add_range(
    'update-index' => {
      'min'      => '0.99.7',
      'min_tag'  => '0.99.7',
      'min_sha1' => '215a7ad1ef790467a4cd3f0dcffbd6e5f04c38f7',
    },
  );
  $self->add_range(
    'ls-remote' => {
      'min'      => '0.99.2',
      'min_tag'  => '0.99.2',
      'min_sha1' => '0fec0822721cc18d6a62ab78da1ebf87914d4921',
    },
  );
  $self->add_range(
    'peek-remote' => {
      'min'      => '0.99.2',
      'min_tag'  => '0.99.2',
      'min_sha1' => '18705953af75aed190badfccdc107ad0c2f36c93',
    },
  );

  my (@GIT_ZERO_LIST) = qw( init-db cat-file show-diff write-tree read-tree commit-tree );

  for my $cmd (@GIT_ZERO_LIST) {
    $self->add_range(
      $cmd => {
        'min'      => '0.99',
        'min_tag'  => '0.99',
        'min_sha1' => 'e83c5163316f89bfbde7d9ab23ca2e25604af290',
      },
    );
  }
  return $self;
}

no Moo;

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Git::Wrapper::Plus::Support::Commands - Database of command support data

=head1 VERSION

version 0.004011

=head1 SUPPORTED COMMANDS

=head2 C<for-each-ref>

Was added in 1.4.4-rc1

=head2 C<init>

Was added in 1.5.0-rc1 as a proxy for C<init-db>

=head2 C<update-cache>

Added in 0.99, Deprecated in 0.99.7, removed in favor of C<update-index> in 1.0.0

=head2 C<update-index>

Was added with intent to replace C<update-cache> in 0.99.7

=head2 C<ls-remote>

Was added in 0.99.2

=head2 C<peek-remote>

Was added in 0.99.2

=head2 C<init-db>

Was present in the first git commit, 0.99

=head2 C<cat-file>

Was present in the first git commit, 0.99

=head2 C<show-diff>

Was present in the first git commit, 0.99

=head2 C<write-tree>

Was present in the first git commit, 0.99

=head2 C<read-tree>

Was present in the first git commit, 0.99

=head2 C<commit-tree>

Was present in the first git commit, 0.99

=for Pod::Coverage::TrustPod BUILD

=head1 AUTHOR

Kent Fredric <kentnl@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by Kent Fredric <kentfredric@gmail.com>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
