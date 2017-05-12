package List::Filter::Library::FileSystem::Not::Not::Not;
use base qw( Class::Base );

=head1 NAME

List::Filter::Library::FileSystem::Not::Not::Not - A dummy module for testing.

=head1 SYNOPSIS

   use List::Filter::Library::FileSystem::Not::Not::Not ':all';

   # This is a mock-up of a "plug-in", not intended to be used directly.

=head1 DESCRIPTION

This module "List::Filter::Library::FileSystem::Not::Not::Not" is in fact
a dummy module intended to resemble slightly <List::Filter::Library::FileSystem>,
to be used in testing the L<List::Filter::Storage> plug-in system.

=head2 EXPORT

None by default.

=cut

use 5.006;
use strict;
use warnings;
my $DEBUG = 1;
use Carp;
use Data::Dumper;
use Hash::Util qw(lock_keys unlock_keys);

our $VERSION = '0.01';


=back

=head2 METHODS

=cut


=item new

Instantiates a new List::Filter::Transform::Library::FileSystem object.

=cut

# Note:
# "new" is inherited from Class::Base.
# It calls the following "init" routine automatically.

=item init

Initialize object attributes and then lock them down to prevent
accidental creation of new ones.

=cut

sub init {
  my $self = shift;
  my $args = shift;
  unlock_keys( %{ $self } );

  my $filter_storage = List::Filter::Storage->new( storage =>
                                                    { format => 'MEM', } );

  # define new attributes
  my $attributes = {
           filter_storage            => $args->{ filter_storage } || $filter_storage,
           };

  # add attributes to object
  my @fields = (keys %{ $attributes });
  @{ $self }{ @fields } = @{ $attributes }{ @fields };    # hash slice

  lock_keys( %{ $self } );
  return $self;
}

=item define_filters_href

Returns a hash reference (keyed by filter name) of filter hash references.

=cut


sub define_filters_href {
  my $self = shift;

  my $filters =
    {
     ':jpeg' =>
     {
      'description'  => 'Find jpegs, for all common extensions.',
      'method'         => 'find_any',
      'terms' =>
      [
       '\.jpeg$',
       '\.JPEG$',
       '\.jpg$',
       '\.JPG$',
      ],
      'modifiers'  => 'x',
     },

     ':web_img' =>              #
     {
      'description'  => 'Find files with common web image format extensions.',
      'method'         => 'find_any',
      'terms' =>
      [
       '\.jpeg$',
       '\.JPEG$',
       '\.jpg$',
       '\.JPG$',
       '\.gif$',
       '\.GIF$',
       '\.png$',
       '\.PNG$',
      ],
      'modifiers'  => 'x',
     },

     ':dired-x-omit' =>         #
     {
      'description'  => 'Filters files like the emacs dired-x omit feature.',
      'method'         => 'skip_any',
      'terms' =>
      [
       '^\.?#',
       '^\.$',
       '^\.\.$',
       'CVS/$',
       '\.o$',
       '~$',
       '\.bin$',
       '\.lbin$',
       '\.fasl$',
       '\.ufsl$',
       '\.a$',
       '\.ln$',
       '\.blg$',
       '\.bbl$',
       '\.elc$',
       '\.lof$',
       '\.glo$',
       '\.idx$',
       '\.lot$',
       '\.dvi$',
       '\.fmt$',
       '\.tfm$',
       '\.pdf$',
       '\.class$',
       '\.fas$',
       '\.lib$',
       '\.x86f$',
       '\.sparcf$',
       '\.lo$',
       '\.la$',
       '\.toc$',
       '\.log$',
       '\.aux$',
       '\.cp$',
       '\.fn$',
       '\.ky$',
       '\.pg$',
       '\.tp$',
       '\.vr$',
       '\.cps$',
       '\.fns$',
       '\.kys$',
       '\.pgs$',
       '\.tps$',
       '\.vrs$',
       '\.pyc$',
       '\.pyo$',
       '\.idx$',
       '\.lof$',
       '\.lot$',
       '\.glo$',
       '\.blg$',
       '\.bbl$',
       '\.cp$',
       '\.cps$',
       '\.fn$',
       '\.fns$',
       '\.ky$',
       '\.kys$',
       '\.pg$',
       '\.pgs$',
       '\.tp$',
       '\.tps$',
       '\.vr$',
       '\.vrs$',
      ],
      'modifiers'  => 'x',
     },

     ':doom-omit' => # the way I like my emacs omit feature set-up
     {
      'description'  => q<emacs-like omit, without omitting too much>,
      'method'         => 'skip_any',
      'terms' =>
      [
       '^\.?#',
       '^\.$',
       '^\.\.$',
       'CVS/$',
       '~$',
       '\.a$',
       '\.elc$',
       '\.idx$',
       '\.dvi$',
      ],
      'modifiers'  => 'x',
     },

     ':skipdull' =>
     {
      'description'  => 'Screen out some uninteresting files.',
      'method'         => 'skip_any',
      'terms' =>
      [
       '~$',                    # emacs backups
       '/\#',                   # emacs autosaves
       '/\.\#',                 # emacs symlinks to autosaves
       ',v$',                   # cvs/rcs repository files
       '\.elc$',                # compiled elisp
      ],
      'modifiers'  => 'x',
     },

     ':compile' =>              #
     {
      'description'  => q<Omit dull files for programmers in compiled languages>,
      'method'         => 'skip_any',
      'terms' =>
      [
       '\.o$',                  # compiled "object" files
       '~$',                    # emacs backups
       '/\#',                   # emacs autosaves
       '/\.\#',                 # emacs symlinks to autosaves
       ',v$',                   # cvs/rcs repository files
       '\.elc$',                # compiled elisp
      ],
      'modifiers'  => 'x',
     },

     ':updatedb_prune' =>              #
     {
      'description'  => q<Prune directories in the same way as updatedb>,
      'method'         => 'skip_any',
      'terms' =>
      [
       '^/tmp$',
       '^/usr/tmp$',
       '^/var/tmp$',
       '^/afs$',
       '^amd$',
       '^/alex$',
       '^/var/spool$',
       '^/sfs$',
       '^/media$',
      ],
      'modifiers'  => 'x',
     },

     ':nada' =>              #
     {
      'description'  => q<nothing much>,
      'method'         => 'bupkes',
      'terms' =>
      [
       '^$',                  # nothing
       '.*',                  # anything
      ],
      'modifiers'  => 'x',
     },

     ':allski' =>              #
     {
      'description'  => q<just kill 'em all>,
      'method'         => 'skip_any',
      'terms' =>
      [
       '.*',                  # anything
      ],
      'modifiers'  => 'x',
     },




    };
  return $filters;
}


=back

=head2 setters and getters

=over


=item filter_storage

Getter for object attribute filter_storage

=cut

sub filter_storage {
  my $self = shift;
  my $filter_storage = $self->{ filter_storage };
  return $filter_storage;
}

=item set_filter_storage

Setter for object attribute set_filter_storage

=cut

sub set_filter_storage {
  my $self = shift;
  my $filter_storage = shift;
  $self->{ filter_storage } = $filter_storage;
  return $filter_storage;
}

1;

=head1 SEE ALSO

L<List::Filter::Project>

=head1 AUTHOR

Joseph Brenner, E<lt>doom@kzsu.stanford.eduE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2007 by Joseph Brenner

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.2 or,
at your option, any later version of Perl 5 you may have available.

=head1 BUGS

None reported... yet.

=cut
