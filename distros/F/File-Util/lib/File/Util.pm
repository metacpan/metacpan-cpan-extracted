use 5.006;
use strict;
use warnings;

use lib 'lib';

package File::Util;
$File::Util::VERSION = '4.161950';
use File::Util::Definitions qw( :all );
use File::Util::Interface::Modern qw( :all );

use Scalar::Util qw( blessed );
use Exporter;

our $AUTHORITY  = 'cpan:TOMMY';
our @ISA        = qw( Exporter );

# some of the symbols below come from File::Util::Definitions
our @EXPORT_OK  = qw(
   NL      can_flock   ebcdic        existent      needs_binmode
   SL      strip_path  is_readable   is_writable   valid_filename
   OS      bitmask     return_path   file_type     escape_filename
   is_bin  created     last_access   last_changed  last_modified
   isbin   split_path  atomize_path  diagnostic    abort_depth
   size    can_read    can_write     read_limit    can_utf8
                       default_path  strict_path
);

our %EXPORT_TAGS = ( all => [ @EXPORT_OK ], diag => [ ] );

our $WANT_DIAGNOSTICS = 0;

# --------------------------------------------------------
# LEGACY methods (which get replaced in AUTOLOAD)
# --------------------------------------------------------
use subs qw( can_read  can_write  isbin  readlimit );

# --------------------------------------------------------
# Constructor
# --------------------------------------------------------
sub new {
   my $this = { };

   bless $this, shift @_;

   my $in = $this->_parse_in( @_ ) || { };

   $this->{opts} = $in || { };

   $this->{opts}->{onfail} ||= 'die';

   # let constructor argument override globals, but set
   # constructor opts to global values if they have not
   # overridden them...

   $USE_FLOCK  = $in->{use_flock}
      if exists  $in->{use_flock}
      && defined $in->{use_flock};

      $this->{opts}->{use_flock} = $USE_FLOCK;

   $WANT_DIAGNOSTICS = $in->{diag}
      if exists  $in->{diag}
      && defined $in->{diag};

      $this->{opts}->{diag} = $WANT_DIAGNOSTICS;

   $in->{read_limit} = defined $in->{read_limit}
      ? $in->{read_limit}
      : defined $in->{readlimit}
         ? $in->{readlimit}
         : undef;

   delete $in->{readlimit};
   delete $in->{read_limit} if !defined $in->{read_limit};

   $READ_LIMIT = $in->{read_limit}
      if exists  $in->{read_limit}
      && defined $in->{read_limit}
      && $in->{read_limit} !~ /\D/;

      $this->{opts}->{read_limit} = $READ_LIMIT;

   $ABORT_DEPTH = $in->{abort_depth}
      if exists  $in->{abort_depth}
      && defined $in->{abort_depth}
      && $in->{abort_depth} !~ /\D/;

      $this->{opts}->{abort_depth} = $ABORT_DEPTH;

   return $this;
}


# --------------------------------------------------------
# File::Util::import()
# --------------------------------------------------------
sub import {

   my ( $class, @wanted_symbols ) = @_;

   ++$WANT_DIAGNOSTICS if grep { /(?<!!):diag/ } @wanted_symbols;

   $class->export_to_level( 1, @_ );
}


# --------------------------------------------------------
# File::Util::list_dir()
# --------------------------------------------------------
sub list_dir {
   my $this = shift @_;
   my $dir  = shift @_;
   my $opts = ref $_[0] eq 'REF' ? ${ shift @_ } : $this->_remove_opts( \@_ );

   my @dir_contents;

   my ( $subdirs, $files ) = ( [], [] );

   my $abort_depth = $opts->{abort_depth};

   # We can bypass all this extra checking/validation when we are recursing
   # because we know we called ourself correctly--

# INPUT VALIDATION AND DEFAULT VALUES

   if ( !$opts->{_recursing} ) { # bypass all this if recursing

      return $this->_throw(
         'no input' => {
            meth    => 'list_dir',
            missing => 'a directory name',
            opts    => $opts,
         }
      ) unless defined $dir && length $dir;

      $abort_depth =
         defined $opts->{abort_depth}
            ? $opts->{abort_depth}
            : defined $this->{opts}->{abort_depth}
               ? $this->{opts}->{abort_depth}
               : $ABORT_DEPTH;

      # in case somebody wants to list_dir( "/tmp////" ) which is legal!
      $dir =~ s/(?<=.)[\/\\:]+$// unless $dir =~ /^$WINROOT$/o;

      # recurse_fast implies recurse, and so does the legacy opt "follow"
      $opts->{recurse} = 1 if $opts->{recurse_fast} || $opts->{follow};

      # "." and ".." make no sense (and cause infinite loops) when recursing...
      $opts->{no_fsdots} = 1 if $opts->{recurse}; # ...so skip them

      # be compatible with GNU find
      $opts->{max_depth} = delete $opts->{maxdepth} if $opts->{maxdepth};

      # break off immediately to helper function if asked to make a ref-tree
      return $this->_as_tree( $dir => $opts ) if $opts->{as_tree};

      return $this->_throw( 'no such file' => { opts => $opts, filename => $dir } )
         unless -e $dir;

      return $this->_throw (
         'called opendir on a file' => {
            filename => $dir,
            opts     => $opts,
         }
      ) unless -d $dir;
   }

# RUNAWAY RECURSION PREVENTION...

   # We have to keep an eye on recursion; we do it with a shared-reference.
   # scalar references didn't work for me, so I'm using a hashref with a
   # single key-value and it works beautifully
   $opts->{_recursion} = {
      _fast   => $opts->{recurse_fast},
      _base   => $dir,
      _isroot => ( $dir eq '/' || $dir =~ /^$WINROOT/ ) ? 1 : 0,
      _depth  => 0,
      _inodes => {},
   } unless defined $opts->{_recursion};

# ...AND FILESYSTEM LOOPING PREVENTION ARE TIED TOGETHER...

   if ( !$opts->{_recursion}->{_fast} )
   {
      my ( $dev, $inode ) = lstat $dir;

      if ( $inode ) { # noop on windows which always returns zero (0) for inode

         # keep track of dir inodes or we're going to get stuck in filesystem
         # loops the following bit of code incrementally populates (with each
         # recursion) a hash table with keys named for the dev ID and inode of
         # the directory, for every directory found

         warn sprintf
            qq(*WARNING! Filesystem loop detected at %s, dev %s, inode %s\n),
               $dir, $dev, $inode
               and return( () )
                  if exists $opts->{_recursion}{_inodes}{ $dev, $inode };

         $opts->{_recursion}{_inodes}{ $dev, $inode } = undef;
      }
   }

# DETERMINE DEPTH AND BAIL IF TOO DEEP

   # this is highly dependent on OS platform, and also whether or not we are
   # listing a root directory, which makes optimizations harder ( / or C:\ )
   # *note - $SL comes from File::Util::Definitions

   my $trailing_dirs;

   if ( $opts->{_recursion}{_isroot} )
   {
      ( $trailing_dirs ) =
         $dir =~ /^ \Q$opts->{_recursion}{_base}\E (.+) /x;
   }
   else
   {
      ( $trailing_dirs ) =
         $dir =~ /^ \Q$opts->{_recursion}{_base}$SL\E (.+) /x;
   }

   if ( $SL eq '/' )
   {
      $opts->{_recursion}{_depth} = $trailing_dirs =~ tr/\/// + 1
         if defined $trailing_dirs;
   }
   else
   {
      $opts->{_recursion}{_depth} = $trailing_dirs =~ tr/[\\:]// + 1
         if defined $trailing_dirs;
   }

   return( () ) if
      $opts->{max_depth} &&
      $opts->{_recursion}{_depth} >= $opts->{max_depth};

   # fail if the shared reference indicates we're to deep
   return $this->_throw(
      'abort_depth exceeded' => {
         meth        => 'list_dir',
         abort_depth => $abort_depth,
         opts        => $opts,
         dir         => $dir,
      }
   ) if $opts->{_recursion}{_depth} == $abort_depth && $abort_depth != 0;

# ACTUAL READING OF THE DIRECTORY

   opendir my $dir_fh, $dir
      or return $this->_throw
         (
            'bad opendir' => {
               dirname    => $dir,
               exception  => $!,
               opts       => $opts,
            }
         );

# LEGACY_MATCHING

   # this form of matching is deprecated and is not robust.  backward compat
   # is preserved here, but it will soon no longer even be mentioned in the
   # documentation, becoming useful only to the legacy code that relies on it

   # primitive pattern matching at top level only, applied to both files & dirs
   @dir_contents = defined $opts->{pattern}
      ? grep /$opts->{pattern}/, readdir $dir_fh
      : readdir $dir_fh;

   # primitive pattern matching applied recursively to only files; if it were
   # applied to both files AND dirs, recursion would often break unexpectedly
   # for users unaware that they couldn't recurse into dirs that didn't match
   # the pattern they probably intended only for files
   @dir_contents = defined $opts->{rpattern}
      ? grep { -d $dir . SL . $_ || /$opts->{rpattern}/ } @dir_contents
      : @dir_contents;

   closedir $dir_fh
      or return $this->_throw(
         'close dir'  => {
            dir       => $dir,
            exception => $!,
            opts      => $opts,
         }
      );

   # get rid of "." and ".." if they are unwanted, and try to do it as fast
   # as possible for large directories; Devel::NYTprof says this is faster
   if ( $opts->{no_fsdots} )
   {
      if ( $dir_contents[0] eq '.' && $dir_contents[1] eq '..' )
      {
         @dir_contents = splice @dir_contents, 2;
      }
      else
      {
         @dir_contents = grep { !/$FSDOTS/ } @dir_contents;
      }
   }

# SEPARATION OF DIRS FROM FILES

   my $dir_base = # << we use this further down
      ( $dir ne '/' && $dir !~ /^$WINROOT$/ )
         ? $dir . SL
         : $dir;

   while ( @dir_contents ) # !! don't do: while my $foo = shift !!
   {
      my $dir_entry = shift @dir_contents;

      if ( -d $dir_base . $dir_entry && !-l $dir_base . $dir_entry )
      {
         push @$subdirs, $dir_entry
      }
      else { push @$files, $dir_entry }
   }

# ADVANCED MATCHING
   if ( !defined $opts->{_matching} )
   {
      $opts->{_matching} =
         $opts->{files_match}    ||
         $opts->{dirs_match}     ||
         $opts->{parent_matches} ||
         $opts->{path_matches}   || 0;

      $opts->{_matching} = !!$opts->{_matching};
   }

   if ( $opts->{_matching} )
   {
      ( $subdirs, $files ) =
         _list_dir_matching( $opts, $dir, $subdirs, $files );
   }

   # prepend full path information to each file name if paths were
   # requested, or if we are recursing.  Then separate the directories
   # and files off into @dirs and @itmes, respectively
   if ( $opts->{recurse} || $opts->{with_paths} )
   {
      @$subdirs = map { $dir_base . $_ } @$subdirs;
      @$files   = map { $dir_base . $_ } @$files;
   }

# CALLBACKS (HIGHER ORDER FUNCTIONS)

   # here below is where we invoke the callbacks on dirs, files, or both.

   if ( my $cb = $opts->{callback} ) {

      $this->throw( qq(callback "$cb" not a coderef), $opts )
         unless ref $cb eq 'CODE';

      $cb->( $dir, \@$subdirs, \@$files, $opts->{_recursion}{_depth} );
   }

   if ( my $cb = $opts->{d_callback} ) {

      $this->throw( qq(d_callback "$cb" not a coderef), $opts )
         unless ref $cb eq 'CODE';

      $cb->( $dir, \@$subdirs, $opts->{_recursion}{_depth} );
   }

   if ( my $cb = $opts->{f_callback} ) {

      $this->throw( qq(f_callback "$cb" not a coderef), $opts )
         unless ref $cb eq 'CODE';

      $cb->( $dir, \@$files, $opts->{_recursion}{_depth} );
   }

# RECURSION
   if
   (
      $opts->{recurse} && !
      (
         $opts->{max_depth} && # don't recurse if we will then be at max depth
         $opts->{_recursion}{_depth} == $opts->{max_depth} - 1
      )
   ) {
      # recurse into all subdirs
      for my $subdir ( @$subdirs ) {

         # certain opts need to be defined, overridden, added, or removed
         # completely before recursing.  That's why we redefine everything
         # here below, eliminating potential user-error where incompatible
         # options would otherwise break recursion and/or cause confusion

         my $recurse_opts = {
            as_ref               => 1,
            with_paths           => 1,
            no_fsdots            => 1,
            abort_depth          => $abort_depth,
            max_depth            => $opts->{max_depth},
            onfail               => $opts->{onfail},
            diag                 => $opts->{diag},
            rpattern             => $opts->{rpattern},
            files_match          => $opts->{files_match},
            dirs_match           => $opts->{dirs_match},
            parent_matches       => $opts->{parent_matches},
            path_matches         => $opts->{path_matches},
            callback             => $opts->{callback},
            d_callback           => $opts->{d_callback},
            f_callback           => $opts->{f_callback},
            _matching            => $opts->{_matching},
            _patterns            => $opts->{_patterns} || {},
            _recursion           => $opts->{_recursion},
            _recursing           => 1,
         };

         my ( $dirs_ref, $files_ref ) =
            $this->list_dir( $subdir => \$recurse_opts );

         push @$subdirs,  @$dirs_ref
            if ref $dirs_ref && ref $dirs_ref eq 'ARRAY';

         push @$files, @$files_ref
            if ref $files_ref && ref $files_ref eq 'ARRAY';
      }
   }

# FINAL PREPARATIONS before returning results

   if (
        !$opts->{_recursing} &&
      (
         $opts->{path_matches} || $opts->{parent_matches}
      )
   ) {
      @$subdirs = _list_dir_lastround_dirmatch( $opts, $subdirs );
   }

   # cosmetic formatting for directories/
   if ( $opts->{sl_after_dirs} ) {

      # append directory separator to everything but the "dots"
      $_ .= SL for grep { !/$FSDOTS/ } @$subdirs;
   }

   # sorting
   if ( $opts->{ignore_case} ) {

      $subdirs = [ sort { uc $a cmp uc $b } @$subdirs  ];
      $files   = [ sort { uc $a cmp uc $b } @$files ];
   }
   else {

      $subdirs = [ sort { $a cmp $b } @$subdirs  ];
      $files   = [ sort { $a cmp $b } @$files ];
   }

# RETURN based on selected opts

   return scalar @$subdirs
      if $opts->{dirs_only} && $opts->{count_only};

   return scalar @$files
      if $opts->{files_only} && $opts->{count_only};

   return scalar @$subdirs + scalar @$files
      if $opts->{count_only};

   return $subdirs, $files
      if $opts->{as_ref};

   $subdirs = [ $subdirs ] if $opts->{dirs_as_ref};
   $files   = [ $files   ] if $opts->{files_as_ref};

   return @$subdirs if $opts->{dirs_only};
   return @$files   if $opts->{files_only};

   return @$subdirs, @$files;
}


# --------------------------------------------------------
# File::Util::_list_dir_matching()
# --------------------------------------------------------
sub _list_dir_matching {
   my ( $opts, $path, $dirs, $files ) = @_;

# COLLECT PATTERN(S) TO BE APPLIED

   {  # memo-ize these patterns

   # FILES AND
      $opts->{_patterns}->{_files_match_and} =
         [ _gather_and_patterns( $opts->{files_match} ) ]
            unless defined $opts->{_patterns}->{_files_match_and};

   # FILES OR
      $opts->{_patterns}->{_files_match_or} =
         [ _gather_or_patterns( $opts->{files_match} ) ]
            unless defined $opts->{_patterns}->{_files_match_or};

   # DIRS AND
      $opts->{_patterns}->{_dirs_match_and} =
         [ _gather_and_patterns( $opts->{dirs_match} ) ]
            unless defined $opts->{_patterns}->{_dirs_match_and};

   # DIRS OR
      $opts->{_patterns}->{_dirs_match_or} =
         [ _gather_or_patterns( $opts->{dirs_match} ) ]
            unless defined $opts->{_patterns}->{_dirs_match_or};

   # PARENT AND
      $opts->{_patterns}->{_parent_matches_and} =
         [ _gather_and_patterns( $opts->{parent_matches} ) ]
            unless defined $opts->{_patterns}->{_parent_matches_and};

   # PARENT OR
      $opts->{_patterns}->{_parent_matches_or} =
         [ _gather_or_patterns( $opts->{parent_matches} ) ]
            unless defined $opts->{_patterns}->{_parent_matches_or};

   # PATH AND
      $opts->{_patterns}->{_path_matches_and} =
         [ _gather_and_patterns( $opts->{path_matches} ) ]
            unless defined $opts->{_patterns}->{_path_matches_and};

   # PATH OR
      $opts->{_patterns}->{_path_matches_or} =
         [ _gather_or_patterns( $opts->{path_matches} ) ]
            unless defined $opts->{_patterns}->{_path_matches_or};
   }

# FILE MATCHING

   for my $pattern ( @{ $opts->{_patterns}->{_files_match_and} } ) {

      @$files = grep { /$pattern/ } @$files;
   }

   @$files = _match_and( $opts->{_patterns}->{_files_match_and}, $files )
      if @{ $opts->{_patterns}->{_files_match_and} };

   @$files = _match_or( $opts->{_patterns}->{_files_match_or}, $files )
      if @{ $opts->{_patterns}->{_files_match_or} };

# DIRECTORY MATCHING

   @$dirs = _match_and( $opts->{_patterns}->{_dirs_match_and}, $dirs )
      if @{ $opts->{_patterns}->{_dirs_match_and} };

   @$dirs = _match_or( $opts->{_patterns}->{_dirs_match_or}, $dirs )
      if @{ $opts->{_patterns}->{_dirs_match_or} };

# FILE &'ed DIRECTORY MATCHING

   if ( $opts->{files_match} && $opts->{dirs_match} ) {

      $files = [ ]
         unless _match_and
         (
            $opts->{_patterns}->{_dirs_match_and},
            [ strip_path( $path ) ]
         );
   }

# MATCHING FILES BY PARENT DIR

   if ( $opts->{parent_matches} ) {

      if ( @{ $opts->{_patterns}->{_parent_matches_and} } ) {

         $files = [ ]
            unless _match_and
            (
               $opts->{_patterns}->{_parent_matches_and},
               [ strip_path( $path ) ]
            );
      }
      elsif ( @{ $opts->{_patterns}->{_parent_matches_or} } ) {

         $files = [ ]
            unless _match_or
            (
               $opts->{_patterns}->{_parent_matches_or},
               [ strip_path( $path ) ]
            );
      }
   }

# MATCHING FILES BY PATH

   if ( $opts->{path_matches} ) {

      if ( @{ $opts->{_patterns}->{_path_matches_and} } ) {

         $files = [ ]
            unless _match_and
            (
               $opts->{_patterns}->{_path_matches_and}, [ $path ]
            );
      }
      elsif ( @{ $opts->{_patterns}->{_path_matches_or} } ) {

         $files = [ ]
            unless _match_or
            (
               $opts->{_patterns}->{_path_matches_or}, [ $path ]
            );
      }
   }

   return ( $dirs, $files );
}


# --------------------------------------------------------
# File::Util::_list_dir_lastround_dirmatch()
# --------------------------------------------------------
sub _list_dir_lastround_dirmatch {
   my ( $opts, $dirs ) = @_;

   my @return_dirs;

# LAST ROUND MATCHING DIRS BY PARENT DIR

   if ( $opts->{parent_matches} ) {

      my %return_dirs;

      if ( @{ $opts->{_patterns}->{_parent_matches_and} } ) {

         for my $qfd_dir ( @$dirs ) {

            my ( $root, $in_path ) = atomize_path( $qfd_dir );

            $in_path = $root . $in_path if $root;

            $return_dirs{ $in_path } = $in_path
               if _match_and
                  (
                     $opts->{_patterns}->{_parent_matches_and},
                     [ strip_path( $in_path ) ]
                  );
         }
      }
      elsif ( @{ $opts->{_patterns}->{_parent_matches_or} } ) {

         for my $qfd_dir ( @$dirs ) {

            my ( $root, $in_path ) = atomize_path( $qfd_dir );

            $in_path = $root . $in_path if $root;

            $return_dirs{ $in_path } = $in_path
               if _match_or
                  (
                     $opts->{_patterns}->{_parent_matches_or},
                     [ strip_path( $in_path ) ]
                  );
         }
      }

      push @return_dirs, keys %return_dirs;
   }

# LAST ROUND MATCHING DIRS BY PATH

   if ( $opts->{path_matches} ) {

      my %return_dirs;

      if ( @{ $opts->{_patterns}->{_path_matches_and} } ) {

         for my $qfd_dir ( @$dirs ) {

            my ( $root, $in_path ) = atomize_path( $qfd_dir );

            $in_path = $root . $in_path if $root;

            $return_dirs{ $in_path } = $in_path
               if _match_and
               (
                  $opts->{_patterns}->{_path_matches_and}, [ $in_path ]
               );

            $return_dirs{ $qfd_dir } = $qfd_dir
               if _match_and
               (
                  $opts->{_patterns}->{_path_matches_and}, [ $qfd_dir ]
               );
         }
      }
      elsif ( @{ $opts->{_patterns}->{_path_matches_or} } ) {

         for my $qfd_dir ( @$dirs ) {

            my ( $root, $in_path ) = atomize_path( $qfd_dir );

            $in_path = $root . $in_path if $root;

            $return_dirs{ $in_path } = $in_path
               if _match_or
               (
                  $opts->{_patterns}->{_path_matches_or}, [ $in_path ]
               );

            $return_dirs{ $qfd_dir } = $qfd_dir
               if _match_or
               (
                  $opts->{_patterns}->{_path_matches_or}, [ $qfd_dir ]
               );
         }
      }

      push @return_dirs, keys %return_dirs;
   }

   return @return_dirs;
}


# --------------------------------------------------------
# File::Util::_gather_and_patterns()
# --------------------------------------------------------
sub _gather_and_patterns {

   my $pattern_ref = shift @_;

   return
      defined $pattern_ref &&
      ref $pattern_ref eq 'HASH' &&
      defined $pattern_ref->{and} &&
      ref $pattern_ref->{and} eq 'ARRAY'
         ? @{ $pattern_ref->{and} }
         : defined $pattern_ref &&
           ref $pattern_ref eq 'Regexp'
            ? ( $pattern_ref )
            : ( );
}


# --------------------------------------------------------
# File::Util::_gather_or_patterns()
# --------------------------------------------------------
sub _gather_or_patterns {

   my $pattern_ref = shift @_;

   return
      defined $pattern_ref &&
      ref $pattern_ref eq 'HASH' &&
      defined $pattern_ref->{or} &&
      ref $pattern_ref->{or} eq 'ARRAY'
         ? @{ $pattern_ref->{or} }
         : ( );
}


# --------------------------------------------------------
# File::Util::_match_and()
# --------------------------------------------------------
sub _match_and {

   my ( $patterns, $items ) = @_;

   for my $pattern ( @$patterns ) {

      @$items = grep { /$pattern/ } @$items;
   }

   return @$items;
}


# --------------------------------------------------------
# File::Util::_match_or()
# --------------------------------------------------------
sub _match_or {

   my ( $patterns, $items ) = @_;

   my $or_pattern;

   for my $pattern ( @$patterns ) {

      $or_pattern = $or_pattern
         ? qr/$pattern|$or_pattern/
         : $pattern;
   }

   @$items = grep { /$or_pattern/ } @$items;

   return @$items;
}


# --------------------------------------------------------
# File::Util::_as_tree()
# --------------------------------------------------------
sub _as_tree {
   my $this = shift @_;
   my $opts = $this->_remove_opts( \@_ );
   my $dir  = shift @_;
   my $tree = {};

   my $treeify = sub
   {
      my ( $dirname, $subdirs, $files ) = @_;

      # find root of tree (if path was absolute)
      my ( $root, $branch, $leaf ) = atomize_path( $dirname );

      my @path_dirs = split /$DIRSPLIT/o, $branch;

      # find place in tree
      my @lineage = ( @path_dirs, $leaf );

      unshift @lineage, $root if $root;

      my $ancestory = $tree;

      # recursively create hashref tree

      for ( my $i = 0; $i < @lineage; $i++ )
      {
         my $self = $lineage[ $i ];

         my $parent = $i > 0 ? $i - 1 : undef;

         if ( defined $parent )
         {
            my @predecessors = @lineage[ 0 .. $parent ];

            # for abs paths on *nix
            shift @predecessors if
               @predecessors > 1 &&
               $predecessors[0] eq SL;

            $parent = join SL, @predecessors;

            $parent = $root . $parent if $root && $parent ne $root;
         }

         $ancestory->{ $self } ||= { };

         unless (
            exists  $opts->{dirmeta} &&
            defined $opts->{dirmeta} &&
            $opts->{dirmeta} == 0
         ) {
            $ancestory->{ $self }{ _DIR_PARENT_ } = $parent;

            $ancestory->{ $self }{ _DIR_SELF_ }   =
               !defined $parent
                  ? $self
                  : $parent eq $root
                     ? $parent . $self
                     : $parent . SL . $self;
         }

         $ancestory = $ancestory->{ $self };
      }

      # the next two loops populate the tree

      my $parent = $ancestory;

      for my $subdir ( @$subdirs )
      {
         $parent->{ strip_path( $subdir ) } ||= { };
      }

      for my $file ( @$files )
      {
         $parent->{ strip_path( $file ) } = $file;
      }
   };

   $opts->{callback} = $treeify;

   delete $opts->{as_tree};

   $this->list_dir( $dir => $opts );

   return $tree;
}


# --------------------------------------------------------
# File::Util::_dropdots()
# --------------------------------------------------------
sub _dropdots {
   my $this     = shift @_;
   my $opts     = $this->_remove_opts( \@_ );
   my @copy     = @_;
   my @out      = ();
   my @dots     = ();
   my $gottadot = 0;

   while ( @copy ) {

      if ( $gottadot == 2 ) { push @out, @copy and last }

      my $dir_item = shift @copy;

      if ( $dir_item =~ /$FSDOTS/ ) {

         ++$gottadot;

         push @dots, $dir_item;

         next;
      }

      push @out, $dir_item;
   }

   return( \@dots, @out ) if $opts->{save_dots};

   return @out;
}


# --------------------------------------------------------
# File::Util::load_file()
# --------------------------------------------------------
sub load_file {
   my $this       = shift @_;
   my $in         = $this->_parse_in( @_ );
   my @dirs       = ();
   my $blocksize  = 1024; # 1.24 kb
   my $fh_passed  = 0;
   my $fh;

   my ( $file, $root, $path, $clean_name, $content, $mode  ) =
      ( '',    '',    '',    '',          '',       'read' );

   # all of this logic branching is to cover the possibilities in the way
   # this method could have been called.  we try to support as many methods
   # as make at least some amount of sense

   $in->{read_limit} = defined $in->{read_limit}
      ? $in->{read_limit}
      : defined $in->{readlimit}
         ? $in->{readlimit}
         : undef;

   delete $in->{readlimit};
   delete $in->{read_limit} if !defined $in->{read_limit};

   my $read_limit =
      defined $in->{read_limit}
         ? $in->{read_limit}
         : defined $this->{opts}->{read_limit}
            ? $this->{opts}->{read_limit}
            : defined $READ_LIMIT
               ? $READ_LIMIT
               : 0;

   return $this->_throw(
      'bad read_limit' => { opts => $in, bad => $read_limit }
   ) if $read_limit =~ /\D/;

   # support old-school "FH" option, *and* the new, more sensible "file_handle"
   $in->{FH} = $in->{file_handle} if defined $in->{file_handle};

   if ( !defined $in->{FH} ) { # unless we were passed a file handle...

      $file = defined $in->{file}
         ? $in->{file}
         : defined $in->{filename}
            ? $in->{filename}
            : shift @_ || '';

      return $this->_throw(
         'no input',
         {
            meth    => 'load_file',
            missing => 'a file name or file handle reference',
            opts    => $in,
         }
      ) unless length $file;

      ( $root, $path, $file ) = atomize_path( $file );

      @dirs = split /$DIRSPLIT/, $path;

      unshift @dirs, $root if $root;

      # cleanup file name - if path is relative, normalize it
      #    - /foo/bar/baz.txt stays as /foo/bar/baz.txt
      #    - foo/bar/baz.txt  becomes ./foo/bar/baz.txt
      #    - baz.txt          stays as baz.txt
      if ( !length $root && !length $path ) {

         $path = '.' . SL;
      }
      else { # otherwise path normalized at end

         $path .= SL;
      }

      # final clean filename assembled
      $clean_name = $root . $path . $file;
   }
   else {

      # did we get a filehandle?
      if ( ref $in->{FH} eq 'GLOB' ) {

         $fh_passed++;
      }
      else {

         return $this->_throw(
            'no input',
            {
               meth    => 'load_file',
               missing => 'a true file handle reference (not a string)',
               opts    => $in,
            }
         );
      }
   }

   if ( $fh_passed ) {

      my $buffer     = 0;
      my $bytes_read = 0;
      $fh = $in->{FH};

      while ( <$fh> ) {

         if ( $buffer < $read_limit ) {

            $bytes_read = read( $fh, $content, $blocksize );

            $buffer += $bytes_read;
         }
         else {

            return $this->_throw(
               'read_limit exceeded',
               {
                  filename   => '<filehandle>',
                  size       => qq{[truncated at $bytes_read]},
                  read_limit => $read_limit,
                  opts       => $in,
               }
            );
         }
      }

      # return an array of all lines in the file if the call to this method/
      # subroutine asked for an array eg- my @file = load_file('file');
      # otherwise, return a scalar value containing all of the file's content
      return split /$NL|\r|\n/o, $content
         if $in->{as_list};

      return $content;
   }

   # if the file doesn't exist, send back an error
   return $this->_throw(
      'no such file',
      {
         filename => $clean_name,
         opts     => $in,
      }
   ) unless -e $clean_name;

   # it's good to know beforehand whether or not we have permission to open
   # and read from this file allowing us to handle such an exception before
   # it handles us.

   # first check the readability of the file's housing dir
   return $this->_throw(
      'cant dread',
      {
         filename => $clean_name,
         dirname  => $root . $path,
         opts     => $in,
      }
   ) unless -r $root . $path;

   # now check the readability of the file itself
   return $this->_throw(
      'cant fread',
      {
         filename => $clean_name,
         dirname  => $root . $path,
         opts     => $in,
      }
   ) unless -r $clean_name;

   # if the file is a directory it will not be opened
   return $this->_throw(
      'called open on a dir',
      {
         filename => $clean_name,
         opts     => $in,
      }
   ) if -d $clean_name;

   my $fsize = -s $clean_name;

   return $this->_throw(
      'read_limit exceeded',
      {
         filename   => $clean_name,
         size       => $fsize,
         opts       => $in,
         read_limit => $read_limit,
      }
   ) if $fsize > $read_limit;

   # localize the global output record separator so we can slurp it all
   # in one quick read.  We fail if the filesize exceeds our limit.
   local $/;

   # open the file for reading (note the '<' syntax there) or fail with a
   # error message if our attempt to open the file was unsuccessful

   # lock file before I/O on platforms that support it
   if (
      $in->{no_lock}           ||
      $this->{opts}->{no_lock} ||
      !$this->use_flock()
   ) {

      # if you use the 'no_lock' option you are probably inefficient
      open $fh, '<', $clean_name or
         return $this->_throw(
            'bad open',
            {
               filename  => $clean_name,
               mode      => $mode,
               exception => $!,
               cmd       => qq(< $clean_name),
               opts      => $in,
            }
         );
   }
   else {
      open $fh, '<', $clean_name or
         return $this->_throw(
            'bad open',
            {
               filename  => $clean_name,
               mode      => $mode,
               exception => $!,
               cmd       => qq(< $clean_name),
               opts      => $in,
            }
         );

      $this->_seize( $clean_name, $fh, $in );
   }

   # call binmode on binary files for portability across platforms such
   # as MS flavor OS family

   binmode $fh if -B $clean_name;

   # call binmode on the filehandle if it was requested or UTF-8
   if ( $in->{binmode} )
   {
      if ( lc $in->{binmode} eq 'utf8' )
      {
         if ( $HAVE_UU )
         {
            binmode $fh, ':unix:encoding(UTF-8)';
         }
         else
         {
            close $fh;

            return $this->_throw( 'no unicode' => $in );
         }
      }
      elsif ( $in->{binmode} == 1 )
      {
         binmode $fh;
      }
      else
      {
         binmode $fh, $in->{binmode} # apply user-specified IO layer(s)
      }
   }

   # assign the content of the file to this lexically scoped scalar variable
   # (memory for *that* variable will be freed when execution leaves this
   # method / sub

   $content = <$fh>;

   if ( $in->{no_lock} || $this->{opts}->{no_lock} ) {

      # if execution gets here, you used the 'no_lock' option, and you
      # are probably inefficient

      close $fh or return $this->_throw(
         'bad close',
         {
            filename  => $clean_name,
            mode      => $mode,
            exception => $!,
            opts      => $in,
         }
      );
   }
   else {
      # release shadow-ed locks on the file
      $this->_release( $fh, $in );

      close $fh or return $this->_throw(
         'bad close',
         {
            filename  => $clean_name,
            mode      => $mode,
            exception => $!,
            opts      => $in,
         }
      );
   }

   # return an array of all lines in the file if the call to this method/
   # subroutine asked for an array eg- my @file = load_file('file');
   # otherwise, return a scalar value containing all of the file's content
   return split /$NL|\r|\n/o, $content
      if $in->{as_lines};

   return $content;
}


# --------------------------------------------------------
# File::Util::write_file()
# --------------------------------------------------------
sub write_file {
   my $this     = shift @_;
   my $in       = $this->_parse_in( @_ );
   my $content  = '';
   my $raw_name = '';
   my $file     = '';
   my $mode     = $in->{mode}     || 'write';
   my $bitmask  = $in->{bitmask}  || oct 777;
   my $write_fh; # will be the lexical file handle local to this block
   my ( $root, $path, $clean_name, @dirs ) =
      ( '',    '',    '',          ()    );

   # get name of file when passed in as a name/value pair...

   $file =
      exists  $in->{filename} &&
      defined $in->{filename} &&
      length  $in->{filename}
         ? $in->{filename}
         : exists  $in->{file} &&
           defined $in->{file} &&
           length  $in->{file}
            ? $in->{file}
            : '';

   # ...or fall back to support of two-argument form of invocation

   my $maybe_file    = shift @_; $maybe_file    = '' if !defined $maybe_file;
   my $maybe_content = shift @_; $maybe_content = '' if !defined $maybe_content;

   $file    = $maybe_file if !ref $maybe_file && $file eq '';
   $content =
      !ref $maybe_content &&
      !exists $in->{content}
         ? $maybe_content
         : $in->{content};

   my ( $winroot ) = $file =~ /^($WINROOT)/;

   $file =~ s/^($WINROOT)//;
   $file =~ s/$DIRSPLIT{2,}/$SL/o;
   $file =~ s/$DIRSPLIT+$//o unless $file eq SL;
   $file =  $winroot . $file if $winroot;

   $raw_name = $file; # preserve original filename input before line below:

   ( $root, $path, $file ) = atomize_path( $file );

   $mode = 'trunc' if $mode eq 'truncate';
   $content = '' if $mode eq 'trunc';

   # if the call to this method didn't include a filename to which the caller
   # wants us to write, then complain about it
   return $this->_throw(
      'no input' => {
         meth    => 'write_file',
         missing => 'a file name to create, write, or append',
         opts    => $in,
      }
   ) unless length $file;

   # if the call to this method didn't include any data which the caller
   # wants us to write or append to the file, then complain about it
   return $this->_throw(
      'no input' => {
         meth    => 'write_file',
         missing => 'the content you want to write or append',
         opts    => $in,
      }
   ) if (
     ( !defined $content ||
         length $content == 0 )
         &&
      $mode ne 'trunc'
         &&
      !$EMPTY_WRITES_OK
         &&
      !$in->{empty_writes_OK}
         &&
      !$in->{empty_writes_ok}
   );

   # check if file already exists in the form of a directory
   return $this->_throw(
      'cant write_file on a dir' => {
         filename => $raw_name,
         opts     => $in,
      }
   ) if -d $raw_name;

   # determine existance of the file path, make directory(ies) for the
   # path if the full directory path doesn't exist
   @dirs = split /$DIRSPLIT/, $path;

   # if prospective file name has illegal chars then complain
   foreach ( @dirs ) {

      return $this->_throw(
         'bad chars' => {
            string   => $_,
            purpose  => 'the name of a file or directory',
            opts     => $in,
         }
      ) if !$this->valid_filename( $_ );
   }

   # do this AFTER the above check!!
   unshift @dirs, $root if $root;

   # make sure that open mode is a valid mode
   unless ( $mode eq 'write' || $mode eq 'append' || $mode eq 'trunc' ) {

      return $this->_throw(
         'bad openmode popen' => {
            meth     => 'write_file',
            filename => $raw_name,
            badmode  => $mode,
            opts     => $in,
         }
      )
   }

   # cleanup file name - if path is relative, normalize it
   #    - /foo/bar/baz.txt stays as /foo/bar/baz.txt
   #    - foo/bar/baz.txt  becomes ./foo/bar/baz.txt
   #    - baz.txt          stays as baz.txt
   if ( !length $root && !length $path ) {

      $path = '.' . SL;
   }
   else { # otherwise path normalized at end

      $path .= SL;
   }

   # final clean filename assembled
   $clean_name = $root . $path . $file;

   # create path preceding file if path doesn't exist
   if ( !-e $root . $path ) {

      my $make_dir_ok = 1;

      my $make_dir_return = $this->make_dir(
         $root . $path,
         exists $in->{dbitmask} &&
         defined $in->{dbitmask}
            ? $in->{dbitmask}
            : oct 777,
            {
               diag   => $in->{diag},
               onfail => sub {
                  my ( $err, $trace ) = @_;

                  return $in->{onfail}
                     if ref $in->{onfail} &&
                        ref $in->{onfail} eq 'CODE';

                  $make_dir_ok = 0;

                  return $err . $trace;
               }
            }
      );

      die $make_dir_return unless $make_dir_ok;
   }

   # if file already exists, check if we can write to it
   if ( -e $clean_name ) {

      return $this->_throw(
         'cant fwrite' => {
            filename   => $clean_name,
            dirname    => $root . $path,
            opts       => $in,
         }
      ) unless -w $clean_name;
   }
   else {

      # if file doesn't exist, see if we can create it
      return $this->_throw(
         'cant fcreate' => {
            filename    => $clean_name,
            dirname     => $root . $path,
            opts        => $in,
         }
      ) unless -w $root . $path;
   }

   # if you use the no_lock option, please consider the risks

   if ( $in->{no_lock} || !$USE_FLOCK ) {

      # only non-existent files get bitmask arguments
      if ( -e $clean_name )
      {
         # you can't use UTF8 'mode' on system IO, so if a user requests
         # UTF8, we have to use PerlIO
         if ( $in->{binmode} && lc $in->{binmode} eq 'utf8' )
         {
            open
               $write_fh,
               $$MODES{popen}{ $mode },
               $clean_name
            or return $this->_throw(
               'bad open'   => {
                  filename  => $clean_name,
                  mode      => $mode,
                  opts      => $in,
                  exception => $!,
                  cmd       => $mode . $clean_name,
               }
            );
         }
         else
         {
            sysopen
               $write_fh,
               $clean_name,
               $$MODES{sysopen}{ $mode }
            or return $this->_throw(
               'bad open'   => {
                  filename  => $clean_name,
                  mode      => $mode,
                  opts      => $in,
                  exception => $!,
                  cmd       => qq($clean_name, $$MODES{sysopen}{ $mode }),
               }
            );
         }
      }
      else
      {
         sysopen
            $write_fh,
            $clean_name,
            $$MODES{sysopen}{ $mode },
            $bitmask
         or return $this->_throw(
            'bad open'   => {
               filename  => $clean_name,
               mode      => $mode,
               exception => $!,
               cmd       => qq($clean_name, $$MODES{sysopen}{$mode}, $bitmask),
               opts      => $in,
            }
         );
      }
   }
   else
   {
      # open read-only first to safely check if we can get a lock.
      if ( -e $clean_name )
      {
         open $write_fh, '<', $clean_name
         or return $this->_throw(
            'bad open'   => {
               filename  => $clean_name,
               mode      => 'read',
               exception => $!,
               cmd       => $mode . $clean_name,
               opts      => $in,
            }
         );

         # lock file before I/O on platforms that support it
         my $lockstat = $this->_seize( $clean_name, $write_fh, $in );

         return unless $lockstat;

         # you can't use UTF8 'mode' on system IO, so if a user requests
         # UTF8, we have to use PerlIO
         if ( $in->{binmode} && lc $in->{binmode} eq 'utf8' )
         {
            open
               $write_fh,
               $$MODES{popen}{ $mode },
               $clean_name
            or return $this->_throw(
               'bad open'   => {
                  filename  => $clean_name,
                  mode      => $mode,
                  opts      => $in,
                  exception => $!,
                  cmd       => $mode . $clean_name,
               }
            );
         }
         else
         {
            sysopen
               $write_fh,
               $clean_name,
               $$MODES{sysopen}{ $mode }
            or return $this->_throw(
               'bad open'   => {
                  filename  => $clean_name,
                  mode      => $mode,
                  opts      => $in,
                  exception => $!,
                  cmd       => qq($clean_name, $$MODES{sysopen}{ $mode }),
               }
            );
         }
      }
      else { # only non-existent files get bitmask arguments
             # ...unless doing utf8 business, in which case it's irrelevant

         # you can't use UTF8 'mode' on system IO, so if a user requests
         # UTF8, we have to use PerlIO
         if ( $in->{binmode} && lc $in->{binmode} eq 'utf8' )
         {
            open
               $write_fh,
               $$MODES{popen}{ $mode },
               $clean_name
            or return $this->_throw(
               'bad open'   => {
                  filename  => $clean_name,
                  mode      => $mode,
                  opts      => $in,
                  exception => $!,
                  cmd       => $mode . $clean_name,
               }
            );
         }
         else
         {
            sysopen
               $write_fh,
               $clean_name,
               $$MODES{sysopen}{ $mode },
               $bitmask
            or return $this->_throw(
               'bad open'   => {
                  filename  => $clean_name,
                  mode      => $mode,
                  opts      => $in,
                  exception => $!,
                  cmd       => qq($clean_name, $$MODES{sysopen}{$mode}, $bitmask),
               }
            );
         }

         # lock file before I/O on platforms that support it
         my $lockstat = $this->_seize( $clean_name, $write_fh, $in );

         return unless $lockstat;
      }

      # now truncate
      if ( $mode ne 'append' ) {

         truncate( $write_fh, 0 ) or return $this->_throw(
            'bad systrunc' => {
               filename    => $clean_name,
               exception   => $!,
               opts        => $in,
            }
         );
      }
   }

   if ( $in->{binmode} )
   {
      if ( lc $in->{binmode} eq 'utf8' )
      {
         if ( $HAVE_UU )
         {
            binmode $write_fh, ':unix:encoding(UTF-8)';

            print $write_fh $content; # utf8 filehandles use PerlIO
         }
         else
         {
            close $write_fh;

            return $this->_throw( 'no unicode' => $in );
         }
      }
      elsif ( $in->{binmode} == 1 )
      {
         binmode $write_fh;

         syswrite( $write_fh, $content );
      }
      else
      {
         binmode $write_fh, $in->{binmode}; # apply user-specified IO layer(s)

         syswrite( $write_fh, $content );
      }
   }
   else
   {
      syswrite( $write_fh, $content );
   }

   # release lock on the file

   $this->_release( $write_fh, $in ) unless $$in{no_lock} || !$USE_FLOCK;

   close $write_fh or
      return $this->_throw(
         'bad close'  => {
            filename  => $clean_name,
            mode      => $mode,
            exception => $!,
            opts      => $in,
         }
      );

   return 1;
}


# --------------------------------------------------------
# File::Util::_seize()
# --------------------------------------------------------
sub _seize {
   my ( $this, $file, $fh, $opts ) = @_;

   return $this->_throw( 'no handle passed to _seize.' => $opts )
      unless $fh;

   $file = defined $file ? $file : ''; # yes, even files named "0" are allowed

   return $this->_throw( 'no file name passed to _seize.' => $opts )
      unless length $file;

   # forget seizing if system can't flock
   return $fh if !$CAN_FLOCK;

   my @policy = @ONLOCKFAIL;

   # seize filehandle, return it if lock is successful

   while ( @policy ) {

      my $fh = &{ $_LOCKS->{ shift @policy } }( $this, $file, $fh, $opts );

      return $fh if $fh || !scalar @policy;
   }

   return $fh;
}


# --------------------------------------------------------
# File::Util::_release()
# --------------------------------------------------------
sub _release {

   my ( $this, $fh, $opts ) = @_;

   return $this->_throw(
      'not a filehandle.' => { opts => $opts, argtype => ref $fh } )
      unless $fh && ref $fh eq 'GLOB';

   if ( $CAN_FLOCK ) { flock $fh, &Fcntl::LOCK_UN }
   return 1;
}


# --------------------------------------------------------
# File::Util::valid_filename()
# --------------------------------------------------------
sub valid_filename {
   my $f = _myargs( @_ );

   $f =~ s/$WINROOT//; # windows abs paths would throw this off

   $f !~ /$ILLEGAL_CHR/ ? 1 : undef;
}


# --------------------------------------------------------
# File::Util::strip_path()
# --------------------------------------------------------
sub strip_path {
   my $arg = _myargs( @_ );

   my ( $stripped ) = $arg =~ /^.*$DIRSPLIT(.+)/o;

   return $stripped if defined $stripped;

   return $arg;
}


# --------------------------------------------------------
# File::Util::atomize_path()
# --------------------------------------------------------
sub atomize_path {
   my $fqfn = _myargs( @_ );

   $fqfn =~ m/$ATOMIZER/o;

   # root = $1
   # path = $2
   # file = $3

   return( $1||'', $2||'', $3||'' );
}


# --------------------------------------------------------
# File::Util::split_path()
# --------------------------------------------------------
sub split_path {
   my $path = _myargs( @_ );

   # find root of tree (if path was absolute)
   my ( $root, $branch, $leaf ) = atomize_path( $path );

   my @path_dirs = split /$DIRSPLIT/o, $branch;

   unshift @path_dirs, $root if $root;
   push    @path_dirs, $leaf if $leaf;

   return @path_dirs;
}


# --------------------------------------------------------
# File::Util::line_count()
# --------------------------------------------------------
sub line_count {
   my( $this, $file ) = @_;
   my $buff  = '';
   my $lines = 0;
   my $cmd   = '<' . $file;

   open my $fh, '<', $file or
      return $this->_throw(
         'bad open',
         {
            'filename'  => $file,
            'mode'      => 'read',
            'exception' => $!,
            'cmd'       => $cmd,
         }
      );

   while ( sysread( $fh, $buff, 4096 ) ) {

      $lines += $buff =~ tr/\n//;

      $buff  = '';
   }

   close $fh;

   return $lines;
}


# --------------------------------------------------------
# File::Util::bitmask()
# --------------------------------------------------------
sub bitmask {
   my $f = _myargs( @_ );

   defined $f and -e $f ? sprintf('%04o',(stat($f))[2] & oct 777) : undef
}


# --------------------------------------------------------
# File::Util::can_flock()
# --------------------------------------------------------
sub can_flock { $CAN_FLOCK }


# --------------------------------------------------------
# File::Util::can_utf8()
# --------------------------------------------------------
sub can_utf8 { $HAVE_UU }


# File::Util::--------------------------------------------
# is_readable(), is_writable() -- was: can_read(), can_write()
# --------------------------------------------------------
sub is_readable { my $f = _myargs( @_ ); defined $f ? -r $f : undef }
sub is_writable { my $f = _myargs( @_ ); defined $f ? -w $f : undef }


# --------------------------------------------------------
# File::Util::created()
# --------------------------------------------------------
sub created {
   my $f = _myargs( @_ );

   defined $f and -e $f ? $^T - ((-M $f) * 60 * 60 * 24) : undef
}


# --------------------------------------------------------
# File::Util::ebcdic()
# --------------------------------------------------------
sub ebcdic { $EBCDIC }


# --------------------------------------------------------
# File::Util::escape_filename()
# --------------------------------------------------------
sub escape_filename {
   my( $file, $escape, $also ) = _myargs( @_ );

   return '' unless defined $file;

   $escape = '_' if !defined $escape;

   if ( $also ) { $file =~ s/\Q$also\E/$escape/g }

   $file =~ s/$ILLEGAL_CHR/$escape/g;
   $file =~ s/$DIRSPLIT/$escape/g;

   $file
}


# --------------------------------------------------------
# File::Util::existent()
# --------------------------------------------------------
sub existent { my $f = _myargs( @_ ); defined $f ? -e $f : undef }


# --------------------------------------------------------
# File::Util::touch()
# --------------------------------------------------------
sub touch {
   my $this = shift @_;
   my $file = shift @_ || '';
   my $opts = $this->_remove_opts( \@_ );
   my $path;

   return $this->_throw(
      'no input',
      {
         meth    => 'touch',
         missing => 'a file name or file handle reference',
         opts    => $opts,
      }
   ) unless defined $file && length $file;

   $path = $this->return_path( $file );

   # see if the file exists already and is a directory
   return $this->_throw(
      'cant touch on a dir',
      {
         filename => $file,
         dirname  => $path,
         opts     => $opts,
      }
   ) if -e $file && -d $file;

   # it's good to know beforehand whether or not we have permission to open
   # and read from this file allowing us to handle such an exception before
   # it handles us.

   # first check the readability of the file's housing dir
   return $this->_throw(
      'cant dread',
      {
         filename => $file,
         dirname  => $path,
         opts     => $opts,
      }
   ) if ( -e $path && !-r $path );

   $this->make_dir( $path ) unless -e $path;

   # create the file if it doesn't exist (like the *nix touch command does)
   # except we'll create it in binmode or with UTF-8 encoding if requested
   $this->write_file(
      $file => '' => { empty_writes_OK => 1, binmode => $opts->{binmode} }
   ) unless -e $file;

   my $now = time();

   # return
   return utime $now, $now, $file;
}


# --------------------------------------------------------
# File::Util::file_type()
# --------------------------------------------------------
sub file_type {
   my $f = _myargs( @_ );

   return unless defined $f and -e $f;

   my @ret;

   push @ret, 'PLAIN'     if -f $f;   push @ret, 'TEXT'      if -T $f;
   push @ret, 'BINARY'    if -B $f;   push @ret, 'DIRECTORY' if -d $f;
   push @ret, 'SYMLINK'   if -l $f;   push @ret, 'PIPE'      if -p $f;
   push @ret, 'SOCKET'    if -S $f;   push @ret, 'BLOCK'     if -b $f;
   push @ret, 'CHARACTER' if -c $f;

   ## no critic
   push @ret, 'TTY'       if -t $f;
   ## use critic

   push @ret, 'ERROR: Cannot determine file type' unless scalar @ret;

   return @ret;
}


# --------------------------------------------------------
# File::Util::flock_rules()
# --------------------------------------------------------
sub flock_rules {
   my $this   = shift(@_);
   my @rules  = _myargs( @_ );

   return @ONLOCKFAIL unless scalar @rules;

   my %valid = qw/
      NOBLOCKEX   NOBLOCKEX
      NOBLOCKSH   NOBLOCKSH
      BLOCKEX     BLOCKEX
      BLOCKSH     BLOCKSH
      FAIL        FAIL
      WARN        WARN
      IGNORE      IGNORE
      UNDEF       UNDEF
      ZERO        ZERO /;

   map {
      return $this->_throw('bad flock rules', { 'bad' => $_, 'all' => \@rules })
      unless exists $valid{ $_ }
   } @rules;

   @ONLOCKFAIL = @rules;

   @ONLOCKFAIL
}


# --------------------------------------------------------
# File::Util::is_bin()
# --------------------------------------------------------
sub is_bin { my $f = _myargs( @_ ); defined $f ? -B $f : undef }


# --------------------------------------------------------
# File::Util::last_access()
# --------------------------------------------------------
sub last_access {
   my $f = _myargs( @_ ); $f ||= '';

   return unless -e $f;

   # return the last accessed time of $f
   $^T - ((-A $f) * 60 * 60 * 24)
}


# --------------------------------------------------------
# File::Util::last_modified()
# --------------------------------------------------------
sub last_modified {
   my $f = _myargs( @_ ); $f ||= '';

   return unless -e $f;

   # return the last modified time of $f
   $^T - ((-M $f) * 60 * 60 * 24)
}


# --------------------------------------------------------
# File::Util::last_changed()
# --------------------------------------------------------
sub last_changed {
   my $f = _myargs( @_ ); $f ||= '';

   return unless -e $f;

   # return the last changed time of $f
   $^T - ((-C $f) * 60 * 60 * 24)
}


# --------------------------------------------------------
# File::Util::load_dir()
# --------------------------------------------------------
sub load_dir {
   my $this = shift @_;
   my $opts = $this->_remove_opts( \@_ );
   my $dir  = shift @_;

   my @files    = ( );
   my $dir_hash = { };
   my $dir_list = [ ];

   $dir ||= '';

   return $this->_throw(
      'no input' => {
         meth    => 'load_dir',
         missing => 'a directory name',
         opts    => $opts,
      }
   ) unless length $dir;

   @files = $this->list_dir( $dir => { files_only => 1 } );

   # map the content of each file into a hash key-value element where the
   # key name for each file is the name of the file
   if ( !$opts->{as_list} && !$opts->{as_listref} ) {

      foreach ( @files ) {

         $dir_hash->{ $_ } = $this->load_file( $dir . SL . $_ );
      }

      return $dir_hash;
   }
   else {

      foreach ( @files ) {

         push @$dir_list, $this->load_file( $dir . SL . $_ );
      }

      return $dir_list if $opts->{as_listref};

      return @$dir_list;
   }

   return $dir_hash;
}


# --------------------------------------------------------
# File::Util::make_dir()
# --------------------------------------------------------
sub make_dir {
   my $this = shift @_;
   my $opts = $this->_remove_opts( \@_ );
   my( $dir, $bitmask ) = @_;

   $bitmask = defined $bitmask ? $bitmask : $opts->{bitmask};
   $bitmask ||= oct 777;

   # if the call to this method didn't include a directory name to create,
   # then complain about it
   return $this->_throw(
      'no input',
      {
         meth    => 'make_dir',
         missing => 'a directory name',
         opts    => $opts,
      }
   ) unless defined $dir && length $dir;

   if ( $opts->{if_not_exists} ) {

      if ( -e $dir ) {

         return $dir if -d $dir;

         return $this->_throw(
            'called mkdir on a file',
            {
               filename => $dir,
               dirname  => join( SL, split /$DIRSPLIT/, $dir ) . SL,
               opts     => $opts,
            }
         );
      }
   }
   else {

      if ( -e $dir ) {

         return $this->_throw(
            'called mkdir on a file',
            {
               filename => $dir,
               dirname  => join( SL, split /$DIRSPLIT/, $dir ) . SL,
               opts     => $opts,
            }
         ) unless -d $dir;

         return $this->_throw(
            'make_dir target exists',
            {
               dirname  => $dir,
               filetype => [ $this->file_type( $dir ) ],
               opts     => $opts,
            }
         );
      }
   }

   my ( $winroot ) = $dir =~ /^($WINROOT)/;

   $dir =~ s/^($WINROOT)//;
   $dir =~ s/$DIRSPLIT{2,}/$SL/o;
   $dir =~ s/$DIRSPLIT+$//o unless $dir eq SL;
   $dir =  $winroot . $dir if $winroot;

   my ( $root, $path ) = atomize_path( $dir . SL );

   my @dirs_in_path = split /$DIRSPLIT/, $path;

   # if prospective file name has illegal chars then complain
   foreach ( @dirs_in_path ) {

      return $this->_throw(
         'bad chars',
         {
            string  => $_,
            purpose => 'the name of a file or directory',
            opts    => $opts,
         }
      ) if !$this->valid_filename( $_ );
   }

   # do this AFTER the above check!!
   unshift @dirs_in_path, $root if $root;

   # qualify each subdir in @dirs_in_path by prepending its preceeding dir
   # names to it. Above, "/foo/bar/baz" becomes ("/", "foo", "bar", "baz")
   # and below it becomes ("/", "/foo", "/foo/bar", "/foo/bar/baz")

   if ( @dirs_in_path > 1 ) {
      for ( my $depth = 1; $depth < @dirs_in_path; ++$depth ) {

         if ( $dirs_in_path[ $depth-1 ] eq SL ) {

            $dirs_in_path[ $depth ] = SL . $dirs_in_path[ $depth ]
         }
         else {

            $dirs_in_path[ $depth ] =
               join SL, @dirs_in_path[ ( $depth - 1 ) .. $depth ]
         }
      }
   }

   my $i = 0;

   foreach ( @dirs_in_path ) {
      my $dir = $_;
      my $up  = ( $i > 0 ) ? $dirs_in_path[ $i - 1 ] : '..';

      ++$i;

      if ( -e $dir && !-d $dir ) {

         return $this->_throw(
            'called mkdir on a file',
            {
               filename => $dir,
               dirname  => $up . SL,
               opts     => $opts,
            }
         );
      }

      next if -e $dir;

      # it's good to know beforehand whether or not we have permission to
      # create dirs here, which allows us to handle such an exception
      # before it handles us.
      return $this->_throw(
         'cant dcreate',
         {
            dirname  => $dir,
            parentd  => $up,
            opts     => $opts,
         }
      ) unless -w $up;

      mkdir( $dir, $bitmask ) or
         return $this->_throw(
            'bad make_dir',
            {
               exception => $!,
               dirname   => $dir,
               bitmask   => $bitmask,
               opts      => $opts,
            }
         );
   }

   return $dir;
}


# --------------------------------------------------------
# File::Util::abort_depth()
# --------------------------------------------------------
sub abort_depth {
   my $arg  = _myargs( @_ );
   my $this = shift @_;

   if ( defined $arg ) {

      return File::Util->new->_throw( 'bad abort_depth' => { bad => $arg } )
         if $arg =~ /\D/;

      $ABORT_DEPTH = $arg;

      $this->{opts}->{abort_depth} = $arg
         if blessed $this && $this->{opts};
   }

   return $ABORT_DEPTH;
}

# --------------------------------------------------------
# File::Util::onfail()
# --------------------------------------------------------
sub onfail {
   my ( $this, $arg ) = @_;

   return unless blessed $this;

   $this->{opts}->{onfail} = $arg if $arg;

   return $this->{opts}->{onfail};
}


# --------------------------------------------------------
# File::Util::read_limit()
# --------------------------------------------------------
sub read_limit {
   my $arg  = _myargs( @_ );
   my $this = shift @_;

   if ( defined $arg ) {

      return File::Util->new->_throw ( 'bad read_limit' => { bad => $arg } )
         if $arg =~ /\D/;

      $READ_LIMIT = $arg;

      $this->{opts}->{read_limit} = $arg
         if blessed $this && $this->{opts};
   }

   return $READ_LIMIT;
}


# --------------------------------------------------------
# File::Util::diagnostic()
# --------------------------------------------------------
sub diagnostic {
   my $arg  = _myargs( @_ );
   my $this = shift @_;

   if ( defined $arg ) {

      $WANT_DIAGNOSTICS = $arg ? 1 : 0;

      $this->{opts}->{diag} = $arg ? 1 : 0
         if blessed $this && $this->{opts};
   }

   return $WANT_DIAGNOSTICS;
}


# --------------------------------------------------------
# File::Util::needs_binmode()
# --------------------------------------------------------
sub needs_binmode { $NEEDS_BINMODE }


# --------------------------------------------------------
# File::Util::open_handle()
# --------------------------------------------------------
sub open_handle {
   my $this     = shift @_;
   my $in       = $this->_parse_in( @_ );
   my $file     = '';
   my $mode     = '';
   my $bitmask  = $in->{bitmask} || oct 777;
   my $raw_name = $file;
   my $fh; # will be the lexical file handle scoped to this method
   my ( $root, $path, $clean_name, @dirs ) =
      ( '',    '',    '',          ()    );

   # get name of file when passed in as a name/value pair...

   $file =
      exists  $in->{filename} &&
      defined $in->{filename} &&
      length  $in->{filename}
         ? $in->{filename}
         : exists  $in->{file} &&
           defined $in->{file} &&
           length  $in->{file}
            ? $in->{file}
            : '';

   # ...or fall back to support of two-argument form of invocation

   my $maybe_file = shift @_; $maybe_file = '' if !defined $maybe_file;
   my $maybe_mode = shift @_; $maybe_mode = '' if !defined $maybe_mode;

   $file = $maybe_file if !ref $maybe_file && $file eq '';
   $mode =
      !ref $maybe_mode &&
      !exists $in->{mode}
         ? $maybe_mode
         : $in->{mode};

   $mode ||= 'read';


   my ( $winroot ) = $file =~ /^($WINROOT)/;

   $file =~ s/^($WINROOT)//;
   $file =~ s/$DIRSPLIT{2,}/$SL/o;
   $file =~ s/$DIRSPLIT+$//o unless $file eq SL;
   $file =  $winroot . $file if $winroot;

   $raw_name = $file; # preserve original filename input before line below:

   ( $root, $path, $file ) = atomize_path( $file );

   # begin user input validation/sanitation sequence

   # if the call to this method didn't include a filename to which the caller
   # wants us to write, then complain about it
   return $this->_throw(
      'no input',
      {
         meth    => 'open_handle',
         missing => 'a file name to create, write, read/write, or append',
         opts    => $in,
      }
   ) unless length $file;

   if ( $mode eq 'read' && !-e $raw_name ) {

      # if the file doesn't exist, send back an error
      return $this->_throw(
         'no such file',
         {
            filename => $raw_name,
            opts     => $in,
         }
      ) unless -e $clean_name;
   }

   # if prospective filename contains 2+ dir separators in sequence then
   # this is a syntax error we need to whine about
   {
      my $try_filename = $raw_name;

      $try_filename =~ s/$WINROOT//; # windows abs paths would throw this off

      return $this->_throw(
         'bad chars',
         {
            string  => $raw_name,
            purpose => 'the name of a file or directory',
            opts    => $in,
         }
      ) if $try_filename =~ /(?:$DIRSPLIT){2,}/;
   }

   # determine existance of the file path, make directory(ies) for the
   # path if the full directory path doesn't exist
   @dirs = split /$DIRSPLIT/, $path;

   # if prospective file name has illegal chars then complain
   foreach ( @dirs ) {

      return $this->_throw(
         'bad chars',
         {
            string  => $_,
            purpose => 'the name of a file or directory',
            opts    => $in,
         }
      ) if !$this->valid_filename( $_ );
   }

   # do this AFTER the above check!!
   unshift @dirs, $root if $root;

   # make sure that open mode is a valid mode
   if (
      !exists $in->{use_sysopen} &&
      !defined $in->{use_sysopen}
   ) {
      # native Perl open modes
      unless (
         exists $$MODES{popen}{ $mode } &&
         defined $$MODES{popen}{ $mode }
      ) {
         return $this->_throw(
            'bad openmode popen',
            {
               meth     => 'open_handle',
               filename => $raw_name,
               badmode  => $mode,
               opts     => $in,
            }
         )
      }
   }
   else {
      # system open modes
      unless (
         exists $$MODES{sysopen}{ $mode } &&
         defined $$MODES{sysopen}{ $mode }
      ) {
         return $this->_throw(
            'bad openmode sysopen',
            {
               meth     => 'open_handle',
               filename => $raw_name,
               badmode  => $mode,
               opts     => $in,
            }
         )
      }
   }

   # cleanup file name - if path is relative, normalize it
   #    - /foo/bar/baz.txt stays as /foo/bar/baz.txt
   #    - foo/bar/baz.txt  becomes ./foo/bar/baz.txt
   #    - baz.txt          stays as baz.txt
   if ( !length $root && !length $path ) {

      $path = '.' . SL;
   }
   else { # otherwise path normalized at end

      $path .= SL;
   }

   # final clean filename assembled
   $clean_name = $root . $path . $file;

   # create path preceding file if path doesn't exist and not in read mode
   if ( $mode ne 'read' && !-e $root . $path ) {

      my $make_dir_ok = 1;

      my $make_dir_return = $this->make_dir(
         $root . $path,
         exists $in->{dbitmask} &&
         defined $in->{dbitmask}
            ? $in->{dbitmask}
            : oct 777,
            {
               diag   => $in->{diag},
               onfail => sub {
                  my ( $err, $trace ) = @_;

                  return $in->{onfail}
                     if ref $in->{onfail} &&
                        ref $in->{onfail} eq 'CODE';

                  $make_dir_ok = 0;

                  return $err . $trace;
               }
            }
      );

      die $make_dir_return unless $make_dir_ok;
   }

   # sanity checks based on requested mode
   if (
         $mode eq 'write'     ||
         $mode eq 'append'    ||
         $mode eq 'rwcreate'  ||
         $mode eq 'rwclobber' ||
         $mode eq 'rwappend'
   ) {
      # Check whether or not we have permission to open and perform writes
      # on this file.

      if ( -e $clean_name ) {

         return $this->_throw(
            'cant fwrite',
            {
               filename => $clean_name,
               dirname  => $root . $path,
               opts     => $in,
            }
         ) unless -w $clean_name;
      }
      else {
         # If file doesn't exist and the path isn't writable, the error is
         # one of unallowed creation.
         return $this->_throw(
            'cant fcreate',
            {
               filename => $clean_name,
               dirname  => $root . $path,
               opts     => $in,
            }
         ) unless -w $root . $path;
      }
   }
   elsif ( $mode eq 'read' || $mode eq 'rwupdate' ) {
      # Check whether or not we have permission to open and perform reads
      # on this file, starting with file's housing directory.
      return $this->_throw(
         'cant dread',
         {
            filename => $clean_name,
            dirname  => $root . $path,
            opts     => $in,
         }
      ) unless -r $root . $path;

      # Seems obvious, but we can't read non-existent files
      return $this->_throw(
         'cant fread not found',
         {
            filename => $clean_name,
            dirname  => $root . $path,
            opts     => $in,
         }
      ) unless -e $clean_name;

      # Check the readability of the file itself
      return $this->_throw(
         'cant fread',
         {
            filename => $clean_name,
            dirname  => $root . $path,
            opts     => $in,
         }
      ) unless -r $clean_name;
   }
   else {
      return $this->_throw(
         'no input',
         {
            meth    => 'open_handle',
            missing => q{a valid IO mode. (eg- 'read', 'write'...)},
            opts    => $in,
         }
      );
   }

   # Final bit of input validation made necessary by the would-be perils
   # of IO encoding while using sys(open,read,write,seek,tell,etc) -
   # Basically, using :utf8 encoding with syswrite is deprecated
   if
   (
      ( exists $in->{use_sysopen} && defined $in->{use_sysopen} ) &&
      ( $in->{binmode} && lc $in->{binmode} eq 'utf8' )
   )
   {
      return $this->_throw(
         'bad binmode',
         {
            meth    => 'open_handle',
            filename => $clean_name,
            dirname  => $root . $path,
            opts     => $in,
         }
      );
   }

   # input validation sequence finished

   if ( $$in{no_lock} || !$USE_FLOCK ) {
      if (
         !exists $in->{use_sysopen} &&
         !defined $in->{use_sysopen}
      ) { # perl open
         # get open mode
         $mode = $$MODES{popen}{ $mode };

         open $fh, $mode, $clean_name or
            return $this->_throw(
               'bad open',
               {
                  filename  => $clean_name,
                  mode      => $mode,
                  exception => $!,
                  cmd       => $mode . $clean_name,
                  opts      => $in,
               }
            );
      }
      else { # sysopen
         # get open mode
         $mode = $$MODES{sysopen}{ $mode };

         sysopen( $fh, $clean_name, $mode ) or
            return $this->_throw(
               'bad open',
               {
                  filename  => $clean_name,
                  mode      => $mode,
                  exception => $!,
                  cmd       => qq($clean_name, $mode),
                  opts      => $in,
               }
            );
      }
   }
   else {
      if (
         !exists $in->{use_sysopen} &&
         !defined $in->{use_sysopen}
      ) { # perl open
         # open read-only first to safely check if we can get a lock.
         if ( -e $clean_name ) {

            open $fh, '<', $clean_name or
               return $this->_throw(
                  'bad open',
                  {
                     filename  => $clean_name,
                     mode      => 'read',
                     exception => $!,
                     cmd       => $mode . $clean_name,
                     opts      => $in,
                  }
               );

            # lock file before I/O on platforms that support it
            my $lockstat = $this->_seize( $clean_name, $fh, $in );

            warn "returning $lockstat" && return $lockstat unless fileno $lockstat;

            if ( $mode ne 'read' ) {

               open $fh, $$MODES{popen}{ $mode }, $clean_name or
                  return $this->_throw(
                     'bad open',
                     {
                        exception => $!,
                        filename  => $clean_name,
                        mode      => $mode,
                        opts      => $in,
                        cmd       => $$MODES{popen}{ $mode } . $clean_name,
                     }
                  );
            }
         }
         else {
            open $fh, $$MODES{popen}{ $mode }, $clean_name or
               return $this->_throw(
                  'bad open',
                  {
                     exception => $!,
                     filename  => $clean_name,
                     mode      => $mode,
                     opts      => $in,
                     cmd       => $$MODES{popen}{ $mode } . $clean_name,
                  }
               );

            # lock file before I/O on platforms that support it
            my $lockstat = $this->_seize( $clean_name, $fh, $in );

            return $lockstat unless $lockstat;
         }
      }
      else { # sysopen
         # open read-only first to safely check if we can get a lock.
         if ( -e $clean_name ) {

            open $fh, '<', $clean_name or
               return $this->_throw(
                  'bad open',
                  {
                     filename  => $clean_name,
                     mode      => 'read',
                     exception => $!,
                     cmd       => $mode . $clean_name,
                     opts      => $in,
                  }
               );

            # lock file before I/O on platforms that support it
            my $lockstat = $this->_seize( $clean_name, $fh, $in );

            return $lockstat unless $lockstat;

            sysopen( $fh, $clean_name, $$MODES{sysopen}{ $mode } )
               or return $this->_throw(
                  'bad open',
                  {
                     filename  => $clean_name,
                     mode      => $mode,
                     opts      => $in,
                     exception => $!,
                     cmd       => qq($clean_name, $$MODES{sysopen}{ $mode }),
                  }
               );
         }
         else { # only non-existent files get bitmask arguments
            sysopen(
               $fh,
               $clean_name,
               $$MODES{sysopen}{ $mode },
               $bitmask
            ) or return $this->_throw(
               'bad open',
               {
                  filename  => $clean_name,
                  mode      => $mode,
                  opts      => $in,
                  exception => $!,
                  cmd       => qq($clean_name, $$MODES{sysopen}{$mode}, $bitmask),
               }
            );

            # lock file before I/O on platforms that support it
            my $lockstat = $this->_seize( $clean_name, $fh, $in );

            return $lockstat unless $lockstat;
         }
      }
   }

   # call binmode on the filehandle if it was requested or UTF-8
   if ( $in->{binmode} )
   {
      if ( lc $in->{binmode} eq 'utf8' )
      {
         if ( $HAVE_UU )
         {
            binmode $fh, ':unix:encoding(UTF-8)';
         }
         else
         {
            close $fh;

            return $this->_throw( 'no unicode' => $in );
         }
      }
      elsif ( $in->{binmode} == 1 )
      {
         binmode $fh;
      }
      else
      {
         binmode $fh, $in->{binmode} # apply user-specified IO layer(s)
      }
   }

   # return file handle reference to the caller
   return $fh;
}


# --------------------------------------------------------
# File::Util::unlock_open_handle()
# --------------------------------------------------------
sub unlock_open_handle {
   my( $this, $fh ) = @_;

   return 1 unless $USE_FLOCK;

   return $this->_throw(
      'not a filehandle' => {
         opts    => $this->_remove_opts( \@_ ),
         argtype => ref $fh,
      }
   ) unless $fh && fileno $fh;

   return flock( $fh, &Fcntl::LOCK_UN ) if $CAN_FLOCK;

   return 0;
}


# --------------------------------------------------------
# File::Util::return_path()
# --------------------------------------------------------
sub return_path { my $f = _myargs( @_ ); $f =~ s/(^.*)$DIRSPLIT.*/$1/; $f }


# --------------------------------------------------------
# File::Util::strict_path()
# --------------------------------------------------------
sub strict_path
{
   my $path = _myargs( @_ );
   my $copy = $path;

   ( $path ) = $path =~ /(^.*$DIRSPLIT)/;

   ( $path ) = $copy =~ /(^\.{1,2}$)/ if !defined $path;

   return unless defined $path;

   $path .= SL unless substr $path, -1, 1 =~ /$DIRSPLIT/;

   return $path =~ /$DIRSPLIT/ ? $path : undef;
}


# --------------------------------------------------------
# File::Util::default_path()
# --------------------------------------------------------
sub default_path
{
   my ( $path, $dflt ) = _myargs( @_ );

   $dflt = defined $dflt ? $dflt : '.' . SL;

   $path = strict_path( $path );

   return defined $path ? $path : $dflt;
}


# --------------------------------------------------------
# File::Util::size()
# --------------------------------------------------------
sub size { my $f = _myargs( @_ ); $f ||= ''; return unless -e $f; -s $f }


# --------------------------------------------------------
# File::Util::trunc()
# --------------------------------------------------------
sub trunc { $_[0]->write_file( { mode => trunc => file => $_[1] } ) }


# --------------------------------------------------------
# File::Util::use_flock()
# --------------------------------------------------------
sub use_flock {
   my $arg = _myargs( @_ );

   $USE_FLOCK = !!$arg if defined $arg;

   return $USE_FLOCK;
}

# --------------------------------------------------------
# File::Util::AUTOLOAD()
# --------------------------------------------------------
sub AUTOLOAD {

   # The main purpose of using autoload here is to avoid compiling in
   # copious amounts of error handling code at compile time, when in
   # the majority of cases and in production code-- such errors should
   # have already been debugged and the error handling mechanism will
   # end up getting invoked seldom if ever.  There's no reason to pay
   # the performance penalty when it's not necessary.
   # The other purpose is to support legacy method names.

   ( my $name = our $AUTOLOAD ) =~ s/.*:://;

   # These are legacy method names, and their current replacements.  In order
   # to future-proof things, this hashref is used as a dispatch table further
   # down in the code in lieu of potentially-growing if/else block, which
   # would ugly to maintain

   my $redirect_methods = {
      can_write => \&is_writable,
      can_read  => \&is_readable,
      isbin     => \&is_bin,
      readlimit => \&read_limit,
      max_dives => \&abort_depth,
   };

   if ( $name eq '_throw' )
   {
      *_throw = sub
      {
         my $this = shift @_;
         my $in   = $this->_parse_in( @_ ) || { };
         my $error_class;

         # direct input can override object-global diag default, otherwise
         # the object's "want diagnostics" setting is inherited

         $in->{diag} = defined $in->{diag} && !$in->{diag}
            ? 0
            : $in->{diag}
               ? $in->{diag}
               : $this->{opts}->{diag};

         if
         (
            $in->{diag} ||
            (      $in->{opts}           &&
               ref $in->{opts}           &&
               ref $in->{opts} eq 'HASH' &&
               $in->{opts}->{diag}
            )
         )
         {
            require File::Util::Exception::Diagnostic;

            $error_class = 'File::Util::Exception::Diagnostic';

            unshift @_, $this, $error_class;

            goto \&File::Util::Exception::Diagnostic::_throw;
         }
         else
         {
            require File::Util::Exception::Standard;

            $error_class = 'File::Util::Exception::Standard';

            unshift @_, $this, $error_class;

            goto \&File::Util::Exception::Standard::_throw;

         }
      };

      goto \&_throw;
   }
   elsif ( exists $redirect_methods->{ $name } ) {

      { no strict 'refs'; *{ $name } = $redirect_methods->{ $name } }

      goto \&$name;
   }

   die qq(Unknown method: File::Util::$name\n);
}


# --------------------------------------------------------
# File::Util::DESTROY()
# --------------------------------------------------------
sub DESTROY { }

1;


__END__

=pod

=head1 NAME

File::Util - Easy, versatile, portable file handling

=head1 VERSION

version 4.161950

=head1 DESCRIPTION

File::Util provides a comprehensive toolbox of utilities to automate all
kinds of common tasks on files and directories.  Its purpose is to do so
in the most B<portable> manner possible so that users of this module won't
have to worry about whether their programs will work on other operating systems
and/or architectures.  It works on Linux, Windows, Mac, BSD, Unix and others.

File::Util is written B<purely in Perl>, and requires no compiler or make
utility on your system in order to install and run it.  It loads a minimal
amount of code when used, only pulling in support for lesser-used methods
on demand.  It has no dependencies other than what comes installed with Perl
itself.

File::Util also aims to be as backward compatible as possible, running without
problems on Perl installations as old as 5.006.  You are encouraged to run
File::Util on Perl version 5.8 and above.

After browsing this document, please have a look at the other documentation.
I<(See L<DOCUMENTATION|/DOCUMENTATION> section below.)>

=head1 SYNOPSIS

   # use File::Util in your program
   use File::Util;

   # create a new File::Util object
   my $f = File::Util->new();

   # read file into a variable
   my $content = $f->load_file( 'some_file.txt' );

   # write content to a file
   $f->write_file( 'some_other_file.txt' => 'Hello world!' );

   # get the contents of a directory, 3 levels deep
   my @songs = $f->list_dir( '~/Music' => { recurse => 1, max_depth => 3 } );

=head1 DOCUMENTATION

You can do much more with File::Util than the examples above.  For an
explanation of all the features available to you, take a look at these other
reference materials:

=over

=item B<Examples>

The L<File::Util::Manual::Examples> document has a long list of small, reusable
code snippets and techniques to use in your own programs.  This is the "cheat
sheet", and is a great place to get started quickly.  Almost everything you
need is here.

=item B<Complete API Reference>

The L<File::Util::Manual> is the complete reference document explaining every
available feature and object method.  Use this to look up the full information
on any given feature when the examples aren't enough.

=item B<Cookbook>

The L<File::Util::Cookbook> contains examples of complete, working programs
that use File::Util to easily accomplish tasks which require file handling.

=back

=head1 BASIC USAGE

=head2 Getting Started

   # use File::Util in your program
   use File::Util;

   # ...you can optionally enable File::Util's diagnostic error messages:
   # (see File::Util::Manual section regarding diagnostics)
   use File::Util qw( :diag );

   # create a new File::Util object
   my $f = File::Util->new();

   # ...you can enable diagnostics for individual objects:
   $f = File::Util->new( diag => 1 );

=head2 File Operations

   # load file content into a scalar variable as raw text
   my $content = $f->load_file( 'somefile.txt' );

   # read a binary file the same way
   my $binary_content = $f->load_file( 'barking-cat.mp4' );

   # write a raw text file
   $f->write_file( 'somefile.txt' => $content );

   # ...and write a binary file, using some other options as well
   $f->write_file(
      'llama.jpg' => $picture_data => { binmode => 1, bitmask => oct 644 }
   );

   # ...or write a file with UTF-8 encoding (unicode support)
   $f->write_file( 'encoded.txt' => qq(\x{c0}) => { binmode => 'utf8' } );

   # load a file into an array, line by line
   my @lines = $f->load_file( 'file.txt' => { as_lines => 1 } );

   # see if you have permission to write to a file, then append to it
   if ( $f->is_writable( 'captains.log' ) ) {

      my $fh = $f->open_handle( 'captains.log' => 'append' );

      print $fh "Captain's log, stardate 41153.7.  Our destination is...";

      close $fh or die $!;
   }
   else { # ...or warn the crew

      warn "Trouble on the bridge, the Captain can't access his log!";
   }

   # get the number of lines in a file
   my $log_line_count = $f->line_count( '/var/log/messages' );

=head2 File Handles

   # get an open file handle for reading
   my $fh = $f->open_handle( 'Ian likes cats.txt' => 'read' );

   while ( my $line = <$fh> ) { # read the file, line by line
      # ... do stuff
   }

   # get an open file handle for writing the same way
   $fh = $f->open_handle( 'John prefers dachshunds.txt' => 'write' );

   # You add the option to turn on UTF-8 strict encoding for your reads/writes
   $fh = $f->open_handle(
      'John prefers dachshunds.txt' => 'write' => { binmode => 'utf8' }
   );

   print $fh "Bob is happy! \N{U+263A}"; # << unicode smiley face!

   # you can use sysopen to get low-level with your file handles if needed
   $fh = $f->open_handle(
      'alderaan.txt' => 'rwclobber' => { use_sysopen => 1 }
   );

   syswrite $fh, "that's no moon";

   # ...You can use any of these syswrite modes with open_handle():
   # read, write, append, rwcreate, rwclobber, rwappend, rwupdate, and trunc

PLEASE NOTE that as of Perl 5.23, it is deprecated to mix system IO
(sysopen/syswrite/sysread/sysseek) with utf8 binmode (see perldoc perlport).
As such, File::Util will no longer allow you to do this after version
4.132140.  Please see notes on UTF-8 and encoding further below.

   # ...THIS WILL NOW FAIL!
   $f->open_handle(
      'somefile.txt' => 'write' => { use_sysopen => 1, binmode => 'utf8' }
   );

=head2 Directories

   # get a listing of files, recursively, skipping directories
   my @files = $f->list_dir( '/var/tmp' => { files_only => 1, recurse => 1 } );

   # get a listing of text files, recursively
   my @textfiles = $f->list_dir(
      '/var/tmp' => {
         files_match => qr/\.txt$/,
         files_only  => 1,
         recurse     => 1,
      }
   );

   # walk a directory, using an anonymous function or function ref as a callback
   $f->list_dir( '/home/larry' => {
      recurse  => 1,
      callback => sub {
         my ( $selfdir, $subdirs, $files ) = @_;
         # do stuff ...
      },
   } );

   # get an entire directory tree as a hierarchal datastructure reference
   my $tree = $f->list_dir( '/my/podcasts' => { as_tree => 1 } );

=head2 Getting Information About Files

   print 'My file has a bitmask of ' . $f->bitmask( 'my.file' );

   print 'My file is a ' . join(', ', $f->file_type( 'my.file' )) . " file.";

   warn 'This file is binary!' if $f->is_bin( 'my.file' );

   print 'My file was last modified on ' .
      scalar localtime $f->last_modified( 'my.file' );

=head2 Getting Information About Your System's IO Capabilities

   # Does your running Perl support unicode?
   print 'I support unicode' if $f->can_utf8;

   # Can your system use file locking?
   print 'I can use flock' if $f->can_flock;

   # The correct directory separator for your system
   print 'The correct directory separator for this system is ' . $f->SL;

   # Does your platform require binmode for all IO?
   print 'I always need binmode' if $f->needs_binmode;

   # Is your system an EBCDIC platform?  (see perldoc perlebcdic)
   print 'This is an EBCDIC platform, so be careful!' if $f->EBCDIC;

...See the L<File::Util::Manual> for more details and features like advanced
pattern matching in directories, callbacks, directory walking, user-definable
error handlers, and more.

=head2 File Encoding and UTF-8

If you want to read/write in UTF-8, you can do that:

   $ftl->load_file( 'file.txt' => $content => { binmode => 'utf8' } );

   $ftl->write_file( 'file.txt' => $content => { binmode => 'utf8' } );

   $ftl->open_handle( 'file.txt' => 'read' => { binmode => 'utf8' } );

   # ...and so on

Only use C<binmode =E<gt> 'utf8'> for text.

Encoding and IO layers (sometimes called disciplines) can become complex.
It's not something you usually need to worry about unless you wish to
really fine tune File::Util's behavior beyond what are very suitable, portable
defaults, or accomplish very specific tasks like encoding conversions.

You're free to specify any binmode you like, or allow File::Util to use the
system's default IO layering.  It will automatically use the ":raw" pseudo layer
when reading files that are binary, unless specifically told to use something
different.

You can control things as shown in the examples below:

   $ftl->load_file( 'file.txt' => $content => { binmode => SPEC } );

   $ftl->write_file( 'file.txt' => $content => { binmode => SPEC } );

   $ftl->open_handle( 'file.txt' => 'read' => { binmode => SPEC } );

...where C<SPEC> is one or more of any supported IO layers on your system.
Examples might include:

=over

=item *

C<':raw'>

=item *

C<':unix'>

=item *

C<':crlf'>

=item *

C<':stdio'>

=item *

C<':encoding(ENCODING)'> I<with ENCODING's like iso-8859-1, shiftjis, etc>

=item *

...and much more

=back

You can learn about the IO layers available to you and what they do in the
L<PerlIO> perldoc.  Available options have increased over the years, and are
likely subject to continued evolution.  Consult the L<PerlIO> and L<Encode>
documentation as your authoritative source of info on what layers to use.

=head1 PERFORMANCE

File::Util consists of a set of smaller modules, but only loads the ones it
needs when it needs them.  It offers a comparatively fast load-up time, so using
File::Util doesn't bloat your code's resource footprint.

Additionally, File::Util has been optimized to run fast.  In many scenarios
it does more and still out-performs other popular IO modules.  Benchmarking tools
are included as part of the File::Util installation package.

I<(See the benchmarking and profiling scripts>
I<that are included as part of this distribution.)>

=head1 METHODS

File::Util exposes the following public methods.

B<Each of which are covered in the L<File::Util::Manual>>, which has more room for
the detailed explanation that is provided there.

This is just an itemized table of contents for HTML POD readers.  For those viewing
this document in a text terminal, open perldoc to the C<File::Util::Manual>.

=over

=item atomize_path         I<(see L<atomize_path|File::Util::Manual/atomize_path>)>

=item bitmask              I<(see L<bitmask|File::Util::Manual/bitmask>)>

=item can_flock            I<(see L<can_flock|File::Util::Manual/can_flock>)>

=item can_utf8             I<(see L<can_utf8|File::Util::Manual/can_utf8>)>

=item created              I<(see L<created|File::Util::Manual/created>)>

=item default_path         I<(see L<default_path|File::Util::Manual/default_path>)>

=item diagnostic           I<(see L<diagnostic|File::Util::Manual/diagnostic>)>

=item ebcdic               I<(see L<ebcdic|File::Util::Manual/ebcdic>)>

=item escape_filename      I<(see L<escape_filename|File::Util::Manual/escape_filename>)>

=item existent             I<(see L<existent|File::Util::Manual/existent>)>

=item file_type            I<(see L<file_type|File::Util::Manual/file_type>)>

=item flock_rules          I<(see L<flock_rules|File::Util::Manual/flock_rules>)>

=item is_bin               I<(see L<is_bin|File::Util::Manual/is_bin>)>

=item is_readable          I<(see L<is_readable|File::Util::Manual/is_readable>)>

=item is_writable          I<(see L<is_writable|File::Util::Manual/is_writable>)>

=item last_access          I<(see L<last_access|File::Util::Manual/last_access>)>

=item last_changed         I<(see L<last_changed|File::Util::Manual/last_changed>)>

=item last_modified        I<(see L<last_modified|File::Util::Manual/last_modified>)>

=item line_count           I<(see L<line_count|File::Util::Manual/line_count>)>

=item list_dir             I<(see L<list_dir|File::Util::Manual/list_dir>)>

=item load_dir             I<(see L<load_dir|File::Util::Manual/load_dir>)>

=item load_file            I<(see L<load_file|File::Util::Manual/load_file>)>

=item make_dir             I<(see L<make_dir|File::Util::Manual/make_dir>)>

=item abort_depth          I<(see L<abort_depth|File::Util::Manual/abort_depth>)>

=item needs_binmode        I<(see L<needs_binmode|File::Util::Manual/needs_binmode>)>

=item new                  I<(see L<new|File::Util::Manual/new>)>

=item onfail               I<(see L<onfail|File::Util::Manual/onfail>)>

=item open_handle          I<(see L<open_handle|File::Util::Manual/open_handle>)>

=item read_limit           I<(see L<read_limit|File::Util::Manual/read_limit>)>

=item return_path          I<(see L<return_path|File::Util::Manual/return_path>)>

=item size                 I<(see L<size|File::Util::Manual/size>)>

=item split_path           I<(see L<split_path|File::Util::Manual/split_path>)>

=item strict_path          I<(see L<strict_path|File::Util::Manual/strict_path>)>

=item strip_path           I<(see L<strip_path|File::Util::Manual/strip_path>)>

=item touch                I<(see L<touch|File::Util::Manual/touch>)>

=item trunc                I<(see L<trunc|File::Util::Manual/trunc>)>

=item unlock_open_handle   I<(see L<unlock_open_handle|File::Util::Manual/unlock_open_handle>)>

=item use_flock            I<(see L<use_flock|File::Util::Manual/use_flock>)>

=item valid_filename       I<(see L<valid_filename|File::Util::Manual/valid_filename>)>

=item write_file           I<(see L<write_file|File::Util::Manual/write_file>)>

=back

=head1 EXPORTED SYMBOLS

Exports nothing by default.  File::Util fully respects your namespace.
You can, however, ask it for certain things (below).

=head2 EXPORT_OK

The following symbols comprise C<@File::Util::EXPORT_OK>, and as such are
available for import to your namespace only upon request.  They can be
used either as object methods or like regular subroutines in your program.

   -  atomize_path      -  can_flock         -  can_utf8
   -  created           -  default_path      -  diagnostic
   -  ebcdic            -  escape_filename   -  existent
   -  file_type         -  is_bin            -  is_readable
   -  is_writable       -  last_access       -  last_changed
   -  last_modified     -  needs_binmode     -  strict_path
   -  return_path       -  size              -  split_path
   -  strip_path        -  valid_filename    -  NL and S L

To get any of these functions/symbols into your namespace without having
to use them as object methods, use this kind of syntax:

   use File::Util qw( strip_path return_path existent size );

   my $file  = $ARGV[0];
   my $fname = strip_path( $file );
   my $path  = return_path( $file );
   my $size  = size( $file );

   print qq(File "$fname" exists in "$path", and is $size bytes in size)
      if existent( $file );

=head2 EXPORT_TAGS

   :all (imports all of @File::Util::EXPORT_OK to your namespace)

   :diag (imports nothing to your namespace, it just enables diagnostics)

You can use these tags alone, or in combination with other symbols as
shown above.

=head1 PREREQUISITES

=over

=item None.  There are no external prerequisite modules.

File::Util only depends on modules that are part of the Core Perl distribution,
and you don't need a compiler on your system to install it.

=item File::Util recommends L<Perl|perl> 5.8.1 or better ...

You can technically run File::Util on older versions of Perl 5, but it isn't
recommended, especially if you want unicode support and wish to take advantage
of File::Util's ability to read and write files using UTF-8 encoding.

L<Unicode::UTF8> is also recommended and helps speed things up
in several places where you might choose to use unicode as described
elsewhere in the L<File::Util::Manual>.

=back

=head1 INSTALLATION

To install this module type the following at the command prompt:

   perl Build.PL
   perl Build
   perl Build test
   sudo perl Build install

On Windows systems, the "sudo" part of the command may be omitted, but you
will need to run the rest of the install command with Administrative privileges

=head1 BUGS

Send bug reports and patches to the CPAN Bug Tracker for File::Util at
L<rt.cpan.org|https://rt.cpan.org/Dist/Display.html?Name=File%3A%3AUtil>

=head1 SUPPORT

If you want to get help, contact the authors (links below in AUTHORS section)

I fully endorse L<http://www.perlmonks.org> as an excellent source of help
with Perl in general.

=head1 CONTRIBUTING

The project website for File::Util is at
L<https://github.com/tommybutler/file-util/wiki>

The git repository for File::Util is on Github at
L<https://github.com/tommybutler/file-util>

Clone it at L<git://github.com/tommybutler/file-util.git>

This project was a private endeavor for too long so don't hesitate to pitch in.

=head1 CONTRIBUTORS

The following people have contributed to File::Util in the form of feedback,
encouragement, recommendations, testing, or assistance with problems either
on or offline in one form or another.  Listed in no particular order:

=over

=item *

John Fields <jfields.cpan.org@spammenot.com>

=item *

BrowserUk <browseruk@cpan.org>

=item *

Ricardo SIGNES <rjbs@cpan.org>

=item *

Matt S Trout <perl-stuff@trout.me.uk>

=item *

Nicholas Perez <nperez@cpan.org>

=item *

David Golden <dagolden@cpan.org>

=back

=head1 AUTHORS

Tommy Butler L<http://www.atrixnet.com/contact>

Others Welcome!

=head1 COPYRIGHT

Copyright(C) 2001-2013, Tommy Butler.  All rights reserved.

=head1 LICENSE

This library is free software, you may redistribute it and/or modify it
under the same terms as Perl itself. For more details, see the full text of
the LICENSE file that is included in this distribution.

=head1 LIMITATION OF WARRANTY

This software is distributed in the hope that it will be useful, but without
any warranty; without even the implied warranty of merchantability or fitness
for a particular purpose.

This disclaimer applies to every part of the File::Util distribution.

=head1 SEE ALSO

The rest of the documentation:
L<File::Util::Manual>, L<File::Util::Manual::Examples>, L<File::Util::Cookbook>

Other Useful Modules that do similar things:
L<File::Slurp>, L<File::Spec>, L<File::Find::Rule>, L<Path::Class>,
L<Path::Tiny>

=cut
