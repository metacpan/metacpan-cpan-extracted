package LCFG::Build::VCS;   # -*-perl-*-
use strict;
use warnings;

use v5.10;

# $Id: VCS.pm.in 35396 2019-01-17 12:01:51Z squinney@INF.ED.AC.UK $
# $Source: /var/cvs/dice/LCFG-Build-VCS/lib/LCFG/Build/VCS.pm.in,v $
# $Revision: 35396 $
# $HeadURL: https://svn.lcfg.org/svn/source/tags/LCFG-Build-VCS/LCFG_Build_VCS_0_3_9/lib/LCFG/Build/VCS.pm.in $
# $Date: 2019-01-17 12:01:51 +0000 (Thu, 17 Jan 2019) $

our $VERSION = '0.3.9';

use DateTime ();
use File::Copy ();
use File::Path ();
use File::Spec ();
use File::Temp ();
use IO::File ();
use IPC::Run qw(run);
use Template v2.14 ();

use Moose::Role;
use Moose::Util::TypeConstraints;

subtype 'AbsPath'
    => as 'Str'
    => where { File::Spec->file_name_is_absolute($_) }
    => message { 'Directory must be an absolute path.' };

# coerce the input string (which is possibly a relative path) into an
# absolute path which does not have a trailing /

coerce 'AbsPath'
    => from 'Str'
    => via {  my $path = File::Spec->file_name_is_absolute($_) ? $_ : File::Spec->rel2abs($_); $path =~ s{/$}{}; $path };

requires qw/checkcommitted genchangelog tagversion export export_devel import_project checkout_project/;

has 'id' => (
    is       => 'ro',
    isa      => 'Str',
    required => 1,
);

has 'module' => (
    is       => 'rw',
    isa      => 'Str',
    required => 1,
);

has 'workdir' => (
    is       => 'rw',
    isa      => 'AbsPath',
    required => 1,
    coerce   => 1,
    default  => q{.},
);

has 'binpath' => (
    is       => 'rw',
    isa      => 'Str',
    required => 0,
);

has 'quiet' => (
    is       => 'rw',
    isa      => 'Bool',
    default  => 0,
    required => 0,
);

has 'dryrun' => (
    is       => 'rw',
    isa      => 'Bool',
    default  => 0,
    required => 0,
);

has 'logname' => (
    is       => 'rw',
    isa      => 'Str',
    default  => 'ChangeLog',
    required => 1,
);

sub build_cmd {
    my ( $self, @args ) = @_;

    my @cmd = ( $self->binpath, @args );

    return @cmd;
}

sub run_cmd {
    my ( $self, @args ) = @_;

    my @cmd = $self->build_cmd(@args);

    my @out;
    if ( $self->dryrun ) {
        my $cmd = join q( ), @cmd;
        print "Dry-run: $cmd\n";
    }
    else {
        my ( $in, $out, $err );

        my $success = run \@cmd, \$in, \$out, \$err;
        if ( !$success ) {
            die "Error whilst running @cmd: $err\n";
        }
        if ($err) {
            warn "$err\n";
        }

        @out = split /[\r\n]+/, $out;
    }

    return @out;
}

sub logfile {
    my ($self) = @_;

    return File::Spec->catfile( $self->workdir, $self->logname );
}

sub gen_tag {
    my ( $self, $version ) = @_;

    # Build a tag from the name and version (if specified) and then
    # replace any period or hyphen characters.
    #
    # name: lcfg-foo, version: 1.0.1, gives: lcfg_foo_1_0_1

    my $tag;
    if ( !defined $version ) {
        $tag = $self->module;
    }
    else {

        if ( $version eq 'latest' ) {
            $tag = 'latest';
        }
        else {
            $tag = join q{_}, $self->module, $version;
        }

    }

    $tag =~ s/\./_/g;
    $tag =~ s/\-/_/g;

    return $tag;
}

sub update_changelog {
    my ( $self, $version, $options ) = @_;
    $options //= {};

    $options->{dryrun}  = $self->dryrun;
    $options->{id}      = $self->id;
    $options->{version} = $version;
    $options->{style} ||= 'default';

    my $dir = $self->workdir;

    my ( $logfile, $needs_add );
    if ( $options->{style} eq 'debian' ) {
        $logfile = File::Spec->catfile( $dir, 'debian', 'changelog' );
        $needs_add = !-e $logfile;

        if ( !$options->{pkgname} ) {

            # Cook up something sensible which looks like a Debian package
            # name

            $options->{pkgname} = lc $self->module;

            # underscores are not permitted, helpfully replace with dashes
            $options->{pkgname} =~ s/_/-/g;

            # For safety remove any other invalid characters
            $options->{pkgname} =~ s/[^a-z0-9-]//;
        }

        update_debian_changelog( $logfile, $options );
    } else {
        $logfile = $self->logfile;
        $needs_add = !-e $logfile;

        update_lcfg_changelog( $logfile, $options );
    }

    if ( !$self->dryrun ) {
        if ($needs_add) {
            $self->run_cmd( 'add', $logfile );
        }
    }

    return;
}

sub update_lcfg_changelog {
    my ( $logfile, $options ) = @_;
    $options //= {};

    $options->{date} ||= DateTime->now->ymd;

    my $dir = (File::Spec->splitpath($logfile))[1];

    my $tmplog = File::Temp->new(
        TEMPLATE => 'lcfgXXXXXX',
        UNLINK   => 1,
        DIR      => $dir,
    );

    my $tmpname = $tmplog->filename;

    $tmplog->print(<<"EOT");
$options->{date}  $options->{id}: new release

\t* Release: $options->{version}

EOT

    if ( -f $logfile ) {
        my $log = IO::File->new( $logfile, 'r' )
            or die "Could not open $logfile: $!\n";

        while ( defined( my $line = <$log> ) ) {
            $tmplog->print($line);
        }

        $log->close;
    }

    $tmplog->close
        or die "Could not close temporary file, $tmpname: $!\n";

    if ( !$options->{dryrun} ) {
        rename $tmpname, $logfile
          or die "Could not rename $tmpname as $logfile: $!\n";
    }

    return;
}

# These update_*_changelog subroutines are also used externally from
# places which do not have access to the VCS object so they are not
# class methods.

sub update_debian_changelog {
    my ( $logfile, $options ) = @_;
    $options //= {};

    $options->{urgency}      ||= 'low';
    $options->{distribution} ||= 'unstable';
    $options->{release}      //= 1;
    $options->{message}      ||= 'New upstream release';

    # RFC822 date
    $options->{date} = DateTime->now->strftime('%a, %d %b %Y %H:%M:%S %z');

    if ( !$options->{email} ) {
        my $user_name = (getpwuid($<))[0];

        my $email_addr = $ENV{DEBEMAIL} || $ENV{EMAIL};

        if ( !$email_addr ) {
            require Net::Domain;

            my $domain = Net::Domain::hostdomain();
            
            $email_addr = join '@', $user_name, $domain;
        }

        # trim any leading or trailing whitespace
        $email_addr =~ s/^\s+//; $email_addr =~ s/\s+$//;

        if ( $email_addr !~ m/<.+>/ ) {
            my $email_name = $ENV{DEBFULLNAME} || $ENV{NAME}  || $user_name;
            $email_name =~ s/^\s+//; $email_name =~ s/\s+$//;

            $email_addr = "$email_name <$email_addr>";
        }

        $options->{email} = $email_addr;
    }

    my ( $dir, $basename ) = (File::Spec->splitpath($logfile))[1,2];

    my $tmplog = File::Temp->new(
        TEMPLATE => 'lcfgXXXXXX',
        UNLINK   => 1,
        DIR      => $dir,
    );
    my $tmpname = $tmplog->filename;

    my $tt = Template->new(
        {
            INCLUDE_PATH => $dir,
        }
    ) or die $Template::ERROR . "\n";

    my $template = q{
[%- FOREACH entry IN entries -%]
[% entry.item('pkgname') %] ([% entry.item('version') %]-[% entry.item('release') %]) [% entry.item('distribution') %]; urgency=[% entry.item('urgency') %]

  * [% entry.item('message') %]

 -- [% entry.item('email') %]  [% entry.item('date') %]

[% END -%]
[% IF current_logfile %][% INSERT $current_logfile %][% END -%]
};

    my %args = (
        entries => [$options],
    );

    if ( -e $logfile ) {
        $args{current_logfile} = $basename;
    }

    $tt->process( \$template, \%args, $tmplog )
        or die $tt->error() . "\n";

    $tmplog->close
        or die "Could not close temporary file, $tmpname: $!\n";

    if ( !$options->{dryrun} ) {
        rename $tmpname, $logfile
          or die "Could not rename $tmpname as $logfile: $!\n";
    }

    return;

}

sub mirror_file {
    my ( $self, $workdir, $exportdir, $dirname, $fname ) = @_;

    my $from_dir = File::Spec->catdir( $workdir, $dirname );
    my $to_dir   = File::Spec->catdir( $exportdir, $dirname );

    if ( !$self->dryrun && !-d $to_dir ) {
        eval { File::Path::mkpath($to_dir) };
        if ($@) {
            die "Could not create $to_dir: $@\n";
        }

        my ($dev,   $ino,     $mode, $nlink, $uid,
            $gid,   $rdev,    $size, $atime, $mtime,
            $ctime, $blksize, $blocks
        ) = stat $from_dir;

        chmod $mode, $to_dir or die "chmod on $to_dir failed: $!\n";

        # We don't care about atime/mtime for directories
    }

    my $from = File::Spec->catfile( $workdir, $dirname, $fname );
    my $to   = File::Spec->catfile( $exportdir, $dirname, $fname );

    my ($dev,   $ino,     $mode, $nlink, $uid,
        $gid,   $rdev,    $size, $atime, $mtime,
        $ctime, $blksize, $blocks
    ) = stat $from;

    if ( $self->dryrun ) {
        print "Dry-run: $from -> $to\n";
    }
    else {
        File::Copy::syscopy( $from, $to )
              or die "Copy $from to $to failed: $!\n";

        chmod $mode, $to or die "chmod on $to to ($mode) failed: $!\n";
        utime $atime, $mtime, $to or die "utime on $to to ($atime, $mtime) failed: $!\n";

    }

    return;
}

sub store_version {
    my ( $self, $version ) = @_;

    warn "Updating build ID file\n";

    my $dir          = $self->workdir;
    my $version_file = 'lcfg-build-id.txt';

    my $tmpfh = File::Temp->new(
        UNLINK => 1,
        DIR    => $dir,
        SUFFIX => '.tmp',
    );

    my $tmpname = $tmpfh->filename;

    $tmpfh->say($version);

    $tmpfh->close
        or die "Could not close temporary file, $tmpname: $!\n";

    if ( !$self->dryrun ) {
        rename $tmpname, $version_file
            or die "Could not rename $tmpname as $version_file: $!\n";
    }

    return;
}

1;
__END__

=head1 NAME

    LCFG::Build::VCS - LCFG version-control infrastructure

=head1 VERSION

This documentation refers to LCFG::Build::VCS version 0.3.9

=head1 SYNOPSIS

    my $vcs = LCFG::Build::VCS::CVS->new();

    $vcs->genchangelog();

    if ( $vcs->checkcommitted() ) {
      $vcs->tagversion();
    }

=head1 DESCRIPTION

This is a suite of tools designed to provide a standardised interface
to version-control systems so that the LCFG build tools can deal with
project version-control in a high-level abstract fashion. Typically
they provide support for procedures such as importing and exporting
projects, doing tagged releases, generating the project changelog from
the version-control log and checking all changes are committed.

This is an interface, you should not attempt to create objects
directly using this module. You will need to implement a sub-class,
for example L<LCFG::Build::VCS::CVS>. This interface requires certain
attributes and methods be specified within any implementing sub-class,
see below for details. For complete details you should read the
documentation associated with the specific sub-class.

More information on the LCFG build tools is available from the website
http://www.lcfg.org/doc/buildtools/

=head1 ATTRIBUTES

=over

=item module

The name of the software package in this repository. This is required
and there is no default value.

=item workdir

The directory in which the version-control system commands should be
carried out. This is required and if none is specified then it will
default to '.', the current working directory. This must be an
absolute path but if you pass in a relative path coercion will
automatically occur based on the current working directory.

=item binpath

The path to the version-control tool. This is required and it is
expected that any module which implements this interface will set a
suitable default command name.

=item quiet

This is a boolean value which controls the quietness of the
version-control system commands. By default it is false and commands,
such as CVS, will print lots of extra stuff to the screen.

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

This module provides a few fully-implemented methods which are likely
to be useful for all sub-classes which implement the interface.

=over

=item gen_tag($version)

Generate a tag based on the package name and the specified
version. Tags are generated from the module name attribute and the
version information passed in by replacing any hyphens or dots with
underscores and joining the two fields with an underscore. For
example, lcfg-foo and 1.0.1 would become lcfg_foo_1_0_1. If no version
is specified then just the module name will be used.

=item update_changelog($version)

This will add a standard-format release tag entry to the top of the
change log file.

=item mirror_file( $sourcedir, $targetdir, $reldir, $basename )

This will copy a file from the source directory to the target
directory. The relative path of the file (within the source directory)
must be split into the relative directory path and filename. Effort is
made to preserve the mode and, in the case of files, atime and
mtime. This is used by various modules in the export_devel() method to
mirror the project directory into a build directory.

=item logfile()

This is a convenience method which returns the full path to the
logfile based on the workdir and logname attributes.

=back

As well as the methods above, any class which implements this
interface MUST provide methods for:

=over

=item checkcommitted()

Test to see if there are any uncommitted files in the project
directory. Note this test does not spot files which have not been
added to the version-control system. In scalar context the subroutine
returns 1 if all files are committed and 0 (zero) otherwise. In list
context the subroutine will return this code along with a list of any
files which require committing.

=item genchangelog($version)

This method will generate a changelog (the name of which is controlled
by the logname attribute) from the log kept within the version-control
system.

=item store_version($version)

This method can be used to store the version string (e.g. C<1.2.3>)
into a file named F<lcfg-build-id.txt> in the top-level directory for
the project. This is useful if you need to have eacy access to the
version string in build scripts.

=item tagversion($version)

This method is used to tag a set of files for a project at a
particular version. It will also update the changelog
appropriately. The tag name is generated using the I<gen_tag()>
method, see below for full details.

=item run_cmd(@args)

A method used to handle the running of commands for the particular
version-control system. This is required for systems like CVS where
shell commands have to be executed. Not all modules will need to
implement this method as they may well use a proper Perl module API
(e.g. subversion).

=item export( $version, $dir )

Exports the source code for the project tagged at the specified
release. The second argument specifies the directory into which the
exported project directory will be placed.

=item export_devel( $version, $dir )

Exports the current development version of the source code for the
project (i.e. your working copy). The second argument specifies the
directory into which the exported project directory will be placed.

=item import_project( $dir, $version, $message )

Imports a project source tree into the version-control system.

=item checkout_project( $version, $dir )

Does a check-out from the version-control system of the project tagged
at the specified version. Unlike the export() method this checked-out
copy will include the files necessary for the version-control system
(e.g. CVS or .svn directories).

=back

=head1 DEPENDENCIES

This module is L<Moose> powered. It also requires L<DateTime> and L<IPC::Run>.

=head1 SEE ALSO

L<LCFG::Build::PkgSpec>, L<LCFG::Build::VCS::CVS>, L<LCFG::Build::VCS::None>, L<LCFG::Build::Tools>

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

Copyright (C) 2008-2019 University of Edinburgh. All rights reserved.

This library is free software; you can redistribute it and/or modify
it under the terms of the GPL, version 2 or later.

=cut
