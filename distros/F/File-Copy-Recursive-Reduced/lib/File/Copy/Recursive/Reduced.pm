package File::Copy::Recursive::Reduced;
use strict;
use warnings;

use parent qw( Exporter );
our @EXPORT_OK = qw( dircopy fcopy );
our $VERSION = '0.003';

use File::Copy;
use File::Find;
use File::Path qw( mkpath );
use File::Spec;

our $Link       = eval { local $SIG{'__DIE__'}; link    '', ''; 1 } || 0;
our $CopyLink   = eval { local $SIG{'__DIE__'}; symlink '', ''; 1 } || 0;
our $DirPerms   = 0777;


=head1 NAME

File::Copy::Recursive::Reduced - Recursive copying of files and directories within Perl 5 toolchain

=head1 SYNOPSIS

    use File::Copy::Recursive::Reduced qw(fcopy dircopy);

    fcopy($orig,$new) or die $!;

    dircopy($orig,$new) or die $!;

=head1 DESCRIPTION

This library is intended as a not-quite-drop-in replacement for certain
functionality provided by L<CPAN distribution
File-Copy-Recursive|http://search.cpan.org/dist/File-Copy-Recursive/>.  The
library provides methods similar enough to that distribution's C<fcopy()> and
C<dircopy()> functions to be usable in those CPAN distributions often
described as being part of the Perl toolchain.

=head2 Rationale

F<File::Copy::Recursive> (hereinafter referred to as B<FCR>) is heavily used
in other CPAN libraries.  Out of over 30,000 other CPAN distributions studied
in early 2018, it ranks in one calculation as the 129th highest distribution
in terms of its total direct and indirect reverse dependencies.  In current
parlance, it sits C<high upstream on the CPAN river.> Hence, it ought to work
correctly and be installable on all operating systems where Perl is well
supported.

However, as of the time of creation of F<File::Copy::Recursive::Reduced>
(April 2018), FCR version 0.40 is failing to pass its tests against either
Perl 5.26 or Perl 5 blead on important operating systems including Windows,
FreeBSD and NetBSD
(L<http://fast-matrix.cpantesters.org/?dist=File-Copy-Recursive%200.40>).  As
a consequence, CPAN installers such as F<cpan> and F<cpanm> will not install
it without use of the C<--force> option.  This will prevent distributions
dependent on FCR from being installed as well.  Some patches have been
provided to the
L<FCR bug tracker|https://rt.cpan.org/Dist/Display.html?Name=File-Copy-Recursive> for
this problem but as of the date on which this distribution is being uploaded
to CPAN, FCR's author has not yet applied them.  However, even if those
patches are applied, FCR may face other installability problems on certain platforms.

F<File::Copy::Recursive::Reduced> (hereinafter referred to as B<FCR2>) is
intended to provide an almost minimal subset of FCR's functionality
-- just enough to get the Perl toolchain working on the platforms where FCR is
currently failing.  Functions will be added to FCR2 only insofar as
investigation shows that they can replace usage of FCR functions in toolchain
and other heavily used modules.  No attempt will be made to reproduce all the
functionality currently provided or claimed to be provided by FCR.

=head1 SUBROUTINES

The current version of FCR2 provides two exportable and publicly supported
subroutines partially equivalent to the similarly named subroutines exported
by FCR.

=head2 C<fcopy()>

=over 4

=item * Purpose

A stripped-down replacement for C<File::Copy::Recursive::fcopy()>.

Copies a file to a new location, recursively creating directories as needed.
Does not copy directories.  Unlike C<File::Copy::copy()>, C<fcopy()> attempts
to preserve the mode of the original file.

=item * Arguments

    fcopy($orig, $new) or die $!;

List of two required arguments:

=over 4

=item * Absolute path to the file being copied; and

=item * Absolute path to the location to which the file is being copied.

=back

Four cases should be noted:

=over 4

=item 1 Create copy within same directory but new basename

    fcopy('/path/to/filename', '/path/to/newfile');

The second argument must be the absolute path to the new file.  (Otherwise
the file will be created in the current working directory, which is almost
certainly what you do not want.)

=item 2 Create copy within different, already B<existing> directory, same basename

    fcopy('/path/to/filename', '/path/to/existing/directory');

The second argument can be merely the path to the existing directory; will
create F</path/to/existing/directory/filename>.

=item 3 Create copy within different, not yet existing directory, same basename

    fcopy('/path/to/filename', '/path/not/yet/existing/directory/filename');

The second argument will be interpreted as the complete path to the newly
created file.  The basename must be included even if it is the same as in the
first argument.  Will create F</path/not/yet/existing/directory/filename>.

=item 4 Create copy within different, not yet existing directory, different basename

    fcopy('/path/to/filename', '/path/not/yet/existing/directory/newfile');

The second argument will be interpreted as the complete path to the newly
created file.  Will create F</path/not/yet/existing/directory/newfile>.

=back

=item * Return Value

Returns C<1> upon success; C<0> upon failure.  Returns an undefined value if,
for example, function cannot validate arguments.

=item * Comment

Since C<fcopy()> internally uses C<File::Copy::copy()> to perform the copying,
the arguments are subject to the same qualifications as that function's
arguments.  Call F<perldoc File::Copy> for discussion of those arguments.

=item * Restrictions

=over 4

=item *

Does not currently handle copying of symlinks, though it may do so in a future
version.

=back

=back

=cut

sub fcopy {
    return if @_ != 2;
    my ($from, $to) = @_;
    return unless _samecheck($from, $to);
    my ( $volm, $path ) = File::Spec->splitpath($to);

    # TODO: Explore whether it's possible for $path to be Perl-false in
    # following line.  If not, remove.
    if ( $path && !-d $path ) {
        pathmk(File::Spec->catpath($volm, $path, ''));
    }
    if (-l $from) { return; }
    elsif (-d $from && -f $to) { return; }
    else {
        copy($from, $to) or return;

        my @base_file = File::Spec->splitpath( $from );
        my $mode_trg = -d $to ? File::Spec->catfile( $to, $base_file[$#base_file] ) : $to;

        chmod scalar((stat($from))[2]), $mode_trg;
    }
    return 1;
}

sub pathmk {
    my ( $vol, $dir, $file ) = File::Spec->splitpath( shift() );

    # TODO: Exploration whether $dir can be undef at this point.
    # If possible, then we should probably return immediately.
    if ( defined($dir) ) {
        my (@dirs) = File::Spec->splitdir($dir);

        for ( my $i = 0; $i < scalar(@dirs); $i++ ) {
            my $newdir = File::Spec->catdir( @dirs[ 0 .. $i ] );
            my $newpth = File::Spec->catpath( $vol, $newdir, "" );
            mkdir( $newpth );
            return unless -d $newpth;
        }
    }

    # TODO: Exploration whether $file can be undef at this point.
    # If possible, then we should probably return immediately.
    if ( defined($file) ) {
        my $newpth = File::Spec->catpath( $vol, $dir, $file );
        mkdir( $newpth );
        return unless -d $newpth;
    }

    return 1;
}


=head2 C<dircopy()>

=over 4

=item * Purpose

A stripped-down replacement for C<File::Copy::Recursive::dircopy()>.

Given the path to the directory specified by the first argument, the function
copies all of the files and directories beneath it to the directory specified
by the second argument.

=item * Arguments

    my $count = dircopy($orig, $new);
    warn "dircopy() returned undefined value" unless defined $count;

=item * Return Value

Upon completion, returns the count of directories and files created -- which
might be C<0>.

Should the function not complete (but not C<die>), an undefined value will be
returned.  That generally indicates problems with argument validation.  This
approach is taken for consistency with C<File::Copy::Recursive::dircopy()>.

=item * Restrictions

None of C<File::Copy::Recursive::dircopy>'s bells and whistles.  No provision
for special handling of symlinks.  No preservation of file or directory modes.
No restriction on maximum depth.  No nothing; this is fine-tuned to the needs
of Perl toolchain modules and their test suites.

=back

=cut

sub dircopy {

    # I'm not supporting the buffer limitation, at this point I can insert a
    # Check for the correct number of arguments:  2
    # FCR2 dircopy does not support buffer limit as third argument

    return unless @_ == 2;

    # Check the definedness and string inequality of the arguments now;
    # Failure to do it now means that if $_[0] is not defined, you'll get an
    # uninitalized value warning in the first line that calls 'substr' below.

    return unless _basic_samecheck(@_);

    # See local file globstar-investigation.pl
    # What the block above does is to trim the 'from' argument so that, if user
    # said 'dircopy(/path/to/directory/*, /path/to/copy)', the first argument
    # is effectively reduced to '/path/to/directory/' but inside $globstar is
    # set to true.  Have to see what impact of $globstar true is.

    my $globstar = 0;
    my $_zero    = $_[0];
    my $_one     = $_[1];
    if ( substr( $_zero, ( 1 * -1 ), 1 ) eq '*' ) {
        $globstar = 1;
        $_zero = substr( $_zero, 0, ( length($_zero) - 1 ) );
    }

    # Note also that, in the above, $_[0] and $_[1], while assigned to
    # variables, are not shifted-in.  Hence they retain their original values.
    # TODO: Investigate whether replacing $_[1] from this point forward with a
    # 'my' variable would be harmful.

    # Both arguments must now be defined (though not necessarily true -- yet);
    # they can't be equal; they can't be "dev-ino" equal on non-Win32 systems.
    # Verify that.

    return unless _dev_ino_check( $_zero, $_[1] );

    if ( !-d $_zero || ( -e $_[1] && !-d $_[1] ) ) {
        $! = 20;
        return;
    }

    # If the second argument is not an already existing directory,
    # then, create that directory now (the top-level 'to').

    if ( !-d $_[1] ) {
        pathmk( $_[1] ) or return;
    }
    # If the second argument is an existing directory ...
    # ... $globstar false is the typical case, i.e., no '/*' at end of 2nd argument

    my $baseend = $_one;
    my $level   = 0;
    my $filen   = 0;
    my $dirn    = 0;

    my $recurs;    #must be my()ed before sub {} since it calls itself
    $recurs = sub {
        my ( $str, $end ) = @_;
        $filen++ if $end eq $baseend;
        $dirn++  if $end eq $baseend;

        # On each pass of the recursive coderef, create the directory in the
        # 2nd argument or return (undef) if that does not succeed

        mkdir( $end ) or return if !-d $end;
        $level++;

        opendir( my $str_dh, $str ) or return;
        my @entities = grep( $_ ne '.' && $_ ne '..', readdir($str_dh) );
        closedir $str_dh;

        for my $entity (@entities) {
            my ($entity_ut) = $entity =~ m{ (.*) }xms;
            my $org = File::Spec->catfile( $str, $entity_ut );
            my $new = File::Spec->catfile( $end, $entity_ut );
#            if ( -l $org && $CopyLink ) {
#                my $target = readlink($org);
#                ($target) = $target =~ m/(.*)/;    # mass-untaint is OK since we have to allow what the file system does
#                carp "Copying a symlink ($org) whose target does not exist"
#                  if !-e $target && $BdTrgWrn;
#                unlink $new if -l $new;
#                symlink( $target, $new ) or return;
#            }
#            elsif ( -d $org ) {
            if ( -d $org ) {
                my $rc;
#                if ( !-w $org && $KeepMode ) {
#                    local $KeepMode = 0;
#                    carp "Copying readonly directory ($org); mode of its contents may not be preserved.";
##                    $rc = $recurs->( $org, $new ) if !defined $buf;
#                    $rc = $recurs->( $org, $new );
#                    chmod scalar( ( stat($org) )[2] ), $new;
#                }
#                else {
##                    $rc = $recurs->( $org, $new ) if !defined $buf;
                    $rc = $recurs->( $org, $new );
#                }
                return unless $rc;
                $filen++;
                $dirn++;
            }
            else {
                fcopy( $org, $new ) or return;
#                chmod scalar( ( stat($org) )[2] ), $new if $KeepMode;
                $filen++;
            }
        } # End 'for' loop around @entities
        $level--;
#        chmod scalar( ( stat($str) )[2] ), $end if $KeepMode;
        1;

    }; # END definition of $recurs

    $recurs->( $_zero, $_one ) or return;
#    return wantarray ? ( $filen, $dirn, $level ) : $filen;
    return $filen;
}

sub _basic_samecheck {
    my ($from, $to) = @_;
    return if !defined $from || !defined $to;
    return if $from eq $to;
    return 1;
}

sub _dev_ino_check {
    my ($from, $to) = @_;
    return 1 if $^O eq 'MSWin32';

    # perldoc perlport: "(Win32) "dev" and "ino" are not meaningful."
    # Will probably have to add restrictions for VMS and other OSes.
    my $one = join( '-', ( stat $from )[ 0, 1 ] ) || '';
    my $two = join( '-', ( stat $to   )[ 0, 1 ] ) || '';
    if ( $one and $one eq $two ) {
        warn "$from and $to are identical";
        return;
    }
    return 1;
}

sub _samecheck {
    # Adapted from File::Copy::Recursive
    my ($from, $to) = @_;
    #return if !defined $from || !defined $to;
    #return if $from eq $to;
    return unless _basic_samecheck($from, $to);

    # TODO:  Explore whether we should check (-e $from) here.
    # If we don't have a starting point, it shouldn't make any sense to go
    # farther.

#    if ($^O ne 'MSWin32') {
#        # perldoc perlport: "(Win32) "dev" and "ino" are not meaningful."
#        # Will probably have to add restrictions for VMS and other OSes.
#        my $one = join( '-', ( stat $from )[ 0, 1 ] ) || '';
#        my $two = join( '-', ( stat $to   )[ 0, 1 ] ) || '';
#        if ( $one and $one eq $two ) {
#            warn "$from and $to are identical";
#            return;
#        }
#    }
    return unless _dev_ino_check($from, $to);
    return 1;
}

=head2 File::Copy::Recursive Subroutines Not Supported in File::Copy::Recursive::Reduced

As of the current version, FCR2 has no publicly documented, exportable subroutines equivalent
to the following FCR exportable subroutines:

    rcopy
    rcopy_glob
    fmove
    rmove
    rmove_glob
    dirmove
    pathempty
    pathrm
    pathrmdir

Consideration is being given to supporting C<rcopy()>.

=head1 BUGS AND SUPPORT

Please report any bugs by mail to C<bug-File-Copy-Recursive-Reduced@rt.cpan.org>
or through the web interface at L<http://rt.cpan.org>.

=head1 ACKNOWLEDGEMENTS

Notwithstanding the fact that this distribution is being released to address
certain problems in File-Copy-Recursive, credit must be given to FCR author
L<Daniel Muey|http://www.cpan.org/authors/id/D/DM/DMUEY/> for ingenious
conception and execution.  The implementation of the subroutines provided by
FCR2 follows that found in FCR to a significant extent.

Thanks also to Tom Hukins for supplying the patch which corrects FCR's
problems and which has been incorporated into FCR2 as well.

=head1 AUTHOR

    James E Keenan
    CPAN ID: JKEENAN
    jkeenan@cpan.org
    http://thenceforward.net/perl

=head1 COPYRIGHT

This program is free software; you can redistribute
it and/or modify it under the same terms as Perl itself.

The full text of the license can be found in the
LICENSE file included with this module.

Copyright James E Keenan 2018.  All rights reserved.

=head1 SEE ALSO

perl(1). File::Copy::Recursive(3).

=cut

1;

__END__

