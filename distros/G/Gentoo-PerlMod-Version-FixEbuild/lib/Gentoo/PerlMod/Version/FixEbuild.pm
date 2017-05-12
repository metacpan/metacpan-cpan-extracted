use strict;
use warnings;

package Gentoo::PerlMod::Version::FixEbuild;
BEGIN {
  $Gentoo::PerlMod::Version::FixEbuild::VERSION = '0.1.1';
}

# ABSTRACT: Automatically fix an old-style ebuild to a new style ebuild.


use Carp qw( confess carp cluck croak );
use Gentoo::PerlMod::Version qw( gentooize_version );
use Path::Class qw( file dir );
use Params::Util qw( _HASHLIKE _ARRAY );
use File::pushd;
use Moose qw( has );

has 'verbose'    => ( isa => 'Int',  is => 'ro', writer => 'set_verbose',    default => 1, );
has 'lax'        => ( isa => 'Int',  is => 'ro', writer => 'set_lax',        default => 1, );
has 'changelog'  => ( isa => 'Bool', is => 'ro', writer => 'set_changelog',  default => 1, );
has 'remove_old' => ( isa => 'Bool', is => 'ro', writer => 'set_remove_old', default => 1, );
has 'commit'     => ( isa => 'Bool', is => 'ro', writer => 'set_commit',     default => 1, );

has 'manifest'   => ( isa => 'Bool', is => 'ro', writer => 'set_manifest',   default => 1, );
has 'copyright'  => ( isa => 'Bool', is => 'ro', writer => 'set_copyright',  default => 1, );
has 'scm_add'    => ( isa => 'Str',  is => 'ro', writer => 'set_scm_add',    default => 'git add "%s"' );
has 'scm_rm'     => ( isa => 'Str',  is => 'ro', writer => 'set_scm_rm',     default => 'git rm "%s"' );
has 'scm_commit' => ( isa => 'Str',  is => 'ro', writer => 'set_scm_commit', default => 'repoman ci -m "%s"' );

#has 'backup'           => ( isa => 'Bool', is => 'ro', writer => 'set_backup',           default => 0, );
#has 'backup_extension' => ( isa => 'Str',  is => 'ro', writer => 'set_backup_extension', default => '.bak', );
has 'error_callback' => (
  isa     => 'CodeRef',
  is      => 'ro',
  writer  => 'set_error_callback',
  default => sub { return shift->can('_default_error_callback') },
  traits  => ['Code'],
  handles => { 'call_error_callback' => 'execute_method' }
);
has 'log_callback' => (
  isa     => 'CodeRef',
  is      => 'ro',
  writer  => 'set_log_callback',
  default => sub { return shift->can('_default_log_callback') },
  traits  => ['Code'],
  handles => { 'log' => 'execute_method' }
);

sub _default_error_callback {
  my ( $self, $reason, $tag ) = @_;
  local $Carp::CarpLevel = $Carp::CarpLevel + 1;
  croak($reason);
}

sub _default_log_callback {
  my ( $self, $level, $message, $tags ) = @_;
  return $self if ( $self->verbose < 1 );
  local $Carp::CarpLevel = $Carp::CarpLevel + 1;
  my $tag = "[log: $level";
  if ($tags) {
    $tag .= '/' . $tags;
  }
  $tag .= '] ' . $message;
  carp $tag if $level <= $self->verbose;
  return $self;
}

sub _fix_file_single {
  my ( $self, $filename ) = @_;
  return unless $self->_is_ebuild($filename);

  my ( $category, $package, $version ) = $self->_get_atom_bits($filename);

  my $newversion = gentooize_version( $version, { lax => $self->lax } );

  $self->log( 2, "Version change is $version -> $newversion", 'fixfilesingle' );

  if ( $newversion eq $version ) {
    $self->log( 2, "Version numbers are the same, no change", 'fixfilesingle' );
    return;
  }

  my $lines = $self->_get_file($filename);

  if ( not _ARRAY($lines) ) {
    $self->call_error_callback( "Source file is empty", 'emptysource' );
    return;
  }

  my $newfile = $self->_get_new_filename( $filename, $package, $newversion );

  $self->_check_env( $filename, $lines, $newfile );

  $self->_fix_copyright($lines);

  $self->_inject_version( $lines, $version );

  $self->log( 2, "Going to create $newfile", 'fixfilesingle' );

  $self->_write_file( $newfile, $lines );

  $self->_add_to_scm($newfile);

  if ( $self->remove_old ) {
    $self->_rm_from_scm($filename);
  }

  $self->_do_manifest($newfile);

  $self->_add_to_scm( file($newfile)->dir->file("ChangeLog") );
  $self->_add_to_scm( file($newfile)->dir->file("Manifest") );

  $self->_do_changelog( $newfile, $version, $newversion );

  $self->_add_to_scm( file($newfile)->dir->file("ChangeLog") );
  $self->_add_to_scm( file($newfile)->dir->file("Manifest") );

  if ( $self->commit ) {
    $self->_commit_to_scm( $newfile, $package, $version, $newversion );
  }
}

sub _add_to_scm {
  my ( $self, $filename ) = @_;
  $self->log( 2, "adding $filename to SCM", 'addtoscm' );
  my $pushd = pushd( file($filename)->dir );
  my $command = sprintf $self->scm_add, file($filename)->relative('.');
  return system($command ) and do {
    $self->call_error_callback( "Error from system call, on '$command': $!", 'failscmadd' );
    $self->log( 2, "Error from close, on $filename: $!", 'addtoscm' );
  };
}

sub _rm_from_scm {
  my ( $self, $filename ) = @_;
  $self->log( 2, "removing $filename to SCM", 'rmfromscm' );
  my $pushd = pushd( file($filename)->dir );
  my $command = sprintf $self->scm_rm, file($filename)->relative('.');
  return system($command ) and do {
    $self->call_error_callback( "Error from system call, on '$command': $!", 'failscmrm' );
    $self->log( 2, "Error from systemcall : $!", 'rmfromscm' );
  };
}

sub _commit_to_scm {
  my ( $self, $filename, $package, $oldversion, $newversion ) = @_;
  $self->log( 2, "committing to SCM", 'committoscm' );
  my $pushd = pushd( file($filename)->dir );
  my $command = sprintf $self->scm_commit, "[autofix] move $package from $oldversion to $newversion";
  return system($command ) and do {
    $self->call_error_callback( "Error from system call, on '$command': $!", 'failscmcommit' );
    $self->log( 2, "Error from systemcall: $!", 'committoscm' );
  };
}

sub _do_manifest {
  my ( $self, $filename ) = @_;
  $self->log( 2, "manifesting dir of $filename", 'manifest' );
  return unless $self->manifest;
  my $pushd = pushd( file($filename)->dir );

  return system( 'repoman', 'manifest' ) and do {
    $self->call_error_callback( "Error from system call, on 'repoman manifest': $!", 'failsmanifest' );
    $self->log( 2, "Error from system, on $filename: $!", 'domanifest' );
  };
}

sub _do_changelog {
  my ( $self, $filename, $oldversion, $newversion ) = @_;
  $self->log( 2, "updating changelog for $filename", 'changelog' );
  return unless $self->changelog;
  my $pushd = pushd( file($filename)->dir );

  return system( 'echangelog', "AUTOFIX: Migrated from old version format ( $oldversion ) to new version format ( $newversion )" )
    and do {
    $self->call_error_callback( "Error from system call, on 'echangelog' $!", 'failsechangelog' );
    $self->log( 2, "Error from system, on $filename: $!", 'dochangelog' );
    };
}

sub _check_env {
  my ( $self, $filename, $lines, $newfile ) = @_;

  $self->_need_perl_module_inherit($lines);

  $self->_need_no_existing_tricks($lines);

  if ( -e $newfile ) {
    $self->call_error_callback( "Destination file already exists : " . $newfile->basename, 'fileexists' );
  }
  return;
}


sub fix_file {
  my ( $self, @files ) = @_;
  if ( _HASHLIKE( $files[1] ) ) {
    $self = $self->meta->clone_object( $self, %{ shift(@files) } );
  }
  for my $filename (@files) {
    $self->_fix_file_single($filename);

  }
  return 1;
}

sub _get_new_filename {
  my ( $self, $original_file, $package, $newversion ) = @_;
  return file($original_file)->dir->file( $package . '-' . $newversion . '.ebuild' );

}

sub _get_atom_bits {
  my ( $self, $filename ) = @_;
  my $file     = file($filename)->absolute();
  my $dir      = $file->parent;
  my $package  = $dir->dir_list(-1);
  my $basename = $file->basename;
  $basename =~ s/\.ebuild$//;
  $basename =~ s/^\Q$package\E-//;
  my $category = $dir->parent->dir_list(-1);
  $self->log( 2, "Processing $category / $package version $basename", 'getatombits' );

  return ( $category, $package, $basename );
}

sub _is_ebuild {
  my ( $self, $filename ) = @_;
  if ( $filename !~ /\.ebuild$/ ) {
    $self->call_error_callback( "$filename lacks .ebuild", 'extension' );
    $self->log( 2, "$filename lacks .ebuild", 'isebuild' );
  }
  return 1;
}

sub _get_file {
  my ( $self, $filename ) = @_;
  my $basename = file($filename)->basename;
  $self->log( 2, "Reading file $basename", 'getfile', );

  open my $fh, '<', $filename or do {
    $self->call_error_callback( "Error from open, cant open $filename: $!", 'failopen' );
    $self->log( 2, "Cant open $filename: $!", 'getfile' );
  };
  my @lines = map { chomp; $_ } <$fh>;
  close $fh or do {
    $self->call_error_callback( "Error from close, on $filename: $!", 'failclose' );
    $self->log( 2, "Error from close, on $filename: $!", 'getfile' );
  };
  $self->log( 2, 'Read file, lines:' . scalar @lines, 'getfile' );

  return \@lines;
}

sub _write_file {
  my ( $self, $filename, $lines ) = @_;

  my $basename = file($filename)->basename;

  $self->log( 2, "Writing file $basename", 'writefile', );

  open my $fh, '>', $filename or do {
    $self->call_error_callback( "Error from open, cant open $filename: $!", 'failopenw' );
    $self->log( 2, "Cant open $filename: $!", 'writefile' );
  };
  for ( @{$lines} ) {
    print {$fh} $_, "\n" or do {
      $self->call_error_callback( "Error from print, cant write to  $filename: $!", 'failprintw' );
      $self->log( 2, "Cant print to $filename: $!", 'writefile' );
    };
  }
  close $fh or do {
    $self->call_error_callback( "Error from close, on $filename: $!", 'failclosew' );
    $self->log( 2, "Error from close, on $filename: $!", 'writefile' );
  };

  $self->log( 2, "Wrote file $basename", 'writefile', );

}

sub _fix_copyright {
  my ( $self, $lines ) = @_;
  $self->log( 2, 'Fixing copyright.', 'fixcopyright' );

  my $year = ( [localtime]->[5] + 1900 );
  my $count = 0;
  for ( 0 .. $#{$lines} ) {
    my $line = $lines->[$_];

    if ( $line =~ /^#\sCopyright\s(\d+)-(\d+)\sGentoo\sFoundation/ ) {
      my $od = $1;
      my $d  = $2;
      $count++;
      $self->log( 2, "Copyright found on line $_", 'fixcopyright' );
      if ( "$d" eq "$year" ) {
        $self->log( 2, "Copyright already up-to-date", 'fixcopyright' );
        next;
      }
      if ( not $self->copyright ) {
        $self->log( 2, "Copyright outdated, but self->copyright is false", 'fixcopyright' );
        next;
      }
      $line = "# Copyright " . $od . "-" . $year . " Gentoo Foundation";
      $self->log( 2, "Copyright updated, $d -> $year", 'fixcopyright' );
      $lines->[$_] = $line;
      next;
    }
    $self->log( 3, "No copyright found on line $_ >" . $line . "<", 'fixcopyright' );
  }
  if ( $count < 1 ) {
    $self->call_error_callback( "No copyright found", 'nocopyright' );
    return 0;
  }
  if ( $count > 1 ) {
    $self->call_error_callback( "Copyright found on multiple lines", 'mutliplecopyright' );
    return 0;
  }
  return 1;
}

sub _need_perl_module_inherit {
  my ( $self, $lines ) = @_;
  $self->log( 2, 'Checking for perl-module', 'needperlmoduleinherit' );
  my $count = 0;
  for ( 0 .. $#{$lines} ) {
    my $line = $lines->[$_];

    if ( $line =~ /^\s*inherit\s*(.*$)/ ) {
      my $inherit = "$1";
      $self->log( 2, "inherit stanza  found on line $_", 'needperlmoduleinherit' );
      if ( $inherit !~ /(^|\w|\s)perl-module(\w|\s|$)/ ) {
        $self->log( 2, "no perl-module found in inherit stanza q[$inherit]", 'needperlmoduleinherit' );
        next;
      }
      $self->log( 2, "perl-module found in inherit stanza q[$inherit]", 'needperlmoduleinherit' );
      $count++;
      next;
    }
    $self->log( 3, "No inherit stanza found on line $_ >" . $line . "<", 'needperlmoduleinherit' );
  }
  if ( $count < 1 ) {
    $self->call_error_callback( "No perl-module inherit found", 'noinherit' );
    return 0;
  }
  if ( $count > 1 ) {
    $self->call_error_callback( "perl-module inherit found on multiple lines", 'mutlipleinherit' );
    return 0;
  }
  return 1;
}

sub _need_no_existing_tricks {
  my ( $self, $lines ) = @_;
  $self->log( 2, 'Checking for existing(incompatible) version switching tricks', 'existingtricks' );

  my $count = 0;
  for ( 0 .. $#{$lines} ) {
    my $line = $lines->[$_];

    if ( $line =~ /^\s*MODULE_VERSION=/ ) {
      $self->call_error_callback( "MODULE_VERSION= already defined", 'existingtricks' );
      return 0;
    }
    if ( $line =~ /^\s*S=/ ) {
      $self->call_error_callback( "S= already defined", 'existingtricks' );
      return 0;
    }
    if ( $line =~ /^\s*MY_P=/ ) {
      $self->call_error_callback( "MY_P= already defined", 'existingtricks' );
      return 0;
    }
    if ( $line =~ /^\s*MY_PV=/ ) {
      $self->call_error_callback( "MY_PV= already defined", 'existingtricks' );
      return 0;
    }
  }
  return 1;
}

sub _inject_version {
  my ( $self, $lines, $version ) = @_;
  $self->log( 2, "Injecting Version", 'injectversion' );

  my $count = 0;
  for ( 0 .. $#{$lines} ) {
    my $line = $lines->[$_];

    if ( $line =~ /^\s*inherit\s*(.*$)/ ) {
      my $inherit = "$1";
      $self->log( 2, "inherit stanza  found on line $_", 'injectversion' );
      if ( $inherit !~ /(^|\w|\s)perl-module(\w|\s|$)/ ) {
        $self->log( 3, "no perl-module found in inherit stanza q[$inherit]", 'injectversion' );
        next;
      }
      $self->log( 2, "perl-module found in inherit stanza q[$inherit] on line $_", 'injectversion' );
      splice @{$lines}, $_, 0, 'MODULE_VERSION="' . $version . '"';
      $self->log( 2, 'array Spliced',              'injectversion' );
      $self->log( 3, '-1 : ' . $lines->[ $_ - 1 ], 'injectversion' );
      $self->log( 3, ' 0 : ' . $lines->[$_],       'injectversion' );
      $self->log( 3, ' 1 : ' . $lines->[ $_ + 1 ], 'injectversion' );
      return;
    }
  }

}

__PACKAGE__->meta->make_immutable;
1;

__END__
=pod

=head1 NAME

Gentoo::PerlMod::Version::FixEbuild - Automatically fix an old-style ebuild to a new style ebuild.

=head1 VERSION

version 0.1.1

=head1 SYNOPSIS

This module is severely incomplete and only 'Just Works'.

see the accompanying script for usage.

This is currently my poorest quality module on CPAN, and this is just a release to get this horrible beast off my machine.

The code is horrible, and far too complex for this and needs a serious overhaul. (yes, already, too much featureitis )

=head1 METHODS

=head2 fix_file

    $instance->fix_file( @file_list )
    $instance->fix_file( $file );
    $instance->fix_file( \%config_overrides , @file_list );

Fixes the given files.

=head1 AUTHOR

Kent Fredric <kentnl@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2011 by Kent Fredric <kentnl@cpan.org>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

