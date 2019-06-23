package LCFG::Build::VCS::SVN; # -*-perl-*-
use strict;
use warnings;

# $Id: SVN.pm.in 35424 2019-01-18 10:01:16Z squinney@INF.ED.AC.UK $
# $Source: /var/cvs/dice/LCFG-Build-VCS/lib/LCFG/Build/VCS/SVN.pm.in,v $
# $Revision: 35424 $
# $HeadURL: https://svn.lcfg.org/svn/source/tags/LCFG-Build-VCS/LCFG_Build_VCS_0_3_9/lib/LCFG/Build/VCS/SVN.pm.in $
# $Date: 2019-01-18 10:01:16 +0000 (Fri, 18 Jan 2019) $

our $VERSION = '0.3.9';

use v5.10;

use File::Path ();
use File::Spec ();
use IPC::Run qw(run);
use IO::File qw(O_WRONLY O_CREAT O_NONBLOCK O_NOCTTY);
use Try::Tiny;
use URI ();

use Moose;

with 'LCFG::Build::VCS';

has '+binpath' => ( default => 'svn' );

has '+id' => ( default => 'SVN' );

no Moose;
__PACKAGE__->meta->make_immutable;

sub auto_detect {
    my ( $class, $dir ) = @_;

    my $is_svn = 0;
    try {
	my $vcs = $class->new( module  => 'test',
			       workdir => $dir );

	$vcs->run_cmd( 'info', $dir );
	$is_svn = 1;
    };

    return $is_svn;
}

sub get_info {
    my ( $self, $infokey, $directory ) = @_;

    if ( !defined $directory ) {
        $directory = $self->workdir;
    }

    my @info = $self->run_infocmd( 'info', $directory );

    for my $line (@info) {
        if ( $line =~ m/^
                        ([^:]+)  # key
                        :
                        \s+
                        (.+)     # value
                        $/x ) {
            my ( $key, $value ) = ( $1, $2 );
            $key =~ s/\s+//g;

            if ( $key eq $infokey ) {
                return $value;
            }
        }
    }

    return;
}

sub _build_url {
  my ( $self, $dir, $section, @extra ) = @_;

  my $url = $self->get_info( 'URL', $dir );

  my $u = URI->new($url);
  my @path = split '/', $u->path;

  while ( defined( my $part = pop @path ) ) {
    if ( $part eq 'trunk' || $part eq 'tags' || $part eq 'branches' ) {
      last;
    }
  }

  my $module = $self->module;

  my $tags_path = join q{/}, @path, $section, $module, @extra;

  $u->path($tags_path);

  return $u->as_string;
}

sub tag_base {
    my ( $self, $dir ) = @_;

    return $self->_build_url( $dir, 'tags' );
}

sub tag_url {
    my ( $self, $tag, $dir ) = @_;

    return $self->_build_url( $dir, 'tags', $tag );
}

sub trunk_url {
    my ( $self, $dir ) = @_;

    return $self->_build_url( $dir, 'trunk' );
}

sub run_infocmd {
    my ( $self, @args ) = @_;

    my @cmd = $self->build_cmd(@args);

    my ( $in, $out, $err );

    my $success = run \@cmd, \$in, \$out, \$err;
    if ( !$success ) {
        die "Error whilst running @cmd: $err\n";
    }

    my @out = split /[\r\n]+/, $out;

    return @out;
}

sub checkcommitted {
    my ( $self, $dir ) = @_;

    warn "Checking that all file changes have been committed.\n";

    if ( !defined $dir ) {
        $dir = $self->workdir;
    }

    my @notcommitted = $self->run_infocmd( 'status', '--quiet', $dir );

    my $allcommitted;
    if ( scalar @notcommitted > 0 ) {
        $allcommitted = 0;
    }
    else {
        $allcommitted = 1;
    }

    if (wantarray) {
        # This makes the output the same as for the CVS module

        my @shortnames;
        for my $file (@notcommitted) {
            if ( $file =~ m/^M\s+(.+)$/ ) {
                my $short = File::Spec->abs2rel( $1, $dir );
                push @shortnames, $short;
            }
        }

        return ( $allcommitted, @shortnames );
    }
    else {
        return $allcommitted;
    }

}

sub checkout_project {
    my ( $self, $version, $outdir ) = @_;

    my $url;
    if ( defined $version ) {
        my $tag = $self->gen_tag($version);
        $url = $self->tag_url($tag);
    }
    else {
        $url = $self->trunk_url();
    }

    my @cmd = ( 'checkout', $url );
    if ( defined $outdir ) {
        push @cmd, $outdir;
    }

    $self->run_cmd(@cmd);

    return;
}

sub export {
    my ( $self, $version, $dir ) = @_;

    my $tag = $self->gen_tag($version);

    my $target = join q{-}, $self->module, $version;
    my $exportdir = File::Spec->catdir( $dir, $target );

    if ( !$self->dryrun ) {
        if ( !-d $dir ) {
            eval { File::Path::mkpath($dir) };
            if ($@) {
                die "Could not create $dir: $@\n";
            }
        }

        if ( -d $exportdir ) {
            File::Path::rmtree($exportdir);
        }
    }

    my $tag_url = $self->tag_url($tag);

    # It appears that svn will pretend that you can export anything
    # whether or not it actually exists. So we have to check for
    # existence first with a 'list' command.

    eval { $self->run_infocmd( 'list', $tag_url ) };
    if ( $@ ) {
        die "Could not find tag $tag_url\n";
    }

    $self->run_cmd( 'export', $tag_url, $exportdir );

    return $exportdir;
}

sub export_devel {
    my ( $self, $version, $dir ) = @_;

    my $target = join q{-}, $self->module, $version;

    my $exportdir = File::Spec->catdir( $dir, $target );

    if ( !$self->dryrun ) {
        if ( !-d $dir ) {
            eval { File::Path::mkpath($dir) };
            if ($@) {
                die "Could not create $dir: $@\n";
            }
        }

        if ( -d $exportdir ) {
            File::Path::rmtree($exportdir);
        }
    }

    $self->run_cmd( 'export', $self->workdir, $exportdir );

    return $exportdir;

}

sub genchangelog {
    my ($self) = @_;

    warn "Generating Changelog from subversion log\n";

    my $dir     = $self->workdir;
    my $logfile = $self->logfile;

    if ( !-e $logfile ) {

        # This bit borrowed from File::Touch
        sysopen my $fh, $logfile, O_WRONLY | O_CREAT | O_NONBLOCK | O_NOCTTY
            or die "Cannot create $logfile : $!\n";
        $fh->close or die "Cannot close $logfile : $!\n";

        # Assume it is not already part of the repository
        $self->run_cmd( 'add', $logfile );
    }

    # MUST do an update beforehand otherwise some logs get missed.
    $self->run_cmd( 'update', $dir );

    my @cmd = ( 'svn2cl', '--output', $logfile, $dir );
    if ( $self->dryrun ) {
        print "Dry-run: @cmd\n";
    }
    else {
        my ( $in, $out, $err );
        my $success = run \@cmd, \$in, \$out, \$err;
        if ( !$success ) {
            die "Could not run svn2cl: $err\n";
        }
    }

    return;
}

sub import_project {
    my ( $self, $dir, $version, $message ) = @_;

    if ( !defined $message ) {
        $message = 'Imported with LCFG build tools';
    }

    my $module = $self->module;
    my $trunk_url = $self->trunk_url();

    # we want this to fail...
    eval { $self->run_infocmd( 'list', $trunk_url ) };
    if ( !$@ ) {
        die "There is already a project named \"$module\" at $trunk_url\n";
    }

    $self->run_cmd( 'import',
                    '--message', $message,
                    $dir, $trunk_url );

    my $tag_base = $self->tag_base();

    # Ensure the tags directory for this project actually exists
    eval { $self->run_infocmd( 'list', $tag_base ) };
    if ( $@ ) {
        warn "Creating tag base directory for $module\n";
        $self->run_cmd( 'mkdir', '--message', "Creating tag base directory for $module", $tag_base );
    }

    my $tag = $self->gen_tag($version);

    my $tagurl = $self->tag_url($tag);

    $self->run_cmd( 'copy', '--message', "Tagging $module at $tag", $trunk_url, $tagurl );

    return;
}

sub tagversion {
    my ( $self, $version ) = @_;

    my $module = $self->module;

    warn "Tagging $module at version $version\n";

    $self->update_changelog($version);

    my $dir = $self->workdir;

    $self->run_cmd( 'commit', '--message', "$module release: $version", $dir )
        or die "Could not mark release for $dir at $version\n";

    my $tag_base = $self->tag_base();

    # Ensure the tags directory for this project actually exists
    eval { $self->run_infocmd( 'list', $tag_base ) };
    if ( $@ ) {
        warn "Creating tag base directory for $module\n";
        $self->run_cmd( 'mkdir', '--message', "Creating tag base directory for $module", $tag_base );
    }

    my $tag = $self->gen_tag($version);

    my $tagurl = $self->tag_url($tag);

    # It would appear that it is occasionally necessary to do an
    # "update" to get things into a sane state so that a copy will
    # complete successfully. See https://bugs.lcfg.org/show_bug.cgi?id=302

    $self->run_cmd( 'update', $dir );

    $self->run_cmd( 'copy', '--message', "Tagging $module at $tag", $dir, $tagurl );

    $self->run_cmd( 'update', $dir );

    return;
}

__END__

=head1 NAME

    LCFG::Build::VCS::SVN - LCFG build tools for subversion version-control

=head1 VERSION

    This documentation refers to LCFG::Build::VCS::SVN version 0.3.9

=head1 SYNOPSIS

    my $dir = ".";

    my $spec = LCFG::Build::PkgSpec->new_from_metafile("$dir/lcfg.yml");

    my $vcs = LCFG::Build::VCS::SVN->new( module  => $spec->fullname,
                                          workdir => $dir );

    $vcs->genchangelog();

    if ( $vcs->checkcommitted() ) {
      $vcs->tagversion();
    }

=head1 DESCRIPTION

This is part of a suite of tools designed to provide a standardised
interface to version-control systems so that the LCFG build tools can
deal with project version-control in a high-level abstract fashion.

This module implements the interface specified by
L<LCFG::Build::VCS>. It provides support for LCFG projects which use
the subversion version-control system. Facilities are available for
procedures such as importing and exporting projects, doing tagged
releases, generating the project changelog from the version-control
log and checking all changes are committed.

More information on the LCFG build tools is available from the website
http://www.lcfg.org/doc/buildtools/

=head1 ATTRIBUTES

=over

=item module

The name of the software package in this repository. This is required
and there is no default value.

=item workdir

The directory in which the svn commands should be carried out. This is
required and if none is specified then it will default to '.', the
current working directory. This must be an absolute path but if you
pass in a relative path coercion will automatically occur based on the
current working directory.

=item binpath

The name of the svn executable, by default this is C<svn>.

=item quiet

This is a boolean value which controls the quietness of the subversion
commands. By default it is false and commands, such as svn, will print
some extra stuff to the screen.

=item dryrun

This is a boolean value which controls whether the commands will
actually have a real effect or just print out what would be done. By
default it is false.

=item logname

The name of the logfile to which information should be directed when
doing version updates. This is also the name of the logfile to be used
if you utilise the automatic changelog generation option. The default
file name is 'ChangeLog'.

=back

=head1 SUBROUTINES/METHODS

The following class methods are available:

=over

=item new

Creates a new instance of the class.

=item auto_detect($dir)

This method returns a boolean value which indicates whether or not the
specified directory is part of a checked out working copy of a
subversion repository.

=back

The following instance methods are available:

=over

=item get_info($key)

This method can be used to query any information (for example URL or
Repository Root) which is available in the output of the subversion
C<info> command. The key has had the whitespace stripped, for example,
"Last Changed Author" becomes "LastChangedAuthor". If you request
information for a key which is not present this method will die.

=item checkcommitted()

Test to see if there are any uncommitted files in the project
directory. Note this test does not spot files which have not been
added to the version-control system. In scalar context the subroutine
returns 1 if all files are committed and 0 (zero) otherwise. In list
context the subroutine will return this code along with a list of any
files which require committing.

=item genchangelog()

This method will generate a changelog (the name of which is controlled
by the logname attribute) from the log kept within the version-control
system. For subversion the svn2cl(1) command is used.

=item tagversion($version)

This method is used to tag a set of files for a project at a
particular version. It will also update the changelog
appropriately. Tags are generated using the I<gen_tag()> method, see
below for details.

=item gen_tag($version)

Tags are generated from the name and version details passed in by
replacing any hyphens or dots with underscores and joining the two
fields with an underscore. For example, lcfg-foo and 1.0.1 would
become lcfg_foo_1_0_1.

=item run_cmd(@args)

A method used to handle the running of commands for the particular
version-control system. Although we could have used the proper perl
API for subversion it was a lot quicker to just wrap the command line
tools. This method honours the dry-run setting and when a dry-run has
been requested will print out the command and not execute.

For example:

       $vcs->run_cmd( 'update', $workingcopydir );

=item run_infocmd(@args)

This is similar to run_cmd( ) except that it will B<always> run the
command. This is for executing commands which just gather information
and do not modify the repository or working copy.

       $vcs->run_infocmd( 'ls', '-R', $repos_url );

=item export( $version, $dir )

This will export a particular tagged version of the module. You need
to specify the target "build" directory into which the exported tree
will be put. The exported tree will be named like
"modulename-version". For example:

  my $vcs = LCFG::Build::VCS::SVN->new(module => "lcfg-foo");
  $vcs->export( "1.2.3", "/tmp" );

Would give you an exported tree of code for the lcfg-foo module tagged
as lcfg_foo_1_2_3 and it would be put into /tmp/lcfg-foo-1.2.3/

Returns the name of the directory into which the tree was exported.

=item export_devel( $version, $dir )

This is similar to the export method. It takes the current working
copy tree for a module and exports it directly to another tree based
in the specified target "build" directory.

  my $vcs = LCFG::Build::VCS::SVN->new(module => "lcfg-foo");
  $vcs->export_devel( "1.2.3_dev", "/tmp" );

Would give you an exported tree of code for the lcfg-foo module
directory and it would be put into /tmp/lcfg-foo-1.2.3_dev/

Returns the name of the directory into which the tree was exported.

=item import_project( $dir, $version, $message )

Imports a project source tree into the version-control system. You
need to specify the version for the initial tag. Optionally you can
specify a message which will be used.

=item logfile()

This is a convenience method which returns the full path to the
logfile based on the workdir and logname attributes.

=back

=head1 DEPENDENCIES

This module is L<Moose> powered and it depends on
L<LCFG::Build::VCS>. You will need a working C<svn> executable
somewhere on your system and a subversion repository for this module
to be in anyway useful.

=head1 SEE ALSO

L<LCFG::Build::PkgSpec>, L<LCFG::Build::VCS::None>, L<LCFG::Build::Tools>

=head1 PLATFORMS

This is the list of platforms on which we have tested this
software. We expect this software to work on any Unix-like platform
which is supported by Perl.

FedoraCore5, FedoraCore6, ScientificLinux5

=head1 BUGS AND LIMITATIONS

There are no known bugs in this application. Please report any
problems to bugs@lcfg.org, feedback and patches are also always very
welcome.

=head1 AUTHOR

    Stephen Quinney <squinney@inf.ed.ac.uk>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2008-2013 University of Edinburgh. All rights reserved.

This library is free software; you can redistribute it and/or modify
it under the terms of the GPL, version 2 or later.

=cut
