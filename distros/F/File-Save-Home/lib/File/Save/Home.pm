package File::Save::Home;
require 5.006_001;
use strict;
use warnings;
use Exporter ();
our $VERSION     = '0.10';
our @ISA         = qw(Exporter);
our @EXPORT_OK   = qw(
    get_home_directory
    get_subhome_directory_status
    make_subhome_directory
    restore_subhome_directory_status
    conceal_target_file
    reveal_target_file
    make_subhome_temp_directory
);
our %EXPORT_TAGS = (
    subhome_status => [ qw|
        get_subhome_directory_status
        restore_subhome_directory_status
    | ],
    target => [ qw|
        conceal_target_file
        reveal_target_file
    | ],
);
use Carp;
use File::Path;
use File::Spec::Functions qw|
    catdir
    catfile
    catpath
    splitdir
    splitpath
|;
use File::Temp qw| tempdir |;
*ok = *Test::More::ok;
use File::Find;

#################### DOCUMENTATION ###################

=head1 NAME

File::Save::Home - Place file safely under user home directory

=head1 VERSION

This document refers to version 0.10, released February 10 2017.

=head1 SYNOPSIS

    use File::Save::Home qw(
        get_home_directory
        get_subhome_directory_status
        make_subhome_directory
        restore_subhome_directory_status
        conceal_target_file
        reveal_target_file
        make_subhome_temp_directory
    );

    $home_dir = get_home_directory();

    $desired_dir_ref = get_subhome_directory_status("desired/directory");

    $desired_dir_ref = get_subhome_directory_status(
        "desired/directory",
        "pseudohome/directory",    # two-argument version
    );

    $desired_dir = make_subhome_directory($desired_dir_ref);

    restore_subhome_directory_status($desired_dir_ref);

    $target_ref = conceal_target_file( {
        dir     => $desired_dir,
        file    => 'file_to_be_checked',
        test    => 0,
    } );

    reveal_target_file($target_ref);

    $tmpdir = make_subhome_temp_directory();

    $tmpdir = make_subhome_temp_directory(
        "pseudohome/directory",    # optional argument version
    );

=head1 DESCRIPTION

In the course of deploying an application on another user's system, you
sometimes need to place a file in or underneath that user's home
directory.  Can you do so safely?

This Perl extension provides several functions which try to determine whether
you can, indeed, safely create directories and files underneath a user's home
directory.  Among other things, if you are placing a file in such a location
only temporarily -- say, for testing purposes -- you can temporarily hide
any already existing file with the same name and restore it to its original
name and timestamps when you are done.

=head1 USAGE

=head2 C<get_home_directory()>

Analyzes environmental information to determine whether there exists on the
system a 'HOME' or 'home-equivalent' directory.  Takes no arguments.  Returns
that directory if it exists; C<croak>s otherwise.

On Win32, this directory is the one returned by the following function from the F<Win32>module:

    Win32->import( qw(CSIDL_LOCAL_APPDATA) );
    $realhome =  Win32::GetFolderPath( CSIDL_LOCAL_APPDATA() );

... which translates to something like F<C:\Documents and Settings\localuser\Local Settings\Application Data>.
(For a further discussion of Win32, see below L</"SEE ALSO">.)

On Unix-like systems, things are much simpler.  We simply check the value of
C<$ENV{HOME}>.  We cannot do that on Win32 because C<$ENV{HOME}> is not
defined there.

=cut

sub get_home_directory {
    my $realhome;
    if ($^O eq 'MSWin32') {
        require Win32;
        Win32->import( qw(CSIDL_LOCAL_APPDATA) );  # 0x001c
        $realhome =  Win32::GetFolderPath( CSIDL_LOCAL_APPDATA() );
        $realhome =~ s{ }{\ }g;
        return $realhome if (-d $realhome);
        $realhome =~ s|(.*?)\\Local Settings(.*)|$1$2|;
        return $realhome if (-d $realhome);
        croak "Unable to identify directory equivalent to 'HOME' on Win32: $!";
    } else { # Unix-like systems
        $realhome = $ENV{HOME};
        $realhome =~ s{ }{\ }g;
        return $realhome if (-d $realhome);
        croak "Unable to identify 'HOME' directory: $!";
    }
}

=head2 C<get_subhome_directory_status()>

=head3 Single argument version

Takes as argument a string holding the name of a directory, either
single-level (C<mydir>) or multi-level (C<path/to/mydir>).  Determines
whether that directory already exists underneath the user's
home or home-equivalent directory. Calls C<get_home_directory()> internally,
then tacks on the path passed as argument.

=head3 Two-argument version

Suppose you want to determine the name of a user's home directory by some
other route than C<get_home_directory()>.  Suppose, for example, that you're
on Win32 and want to use the C<my_home()> method supplied by CPAN distribution
File::HomeDir -- a method which returns a different result from that of our
C<get_home_directory()> -- but you still want to use those File::Save::Home
functions which normally call C<get_home_directory()> internally.  Or, suppose
you want to supply an arbitrary path.

You can now do so by supplying an I<optional second argument> to
C<get_subhome_directory_status>.  This argument should be a valid path name
for a directory to which you have write privileges.
C<get_subhome_directory_status> will determine if the directory exists and, if
so, determine whether the I<first> argument is a subdirectory of the I<second>
argument.

=head3 Both versions

Whether you use the single argument version or the two-argument version,
C<get_subhome_directory_status> returns a reference to a four-element hash
whose keys are:

=over 4

=item home

The absolute path of the home directory.

=item abs

The absolute path of the directory specified as first argument to the function.

=item flag

A Boolean value indicating whether the desired directory already exists (a
true value) or not (C<undef>).

=item top

The uppermost subdirectory passed as the argument to this function.

=back

=cut

sub get_subhome_directory_status {
    my $subdir = shift;
    my ($pseudohome, $home);
    $pseudohome = $_[0] if $_[0];
    if (defined $pseudohome) {
        -d $pseudohome or croak "$pseudohome is not a valid directory: $!";
    }
    $home = defined $pseudohome
        ? $pseudohome
        : get_home_directory();
    my $dirname = catdir($home, $subdir);
    my $subdir_top = (splitdir($subdir))[0];

    if (-d $dirname) {
        return {
            home    => $home,
            top     => $subdir_top,
            abs     => $dirname,
            flag    => 1,
       };
    } else {
        return {
            home    => $home,
            top     => $subdir_top,
            abs     => $dirname,
            flag    => undef,
       };
    }
}

=head2 C<make_subhome_directory()>

Takes as argument the hash reference returned by
C<get_subhome_directory_status()>. Examines the first element in that array --
the directory name -- and creates the directory if it doesn't already exist.
The function C<croak>s if the directory cannot be created.

=cut

sub make_subhome_directory {
    my $desired_dir_ref = shift;
    my $dirname = $desired_dir_ref->{abs};
    if (! -d $dirname) {
        mkpath $dirname
            or croak "Unable to create desired directory $dirname: $!";
    }
    return $dirname;
}

=head2 C<restore_subhome_directory_status()>

Undoes C<make_subhome_directory()>, I<i.e.,> if there was no specified
directory under the user's home directory on the user's system before
testing, any such directory created during testing is removed.  On the
other hand, if there I<was> such a directory present before testing,
it is left unchanged.

=cut

sub restore_subhome_directory_status {
    my $desired_dir_ref = shift;
    my $home = $desired_dir_ref->{home};
    croak "Home directory '$home' apparently lost"
        unless (-d $home);
    my $desired_dir = $desired_dir_ref->{abs};
    my $subdir_top = $desired_dir_ref->{top};
    if (! defined $desired_dir_ref->{flag}) {
        find {
            bydepth   => 1,
            no_chdir  => 1,
            wanted    => sub {
                if (! -l && -d _) {
                    rmdir  or croak "Couldn't rmdir $_: $!";
                } else {
                    unlink or croak "Couldn't unlink $_: $!";
                }
            }
        } => (catdir($home, $subdir_top));
        (! -d $desired_dir)
            ? return 1
            : croak "Unable to restore directory created during test: $!";
    }
    else {
        return 1;
    }
}

=head2 C<make_subhome_temp_directory()>

=head3 Regular version:  no arguments

Creates a randomly named temporary directory underneath the home or
home-equivalent directory returned by C<get_home_directory()>.

=head3 Optional argument version

Creates a randomly named temporary directory underneath the directory supplied
as the single argument.  This version is analogous to the two-argument verion
of L</"get_subhome_directory_status()"> above.  You could use it if, for
example, you wanted to use C<File::HomeDir->my_home()> to supply a value for
the user's home directory instead of our C<get_home_directory()>.

=head3 Both versions

In both versions, the temporary subdirectory is created by calling
C<File::Temp::tempdir (DIR => $home, CLEANUP => 1)>.  The function
returns the directory path if successful; C<croak>s otherwise.

B<Note:>  Any temporary directory so created remains in existence for
the duration of the program, but is deleted (along with all its contents)
when the program exits.

=cut

sub make_subhome_temp_directory {
    my ($pseudohome, $home);
    $pseudohome = $_[0] if $_[0];
    if (defined $pseudohome) {
        -d $pseudohome or croak "$pseudohome is not a valid directory: $!";
    }
    $home = defined $pseudohome
        ? $pseudohome
        : get_home_directory();
    my $tdir = tempdir(DIR => $home, CLEANUP => 1);
    return $tdir ? $tdir : croak "Unable to create temp dir under home: $!";
}

=head2 C<conceal_target_file()>

Determines whether file with specified name already exists in specified
directory and, if so, temporarily hides it by renaming it with a F<.hidden>
suffix and storing away its last access and modification times.  Takes as
argument a reference to a hash with these keys:

=over 4

=item dir

The directory in which the file is presumed to exist.

=item file

The targeted file, I<i.e.,> the file to be temporarily hidden if it already
exists.

=item test

Boolean value which, if turned on (C<1>), will cause the function, when
called, to run two C<Test::More::ok()> tests.  Defaults to off (C<0>).

=back

Returns a reference to a hash with these keys:

=over 4

=item full

The absolute path to the target file.

=item hidden

The absolute path to the now-hidden file.

=item atime

The last access time to the target file (C<(stat($file{full}))[8]>).

=item modtime

The last modification time to the target file (C<(stat($file{full}))[9]>).

=item test

The value of the key C<test> in the hash passed by reference as an argument to
this function.

=back

=cut

sub conceal_target_file {
    my $arg_ref = shift;
    my $desired_dir = $arg_ref->{dir};
    my $target_file = $arg_ref->{file};
    my $test_flag   = $arg_ref->{test};
    my $target_file_hidden = $target_file . '.hidden';
    my %targ;
    $targ{full} = catfile( $desired_dir, $target_file );
    $targ{hidden} = catfile( $desired_dir, $target_file_hidden );
    if (-f $targ{full}) {
        $targ{atime}   = (stat($targ{full}))[8];
        $targ{modtime} = (stat($targ{full}))[9];
        rename $targ{full}, $targ{hidden}
            or croak "Unable to rename $targ{full}: $!";
        if ($test_flag) {
            ok(! -f $targ{full}, "target file temporarily suppressed");
            ok(-f $targ{hidden}, "target file now hidden");
        }
    } else {
        if ($test_flag) {
            ok(! -f $targ{full}, "target file not found");
            ok(1, "target file not found");
        }
    }
    $targ{test} = $test_flag;
    return { %targ };
}

=head2 C<reveal_target_file()>

Used in conjunction with C<conceal_target_file()> to restore the original
status of the file targeted by C<conceal_target_file()>, I<i.e.,> renames the
hidden file to its original name by removing the F<.hidden> suffix, thereby
deleting any other file with the original name created between the calls tothe
two functions.  C<croak>s if the hidden file cannot be renamed.  Takes as
argument the hash reference returned by C<conceal_target_file()>.  If the
value for the C<test> key in the hash passed as an argument to
C<conceal_target_file()> was true, then a call to C<reveal_target_file>
will run three C<Test::More::ok()> tests.

=cut

sub reveal_target_file {
    my $target_ref = shift;;
    if(-f $target_ref->{hidden} ) {
        rename $target_ref->{hidden}, $target_ref->{full},
            or croak "Unable to rename $target_ref->{hidden}: $!";
        if ($target_ref->{test}) {
            ok(-f $target_ref->{full},
                "target file re-established");
            ok(! -f $target_ref->{hidden},
                "hidden target now gone");
            ok( (utime $target_ref->{atime},
                       $target_ref->{modtime},
                      ($target_ref->{full})
                ), "atime and modtime of target file restored");
        }
    } else {
        if ($target_ref->{test}) {
            ok(1, "test not relevant");
            ok(1, "test not relevant");
            ok(1, "test not relevant");
        }
    }
}

=head1 BUGS AND TODO

So far tested only on Unix-like systems and Win32.

=head1 SEE ALSO

perl(1).  ExtUtils::ModuleMaker::Auxiliary.  ExtUtils::ModuleMaker::Utility.
The latter two packages are part of the ExtUtils::ModuleMaker distribution
available from the same author on CPAN.  They and the ExtUtils::ModuleMaker
test suite provide examples of the use of File::Save::Home.

Two other distributions located on CPAN, File::HomeDir and
File::HomeDir::Win32, may also be used to locate a suitable value for a user's
home directory.  It should be noted, however, that those modules and
File::Save::Home each take a different approach to defining a home directory
on Win32 systems.  Hence, each may deliver a different result on a given
system.  I cannot say that one distribution's approach is any more or less
correct than the other two's approaches.  The following comments should be
viewed as my subjective impressions; YMMV.

File::HomeDir was originally written by Sean M Burke and is now maintained by
Adam Kennedy.  As of version 0.52 its interface provides three methods for the
''current user'':

    $home = File::HomeDir->my_home;
    $docs = File::HomeDir->my_documents;
    $data = File::HomeDir->my_data;

When I ran these three methods on a Win2K Pro system running ActivePerl 8, I
got these results:

    C:\WINNT\system32>perl -MFile::HomeDir -e "print File::HomeDir->my_home"
    C:\Documents and Settings\localuser

    C:\WINNT\system32>perl -MFile::HomeDir -e "print File::HomeDir->my_documents"
    C:\Documents and Settings\localuser\My Documents

    C:\WINNT\system32>perl -MFile::HomeDir -e "print File::HomeDir->my_data"
    C:\Documents and Settings\localuser\Local Settings\Application Data

In contrast, when I ran the closest equivalent method in File::Save::Home,
C<get_home_directory>, I got this result:

    C:\WINNT\system32>perl -MFile::Save::Home -e "print File::Save::Home->get_home_directory"
    C:\Documents and Settings\localuser\Local Settings\Application Data

In other words, C<File::Save::Home-E<gt>get_home_directory> gave the same result
as C<File::HomeDir-E<gt>my_data>, I<not>, as I might have expected, the same
result as C<File::HomeDir-E<gt>my_home>.

These results can be explained by peeking behind the curtains and looking at
the source code for each module.

=head2 File::HomeDir

File::HomeDir's objective is to provide a value for a user's home directory on
a wide variety of operating systems.  When invoked, it detects the operating
system you're on and calls a subclassed module.  When used on a Win32 system,
that subclass is called File::HomeDir::Windows (not to be confused with the
separate CPAN distribution File::HomeDir::Win32).
C<File::HomeDir::Windows-E<gt>my_home()> looks like this:

    sub my_home {
    	my $class = shift;
    	if ( $ENV{USERPROFILE} ) { return $ENV{USERPROFILE}; }
    	if ( $ENV{HOMEDRIVE} and $ENV{HOMEPATH} ) {
    		return File::Spec->catpath( $ENV{HOMEDRIVE}, $ENV{HOMEPATH}, '',);
    	}
    	Carp::croak("Could not locate current user's home directory");
    }

In other words, determine the current user's home directory simply by checking
environmental variables analogous to the C<$ENV{HOME}> on Unix-like systems.
A very straightforward approach!

As mentioned above, File::Save::Home takes a different approach.  It uses the
Win32 module to, in effect, check a particular key in the registry.

    Win32->import( qw(CSIDL_LOCAL_APPDATA) );
    $realhome =  Win32::GetFolderPath( CSIDL_LOCAL_APPDATA() );

This approach was suggested to me in August 2005 by several members of
Perlmonks.  (See threads I<Installing a config file during module operation>
(L<http://perlmonks.org/?node_id=481690>) and I<Win32 CSIDL_LOCAL_APPDATA>
(L<http://perlmonks.org/?node_id=485902>).)  I adopted this approach in part
because the people recommending it knew more about Windows than I did, and in
part because File::HomeDir was not quite as mature as it has since become.

But don't trust me; trust Microsoft!  Here's their explanation for the use of
CSIDL values in general and CSIDL_LOCAL_APPDATA() in particular:

=over 4

=item *

I<CSIDL values provide a unique system-independent way
to identify special folders used frequently by
applications, but which may not have the same name or
location on any given system. For example, the system
folder may be ''C:\Windows'' on one system and
''C:\Winnt'' on another. These constants are defined in
Shlobj.h and Shfolder.h.>

=item *

I<CSIDL_LOCAL_APPDATA (0x001c)
Version 5.0. The file system directory that serves as
a data repository for local (nonroaming) applications.
A typical path is C:\Documents and
Settings\username\Local Settings\Application Data.>

=back

(Source:
L<http://msdn.microsoft.com/library/default.asp?url=/library/en-us/shellcc/platform/shell/reference/enums/csidl.asp>.
Link valid as of Feb 18 2006.  Thanks to Soren Andersen for reminding me of
this citation.)

It is interesting that the I<other two> File::HomeDir methods listed above,
C<my_documents()> and C<my_data()> both rely on using a Win32 module to peer
into the registry, albeit in a slightly different manner from
C<File::Save::Home-E<gt>get_home_directory>.  TIMTOWTDI.

In an event, File::Save::Home has a number of useful methods I<besides>
C<get_home_directory()> which merit your consideration.  And, as noted above,
you can supply any valid directory as an optional additional argument to the
two File::Save::Home functions which normally default to calling
C<get_home_directory> internally.

=head2 File::HomeDir::Win32

File::HomeDir::Win32 was originally written by Rob Rothenberg and is now
maintained by Randy Kobes.  According to Adam Kennedy
(L<http://annocpan.org/~JKEENAN/File-Save-Home-0.07/lib/File/Save/Home.pm#note_636>),
''The functionality in File::HomeDir::Win32 is gradually being merged into
File::HomeDir over time and will eventually be deprecated (although left in
place for compatibility purposes).''  Because I have not yet fully installed
File::HomeDir::Win32, I will defer further comparison between it and
File::Save::Home to a later date.

=head1 AUTHOR

	James E Keenan
	CPAN ID: JKEENAN
	jkeenan@cpan.org
	http://search.cpan.org/~jkeenan

=head1 ACKNOWLEDGMENTS

File::Save::Home has its origins in the maintenance revisions I was doing on
CPAN distribution ExtUtils::ModuleMaker in the summer of 2005.
After I made a presentation about that distribution to the Toronto Perlmongers
on October 27, 2005, Michael Graham suggested that certain utility functions
could be extracted to a separate Perl extension for more general applicability.
This module is the implementation of Michael's suggestion.

While I was developing those utility functions for ExtUtils::ModuleMaker, I
turned to the Perlmonks for assistance with the problem of determining a
suitable value for the user's home directory on Win32 systems.  In the
Perlmonks discussion threads referred to above I received helpful suggestions
from monks CountZero, Tanktalus, xdg and holli, among others.

Thanks to Rob Rothenberg for prodding me to expand the SEE ALSO section and to
Adam Kennedy for responding to questions about File::HomeDir.

=head1 COPYRIGHT

Copyright (c) 2005-06 James E. Keenan.  United States.  All rights reserved.

This program is free software; you can redistribute
it and/or modify it under the same terms as Perl itself.

The full text of the license can be found in the
LICENSE file included with this module.

=head1 DISCLAIMER OF WARRANTY

BECAUSE THIS SOFTWARE IS LICENSED FREE OF CHARGE, THERE IS NO WARRANTY
FOR THE SOFTWARE, TO THE EXTENT PERMITTED BY APPLICABLE LAW. EXCEPT WHEN
OTHERWISE STATED IN WRITING THE COPYRIGHT HOLDERS AND/OR OTHER PARTIES
PROVIDE THE SOFTWARE ''AS IS'' WITHOUT WARRANTY OF ANY KIND, EITHER
EXPRESSED OR IMPLIED, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE. THE
ENTIRE RISK AS TO THE QUALITY AND PERFORMANCE OF THE SOFTWARE IS WITH
YOU. SHOULD THE SOFTWARE PROVE DEFECTIVE, YOU ASSUME THE COST OF ALL
NECESSARY SERVICING, REPAIR, OR CORRECTION.

IN NO EVENT UNLESS REQUIRED BY APPLICABLE LAW OR AGREED TO IN WRITING
WILL ANY COPYRIGHT HOLDER, OR ANY OTHER PARTY WHO MAY MODIFY AND/OR
REDISTRIBUTE THE SOFTWARE AS PERMITTED BY THE ABOVE LICENCE, BE
LIABLE TO YOU FOR DAMAGES, INCLUDING ANY GENERAL, SPECIAL, INCIDENTAL,
OR CONSEQUENTIAL DAMAGES ARISING OUT OF THE USE OR INABILITY TO USE
THE SOFTWARE (INCLUDING BUT NOT LIMITED TO LOSS OF DATA OR DATA BEING
RENDERED INACCURATE OR LOSSES SUSTAINED BY YOU OR THIRD PARTIES OR A
FAILURE OF THE SOFTWARE TO OPERATE WITH ANY OTHER SOFTWARE), EVEN IF
SUCH HOLDER OR OTHER PARTY HAS BEEN ADVISED OF THE POSSIBILITY OF
SUCH DAMAGES.

=cut

1;

