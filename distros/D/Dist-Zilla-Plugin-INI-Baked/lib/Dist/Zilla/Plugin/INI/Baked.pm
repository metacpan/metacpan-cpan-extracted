use 5.006;
use strict;
use warnings;

package Dist::Zilla::Plugin::INI::Baked;

our $VERSION = '0.002002';

# ABSTRACT: Add a baked version of your configuration to tree automatically

our $AUTHORITY = 'cpan:KENTNL'; # AUTHORITY

use Moose qw( with has around );
use MooX::Lsub qw( lsub );
use Dist::Zilla::File::FromCode;
use Dist::Zilla::Util::CurrentCmd 0.002000 qw( as_cmd );
use Path::Tiny qw( path );
use Dist::Zilla::Util::ExpandINI 0.001001;

with 'Dist::Zilla::Role::FileGatherer';











lsub 'filename' => sub { 'dist.ini.baked' };











lsub 'source_filename' => sub { 'dist.ini' };

lsub '_root'        => sub { path( $_[0]->zilla->root ) };
lsub '_source_file' => sub { $_[0]->_root->child( $_[0]->source_filename ) };

around dump_config => sub {
  my ( $orig, $self, @args ) = @_;
  my $config = $self->$orig(@args);
  my $localconf = $config->{ +__PACKAGE__ } = {};

  $localconf->{filename} = $self->filename;
  $localconf->{source_filename} = $self->source_filename;

  $localconf->{ q[$] . __PACKAGE__ . '::VERSION' } = $VERSION
    unless __PACKAGE__ eq ref $self;

  return $config;
};

sub _gen_preamble {
  my ($self) = @_;
  my $out = q[];
  $out .= sprintf qq[; This file is generated from %s ( in the source repository ) by %s.\n], $self->filename, $self->meta->name;
  $out .= qq[; It exists for your convenience for development if you need it.\n];
  $out .= sprintf qq[; You should edit %s in the source repository for any long term changes\n], $self->filename;
  return $out;
}

sub _inflate_ini {
  my ($self) = @_;
  my $state = Dist::Zilla::Util::ExpandINI->new();
  $state->_load_file( $self->_source_file );
  $state->_expand();
  return $state->_store_string;
}

sub _gen_ini {
  my ($self) = @_;
  my $out = $self->_gen_preamble;
  as_cmd( 'bakeini' => sub { $out .= $self->_inflate_ini } );
  return $out;

}









sub gather_files {
  my ($self) = @_;

  if ( not -e $self->_source_file ) {
    return $self->log_fatal( [ 'Can\'t bake %s, it does not exist', $self->_source_file->stringify ] );
  }
  my $file = Dist::Zilla::File::FromCode->new(
    {
      name             => $self->filename,
      added_by         => $self->meta->name,
      code_return_type => 'text',
      code             => sub { $self->_gen_ini },
    },
  );
  $self->add_file($file);
  return;
}
__PACKAGE__->meta->make_immutable;
no Moose;

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Dist::Zilla::Plugin::INI::Baked - Add a baked version of your configuration to tree automatically

=head1 VERSION

version 0.002002

=head1 SYNOPSIS

  # somewhere in dist.ini or even your bundle
  [INI::Baked]
  ; filename        = dist.ini.baked
  ; source_filename = dist.ini

  # and and
  dzil build

  # and and
  cat $MYDIST/dist.ini.baked  # yay

Whether you wish to

=over 4

=item * Copy that file back to C<root/>

=item * Name that file C<dist.ini>

=item * Add/Not add the original C<dist.ini> to your built code.

=back

All these choices are your discretion, and are presently expected to master other dzil plugins to make this possible.

I recommend:

=over 4

=item * L<< C<[CopyFilesFromBuild]>|Dist::Zilla::Plugin::CopyFilesFromBuild >>

=item * L<< C<[CopyFilesFromRelease]>|Dist::Zilla::Plugin::CopyFilesFromRelease >>

=item * Passing exclude rules to L<< C<[Git::GatherDir]>|Dist::Zilla::Plugin::Git::GatherDir >>

=item * Passing exclude rules to L<< C<[GatherDir]>|Dist::Zilla::Plugin::GatherDir >>

=back

These will of course all still work, because C<source_filename> is read directly from C<< $zilla->root >>

Patches to make it read from C<< $zilla->files >> will be accepted, but YAGNI for now.

=head1 METHODS

=head2 C<gather_files>

This module subscribes to the L<< C<-FileGatherer>|Dist::Zilla::Role::FileGatherer >> role.

As such, this module injects a L<< C<FromCode>|Dist::Zilla::File::FromCode >> object during the gather phase.

=head1 ATTRIBUTES

=head2 C<filename>

The name of the file to emit.

B<DEFAULT>:

  dist.ini.baked

=head2 C<source_filename>

The name of the file to read

B<DEFAULT:>

  dist.ini

=head1 AUTHOR

Kent Fredric <kentnl@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by Kent Fredric <kentfredric@gmail.com>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
