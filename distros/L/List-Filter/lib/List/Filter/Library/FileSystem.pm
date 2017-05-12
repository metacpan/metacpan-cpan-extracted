package List::Filter::Library::FileSystem;
use base qw( Class::Base );

=head1 NAME

List::Filter::Library::FileSystem - filters for unix file listings

=head1 SYNOPSIS

   # This is a plugin, not intended for direct use.
   # See: List::Filter::Storage::CODE

=head1 DESCRIPTION

A library of L<List::Filter> filters for use on file listings.

See L<List::Filter::Library::Documentation> for a information
about the filters defined here.

=cut

use 5.006;
use strict;
use warnings;
my $DEBUG = 0;
use Carp;
use Data::Dumper;
use Hash::Util qw(lock_keys unlock_keys);

our $VERSION = '0.01';

=head2 METHODS

=over

=item new

Instantiates a new List::Filter::Transform::Library::FileSystem object.

=cut

# Note:
# "new" is inherited from Class::Base.
# It calls the following "init" routine automatically.

=item init

Initialize object attributes and then lock them down to prevent
accidental creation of new ones.

Note: there is no leading underscore on name "init", though it's
arguably an "internal" routine (i.e. not likely to be of use to
client code).

=cut

sub init {
  my $self = shift;
  my $args = shift;
  unlock_keys( %{ $self } );

  my $lfs = List::Filter::Storage->new( storage =>
                                                    { format => 'MEM', } );

  # define new attributes
  my $attributes = {
           storage_handler            => $args->{ storage_handler } || $lfs,
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
       '^\.?\#', # need to escape '#' in a //x match
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
       '^\.?\#',
       '^\.$',
       '^\.\.$',
       'CVS',
       'RCS',
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
       '/CVS$',                 # CVS directories
       '/CVS/',                 # files in CVS directories
       '/RCS$',                 # RCS directories
       '\.elc$',                # compiled elisp
      ],
      'modifiers'  => 'x',
     },

     ':skipdull_not' =>
     {
      'description'  => 'bogus filter for testing.',
      'method'         => 'skip_any',
      'terms' =>
      [
       'e',
      ],
      'modifiers'  => 'x',
     },

     ':c-omit' =>              #
     {
      'description'  => q<Omit dull files for working in compiled languages like C>,
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

     ':hide_vc' =>              #
     {
      'description'  => q<ignore common version control files>,
      'method'         => 'skip_any',
      'terms' =>
      [
       ',v$',                   # cvs/rcs repository files
       '/CVS$',                 # CVS directories
       '/CVS/',                 # files in CVS directories
       '/RCS$',                 # RCS directories
       '/RCS/',                 # files in RCS directories
       '/_MTN$',                # monotone directories
       '/_MTN/',                # files in monotone directories
       '/.svn$',                # SVN directories
       '/.svn/',                # files in SVN directories
       '/_darcs$',              # darcs directories
       '/_darcs/',              # files in darcs directories
       '/.git$',                # GIT directories
       '/.git/',                # files in GIT directories
      ],
      'modifiers'  => 'x',
     },

    };
  return $filters;
}


=back

=head2 setters and getters

=over

=item storage_handler

Getter for object attribute storage_handler

=cut

sub storage_handler {
  my $self = shift;
  my $lfs = $self->{ storage_handler };
  return $lfs;
}

=item set_storage_handler

Setter for object attribute set_storage_handler

=cut

sub set_storage_handler {
  my $self = shift;
  my $lfs = shift;
  $self->{ storage_handler } = $lfs;
  return $lfs;
}

1;

=back

=head1 SEE ALSO

L<List::Filter>
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
