package LCFG::Build::Utils;    # -*-perl-*-
use strict;
use warnings;

# $Id: Utils.pm.in 35408 2019-01-17 16:05:10Z squinney@INF.ED.AC.UK $
# $Source: /var/cvs/dice/LCFG-Build-Tools/lib/LCFG/Build/Utils.pm.in,v $
# $Revision: 35408 $
# $HeadURL: https://svn.lcfg.org/svn/source/tags/LCFG-Build-Tools/LCFG_Build_Tools_0_9_30/lib/LCFG/Build/Utils.pm.in $
# $Date: 2019-01-17 16:05:10 +0000 (Thu, 17 Jan 2019) $

our $VERSION = '0.9.30';

use v5.10;

use Cwd ();
use File::Basename ();
use File::Find     ();
use File::pushd    ();
use File::Spec     ();
use File::Temp     ();
use IO::File       ();
use Module::Pluggable v3.10 search_path => [ 'LCFG::Build::Utils' ];
use Try::Tiny;

use constant NOT_FOUND => -1;

sub datadirs {

  my @dirs;
  if ( defined $ENV{LCFG_BUILD_TMPLDIR} && -d $ENV{LCFG_BUILD_TMPLDIR} ) {
    push @dirs, $ENV{LCFG_BUILD_TMPLDIR};
  }

  for my $dir ( '/usr/local/share/lcfgbuild',
                '/usr/share/lcfgbuild' ) {
    if ( -d $dir ) {
      push @dirs, $dir;
    }
  }

  return @dirs;

}

sub load_configs {

  require YAML::Syck;

  my @datadirs = datadirs();

  state $lcfgcfg = do {
    my $lcfg_file;
    for my $dir (@datadirs) {
      $lcfg_file = File::Spec->catfile( $dir, 'lcfg_config.yml' );
      last if -f $lcfg_file;
    }
    YAML::Syck::LoadFile($lcfg_file);
  };

  state $mapping = do {
    my $map_file;
    for my $dir (@datadirs) {
      $map_file = File::Spec->catfile( $dir, 'mapping_config.yml' );
      last if -f $map_file;
    }
    YAML::Syck::LoadFile($map_file);
  };

  return ( $lcfgcfg, $mapping );
}

sub translate_macro {
    my ( $spec, $macro, $extra ) = @_;

    my ( $lcfgcfg, $mapping ) = load_configs();

    my $output;
    if ( exists $mapping->{$macro} ) {
        my $attr = $mapping->{$macro};
        $output = $spec->$attr;

        if ( !defined $output ) {
            $output = q{};
        }
        elsif ( ref $output eq 'ARRAY' ) {
            $output = join q{, }, @{$output};
        }

    }
    elsif ( exists $lcfgcfg->{$macro} ) {
        $output = $lcfgcfg->{$macro}{value};
    }
    elsif ( defined $extra && exists $extra->{$macro} ) {
        $output = $extra->{$macro};
    }
    else {
        warn "Unknown macro $macro\n";
        return;
    }

    return $output;

}

sub translate_string {
    my ( $spec, $string, $style, $extra ) = @_;

    $style ||= 'autoconf';

    my ( $start_mark, $end_mark );
    if ( $style eq 'cmake' ) {    # ${FOO}
        $start_mark = quotemeta(q(${));
        $end_mark   = quotemeta(q(}));
    }
    else {                        # @FOO@
        $start_mark = quotemeta(q(@));
        $end_mark   = quotemeta(q(@));
    }

    my @macros = (
        $string =~ m{$start_mark
                     (\w+)        # The macro name
                     $end_mark}gx
    );

    # unique-ify
    my %macros = map { $_ => 1 } @macros;
    @macros = keys %macros;

    for my $macro (@macros) {
        my $value = translate_macro( $spec, $macro, $extra );
        if ( defined $value ) {
            $string =~ s{$start_mark
                         \Q$macro\E
                         $end_mark}{$value}gx;
        }
    }

    return $string;
}

sub translate_file {
    my ( $spec, $in, $out, $extra ) = @_;

    my $fh = IO::File->new( $in, 'r' )
        or die "Could not open $in: $!\n";

    my $outdir = ( File::Basename::fileparse($out) )[1];

    my $tmp = File::Temp->new(
        TEMPLATE => 'lcfgXXXXXX',
        DIR      => $outdir,
        UNLINK   => 0,
    );

    while ( defined( my $line = $fh->getline ) ) {
        my $out = translate_string( $spec, $line, 'autoconf', $extra );
        print {$tmp} $out;
    }

    my $tmpname = $tmp->filename;

    $tmp->close or die "Could not close temporary file $tmpname: $!\n";

    rename $tmpname, $out
        or die "Could not move temporary file $tmpname to $out: $!\n";

    my ( $dev,   $ino,     $mode, $nlink, $uid,
         $gid,   $rdev,    $size, $atime, $mtime,
         $ctime, $blksize, $blocks ) = stat $in;

    # Attempt to make the output files look the same as the input files

    chmod $mode, $out or warn "chmod on $out to ($mode) failed: $!\n";
    utime $atime, $mtime, $out or warn "utime on $out to ($atime, $mtime) failed: $!\n";

    return;
}

sub find_trans_files {
    my ( $basedir, @translate ) = @_;

    require File::Find::Rule;

    my %found;

    for my $trans (@translate) {
        my $searchdir = $basedir;
        my $match     = $trans;

        # Matches are *ALWAYS* expressed using a Unix-style
        # path-separator. At this point if we spot a separator we need
        # to handle splitting that string and putting it back together
        # correctly for the current platform.

        if ( index( $trans, q{/} ) != NOT_FOUND ) {
            my @parts = split /\//, $trans;

            $match     = pop @parts;
            $searchdir = File::Spec->catdir( $basedir, @parts );
        }

        my @files;
        if ( index( $match, q(*) ) != NOT_FOUND ) {

            @files = File::Find::Rule->file()->name($match)->in($searchdir);

        }
        else {
            my $file = File::Spec->catfile( $searchdir, $match );
            if ( -f $file ) {
                push @files, $file;
            }
            else {
                warn "Could not find $file\n";
            }
        }

        # Remove the suffix if it is one of the supported special
        # cases, i.e. .cin or .in

        my $suffix;
        if ( $match =~ m/(\.c?in)$/ ) {
            $suffix = $1;
        }

        for my $file (@files) {
            $file = File::Spec->abs2rel( $file, $basedir );

            if ( defined $suffix ) {
                my ( $name, $path )
                    = File::Basename::fileparse( $file, $suffix );
                $found{$file} = File::Spec->catfile( $path, $name );
            }
            else {
                $found{$file} = $file;
            }
        }

    }

    return %found;
}

sub find_and_translate {
    my ( $spec, $dir, $remove_after ) = @_;

    my @translate = $spec->translate;

    my %trans_files = find_trans_files( $dir, @translate );

    for my $in ( keys %trans_files ) {
        my $out = $trans_files{$in};

        $in  = File::Spec->catfile( $dir, $in );
        $out = File::Spec->catfile( $dir, $out );

        translate_file( $spec, $in, $out );

        if ( $remove_after && $in ne $out ) {
            unlink $in;
        }
    }

    return;
}

sub generate_cmake {
    my ( $spec, $dir, $force ) = @_;

    $dir ||= q{.};

    my ( $lcfgcfg, $mapping ) = load_configs();

    require Template;

    my @inc = grep { -d $_ }
              map { File::Spec->catdir( $_, 'templates' ) }
              datadirs();

    my $tt = Template->new(
        {   INCLUDE_PATH => \@inc,
            POST_CHOMP   => 1,
            PRE_CHOMP    => 1,
        }
    ) or die $Template::ERROR . "\n";

    my $args = {
        spec    => $spec,
        lcfgcfg => $lcfgcfg,
        mapping => $mapping
    };

    # We allow the user to write their own CMakeLists.txt unless an
    # override is forced.

    my $cmake_file = File::Spec->catfile( $dir, 'CMakeLists.txt' );
    if ( $force || !-e $cmake_file ) {
        $tt->process( 'cmake.tt', $args, $cmake_file )
            or die $tt->error() . "\n";
    }

    my @translate = $spec->translate;

    my %trans_files = find_trans_files( $dir, @translate );

    $args->{trans} = {%trans_files};

    my $lcfg_cmake_file = File::Spec->catfile( $dir, 'lcfg.cmake' );

    $tt->process( 'lcfg.cmake.tt', $args, $lcfg_cmake_file )
        or die $tt->error() . "\n";

    return;
}

sub generate_srctar {
    my ( $tarname, $srcdir, $resultsdir ) = @_;

    if ( !defined $srcdir ) {
        $srcdir = q{.};
    }
    if ( !File::Spec->file_name_is_absolute( $srcdir ) ) {
        $srcdir = File::Spec->rel2abs( $srcdir );
    }

    if ( !defined $resultsdir ) {
        $resultsdir = q{.};
    }
    if ( !File::Spec->file_name_is_absolute( $resultsdir ) ) {
        $resultsdir = File::Spec->rel2abs( $resultsdir );
    }

    my @parent_dirs = File::Spec->splitdir($srcdir);
    pop @parent_dirs;
    my $parent_dir = File::Spec->catdir(@parent_dirs);

    # Need to ensure we are in the correct directory before adding
    # files to the tar archive.

    my $dh = File::pushd::pushd($parent_dir);

    require Archive::Tar;
    require IO::Zlib;

    my $tar = Archive::Tar->new();

    $tar->setcwd($parent_dir);

    File::Find::find(
        {   wanted => sub {
                # debian packaging stuff does not belong in the source tar file
                if ( $File::Find::name eq "$srcdir/debian" ) {
                    $File::Find::prune = 1;
                    return;
                }
                my $name
                    = File::Spec->abs2rel( $File::Find::name, $parent_dir );
                $tar->add_files($name);
            },
            no_chdir => 1,
        },
        $srcdir
    );

    my $tarfile = File::Spec->catfile( $resultsdir, $tarname );

    $tar->write( $tarfile, 1 );

    return $tarfile;
}

sub run_plugins_method {
    my ( $class, $method, @method_args ) = @_;

    $method //= 'generate_metadata';

    my $success = 1;
    for my $util ( sort $class->plugins() ) {
        my $loaded = $util->require;
        if ( !$loaded ) {
            warn "Failed to load plugin module '$util': $@\n";
            next;
        }

        my $type = ( split /::/, $util )[-1];

        if ( $util->can($method) ) {
            try {
                $util->$method(@method_args);
                say STDERR "Successfully generated metadata files for $type";
            } catch {
                warn "Failed to generate package metadata files for $type: $_\n";
                $success = 0;
            };
        }
    }

    return $success;
}

1;
__END__

=head1 NAME

    LCFG::Build::Utils - LCFG software building utilities

=head1 VERSION

    This documentation refers to LCFG::Build::Utils version 0.9.30

=head1 SYNOPSIS

    my $dir = q{.};

    my $spec = LCFG::Build::PkgSpec->new_from_metafile("$dir/lcfg.yml");

    LCFG::Build::Utils::find_and_translate( $spec, $dir );

    LCFG::Build::Utils::generate_cmake( $spec, $dir );

=head1 DESCRIPTION

This module provides a suite of utilities to help in building packages
from LCFG projects, particularly LCFG components. The methods are
mostly used by tools which implement the LCFG::Build::Tool base class
(e.g. LCFG::Build::Tool::Pack) but typically they are designed to be
generic enough to be used elsewhere.

=head1 SUBROUTINES/METHODS

=over 4

=item translate_macro( $spec, $macro, $extra )

This is used by all other translator subroutines in this module to do
the actual work of replacing macros with their values.

This takes a macro name and translates it using the information stored
in the LCFG build metadata package specification. You can also provide
a reference to an extra hash of keys and values to be searched. You
should note that this subroutine takes a macro I<name> and not the
complete macro, i.e. it is C<FOO> not C<@FOO@>. An unknown macro will
result in the subroutine returning undef. To help in this case a
warning will be printed to STDERR.

For backwards compatibility, if the macro is not found in the package
specification it will also look in the LCFG default package install
locations list (see C</usr/share/lcfgbuild/lcfg_config.yml> for
details). It is STRONGLY RECOMMENDED that you do NOT rely on this
location list as it will inconvenience downstream users who want to
repackage for different Operating Systems.

For backwards compatibility the macros are looked up in a mapping list
which supports the old names. Any macros not beginning with the
C<LCFG_> sub-string should be considered deprecated as they will be
phased out in a future release. See
C</usr/share/lcfgbuild/mapping_config.yml> for a full list of
supported macro mappings.

=item translate_string( $spec, $string, $style, $extra )

This takes a string and finds all the macros embedded within and gets
them translated. Two styles of macros are supported C<cmake> which is
like C<${FOO}> and the standard autoconf style which is
C<@FOO@>. Specifying anything other than C<cmake> will result in
autoconf style substitutions. You can provide a reference to an extra
hash which will be passed through to translate_macro().

Note that an unknown macro will NOT be removed from the string, a warning
is printed to STDERR when this occurs.

=item translate_file( $spec, $in, $out, $extra )

This takes the names for the input file and output file and,
optionally, a reference to a hash of extra key/values to be passed
through to translate_macro(). All macros in the file will be
translated as described above, currently only autoconf-style macros
are supported.

=item find_trans_files( $dir, @translate )

This takes the name of a directory in which to search and a list of
files and file globs to match. A hash of the files found is
returned. Note that the paths will all be relative to the specified
directory and not absolute.

Unless you search for files with a .cin or .in suffix, which are
treated specially, the keys and values will be the same. In the
special cases the keys will be the path to the input files and the
values will be the file names with the .in or .cin file extension
removed.

If you specify a particular file name and it is missing a warning will
be printed but this is not a fatal error.

=item find_and_translate( $spec, $dir, $remove )

This is a wrapper which combines find_trans_files() with the
application of the translate_file() subroutine on each file discovered
in the project directory. If you set the C<remove> parameter to a true
value then, if the input and output file names do not match, the input
files will be removed after the translation has occurred. This can be
useful if you want to generate a pristine tar file which does not
contain *.cin files.

=item generate_cmake( $spec, $dir, $force )

This generates all the necessary CMake files for building an LCFG
project. This will create a simple C<CMakeLists.txt> file unless you
need extra power in which case you can write your own and that will be
used instead. You can set the force variable to a true value to
overwrite any existing CMake file, if you wish. A second file is
created, named C<lcfg.cmake>, which contains all the necessary
functions and macros for building an LCFG project.

=item $tarfile = generate_srctar( $tarname, $srcdir, $resultsdir )

Takes the name of a tarfile to generate and packages up everything in
the specified source directory. The generated tar file will be placed
into the results directory. If either of the the source or results
directories are not specified then the current working directory will
be used. This returns the full path to the generated tar file.

=back

=head1 CONFIGURATION AND ENVIRONMENT

Some of the routines use template files, by default it is assumed that
the standard template directory is
C</usr/local/share/lcfgbuild/templates> on MacOSX and
C</usr/share/lcfgbuild/templates> on all other platforms.  You can
override this using the LCFG_BUILD_TMPLDIR environment variable. If
you have done a local (i.e. non-root) install of this module then this
will almost certainly be necessary.

=head1 DEPENDENCIES

This module uses a number of other Perl modules. For generating
compressed tar files you will need L<Archive::Tar> and
L<IO::Zlib>. For generation of the CMake files you will need the Perl
Template Toolkit. For macro translation you will need
L<YAML::Syck>. For finding the translation files you will need
L<File::Find::Rule>.

Although not a requirement for this module, in most cases if you want
to build the resulting software you will need CMake, version 2.6.0 or
greater, installed on your build machine.

=head1 PLATFORMS

This is the list of platforms on which we have tested this
software. We expect this software to work on any Unix-like platform
which is supported by Perl.

Fedora12, Fedora13, ScientificLinux5, ScientificLinux6, MacOSX7

=head1 BUGS AND LIMITATIONS

There are no known bugs in this application. Please report any
problems to bugs@lcfg.org, feedback and patches are also always very
welcome.

=head1 AUTHOR

    Stephen Quinney <squinney@inf.ed.ac.uk>

=head1 LICENSE AND COPYRIGHT

    Copyright (C) 2008 University of Edinburgh. All rights reserved.

This library is free software; you can redistribute it and/or modify
it under the terms of the GPL, version 2 or later.

=cut

