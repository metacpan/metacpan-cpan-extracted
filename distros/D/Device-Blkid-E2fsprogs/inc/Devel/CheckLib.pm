# $Id: CheckLib.pm,v 1.25 2008/10/27 12:16:23 drhyde Exp $

package Devel::CheckLib;

# use 5.00405;    #postfix foreach
use 5.008000;

use strict;
use vars qw($VERSION @ISA @EXPORT);
$VERSION = '0.92';
use Config qw(%Config);
use Text::ParseWords 'quotewords';

use File::Spec;
use File::Temp;

require Exporter;
@ISA = qw(Exporter);

#@EXPORT =
#  qw(assert_lib check_lib_or_exit check_lib check_blkid_version_or_exit);

our %EXPORT_TAGS = (
    'cflag_defs' => [
        qw(
          API_DEF_133
          API_DEF_136
          API_DEF_138
          API_DEF_140
          )
    ],
    'funcs' => [
        qw/
          assert_lib
          check_lib_or_exit
          check_lib
          check_blkid_version_or_exit
          /
    ],
);
Exporter::export_ok_tags('cflag_defs');
Exporter::export_ok_tags('funcs');

# Used in creating dynamic library build targets
use constant {
    API_DEF_133 => qq/-D__API_1_33/,
    API_DEF_136 => qq/-D__API_1_33 -D__API_1_36/,
    API_DEF_138 => qq/-D__API_1_33 -D__API_1_36 -D__API_1_38/,
    API_DEF_140 => qq/-D__API_1_33 -D__API_1_36 -D__API_1_38 -D__API_1_40/,
};

# localising prevents the warningness leaking out of this module
local $^W = 1;    # use warnings is a 5.6-ism

_findcc();        # bomb out early if there's no compiler

=head1 NAME

Devel::CheckLib - check that a library is available

=head1 DESCRIPTION

Devel::CheckLib is a perl module that checks whether a particular C
library and its headers are available.

=head1 SYNOPSIS

    use Devel::CheckLib;

    check_lib_or_exit( lib => 'jpeg', header => 'jpeglib.h' );
    check_lib_or_exit( lib => [ 'iconv', 'jpeg' ] );
  
    # or prompt for path to library and then do this:
    check_lib_or_exit( lib => 'jpeg', libpath => $additional_path );

=head1 USING IT IN Makefile.PL or Build.PL

If you want to use this from Makefile.PL or Build.PL, do
not simply copy the module into your distribution as this may cause
problems when PAUSE and search.cpan.org index the distro.  Instead, use
the use-devel-checklib script.

=head1 HOW IT WORKS

You pass named parameters to a function, describing to it how to build
and link to the libraries.

It works by trying to compile some code - which defaults to this:

    int main(void) { return 0; }

and linking it to the specified libraries.  If something pops out the end
which looks executable, it gets executed, and if main() returns 0 we know
that it worked.  That tiny program is
built once for each library that you specify, and (without linking) once
for each header file.

If you want to check for the presence of particular functions in a
library, or even that those functions return particular results, then
you can pass your own function body for main() thus:

    check_lib_or_exit(
        function => 'foo();if(libversion() > 5) return 0; else return 1;'
        incpath  => ...
        libpath  => ...
        lib      => ...
        header   => ...
    );

In that case, it will fail to build if either foo() or libversion() don't
exist, and main() will return the wrong value if libversion()'s return
value isn't what you want.

=head1 FUNCTIONS

All of these take the same named parameters and are exported by default.
To avoid exporting them, C<use Devel::CheckLib ()>.

=head2 assert_lib

This takes several named parameters, all of which are optional, and dies
with an error message if any of the libraries listed can
not be found.  B<Note>: dying in a Makefile.PL or Build.PL may provoke
a 'FAIL' report from CPAN Testers' automated smoke testers.  Use 
C<check_lib_or_exit> instead.

The named parameters are:

=over

=item lib

Must be either a string with the name of a single 
library or a reference to an array of strings of library names.  Depending
on the compiler found, library names will be fed to the compiler either as
C<-l> arguments or as C<.lib> file names.  (E.g. C<-ljpeg> or C<jpeg.lib>)

=item libpath

a string or an array of strings
representing additional paths to search for libraries.

=item LIBS

a C<ExtUtils::MakeMaker>-style space-seperated list of
libraries (each preceded by '-l') and directories (preceded by '-L').

This can also be supplied on the command-line.

=back

And libraries are no use without header files, so ...

=over

=item header

Must be either a string with the name of a single 
header file or a reference to an array of strings of header file names.

=item incpath

a string or an array of strings
representing additional paths to search for headers.

=item INC

a C<ExtUtils::MakeMaker>-style space-seperated list of
incpaths, each preceded by '-I'.

This can also be supplied on the command-line.

=back

=head2 check_lib_version_or_exit

This performs the same checks as C<assert_lib>.  In addition, it makes a
get version call against the libblkid library and returns an "integerized"
version representation of the libblkid version which is installed.  Based
upon this, it returns a string to Makefile.PL comprised of the proper
-D define compiler flags required to build and create a targetted build
of L<Device::Blkid::E2fsprogs> to match the current version of the API on
the target system.

If there are any problems with this functionality, please see and edit the
package Makefile.PL by hand.

=head2 check_lib_or_exit

This behaves exactly the same as C<assert_lib()> except that instead of
dieing, it warns (with exactly the same error message) and exits.
This is intended for use in Makefile.PL / Build.PL
when you might want to prompt the user for various paths and
things before checking that what they've told you is sane.

If any library or header is missing, it exits with an exit value of 0 to avoid
causing a CPAN Testers 'FAIL' report.  CPAN Testers should ignore this
result -- which is what you want if an external library dependency is not
available.

=head2 check_lib

This behaves exactly the same as C<assert_lib()> except that it is silent,
returning false instead of dieing, or true otherwise.

=cut

sub check_blkid_version_or_exit {
    eval 'assert_lib(@_)';

    if ( $@ =~ /^200/ ) {
        warn(
            "\tYou currently have a util-linux-ng based version of libblkid installed.\n",
            "\tPlease obtain Device::Blkid from CPAN for your library version.\n\n"
        );
        exit;
    }
    elsif ( $@ =~ /^140/ ) {
        print("\tVersion 1.40 or better of libblkid detected.\n");
        print("\tBuilding module for that version\n\n");
        return API_DEF_140;
    }
    elsif ( $@ =~ /^138/ ) {
        print("\tVersion 1.38 or 1.39 of libblkid detected.\n");
        print("\tBuilding module for those versions\n\n");
        return API_DEF_138;
    }
    elsif ( $@ =~ /^136/ ) {
        print("\tVersion 1.36 or 1.37 of libblkid detected.\n");
        print("\tBuilding module for those versions\n\n");
        return API_DEF_136;
    }
    elsif ( $@ =~ /^133/ ) {
        # Looks like we have a version 1.33-1.35 present, build baseline target
        print("\tlibblkid seems present, but unable to detect its version.\n");
        print("\tBuilding a base v1.33 compliant module by default\n\n");
        return API_DEF_133;
    } else { # default catch, reverts to check_lib_or_exit behavior, library/header not found..
        warn $@;
        exit;
    }
}

sub check_lib_or_exit {
    eval 'assert_lib(@_)';
    if ($@) {
        warn $@;
        exit;
    }
}

sub check_lib {
    eval 'assert_lib(@_)';
    return $@ ? 0 : 1;
}

sub assert_lib {
    my %args = @_;
    my ( @libs, @libpaths, @headers, @incpaths );

    # FIXME: these four just SCREAM "refactor" at me
    @libs = ( ref( $args{lib} ) ? @{ $args{lib} } : $args{lib} )
      if $args{lib};
    @libpaths = ( ref( $args{libpath} ) ? @{ $args{libpath} } : $args{libpath} )
      if $args{libpath};
    @headers = ( ref( $args{header} ) ? @{ $args{header} } : $args{header} )
      if $args{header};
    @incpaths = ( ref( $args{incpath} ) ? @{ $args{incpath} } : $args{incpath} )
      if $args{incpath};

    # work-a-like for Makefile.PL's LIBS and INC arguments
    # if given as command-line argument, append to %args
    for my $arg (@ARGV) {
        for my $mm_attr_key (qw(LIBS INC)) {
            if ( my ($mm_attr_value) = $arg =~ /\A $mm_attr_key = (.*)/x ) {

                # it is tempting to put some \s* into the expression, but the
                # MM command-line parser only accepts LIBS etc. followed by =,
                # so we should not be any more lenient with whitespace than that
                $args{$mm_attr_key} .= " $mm_attr_value";
            }
        }
    }

    # using special form of split to trim whitespace
    if ( defined( $args{LIBS} ) ) {
        foreach my $arg ( split( ' ', $args{LIBS} ) ) {
            die("LIBS argument badly-formed: $arg\n") unless ( $arg =~ /^-l/i );
            push @{ $arg =~ /^-l/ ? \@libs : \@libpaths }, substr( $arg, 2 );
        }
    }
    if ( defined( $args{INC} ) ) {
        foreach my $arg ( split( ' ', $args{INC} ) ) {
            die("INC argument badly-formed: $arg\n") unless ( $arg =~ /^-I/ );
            push @incpaths, substr( $arg, 2 );
        }
    }

    my @cc = _findcc();
    my @missing;
    my @wrongresult;
    my @use_headers;

    my @blkid_version;

    # first figure out which headers we can't find ...
    for my $header (@headers) {
        push @use_headers, $header;
        my ( $ch, $cfile ) =
          File::Temp::tempfile( 'assertlibXXXXXXXX', SUFFIX => '.c' );
        print $ch qq{#include <$_>\n} for @use_headers;
        print $ch qq{int main(void) { return 0; }\n};
        close($ch);
        my $exefile = File::Temp::mktemp('assertlibXXXXXXXX') . $Config{_exe};
        my @sys_cmd;

        # FIXME: re-factor - almost identical code later when linking
        if ( $Config{cc} eq 'cl' ) {    # Microsoft compiler
            require Win32;
            @sys_cmd = (
                @cc, $cfile, "/Fe$exefile",
                ( map { '/I' . Win32::GetShortPathName($_) } @incpaths )
            );
        }
        elsif ( $Config{cc} =~ /bcc32(\.exe)?/ ) {    # Borland
            @sys_cmd =
              ( @cc, ( map { "-I$_" } @incpaths ), "-o$exefile", $cfile );
        }
        else {    # Unix-ish: gcc, Sun, AIX (gcc, cc), ...
            @sys_cmd =
              ( @cc, $cfile, ( map { "-I$_" } @incpaths ), "-o", "$exefile" );
        }
        warn "# @sys_cmd\n" if $args{debug};
        my $rv = $args{debug} ? system(@sys_cmd) : _quiet_system(@sys_cmd);
        push @missing, $header if $rv != 0 || !-x $exefile;
        _cleanup_exe($exefile);
        unlink $cfile;
    }

    # now do each library in turn with headers
    my ( $ch, $cfile ) =
      File::Temp::tempfile( 'assertlibXXXXXXXX', SUFFIX => '.c' );
    print $ch qq{#include <$_>\n} foreach (@headers);
    print $ch "int main(void) { " . ( $args{function} || 'return 0;' ) . " }\n";
    close($ch);
    for my $lib (@libs) {
        my $exefile = File::Temp::mktemp('assertlibXXXXXXXX') . $Config{_exe};
        my @sys_cmd;
        if ( $Config{cc} eq 'cl' ) {    # Microsoft compiler
            require Win32;
            my @libpath =
              map { q{/libpath:} . Win32::GetShortPathName($_) } @libpaths;

            # this is horribly sensitive to the order of arguments
            @sys_cmd = (
                @cc,
                $cfile,
                "${lib}.lib",
                "/Fe$exefile",
                ( map { '/I' . Win32::GetShortPathName($_) } @incpaths ),
                "/link",
                ( map { '/libpath:' . Win32::GetShortPathName($_) } @libpaths ),
            );
        }
        elsif ( $Config{cc} eq 'CC/DECC' ) {    # VMS
        }
        elsif ( $Config{cc} =~ /bcc32(\.exe)?/ ) {    # Borland
            @sys_cmd = (
                @cc, "-o$exefile", "-l$lib",
                ( map { "-I$_" } @incpaths ),
                ( map { "-L$_" } @libpaths ), $cfile
            );
        }
        else {                                        # Unix-ish
                                                      # gcc, Sun, AIX (gcc, cc)
            @sys_cmd = (
                @cc, $cfile, "-o", "$exefile", "-l$lib",
                ( map { "-I$_" } @incpaths ),
                ( map { "-L$_" } @libpaths )
            );
        }
        warn "# @sys_cmd\n" if $args{debug};

        # Grab output from linking
        my $rv = $args{debug} ? system(@sys_cmd) : _quiet_system(@sys_cmd);

        push @missing, $lib if $rv != 0 || !-x $exefile;

        ######################################################
        # If the 'blkid' argument flag is set, bypass original
        # function behavior here and do custom version checks
        # otherwise revert to default
        if ( $args{blkid} ) {
            # libblkid present and we are getting a good return, use it
            push @blkid_version, ( $? >> 8 )    # shift 8 for child's return
              if ( $rv == 0
                && -x $exefile
                && system( File::Spec->rel2abs($exefile) ) > 0 );
            # libblkid present but we can't link; missing version calls so build v1.33 base
            push @blkid_version, ( '133' )  #  baseline
              if ( $rv == 0
                && -x $exefile
                && system( File::Spec->rel2abs($exefile) ) == -1 );
        }
        else {
            push @wrongresult, $lib
              if $rv == 0
                  && -x $exefile
                  && system( File::Spec->rel2abs($exefile) ) != 0;
        }

        if ( $args{debug} && $args{blkid} ) {
            printf( "Libblkid version call return value is %d\n", $? >> 8 );
        }

        _cleanup_exe($exefile);
    }
    unlink $cfile;

    # Basic lib sanity checks, is header and library present?
    my $miss_string = join( q{, }, map { qq{'$_'} } @missing );
    die("Can't link/include $miss_string\n") if @missing;

    ######################################################
    # If the 'blkid' argument flag is set, bypass original
    # function behavior here and do custom version checks
    # otherwise revert to default basic lib check
    if ( $args{blkid} ) {
        # Throw the returned version identifier up
        my $blkid_version = shift @blkid_version;
        die($blkid_version) if ( $blkid_version != 0 );
    }
    else {
        my $wrong_string = join( q{, }, map { qq{'$_'} } @wrongresult );
        die("wrong result: $wrong_string\n") if @wrongresult;
    }
}

sub _cleanup_exe {
    my ($exefile) = @_;
    my $ofile = $exefile;
    $ofile =~ s/$Config{_exe}$/$Config{_o}/;
    unlink $exefile             if -f $exefile;
    unlink $ofile               if -f $ofile;
    unlink "$exefile\.manifest" if -f "$exefile\.manifest";
    return;
}

sub _findcc {

    # Need to use $keep=1 to work with MSWin32 backslashes and quotes
    my @Config_ccflags_ldflags =
      @Config{qw(ccflags ldflags)};    # use copy so ASPerl will compile
    my @flags =
      grep { length }
      map { quotewords( '\s+', 1, $_ || () ) } @Config_ccflags_ldflags;
    my @paths = split( /$Config{path_sep}/, $ENV{PATH} );
    my @cc = split( /\s+/, $Config{cc} );
    return ( @cc, @flags ) if -x $cc[0];
    foreach my $path (@paths) {
        my $compiler = File::Spec->catfile( $path, $cc[0] ) . $Config{_exe};
        return ( $compiler, @cc[ 1 .. $#cc ], @flags ) if -x $compiler;
    }
    die("Couldn't find your C compiler\n");
}

# code substantially borrowed from IPC::Run3
sub _quiet_system {
    my (@cmd) = @_;

    # save handles
    local *STDOUT_SAVE;
    local *STDERR_SAVE;
    open STDOUT_SAVE, ">&STDOUT" or die "CheckLib: $! saving STDOUT";
    open STDERR_SAVE, ">&STDERR" or die "CheckLib: $! saving STDERR";

    # redirect to nowhere
    local *DEV_NULL;
    open DEV_NULL, ">" . File::Spec->devnull
      or die "CheckLib: $! opening handle to null device";
    open STDOUT, ">&" . fileno DEV_NULL
      or die "CheckLib: $! redirecting STDOUT to null handle";
    open STDERR, ">&" . fileno DEV_NULL
      or die "CheckLib: $! redirecting STDERR to null handle";

    # run system command
    my $rv = system(@cmd);

    # restore handles
    open STDOUT, ">&" . fileno STDOUT_SAVE
      or die "CheckLib: $! restoring STDOUT handle";
    open STDERR, ">&" . fileno STDERR_SAVE
      or die "CheckLib: $! restoring STDERR handle";

    return $rv;
}

=head1 PLATFORMS SUPPORTED

You must have a C compiler installed.  We check for C<$Config{cc}>,
both literally as it is in Config.pm and also in the $PATH.

It has been tested with varying degrees on rigourousness on:

=over

=item gcc (on Linux, *BSD, Mac OS X, Solaris, Cygwin)

=item Sun's compiler tools on Solaris

=item IBM's tools on AIX

=item SGI's tools on Irix 6.5

=item Microsoft's tools on Windows

=item MinGW on Windows (with Strawberry Perl)

=item Borland's tools on Windows

=item QNX

=back

=head1 WARNINGS, BUGS and FEEDBACK

This is a very early release intended primarily for feedback from
people who have discussed it.  The interface may change and it has
not been adequately tested.

Feedback is most welcome, including constructive criticism.
Bug reports should be made using L<http://rt.cpan.org/> or by email.

When submitting a bug report, please include the output from running:

    perl -V
    perl -MDevel::CheckLib -e0

=head1 SEE ALSO

L<Devel::CheckOS>

L<Probe::Perl>

=head1 AUTHORS

David Cantrell E<lt>david@cantrell.org.ukE<gt>

David Golden E<lt>dagolden@cpan.orgE<gt>

Yasuhiro Matsumoto E<lt>mattn@cpan.orgE<gt>

Thanks to the cpan-testers-discuss mailing list for prompting us to write it
in the first place;

to Chris Williams for help with Borland support;

to Tony Cook for help with Microsoft compiler command-line options

=head1 COPYRIGHT and LICENCE

Copyright 2007 David Cantrell. Portions copyright 2007 David Golden.

This module is free-as-in-speech software, and may be used, distributed,
and modified under the same conditions as perl itself.

=head1 CONSPIRACY

This module is also free-as-in-mason software.

=cut

1;
