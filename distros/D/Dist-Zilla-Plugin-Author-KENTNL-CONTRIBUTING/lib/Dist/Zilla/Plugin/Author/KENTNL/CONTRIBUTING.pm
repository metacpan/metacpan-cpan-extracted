use 5.006;    # our
use strict;
use warnings;

package Dist::Zilla::Plugin::Author::KENTNL::CONTRIBUTING;

our $VERSION = '0.001006';

# ABSTRACT: Generates a CONTRIBUTING file for KENTNL's distributions.

our $AUTHORITY = 'cpan:KENTNL'; # AUTHORITY

# NB: This list is intentionally short, because these are API-versions
# describing which document to fetch, and certain documents will update
# without changing their API version
my $valid_versions = { map { $_ => 1 } qw( 0.1 ) };

use Moose qw( has around extends );
use Moose::Util::TypeConstraints qw( enum );
use Dist::Zilla::Plugin::GenerateFile::FromShareDir 0.006;

extends 'Dist::Zilla::Plugin::GenerateFile::FromShareDir';

my $valid_version_enum = enum [ keys %{$valid_versions} ];

no Moose::Util::TypeConstraints;











has 'document_version' => (
  isa     => $valid_version_enum,
  is      => 'ro',
  default => '0.1',
);

has '+filename' => (
  lazy    => 1,
  default => sub { 'CONTRIBUTING.pod' },
);

has '+source_filename' => (
  lazy    => 1,
  default => sub { 'contributing-' . $_[0]->document_version . '.pod' },
);

has '+location' => (
  lazy    => 1,
  default => sub { 'root' },
);

has '+phase' => (
  lazy    => 1,
  default => sub { 'build' },
);

around dump_config => sub {
  my ( $orig, $self, @args ) = @_;
  my $config = $self->$orig(@args);
  my $localconf = $config->{ +__PACKAGE__ } = {};

  $localconf->{document_version} = $self->document_version;

  $localconf->{ q[$] . __PACKAGE__ . '::VERSION' } = $VERSION
    unless __PACKAGE__ eq ref $self;

  return $config;
};

__PACKAGE__->meta->make_immutable;
no Moose;

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Dist::Zilla::Plugin::Author::KENTNL::CONTRIBUTING - Generates a CONTRIBUTING file for KENTNL's distributions.

=head1 VERSION

version 0.001006

=head1 DESCRIPTION

This is a personal Dist::Zilla plug-in that generates a CONTRIBUTING
section in my distribution.

I would have made something more general, but my head exploded in thinking about it.

=head1 ATTRIBUTES

=head2 C<document_version>

Specify which shared document to deploy

Valid values:

  [0.1]

=head1 AUTHOR

Kent Fredric <kentnl@cpan.org>

=head1 CONTRIBUTORS

=for stopwords David Golden Karen Etheridge

=over 4

=item *

David Golden <dagolden@cpan.org>

=item *

Karen Etheridge <ether@cpan.org>

=back

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by Kent Fredric <kentfredric@gmail.com>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
