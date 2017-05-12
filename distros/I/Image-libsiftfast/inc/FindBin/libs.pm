#line 1
########################################################################
# FindBin::libs
#
# use $FindBin::Bin to search for 'lib' directories and use them.
#
# default action is to look for dir's named "lib" and silently use
# the lib's without exporting anything. print turns on a short 
# message with the abs_path results, export pushes out a variable
# (default name is the base value), verbose turns on decision output
# and print. export takes an optional argument with the name of a
# variable to export.
#
# Copyright (C) 2003, Steven Lembark, Workhorse Computing.
# This code is released under the same terms as Perl-5.6.1
# or any later version of Perl.
# 
########################################################################

########################################################################
# housekeeping
########################################################################

package FindBin::libs;

use 5.00601;

use strict;

use Carp qw( &croak );

use FindBin;

use Symbol;

# both of these are in the standard distro and 
# should be available.

use File::Basename;

use File::Spec::Functions
qw
(
    &splitpath
    &splitdir
    &catpath
    &catdir
);

BEGIN
{
    # however... there have been complaints of 
    # places where abs_path does not work. 
    #
    # if abs_path fails on the working directory
    # then replace it with rel2abs and live with 
    # possibly slower, redundant directories.
    #
    # the abs_path '//' hack allows for testing 
    # broken abs_path on primitive systems that
    # cannot handle the rooted system being linked
    # back to itself.

    use Cwd qw( &abs_path &cwd );

    unless( eval {abs_path '//';  abs_path cwd } )
    {
        # abs_path seems to be having problems,
        # fix is to stub it out. ref and sub are
        # syntatic sugar, but do you really want
        # to see it all on one line???
        #
        # undef avoids re-defining subroutine nastygram.

        my $ref = qualify_to_ref 'abs_path', __PACKAGE__;

        my $sub = File::Spec::Functions->can( 'rel2abs' );

        undef &{ $ref };

        *$ref = $sub
    };
}

########################################################################
# package variables 
########################################################################

our $VERSION = '1.40';

my %defaultz = 
(
    Bin     => $FindBin::Bin,
    base    => 'lib',
    use     => 1,

    subdir  => '',      # add this subdir also if found.
    subonly => undef,   # leave out lib's, use only subdir.
    export  => undef,   # push variable into caller's space.
    verbose => undef,   # boolean: print inputs, results.
    debug   => undef,   # boolean: set internal breakpoints.

    print   => undef,   # display the results

    p5lib   => undef,   # prefix PERL5LIB with the results

    ignore => '/,/usr', # dir's to skip looking for ./lib
);

# only new directories are used, ignore pre-loads
# this with unwanted values.

my %found = ();

# saves passing this between import and $handle_args.

my %argz = ();

my $verbose = '';

my $empty = q{};

########################################################################
# subroutines
########################################################################

# HAK ALERT: $Bin is an absolute path, there are cases
# where splitdir does not add the leading '' onto the
# directory path for it on VMS. Fix is to unshift a leading
# '' into @dirpath where the leading entry is true.

sub find_libs
{
    my $base    = basename ( shift || $argz{ base } );

    my $subdir  = $argz{ subdir } || '';

    my $subonly = defined $argz{ subonly };

    # for some reason, RH Enterprise V/4 has a 
    # trailing '/'; I havn't seen another copy of 
    # FindBin that does this. fix is quick enough: 
    # strip the trailing '/'.
    #
    # using a regex to extract the value untaints it.
    # after that split path can grab the directory 
    # portion for future use.

    my ( $Bin ) = $argz{ Bin } =~ m{^ (.+) }xs;

    print STDERR "\nSearching $Bin for '$base'...\n"
        if $verbose;

    my( $vol, $dir ) = splitpath $Bin, 1;

    my @dirpath = splitdir $dir;

    # fix for File::Spec::VMS missing the leading empty
    # string on a split. this can be removed once File::Spec
    # is fixed.

    unshift @dirpath, '' if $dirpath[ 0 ];

    my @libz    = ();

    for( 1 .. @dirpath )
    {
        # note that catpath is extraneous on *NIX; the 
        # volume only means something on DOS- & VMS-based
        # filesystems, and adding an empty basename on 
        # *nix is unnecessary.
        #
        # HAK ALERT: the poor slobs stuck on windog have an
        # abs_path that croaks on missing directories. have
        # to eval the check for subdir's. 

        my $abs
        = eval { abs_path catpath $vol, ( catdir @dirpath, $base ), $empty }
        || '';

        my $sub
        = $subdir
        ? eval { abs_path ( catpath '', $abs, $subdir ) } || ''
        : ''
        ;

        my @search = $subonly ? ( $sub ) : ( $abs, $sub );

        for my $dir ( @search )
        {
            if( $dir && -d $dir && ! exists $found{ $dir } )
            {
                $found{ $dir } = 1;

                push @libz, $dir;
            }
        }

        pop @dirpath
    }

    # caller gets back the existing lib paths 
    # (including volume) walking up the path 
    # from $FindBin::Bin -> root.
    #
    # passing it back as a list isn't all that
    # painful for a few paths.

    wantarray ? @libz : \@libz
};

# break out the messy part into a separate block.

my $handle_args 
= sub
{
    # discard the module, rest are arguments.

    shift;

    # anything after the module are options with arguments
    # assigned via '='.

    %argz
    = map
    {
        my ( $k, $v ) = split '=', $_, 2;

        if( $k =~ s{^(?:!|no)}{} )
        {
            $k => undef
        }
        else
        {
            $k => ( $v || '' )
        }
    }
    @_;

    # stuff "debug=1" into your arguments and perl -d will stop here.

    $DB::single = 1 if $argz{debug};

    # use lib behavior is turned off by default if export or
    # perl5lib udpate are requested.

    exists $argz{use} or $defaultz{use} = ! exists $argz{export};
    exists $argz{use} or $defaultz{use} = ! exists $argz{p5lib};

    # now apply the defaults, then sanity check the result.
    # base is a special case since it always has to exist.
    #
    # if $argz{export} is defined but false then it takes
    # its default from $argz{base}.

    exists $argz{$_} or $argz{$_} = $defaultz{$_}
    for keys %defaultz;

    exists $argz{base} && $argz{base} 
    or croak "Bogus FindBin::libs: missing/false base argument, should be 'base=NAME'";

    defined $argz{export} and $argz{export} ||= $argz{base};

    $argz{ ignore } =
    [
        grep { $_ }
        split /\s*,\s*/,
        $argz{ignore}
    ];

    $verbose = defined $argz{verbose};

    my $base = $argz{base};

    # now locate the libraries.
    #
    # %found contains the abs_path results for each directory to 
    # avoid double-including directories.
    #
    # note: loop short-curcuts for the (usually) list.

    %found = ();

    for( @{ $argz{ ignore } } )
    {
      if( my $dir = eval { abs_path catdir $_, $base } )
      {
        if( -d $dir )
        {
          $found{ $dir } = 1;
        }
      }
    }
};

sub import
{
    &$handle_args;

    my @libz = find_libs;

    # HAK ALERT: the regex does nothing for security,
    # just dodges -T. putting this down here instead
    # of inside find_libs allows people to use saner
    # untainting plans via find_libs.

    @libz   = map { m{ (.+) }x } @libz;

    my $caller = caller;

    if( $verbose || defined $argz{print} )
    {
        local $\ = "\n";
        local $, = "\n\t";

        print STDERR "Found */$argz{ base }:", @libz
    }

    if( $argz{export} )
    {
        my $caller = caller;

        print STDERR join '', "\nExporting: @", $caller, '::', $argz{export}, "\n"
        if $verbose;

        # Symbol this is cleaner than "no strict" 
        # for installing the array.

        my $ref = qualify_to_ref $argz{ export }, $caller;

        *$ref = \@libz;
    }

    if( defined $argz{ p5lib } )
    {
        # stuff the lib's found at the front of $ENV{ PERL5LIB }

        ( substr $ENV{ PERL5LIB }, 0, 0 ) = join ':', @libz, ''
        if @libz;

        print STDERR "\nUpdated PERL5LIB:\t$ENV{ PERL5LIB }\n"
        if $verbose;
    }

    if( $argz{use} && @libz )
    {
        # this obviously won't work if lib ever depends 
        # on the caller's package.
        #
        # it does avoids issues with -T blowing up on the
        # old eval technique.

        require lib;

        lib->import( @libz );
    }

    0
}

# keep require happy

1

__END__

