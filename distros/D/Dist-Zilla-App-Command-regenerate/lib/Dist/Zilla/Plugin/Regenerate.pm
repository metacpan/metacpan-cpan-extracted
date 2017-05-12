use 5.006;    # our
use strict;
use warnings;

package Dist::Zilla::Plugin::Regenerate;

our $VERSION = '0.001001';

# ABSTRACT: Write contents to your source tree explicitly

our $AUTHORITY = 'cpan:KENTNL'; # AUTHORITY

use Moose qw( with has around );
use Beam::Event qw();
use Beam::Emitter qw();
use Path::Tiny 0.017 qw( path );
use namespace::clean -except => 'meta';

with qw/ Dist::Zilla::Role::Plugin Dist::Zilla::Role::Regenerator Beam::Emitter /;

has filenames => ( is => 'ro', isa => 'ArrayRef', default => sub { [] }, );

around dump_config => sub {
  my ( $orig, $self, @args ) = @_;
  my $config = $self->$orig(@args);
  my $payload = $config->{ +__PACKAGE__ } = {};
  $payload->{filenames} = $self->filenames;

  ## no critic (RequireInterpolationOfMetachars)
  # Self report when inherited
  $payload->{ q[$] . __PACKAGE__ . '::VERSION' } = $VERSION unless __PACKAGE__ eq ref $self;
  return $config;
};

no Moose;
__PACKAGE__->meta->make_immutable;





sub mvp_multivalue_args { qw( filenames ) }
sub mvp_aliases { +{ filename => 'filenames' } }

sub regenerate {
  my ( $self, $config ) = @_;
  $self->emit( 'before_regenerate', class => 'Dist::Zilla::Event::Regenerate::BeforeRegenerate', %{$config} );

  # Note, that because dzil is build -> dir -> archive -> release
  # regenerate has to pick files from the "dir" target on disk, and can't go through
  # dzil IO
  for my $file ( @{ $self->filenames } ) {
    my $src  = path( $config->{build_root}, $file );
    my $dest = path( $config->{root},       $file );
    $src->copy($dest);
    $self->log("Copied $src to $dest");
  }

  $self->emit( 'after_regenerate', class => 'Dist::Zilla::Event::Regenerate::AfterRegenerate', %{$config} );
}

{
  package    # Hide
    Dist::Zilla::Event::Regenerate::BeforeRegenerate;
  use Moose qw( has extends );
  extends q/Beam::Event/;

  has 'build_root' => ( isa => 'Str', is => 'ro', required => 1 );
  has 'root'       => ( isa => 'Str', is => 'ro', required => 1 );
  no Moose;
  __PACKAGE__->meta->make_immutable;
}
{
  package    # Hide
    Dist::Zilla::Event::Regenerate::AfterRegenerate;
  use Moose qw( has extends );
  extends q/Beam::Event/;

  has 'build_root' => ( isa => 'Str', is => 'ro', required => 1 );
  has 'root'       => ( isa => 'Str', is => 'ro', required => 1 );
  no Moose;
  __PACKAGE__->meta->make_immutable;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Dist::Zilla::Plugin::Regenerate - Write contents to your source tree explicitly

=head1 VERSION

version 0.001001

=head1 SYNOPSIS

B<in C<dist.ini>>

  [Regenerate]
  ; For example
  filenames = Makefile.PL
  filenames = META.json
  filenames = README.mkdn

B<on your command line>

  dzil regenerate
  # Makefile.PL updated
  # META.json updated
  # ...

=head1 DESCRIPTION

This plugin, in conjunction with the L<< C<dzil regenerate>|Dist::Zilla::App::Command::regenerate >>
command, allows turn-key copying of content from your build tree to your source tree.

This is a compatriot of L<< C<[CopyFilesFromBuild]>|Dist::Zilla::Plugin::CopyFilesFromBuild >> and
L<< C<[CopyFilesFromRelease]>|Dist::Zilla::Plugin::CopyFilesFromRelease >>, albeit targeted to happen
outside your standard work phase, allowing you to copy generated files back into the source tree on demand,
and also freeing you from them being updated when you don't require it.

=for Pod::Coverage mvp_multivalue_args mvp_aliases regenerate

=head1 ATTRIBUTES

=head2 C<filenames>

An Array of Strings describing files to copy.

  [Regenerate]
  filename = Makefile.PL
  filename = META.json

B<aliases:> C<filename>

=head1 SEE ALSO

=over 4

=item *  L<< C<[CopyFilesFromBuild]>|Dist::Zilla::Plugin::CopyFilesFromBuild >>

This plugin operates only on the C<AfterBuild> phase, and thus will modify files on every
C<dzil build>, creating undesired work-flow churn.

=item * L<< C<[CopyFilesFromRelease]>|Dist::Zilla::Plugin::CopyFilesFromRelease >>

This plugin operates only on the C<AfterRelease> phase, impeding work-flow slightly
for people who B<WANT> to update their source tree without actually doing a release.

This plugin can be used instead of C<[Regenerate]> though, by using it in conjunction
with L<< C<[Regenerate::AfterReleasers]>|Dist::Zilla::Plugin::Regenerate::AfterReleasers >>

=back

=head1 AUTHOR

Kent Fredric <kentnl@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by Kent Fredric <kentfredric@gmail.com>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
