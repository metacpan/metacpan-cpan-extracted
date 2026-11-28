########################################################################
# housekeeping
########################################################################

package FindBin::libs   v5.1.0;
use v5.40;

use File::Basename;

use Carp        qw( carp croak              );
use List::Util  qw( uniq first              );
use Symbol      qw( qualify qualify_to_ref  );

use File::Spec::Functions
qw
(
    splitpath
    splitdir
    catpath
    catdir
    rel2abs
);

use FindBin::Bin        qw( $Bin_l $Bin_p   );
use FindBin::Parents    qw( dir_paths       );

use File::Util::SecureDir;

########################################################################
# package variables
########################################################################

my %defaultz =
(
    # note the lack of 'exports' due to post-assignment
    # via base after defaults are assigned.

    base    => 'lib'
  , use     => 1
  , subdir  => ''       # add this subdir also if found.
  , abspath => 1        # default to old behavior
  , fail    => 1        # carp on empty results by default

  , ignore  => q{/,/usr} # skip /lib and /usr/lib: entries are
                          # absolute dirs whose ./BASE is skipped.
);

my %allow_undef = map { $_ => 1 }
qw
(
    ignore
    export
);

########################################################################
# utility subs
########################################################################

# HAK ALERT: on VMS splitdir does not return the leading ''
# for an absolute path, and on *NIX and MSW it returns
# ( '', '' ) for the root.  FindBin::Parents::dir_paths handles
# both, so the directories passed here are complete absolute
# paths: this only appends to them.

my $append_dir
= sub
{
    my $dir             = shift;
    my ( $vol, $dirs )  = splitpath $dir, 1;
    my $path            = catpath $vol, catdir( $dirs, @_ ), '';

    $path
};

my $find_dirs
= sub
{
    my $argz    = shift;
    my $base    = basename $argz->{ base };
    my $subdir  = $argz->{ subdir } // '';
    my $subonly = $argz->{ subonly } || $argz->{ scalar };
    my @found   = ();
    my $ignorz  = $argz->{ ignore };

    my $bin
    = $argz->{ abspath }
    ? $Bin_p
    : $Bin_l
    ;

    say STDERR "\nSearching $bin for '$base' ($subdir)..."
    if $argz->{ verbose };

    my @search
    = do
    {
        my @dirz    = dir_paths $bin, 1;

        say STDERR join "\n\t" => 'Parent Dirs:', @dirz
        if $argz->{ verbose };

        my ( $vol ) = splitpath $dirz[0];
        my %skipz
        = map
        {
            (
                catpath
                (
                    $vol, catdir( $_, $base ), ''
                ) => 1
            )
        }
        $ignorz->@*;

        my @subz
        = grep
        {
            ! exists $skipz{ $_ }
        }
        map
        {
            $_->$append_dir( $base )
        }
        @dirz;

        say STDERR join "\n\t" => 'Search Subs:', @subz
        if $argz->{ verbose };

        if( $subdir )
        {
            map
            {
                my $sub = $_->$append_dir( $subdir );

                $subonly
                ? $sub
                : [ $sub => $_ ]
            }
            @subz
        }
        else
        {
            $subonly    = 1;
            @subz
        }
    };

    if( $argz->{ scalar } )
    {
        # return at most one item; first returns undef when nothing passes.

        my $found = first { -d } @search;
        defined $found ? ( $found ) : ()
    }
    elsif( $subonly )
    {
        # grab all the extant items on the list.

        grep
        {
            -d 
        }
        @search
    }
    else
    {
        # if the subdir exists then return it and the subdir.

        map
        {
            -d $_->[0]
            ? $_->@*
            : ()
        }
        @search
    }
};

my $handle_args
= sub
{
    # discard the module, rest are arguments.

    shift;

    # default from the environment. for now assume that 
    # multiple modules whon't hack the environment during
    # compilation to change this after we first see it.

    state $verbose = $ENV{ VERBOSE_FINDBIN_LIBS } // $ENV{ VERBOSE } // '';

    my %argz =
    (
        # default verbosity from the environment.

        verbose => $verbose
      , print   => $verbose
      , map
        {
            my ( $k, $v ) = split '=', $_, 2;

            $k =~ s{^no}{}
            and $v  = '';

            $allow_undef{ $k }
            or $v //= 1;

            ( $k => $v )
        }
        @_
    );

    # exporting a subdir as a scalar requires stopping at
    # the subdir, ignoring its parent.

    $argz{ subonly }
    ||= $argz{ export } && $argz{ subdir } && $argz{ scalar };

    # stuff "debug=1" into your arguments and perl -d stops here.

    $DB::single = 1 if defined $argz{ debug };


    if( exists $argz{ use } )
    {
        # nothing further to do
    }
    elsif
    (
        # default if nothing is supplied is use; 
        # without an explicit export option default
        # it to off with an undef, otherwise it's true.

        defined $argz{ export }
        or 
        defined $argz{ p5lib }
        or
        defined $argz{ ld_lib }
    )
    {
        $argz{ use  } = '';
    }
    else
    {
        $argz{ use  } = 1;
    }

    # now apply the defaults, then sanity check the result.
    # base is a special case since it always has to exist.
    #
    # if $argz{ export } exists but is false then it takes
    # its default from $argz{ base }.

    while( my($k,$v) = each %defaultz )
    {
        $argz{ $k } //= $v;
    }

    exists $argz{ base } && $argz{ base }
    or croak "Bogus FindBin::libs: missing/false base argument, should be 'base=NAME'";

    # at this point the default for export can
    # be assigned IFF it exists at all; otherwise
    # the '' avoids issues with undef warnings.

    if( exists $argz{ export } )
    {
        $argz{ export } //= $argz{ base };
    }
    else
    {
        $argz{ export } = '';
    }

    # scalar selects the single value exported.

    $argz{ scalar } && ! $argz{ export }
    and croak "Bogus 'scalar' argument without 'export'";

    $argz{ ignore } =
    [
        uniq split /\s*,\s*/, ( $argz{ ignore } // '' )
    ];

    \%argz
};

########################################################################
# interface
########################################################################

sub import
{
    my $caller  = caller;
    my $argz    = &$handle_args;

    # HAK ALERT: the regex does nothing for security,
    # just dodges -T. putting this down here instead
    # of inside find_dirs allows people to use saner
    # untainting plans via find_dirs.

    my @libz
    = map
    {
        m{ (.+) }xs
    }
    $argz->$find_dirs;

    if( $argz->{ print } )
    {
        local $\ = "\n";
        local $, = "\n\t";

        say STDERR "Found */$argz->{ base }/$argz->{ subdir }:", @libz;
    }

    if( $argz->{ export } )
    {
        # this has to run in order to install variables that
        # the caller is expecting to exist at runtime -- even
        # if they are empty/undef at the end of it.

        my $ref     = qualify_to_ref $argz->{ export }, $caller;

        if( $argz->{ verbose } )
        {
            my $dest    = qualify $argz->{ export }, $caller;

            $argz->{ scalar }
            ? say STDERR "\nExporting: \$$dest"
            : say STDERR "\nExporting: \@$dest"
            ;
        }

        if( $argz->{ scalar } )
        {
            *$ref
            = @libz
            ? \$libz[0]
            : \( my $a = '' )
            ;
        }
        elsif
        (
            $argz->{ append }
            and
            my $ary = *{ $ref }{ ARRAY }
        )
        {
            push $ary->@*, @libz;
        }
        else
        {
            *$ref = \@libz
        }
    }

    # no 'else', these are not exclusive!

    state $secure = File::Util::SecureDir->new;
    if( my @clean = $secure->filter_dirs( @libz ) )
    {
        my $lib_str = join ':', @clean;

        for
        (
            [ qw( p5lib     PERL5LIB        ) ]
          , [ qw( ld_lib    LD_LIBRARY_PATH ) ]
        )
        {
            my ( $arg, $name ) = $_->@*;

            defined $argz->{ $arg }
            or next;

            # prepend found libs; add ':' separator only when the var
            # is already populated -- a trailing ':' on an empty string
            # silently adds '.' to the search path.

            $ENV{ $name } //= '';

            substr $ENV{ $name }, 0, 0,
                $ENV{ $name }
                ? $lib_str . ':'
                : $lib_str
            ;

            say STDERR "\nUpdated $name:\t$ENV{ $name }"
            if $argz->{ verbose };
        }

        if( $argz->{ use } )
        {
            # this obviously won't work if lib ever depends
            # on the caller's package.
            #
            # it does avoids issues with -T blowing up on the
            # old eval technique.

            require lib;

            lib->import( @clean );
        }
    }
    elsif( @libz )
    {
        local $, = ' ';

        carp "Empty list of usable paths from @libz"
        if $argz->{ fail };
    }
    else
    {
        carp "Empty lib directory list from '$0'"
        if $argz->{ fail };
    }

    0
}

# keep require happy

1

__END__

=head1 NAME

FindBin::libs - locate directories above the program and "use lib" or
export them.

=head1 SYNOPSIS

    # search up from the program's directory for ./lib directories
    # and "use lib" them, nearest first.

    use FindBin::libs;

    # same as above with explicit defaults.

    use FindBin::libs qw( base=lib use abspath fail noexport noprint );

    # any option can be negated with a "no" prefix.

    use FindBin::libs qw( nouse noexport print );   # print only

    # base: look for directories named "altlib" instead of "lib".

    use FindBin::libs qw( base=altlib );

    # export: install @altlib in the caller; "use" defaults off.

    use FindBin::libs qw( base=altlib export );

    # export=NAME: install @mylibs, and "use lib" them as well.

    use FindBin::libs qw( base=altlib export=mylibs use );

    # scalar: with export, only the nearest directory, as $etc.

    use FindBin::libs qw( base=etc export scalar );

    # append: add to an existing exported array.

    use FindBin::libs qw( base=foo subdir=etc subonly export=etc        );
    use FindBin::libs qw( base=bar subdir=etc subonly export=etc append );

    # subdir: use lib/perl5 and its parent lib, for each lib that
    # has a perl5 subdir.

    use FindBin::libs qw( subdir=perl5 );

    # subonly: use only the lib/perl5 dirs.

    use FindBin::libs qw( subdir=perl5 subonly );

    # ignore: skip /opt/lib and /srv/lib (replaces the default list).

    use FindBin::libs qw( ignore=/opt,/srv );

    # abspath (default) walks up from $Bin_p, symlinks resolved;
    # noabspath walks up from $Bin_l, symlinks preserved.

    use FindBin::libs qw( noabspath );

    # p5lib: prefix $ENV{ PERL5LIB } with the directories found.

    use FindBin::libs qw( p5lib );

    # ld_lib: prefix $ENV{ LD_LIBRARY_PATH } for XS or Inline libs.

    use FindBin::libs qw( ld_lib base=blib subdir=arch/auto subonly );

    # print: list the directories found on STDERR.

    use FindBin::libs qw( print );

    # verbose: also describe the search on STDERR.  setting
    # VERBOSE_FINDBIN_LIBS or VERBOSE in the environment turns on
    # verbose and print for every use.

    use FindBin::libs qw( verbose );

    # nofail: no warning if nothing is found.

    use FindBin::libs qw( base=optional export nofail );

    # debug: stop in the debugger after the options are processed.

    use FindBin::libs qw( debug );

=head1 DESCRIPTION

=head2 General Use

FindBin::libs searches the directory containing the program, and each
of its parents up to the root, for a directory with a given name
(default "lib").  The directories found are, by default, added to
@INC with "use lib", nearest to the program first, so the most
specific modules are found first.

The starting point is the program's directory from L<FindBin::Bin>:
C<$Bin_p>, with symlinks resolved, by default, or C<$Bin_l>, with
symlinks preserved, with C<noabspath>.  The walk up to the root is
done by L<FindBin::Parents>.  Only directories (C<-d>) are found;
files and missing paths are skipped.

The directories found can also, or instead, be exported into the
caller's package, prefixed to PERL5LIB or LD_LIBRARY_PATH, or
printed.  Before "use lib", PERL5LIB, or LD_LIBRARY_PATH, they are
checked by L<File::Util::SecureDir>; see L</Directory security>.

Options are given as C<NAME>, C<NAME=VALUE>, or C<noNAME>.  C<NAME>
alone sets the option true; C<noNAME> sets it false.
Unrecognized names are ignored without a warning, so check the
spelling of an option that seems to have no effect.

FindBin::libs can be used any number of times, each with its own
options:

    use FindBin::libs;
    use FindBin::libs qw( export=found base=lib                  );
    use FindBin::libs qw( export=binz  base=bin  ignore=/foo,/bar );
    use FindBin::libs qw( export       base=foobar               );

=head2 Options

=over 4

=item base=NAME

The directory name to search for, default "lib":

    use FindBin::libs qw( base=altlib );

searches for "altlib" directories and "use lib" them.  NAME is
reduced to its last component, so "base=foo/bar" searches for "bar".
A missing or false base croaks:

    Bogus FindBin::libs: missing/false base argument, should be 'base=NAME'

=item use, nouse

Add the directories found to @INC with "use lib".  This is the
default unless C<export>, C<p5lib>, or C<ld_lib> is given, which
turn it off unless C<use> is given explicitly:

    use FindBin::libs qw( export      );   # same as "export nouse"
    use FindBin::libs qw( export use  );   # export and use lib
    use FindBin::libs qw( p5lib       );   # same as "p5lib nouse"

=item export, export=NAME, noexport

Install the directories found in the caller's package.  Without a
NAME the variable is named after the base:

    use FindBin::libs qw( export );              # @lib
    use FindBin::libs qw( export base=meta );    # @meta
    use FindBin::libs qw( export=mylibs );       # @mylibs

The array is in order of distance from the program, nearest first.
It is always installed, even if it is empty, so code that uses it
compiles.  Each "export" replaces the variable unless C<append> is
given.

=item scalar

Used with C<export>: install only the nearest directory found, as a
scalar rather than an array:

    use FindBin::libs qw( export scalar base=etc );

    my $config  = "$etc/Foo.conf";

If nothing is found the scalar is ''.  With C<subdir>, C<scalar>
implies C<subonly>, which is necessary to get the single value.
Without C<export> it croaks:

    Bogus 'scalar' argument without 'export'

=item append

Push the directories found onto an existing exported array instead
of replacing it:

    use FindBin::libs qw( export=etc base=foo subdir=etc subonly        );
    use FindBin::libs qw( export=etc base=bar subdir=etc subonly append );

leaves @etc with any foo/etc directories followed by any bar/etc
directories.  If the array does not exist yet, C<append> exports it
as usual.

=item subdir=NAME

Look for NAME below each directory found.  Each directory that has
the subdirectory is returned as the subdirectory followed by the
directory itself; a directory without the subdirectory is dropped:

    use FindBin::libs qw( subdir=perl5 );

uses ./lib/perl5 and ./lib for each ./lib that has a perl5 subdir,
and skips any ./lib that does not.  To use every ./lib and any
./lib/perl5 use two searches:

    use FindBin::libs;
    use FindBin::libs qw( subdir=perl5 subonly );

NAME can have more than one level, e.g. "subdir=perl5/frobnicate".

=item subonly

With C<subdir>, return only the subdirectories, not the directories
above them:

    use FindBin::libs qw( base=config subdir=mypackage subonly export );

leaves @config with any ./config/mypackage directories, nearest
first, without any ./config directories.  It is also useful when a
project spans several repositories: to use api_foo/lib from
api_bar,

    use FindBin::libs qw( base=api_foo subdir=lib subonly );

C<subonly> has no effect without C<subdir>; C<scalar> implies it.

=item ignore=DIR,DIR, noignore

A comma-separated list of directories whose BASE subdirectory is
skipped.  The list replaces the default:

    use FindBin::libs qw( ignore=/opt,/srv );

skips /opt/lib and /srv/lib, and searches /lib and /usr/lib.
C<noignore> skips nothing.

The default list is "/,/usr", which skips /lib and /usr/lib.  Each
entry is joined with BASE and compared with the absolute paths
searched, so an entry must be an absolute path: a relative entry
such as "usr" matches nothing.

=item abspath, noabspath

Where the search starts.  C<abspath>, the default, walks up from
C<$Bin_p>, the program's directory with symlinks resolved;
C<noabspath> walks up from C<$Bin_l>, the directory as given in $0,
symlinks preserved.  They find different directories when the path
to the program passes through a symlink; see
L</Testing with Symlinks>.

=item p5lib

Prefix $ENV{ PERL5LIB } with the directories found, separated by
':'.  If PERL5LIB is empty no trailing ':' is added (which would add
'.' to the search path).  This affects processes started after the
use, not @INC in the running program; add C<use> for both:

    use FindBin::libs qw( p5lib use );

For example, with

    $ PERL5LIB=/usr/local/lib/foo myprog;

and C<use FindBin::libs qw( p5lib )> in myprog, programs it runs see
PERL5LIB as something like:

    /home/me/sandbox/lib:/usr/local/lib/foo

=item ld_lib

Prefix $ENV{ LD_LIBRARY_PATH } with the directories found, as for
C<p5lib>.  This is mostly useful with XS or Inline where *.so files
are located under the blib path:

    use FindBin::libs qw( ld_lib base=blib subdir=arch/auto subonly );

Like PERL5LIB, it affects processes started afterwards.

=item print, noprint

Print the directories found on STDERR:

    Found */lib/:
        /home/me/sandbox/project/lib
        /home/me/sandbox/lib

=item verbose, noverbose

Also print the starting directory, the parent directories, the
candidate paths, what is exported, and the environment variables
updated, on STDERR.

If VERBOSE_FINDBIN_LIBS, or else VERBOSE, is set in the environment
when FindBin::libs is first used, its value is the default for both
C<verbose> and C<print> in every use:

    $ VERBOSE_FINDBIN_LIBS=1 myprog;

=item fail, nofail

C<fail>, the default, warns via carp when nothing is found:

    Empty lib directory list from '<$0>'

or when nothing passes the security check:

    Empty list of usable paths from <dirs>

C<nofail> suppresses both, for searches that may legitimately find
nothing:

    use FindBin::libs qw( base=optional export nofail );

=item debug

Set $DB::single after the options are processed, so that "perl -d"
stops before the search.

=back

=head2 Directory security

The directories given to "use lib", PERL5LIB, and LD_LIBRARY_PATH
determine what code is executed: by this program via @INC, and by
programs it runs via the environment.  A malicious change to a
searched filesystem, e.g., a writable directory where a lib can be
planted, would otherwise run that code.  Before they are used the
directories found are checked with L<File::Util::SecureDir>, and any
that fail are dropped.  Its default filter rejects world-writable
directories; the program can select a stricter one with

    use File::Util::SecureDir qw( filter=NAME );

before using FindBin::libs.  See L<File::Util::SecureDir> for the
filters.

Exported variables are installed as-is: C<export> installs every
directory found, without the check.  They are data for the caller,
e.g., configuration directories; check them before loading code
from them.

The directory names are untainted, so FindBin::libs can be used with
-T.  This does nothing for security; it leaves the choice of
untainting rules to the caller via the security check above.

=head2 Outcomes and edge cases

These describe what happens when a search does not find what is
expected; they are useful when diagnosing a failure.

=over 4

=item Nothing found

Nothing is added to @INC, PERL5LIB, or LD_LIBRARY_PATH; an exported
array is empty and an exported scalar is ''.  Unless C<nofail> is
given carp reports "Empty lib directory list from '<$0>'".  Check
the starting directory and candidates with C<verbose>.

=item Found, but all rejected by the security check

Nothing is added to @INC, PERL5LIB, or LD_LIBRARY_PATH, but exported
variables still hold the directories.  Unless C<nofail> is given
carp reports "Empty list of usable paths from ..." with the
directories rejected.

=item A file or a broken symlink named like the base

Skipped: only directories are found.

=item subdir without subonly

A directory without the subdirectory is dropped along with it, so
"subdir=perl5" can find fewer ./lib directories than a plain search.

=item An ignore entry that has no effect

Ignore entries must be absolute paths; a relative entry matches
nothing.  See C<ignore> above.

=item The program's directory is the root

The search checks /BASE once.  With the default ignore list /lib is
skipped.

=item Interactive and -e programs

When $0 is '-e', '-', 'interactive', or under /dev/, FindBin::Bin
uses the working directory as the program's directory, so the
search starts there.  See L<FindBin::Bin>.

=item chdir before FindBin::libs is used

The program's directory is computed when FindBin::Bin is first
loaded.  A relative $0 is resolved against the working directory at
that time, so use FindBin::libs before any module that changes the
working directory.  See L<FindBin::Bin/Resolving the working directory>.

=item Unrecognized options

Ignored without a warning: e.g. "perl5lib" for "p5lib" leaves the
default "use lib" in effect.

=back

=head2 Homegrown Library Management

A common problem in managing perl projects is being unable to install
new modules because "it might break things", and being unable to test
them because you can't install them.  The usual outcome is a
collection of hard-coded

    use lib qw( /usr/local/projectX ... )

at the top of each #! file that has to be updated by hand for each
new project.

To get away from this you'll often see relative paths for the libs,
which require running the code from one specific place.  All this
does is push the hard-coding into cron, shell wrappers, and BEGIN
blocks.

With FindBin::libs you need suffer no more.

Automatically finding libraries in and above the executable means you
can put your modules into version control and check them out with the
project, have multiple copies shared by developers, or move a module
up the directory tree in a testbed to regression test it with
existing code, all without modifying a single line of code.

=over 4

=item Code-specific modules

Say your sandbox is in ./sandbox and you are currently working in
./sandbox/project/package/bin on a perl executable.  You may have
some modules that are specific -- or customized -- for this package,
share some modules within the project, and want to use company-wide
modules that are managed out of ./sandbox in development.  All of
this lives under a ./qc tree on the test boxes and under ./production
on production servers.

For simplicity, say that your sandbox lives in your home directory,
/home/jowbloe, as a directory or a symlink.

If your #! code uses FindBin::libs then running
/home/jowbloe/sandbox/project/package/bin/foobar will effectively

    use lib
    qw
    (
        /home/jowbloe/sandbox/project/package/lib
        /home/jowbloe/sandbox/project/lib
        /home/jowbloe/sandbox/lib
    );

This happens the same way whether you use a relative or absolute
path or "perl -d" the program.  The most specific module directories
("closest" to your executable) are found first: a version of
Frobnicate.pm in ./package/lib is used before the one in ./project
or ./sandbox.

If ./sandbox is reached through a symlink, the default C<abspath>
walks the physical directories; see L</Testing with Symlinks>.

The C<p5lib> option can help where some of the code lives outside of
the sandbox.  To test a sandbox version of some other module in the
programs foobar runs:

    use FindBin::libs qw( p5lib use );

and

    $ PERL5LIB=/other/sandbox/module foobar;

=item Regression Testing

Eventually, however, you'll need to regression test Frobnicate.pm
with other modules.

Move, copy, or symlink it into ./project/lib and you can run
./project/*/bin/* with it and see if there are any problems.  So can
the folks in QC.

To install and test a new module, put it into, say, ./sandbox/lib
and all the code that uses FindBin::libs will use it.

=item Testing with Symlinks

When the program's directory path passes through a directory symlink,
C<abspath> and C<noabspath> walk the tree from different starting
points and therefore find different C<lib/> directories.

Consider a layout where C</home/user/app> is a directory symlink to
C</work/projects/app>:

    /home/user/                       # logical subtree
    +-- lib/
    |   \-- SandboxLib.pm             # alternate/test version
    \-- app -> /work/projects/app     # directory symlink

    /work/projects/                   # physical subtree
    +-- lib/
    |   \-- StableLib.pm              # production version
    \-- app/
        \-- bin/
            \-- script                # $0

Running C<script> via the symlink path
(C</home/user/app/bin/script>):

    $Bin_l  =  /home/user/app/bin      # symlink path preserved
    $Bin_p  =  /work/projects/app/bin  # symlink resolved

C<FindBin::libs> uses one of these as the starting point for its
directory walk, depending on the C<abspath> setting:

    use FindBin::libs;               # abspath (default)
    # walks up from $Bin_p: /work/projects/app/bin -> /work/projects
    # use lib '/work/projects/lib'   -> loads StableLib.pm

    use FindBin::libs qw( noabspath );
    # walks up from $Bin_l: /home/user/app/bin -> /home/user
    # use lib '/home/user/lib'       -> loads SandboxLib.pm

The default C<abspath> always walks from the physical location of the
program, so C<lib/> directories are resolved relative to where the
file actually lives on disk.  Use C<noabspath> when you want to test
a program against alternate library versions placed in a tree you
control by pointing a directory symlink at the program's real C<bin/>
directory.

=item Managing Configuration and Meta-data Files

The C<base> option changes the directory searched for.  This allows
for a hierarchical set of metadata directories:

    ./sandbox
        ./meta
        ./project/
            ./meta

        ./project/package
            ./bin
            ./meta

with

    use FindBin::libs qw( base=meta export );

    sub read_meta
    {
        for my $dir ( @meta )
        {
            # open the first one and return
            ...
        }

        # caller gets back empty list if nothing was read.

        ()
    }

=item Using "prove" with local modules

Modules that are not intended for CPAN will not usually have a
Makefile.PL or Build setup, which makes it harder to check the code
via "make test".  Instead of hacking a one-time Makefile, *.t files
can use FindBin::libs to locate modules in a "lib" directory next to
the "t" directory:

    ./t/01.t
    ./t/02.t
    ...

    ./lib/My/Module.pm

The tests then use the current version of the code without it being
copied into ./blib, and

    prove t/*.t;

checks it.

=back

=head1 Notes

=head2 Alternatives

FindBin::libs was developed to avoid pitfalls with the items listed
below.  It uses File::Spec for all directory and volume handling, so
it works on *NIX, MSW, and VMS, where other techniques may be limited
to *NIX.

=over 4

=item PERL5LIB

PERL5LIB can be used to accomplish the same directory lookups as
FindBin::libs.  The problem is that PERL5LIB often contains absolute
paths and does not change depending on where tests are run.  This
can leave you modifying a file, changing directory to see if it
works with some other code, and testing an unmodified version of the
code via PERL5LIB.  FindBin::libs avoids this by searching from the
program's directory.

The same is true of almost any environmental solution, with Perl's
built-in mechanism or one based on $ENV{ PWD } or qx( pwd ).

Aside: combining an existing PERL5LIB for out-of-tree lookups with
the C<p5lib> option works well for most development situations.

=item use lib qw( ../../../../lib );

This works, but how many dots do you need to get all the working
libs into a module or #! code?  Classes distributed among several
levels of subdirectories may need qw( ../../../lib ) vs.
qw( ../../../../lib ) or various combinations of them.  Validating
these by hand (let alone correcting them) leaves me cross-eyed after
only a short session.

=item Anchor on a fixed lib directory

Given a standard directory, it is possible to use something like:

    BEGIN
    {
        my ( $libdir ) = $0 =~ m{ ^( .+? )/SOMEDIR/ }x;

        eval "use lib qw( $libdir )";
    }

This looks for a standard location (e.g., /path/to/Mylib) in the
executable path (or cwd) and uses that.

The main problem here is that if the anchor ever changes (e.g., when
moving code between projects or relocating directories) the path
often has to change in multiple files.  The regex also may have to
support multiple platforms, or be broken into more complicated
File::Spec code that probably looks pretty much like what

    use FindBin::libs qw( base=Mylib )

does anyway.

=back

=head1 See Also

=over 4

=item L<FindBin::Bin>

The program's directory: C<$Bin_p>, C<$Bin_l>, and the working
directory used for interactive programs and a relative $0.

=item L<FindBin::Parents>

The directories from the program's directory up to the root.

=item L<File::Util::SecureDir>

The security check applied before "use lib", PERL5LIB, and
LD_LIBRARY_PATH.

=item File::Spec

Used for portability in splitting and reassembling directory paths.

=item Older perl versions

The version installed depends on the running perl version via $^V.
The tarball's ./version directory is searched for the highest
v-string not greater than $^V, and those contents are installed.  For
example, if the running perl is v5.36 and the available versions
include v5.28 and v5.40 then the release for v5.28 is installed.

The currently supported Perl versions are:

  v5.8.1
  v5.14
  v5.28
  v5.40

=back

=head1 BUGS

=over 4

=item

On VMS, File::Spec's splitdir does not return the leading empty
string for an absolute path.  FindBin::Parents adds it back.  This
is a workaround, but File::Spec seems unlikely to change, so assume
it is permanent.

=item

The version directory is a bit messy; it's the only fix I've found
for not tying the code syntax arbitrarily to what was available on
RHEL 6.0 a few decades ago.

=back

=head1 AUTHOR

Steven Lembark, Workhorse Computing <lembark@wrkhors.com>

=head1 COPYRIGHT

Copyright (C) 2003-2027, Steven Lembark, Workhorse Computing.

=head1 LICENSE

This code is released under the same terms as Perl-5.44
or any later version of Perl.
