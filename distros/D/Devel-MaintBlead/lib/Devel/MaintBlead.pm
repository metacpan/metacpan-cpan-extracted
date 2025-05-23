package Devel::MaintBlead;

# set version information
$VERSION= '0.10';

# make sure we do everything by the book from now on
use strict;
use warnings;

# set up the code for use in "do 'maintblead'"
my $file= 'maintblead';
my $code= <<'CODE';
#-------------------------------------------------------------------------------
# This file was auto-generated by Devel::MaintBlead XXXX on
# YYYY.

# can also be called from Devel::MaintBlead, we need the main:: package
package main;

# mark that we've run this (for testing mostly)
$Devel::MaintBlead::SIZE= SSSSS;

# huh?
if ( !$LIB_TREE or !$REQUIRED ) {
    print STDERR <<'HUH';

Please make sure the global variables $LIB_TREE and $REQUIRED are set before
using the Devel::MaintBlead module in your Makefile.PL.

HUH
    exit 1;
}

# private initializations
my @lib_tree=   split "/", $LIB_TREE;
$lib_tree[$_]= "$lib_tree[ $_ - 1 ]/$lib_tree[$_]" foreach 1 .. $#lib_tree;
my @postfix=    qw( blead maint );
my %maint=      map { $postfix[$_] => $_ } 0 .. $#postfix;
my $auto_maint= ( $] < $REQUIRED ) || 0;

#-------------------------------------------------------------------------------
# set up file moving primitive
use File::Copy ();
sub mv {
    if ( -e $_[1] ) {
        print STDERR <<"HUH";
Cowardly refusing to overwrite

 $_[1]

from

 $_[0]

This should not happen.  Please advise the author of Devel::MaintBlead on
how you managed to do this.  Thank you!
HUH
        exit 1;
    }

    return File::Copy::mv(@_);
} #mv

#-------------------------------------------------------------------------------
# set up file moving logic
#
#  IN: 1 "from" interpolation
#      2 "to" interpolation
#      3 lib_tree setting (default: $LIB_TREE)

sub mv_all {
    my ( $from, $to, $lib_tree )= @_;

    # move generic files
    if ( !$lib_tree ) {
        mv "MANIFEST$from", "MANIFEST$to"
          or die "Could not move file MANIFEST$from -> $to: $!\n";
        foreach ( map { m#/([^/\.]+\.t)$from$# } glob( "t$from/*$from" ) ) {
            mv "t$from/$_$from", "t$to/$_$to"
              or die "Could not move file t$from/$_$from -> $to: $!\n";
        }

        # use the base lib_tree
        $lib_tree= $LIB_TREE;
    }

    # just make sure it exists
    else {
        mkdir "lib$to/$lib_tree";
    }

    # move lib files here
    foreach ( map { m#/([^/\.]+\.pm)$from$# }
              glob( "lib$from/$lib_tree/*$from" ) ) {
        mv "lib$from/$lib_tree/$_$from", "lib$to/$lib_tree/$_$to"
          or die "Could not move file $lib$from/$lib_tree/$_$from -> $to: $!\n";
    }

    # remove now possibly empty subdirectories
    rmdir "lib$from/$lib_tree" if $from;

    # move them there for all subdirs
    mv_all( $from, $to, "$lib_tree/$_" )
      foreach map { m#/([^/]+)$# } grep { -d } glob "lib$from/$lib_tree/*";
} #mv_all

#-------------------------------------------------------------------------------
# unlink_all
#
#  IN: 1 initial directory to remove files from

sub unlink_all {
    my ($dir)= @_;

    # remove all files from this dir (don't care whether worked)
    unlink glob "$dir/*";
    
    # recursively unlink all files in all directories
    unlink_all($_)
      foreach grep { -d } glob "$dir/*";
} #unlink_all

#-------------------------------------------------------------------------------

# first time running Makefile.PL
if ( !-e 'pm_to_blib' ) {

    # set default setting
    $MAINT= !glob( "lib_$postfix[1]/$LIB_TREE/*" ) || 0;
    open( OUT, ">default" );
    print OUT $postfix[$MAINT];
    close OUT;
}

# extract override if there is one
my $type;
@ARGV=
  grep { defined $maint{$_} ? ( $type= $_, $MAINT= $maint{$_}, 0 ) : 1 } @ARGV;

# we have an override
if ($type) {
    print STDERR "Forcing to use the '$type' version of the code\n";
    open( OUT, ">default" );
    print OUT $postfix[$MAINT];
    close OUT;
}

# get default setting if necessary
else {
    open( IN, 'default' );
    $MAINT= $maint{ <IN> };
    close IN;
}

# sorry, we can't help you
if ( $auto_maint and !$MAINT ) {

    # can't do blead, autoselect active, so go to maint
    if ( $ENV{AUTO_SELECT_MAINT_OR_BLEAD} ) {
        $MAINT=1;
    }

    # alas, can't do blead
    else {
        $REQUIRED= sprintf '%1.6f', $REQUIRED;
        print STDERR <<"SORRY";

This distribution requires at least Perl $REQUIRED to be installed.  Since this
is an older distribution, with a history spanning almost a decade, it is also
available inside this distribution as a previous incarnation, which is actively
maintained as well.

You can install that version of this distribution by running this $0
with the additional "maint" parameter, like so:

 $^X $0 maint @ARGV

Or you can provide an automatic selection behavior, which would automatically
select and install the right version of this distribution for the version of
Perl provided, by setting the AUTO_SELECT_MAINT_OR_BLEAD environment variable
to a true value.  On Unix-like systems like so:

 AUTO_SELECT_MAINT_OR_BLEAD=1 $^X $0 @ARGV

Thank you for your attention.

SORRY

        my $line= (caller)[2];
        eval <<"BYEBYE" or print STDERR $@;
#line $line $0
require $REQUIRED;
BYEBYE
        exit 1;
    }
}

# create shortcuts
my $this= $postfix[$MAINT];
my $that= $postfix[ !$MAINT ];

# make sure empty directories exist, 'make dist' doesn't include them
foreach my $postfix (@postfix) {
    mkdir "lib_$postfix";
    mkdir "lib_$postfix/$_" foreach @lib_tree;
    mkdir "t_$postfix";
}

# need to move files into place
if ( my @files= glob( "lib_$this/$LIB_TREE/*" ) ) {
    print STDERR "Moving $this files into position\n";

    # move current files away
    mv_all( '', "_$that" );

    # put files into place
    mv_all( "_$this", '' );

    # make sure we will copy to blib
    unlink_all("blib/lib/$LIB_TREE/*");
}

# right files already there
else {
    print STDERR "Files for $this already in position\n";
}
CODE

# set version info in generated file
{
    no strict;
    $code =~ s#XXXX#$VERSION#s;
    $code =~ s#YYYY# scalar localtime #se;
    $code =~ s#SSSSS# sprintf( '%5d', length $code ) #se;
}

# satisfy -require-
1;

#-------------------------------------------------------------------------------
#
# Standard Perl features
#
#-------------------------------------------------------------------------------
#  IN: 1 class (ignored)

sub import {
    
    # need to adapt code in $0
    if ( !-e $file ) {

        # get running script
        open( IN, $0 )
          or _die("Could not open script for reading '$0': $!");
        my $script= do { local $/; <IN> };
        close IN;

        # update the script
        if ( $script =~
          s#(\s*eval\s*"\s*use\s+Devel::MaintBlead)\s*(["'])#$1; 1$2 or do '$file'#s ) {

            # adapt script
            print STDERR "Installing 'maintblead' code version logic for $0\n";
            open( OUT, ">$0" )
              or _die("Could not open script for writing '$0': $!");
            print OUT $script;
            close OUT
              or _die("Problem flushing '$0': $!");

            # write out check file
            open( OUT, ">$file" )
              or _die("Could not open '$file' for writing: $!");
            print OUT $code;
            close OUT
              or _die("Problem flushing '$file': $!");

            # update the manifest(s)
            foreach my $manifest ( glob( "MANIFEST*" ) ) {
                open( OUT, ">>$manifest" ) or die "Could not open '$manifest': $!";
                print OUT "$file                      maint/blead test (added by Devel::MaintBlead)\n";
                close OUT
                  or _die("Problem flushing '$manifest': $!");
            }

            # cannot continue to execute $0, so we do it from here and then exit
            `$^X $0`;
            exit $? >> 8; # propagate the exit value
        }

        # huh?
        _die( __PACKAGE__ . " could not find code snippet, aborting" );
        exit 1;
    }

    # new version of checking file
    elsif ( -s $file != length $code ) {
        print STDERR "Updating 'maintblead' code version logic\n";
        open( OUT, ">$file" )
          or _die("Could not open '$file' for writing: $!");
        print OUT $code;
        close OUT
          or _die("Problem flushing '$file': $!");
    }

    # do the check
    do $file;
} #import

#-------------------------------------------------------------------------------
#
# Internal subroutines
#
#-------------------------------------------------------------------------------
# _die
#
#  IN: 1 message to die with

sub _die {
    my ($text)= @_;
    chomp($text);

    print STDERR $text, $\;
    exit 1;
} #_die

#-------------------------------------------------------------------------------

__END__

=head1 NAME

Devel::MaintBlead - handle maint / blead code paths for distributions

=head1 VERSION

This documentation describes version 0.10.

=head1 SYNOPSIS

 # before
 our $LIB_TREE= 'Foo/Bar';
 our $REQUIRED= '5.014';
 eval "use Devel::MaintBlead";

 # after
 our $LIB_TREE= 'Foo/Bar';
 our $REQUIRED= '5.014';
 eval "use Devel::MaintBlead; 1" or do 'maintblead';
 # "maintblead" written and added to MANIFEST

=head1 DESCRIPTION

The Devel::MaintBlead module only serves a purpose in the development
environment of an author of a CPAN distribution (or more precisely: a user
of the L<ExtUtils::MakeMaker> module).  It only needs to be installed on the
development environment of an author of a CPAN distribution.

It allows a developer to easily maintain two code paths of the same module(s)
in the same distribution.  Each code path has its own source in the "lib"
directory, its own tests in the "t" directory, and its own MANIFEST.

If the "blead" version of the code is active, a "make dist" will create a
distribution file for the "blead" version.  If the "maint" version of the
code is active, a "make dist" will create a distribution file for the "maint"
version.  It is important that the two code versions have different version
numbers, as PAUSE / CPAN will only accept one upload per version number.

Usually, if both code paths have been updated and ready for CPAN, one will
<first> upload the distribution file for the "maint" version.  And then the
distribution file for the "blead" version.  This will make the most modern
release of your distribution, also the most recent.

=head1 SETUP AND USAGE

Basically, one needs to set up a file structure first, and then make some
changes to the Makefile.PL.

=head2 INITIAL SETUP

By default, the "blead" version is active and its files are:

 lib/**.pm
 t/*.t
 MANIFEST

and the "maint" version of the files are:

 lib_maint/**.pm_maint
 t_main/*.t_maint
 MANIFEST_maint

Please note that '**' here indicates any number of subdirectories.

If the "maint" version is active, then its files are:

 lib/**.pm
 t/*.t
 MANIFEST

and then the "blead" files are:

 lib_blead/**.pm_blead
 t_blead/*.t_blead
 MANIFEST_blead

Note that the inactive files have the type of code path added to their
extension.

If you want to convert your distribution to use this module, you will have
to basically:

=over 4

=item copy all .pm files to lib_maint

In Unix terms:

 $ cp -rp lib lib_maint

=item copy all .t files to t_maint

In Unix terms:

 $ cp -rp t t_maint

=item add "_maint" to all files just copied

In perl terms:

 $ perl -e 'rename $_, "${_}_maint" foreach ( <lib_maint/**>, <t_maint/*> )'

=item add _maint files to MANIFEST

Edit the MANIFEST file to add all of the files you just created, including a
MANIFEST_maint file which you will create after this.

=item copy MANIFEST to MANIFEST_maint, and change _maint to _blead

This is the MANIFEST file that is active if the "maint" version of the code
is active.  In that state, all of the inactive files have "_blead" added to
their file extension.  This is easily achievable by changing all occurrences
of "_maint" to "_blead" in the MANIFEST_maint file.

=item make versions different

The distribution versions of each code path should have a different version.
This is usually the $VERSION of the main source file.  Generally, one would
increase the version number of the "blead" version of the code to the next
major version, e.g. if the code is at "0.20", then the "blead" version should
become "1.00", to really set it apart from the "maint" version.

=back

It is currently considered too dangerous to automate this process.  It might
get automated later at some point in time.

There are basically three situations in which this module can get called.

=head2 INITIAL RUN BY DEVELOPER

If the developer has Devel::MaintBlead installed, and adds the lines:

 our $LIB_TREE= 'Foo/Bar';
 our $REQUIRED= '5.014';
 eval "use Devel::MaintBlead";

to the Makefile.PL, then running the Makefile.PL will create a file called
"maintblead" in the current directory.  This file is intended to be called
with a C<do>.  It contains the code version logic which performs the actual
checks and moves files around if necessary.

The C<$LIB_TREE> variable should contain the path to the directory with the
source files B<without> the C<lib/>.  So for the C<Foo::Bar::Baz module>,
this would be C<Foo/Bar>.

The C<$REQUIRED> variable should contain the minimum version of Perl that
supports the C<blead> version of the code.

The C<$MAINT> variable will be set to B<1> if the C<maint> version of the
code has been selected.  Otherwise the C<$MAINT> variable will be B<0>.
It can be used to further adapt the functioning of your Makefile.PL, e.g.
to be able to set different dependencies in the call to C<WriteMakefile>.

It will also adapt the code in the Makefile.PL itself by changing it to:

 our $LIB_TREE= 'Foo/Bar';
 our $REQUIRED= '5.014';
 eval "use Devel::MaintBlead; 1" or do "maintblead";

Finally, it will adapt all the MANIFEST files by adding the line:

 maintblead                  maint/blead test (Added by Devel::MaintBlead)

This will cause the check file to be included in any distribution made for
that Makefile.PL.

=head2 LATER RUNS BY DEVELOPER

Any subsequent loading of this module, will just execute the "maintblead"
file, do any code path manipulation and not do anything else.

=head2 INSTALLATION BY USER

A user trying to install the distribution, will most likely B<not> have the
Devel::MaintBlead module installed.  This is ok, because then the eval in:

 eval "use Devel::MaintBlead; 1" or do 'maintblead';

will fail, and the "maintblead" file will get executed.  And thus perform
the necessary actions in the user environment.

=head1 REQUIRED MODULES

 (none)

=head1 AUTHOR

Elizabeth Mattijsen, <liz@dijkmat.nl>.

maintained by LNATION, <thisusedtobeanemail@gmail.com>

=head1 COPYRIGHT

Copyright (c) 2012 Elizabeth Mattijsen <liz@dijkmat.nl>. 2025 LNATION <email@lnation.org>  All rights reserved.
This program is free software; you can redistribute it and/or modify it under
the same terms as Perl itself.

=cut
