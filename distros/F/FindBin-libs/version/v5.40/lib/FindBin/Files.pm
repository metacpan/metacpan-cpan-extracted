########################################################################
# housekeeping
########################################################################

package FindBin::Files   v0.1.0;
use v5.40;

use Carp        qw( croak carp              );
use List::Util  qw( uniq first              );
use Symbol      qw( qualify qualify_to_ref  );

use File::Spec::Functions
qw
(
    splitpath
    splitdir
    catpath
    catdir
    file_name_is_absolute
    updir
);

use FindBin::Bin        qw( $Bin_l $Bin_p   );
use FindBin::Parents    qw( dir_paths       );

########################################################################
# package variables
########################################################################

my %defaultz =
(
    dir     => ''       # single directory name prefixed to file
  , strict  => 1        # skip dangling symlinks
  , abspath => 1
  , fail    => 1
  , ignore  => q{/,/usr}
);

my %allow_undef = map { $_ => 1 } qw( ignore export dir );

# names that are always directories on the local filesystem: they
# cannot be a basename, a dir, or a component of file.

my @bogus_basenamz  = ( updir, '.' );
my %bogus_basenamz  = map { ( $_ => 1 ) } @bogus_basenamz;
my $bogus_list      = join q{, } => map { qq{'$_'} } @bogus_basenamz;

########################################################################
# utility subs
########################################################################

my $find_files
= sub
{
    my $argz    = shift;
    my $strict  = $argz->{ strict };

    # file is relative: optional subdir(s) and a basename.

    my ( undef, $file_d, $file_b ) = splitpath $argz->{ file };
    my @file_dirz   = grep { $_ ne '' } splitdir $file_d;

    unshift @file_dirz, $argz->{ dir }
    if $argz->{ dir } ne '';

    my $bin
    = $argz->{ abspath }
    ? $Bin_p
    : $Bin_l
    ;

    my %skipz   = map { ( $_ => 1 ) } $argz->{ ignore }->@*;

    my @search
    = map
    {
        my ( $vol, $dir ) = splitpath $_, 1;

        catpath $vol, catdir( $dir, @file_dirz ), $file_b
    }
    grep
    {
        ! exists $skipz{ $_ }
    }
    dir_paths $bin, 1;

    say STDERR join "\n\t" => "Searching for '$argz->{ file }':", @search
    if $argz->{ verbose };

    # -f is '' for an existing non-file (e.g., a directory) and
    # undef for a missing path or a dangling symlink: strict skips
    # those, nostrict falls through to -l for the undef case, so
    # a dangling link is found and a directory is not.

    my $found
    = $strict
    ? sub { -f $_[0] }
    : sub { -f $_[0] // -l $_[0] }
    ;

    $argz->{ scalar }
    ? ( first { $found->( $_ ) } @search ) // ()
    : grep { $found->( $_ ) } @search
};

my $handle_args
= sub
{
    shift;

    state $verbose
    = $ENV{ VERBOSE_FINDBIN_FILES } // $ENV{ VERBOSE } // '';

    my %argz =
    (
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

    # debug: the use argument or $ENV{ FBF_DEBUG }.

    state $env_debug = $ENV{ FBF_DEBUG } // '';

    $argz{ debug } ||= $env_debug;

    $DB::single = 1 if $argz{ debug };

    $argz{ $_ } //= $defaultz{ $_ }
    for keys %defaultz;

    $argz{ file }
    or croak "Bogus FindBin::Files: missing/false file argument, should be 'file=NAME'";

    # dir is a single directory name: 't', not 't/50-foo' or '/t'.

    if( $argz{ dir } ne '' )
    {
        my @dirz    = splitdir $argz{ dir };

        1 == @dirz
        or croak "Bogus FindBin::Files: 'dir=$argz{ dir }' is a compound path, expected a single directory name";

        $bogus_basenamz{ $argz{ dir } }
        and croak "Bogus FindBin::Files: 'dir=$argz{ dir }' is not a directory name, expected a name other than $bogus_list";
    }

    file_name_is_absolute $argz{ file }
    and croak "Bogus FindBin::Files: 'file=$argz{ file }' is absolute, expected a relative path";

    # splitpath puts a trailing '.' or '..' into the directory,
    # leaving an empty basename: check the last component first
    # so the croak names it.

    my $last    = ( splitdir $argz{ file } )[-1];

    $bogus_basenamz{ $last }
    and croak "Bogus FindBin::Files: 'file=$argz{ file }' has basename '$last', expected a file name other than $bogus_list";

    my ( undef, $file_d, $basename ) = splitpath $argz{ file };

    $basename ne ''
    or croak "Bogus FindBin::Files: 'file=$argz{ file }' has no basename, expected a file name after the last directory";

    grep { $_ eq updir } splitdir $file_d
    and croak "Bogus FindBin::Files: 'file=$argz{ file }' contains '${\ updir }', expected a path below each parent";

    # export always happens.  the default name is the basename split
    # on non-word runs, empty fields dropped, joined with '_':
    # '.myconfig.yaml' and 'etc/.myconfig.yaml' are both myconfig_yaml.
    # the grep removes the leading empty field that split leaves for
    # a leading separator.
    #
    # any basename other than @bogus_basenamz is a legal file name
    # ('-', or UTF-8 that \W does not see as word characters); one
    # that yields no usable name needs export=NAME.

    $argz{ export } //= join '_' =>
    grep
    {
        $_ ne ''
    }
    split qr{ \W+ }x => $basename;

    $argz{ debug }
    && $basename !~ m{ \w }x
    and warn "Basename '$basename' lacks any word chars\n";

    $argz{ export } =~ m{ ^ [A-Za-z_] [\w:]* $ }x
    or croak "Bogus FindBin::Files: export name '$argz{ export }' from 'file=$argz{ file }' is not an identifier, expected 'export=NAME'";

    $argz{ ignore }
    = [ uniq split /\s*,\s*/, $argz{ ignore } // '' ];

    \%argz
};

########################################################################
# interface
########################################################################

sub import
{
    my $caller  = caller;
    my $argz    = &$handle_args;

    my @filz
    = map
    {
        m{ (.+) }xs
    }
    $argz->$find_files;

    say STDERR join "\n\t" => "Found */$argz->{ file }:", @filz
    if $argz->{ print };

    my $ref     = qualify_to_ref $argz->{ export }, $caller;

    say STDERR
    (
        "\nExporting: "
      . ( $argz->{ scalar } ? '$' : '@' )
      . qualify $argz->{ export }, $caller
    )
    if $argz->{ verbose };

    if( $argz->{ scalar } )
    {
        *$ref
        = @filz
        ? \$filz[0]
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
        push $ary->@*, @filz;
    }
    else
    {
        *$ref = \@filz;
    }

    @filz
    or $argz->{ fail }
    && carp "No '$argz->{ file }' found from '$0'";

    0
}

1

__END__

=head1 NAME

FindBin::Files - locate files relative to the executable's parent directories

=head1 SYNOPSIS

    # every ./etc/app.conf found walking up from $FindBin::Bin,
    # nearest first, exported as @app_conf.

    use FindBin::Files qw( file=etc/app.conf );

    # nearest one only, exported as $conf ('' if none found).

    use FindBin::Files qw( file=etc/app.conf scalar export=conf );

    # a basename alone looks in each parent directory itself.

    use FindBin::Files qw( file=.perltidyrc scalar export=tidyrc );

    # accept a dangling symlink, e.g. to report or repair it.

    use FindBin::Files qw( file=etc/app.conf nostrict );

=head1 DESCRIPTION

FindBin::Files is FindBin::libs for files: it walks up from the
executable's directory and exports the paths of a file found below
each parent directory.  Nothing is added to C<@INC> or the
environment, the module only exports variables.

The parent directories come from C<dir_paths> in L<FindBin::Parents>,
starting with the executable's directory and ending with the root.
C<file> is split with C<splitpath> into its subdirectory and basename,
with C<dir>, if given, in front of the subdirectory;
for each parent the subdirectory is appended with C<catdir>, the
path assembled with C<catpath>, and the result checked with C<-f>
(see C<strict>).

=head1 ARGUMENTS

Arguments are strings of the form C<name=value>.  A name without a
value is true; a leading C<no> sets it false (C<nostrict> is
C<strict=''>).

=over 4

=item dir=NAME

A single directory name prefixed to C<file>: C<dir=t file=50-foo/bar.t>
searches each parent for C<t/50-foo/bar.t>.  It is checked with
C<splitdir>, which returns one element for a single name.  A compound
or absolute path croaks, as does C<.> or C<File::Spec-E<gt>updir>
(C<..> on Unix):

    use FindBin::Files qw( dir=t/50-foobar file=bletch.t );   # croaks

    use FindBin::Files qw( dir=t file=50-foobar/bletch.t );   # works

(C<dirname> cannot do the check: C<dirname 't'> is C<'.'>.)  The
default C<''> adds nothing, so the subdirectory comes from C<file>
alone.

=item file=PATH

Required.  A bare C<use FindBin::Files;> croaks; use C<require> to
load the module without searching.

A relative path: a basename (C<file=app.conf>) or one with a leading
subdirectory (C<file=etc/app.conf>).  An absolute path, or one whose
directory contains C<File::Spec-E<gt>updir> (C<..> on Unix), croaks:
either would find a file outside of the parent directory being
searched.

Any basename the filesystem allows is accepted (C<file=->, UTF-8
names) except C<.> and C<File::Spec-E<gt>updir>, which are always
directories.  A missing basename (C<file=etc/>) also croaks.

=item export=NAME

The variable exported into the caller's package; a qualified name
(C<export=Foo::conf>) exports into that package.  Without
C<export>, the name comes from the basename of C<file>; any directory
is ignored.  Leading and trailing non-word characters are stripped and
each embedded run of them becomes one C<_>.  Configuration files often start with a dot and have an
extension:

    use FindBin::Files qw( file=.myconfig.yaml );      # @myconfig_yaml
    use FindBin::Files qw( file=etc/app.conf );        # @app_conf

A name that is not an identifier croaks; pass C<export=NAME>.  That
includes a basename with no word characters (C<file=-> gives C<''>;
C<debug> warns about it), one starting with a digit (C<file=1app.conf>
gives C<1app_conf>), and UTF-8 bytes that C<\W> does not see as word
characters.

    use FindBin::Files qw( file=- export=dash );       # @dash

=item scalar

Export C<$NAME> holding the nearest match instead of C<@NAME> holding
all of them.  If nothing is found C<$NAME> is C<''>.

=item append

Push the matches onto an existing C<@NAME> instead of replacing it.
Ignored with C<scalar>.

=item strict (default true)

A match is a plain file, C<-f>, or a symlink to one.  C<-f> is
undef for a missing path or a symlink whose target does not exist, so
by default dangling links are skipped.  C<nostrict> checks the undef
case with C<-l>, accepting dangling links:

    my $exists = $strict ? -f $path : -f $path // -l $path;

A directory gives C<-f> of C<''>, not undef, so it is never a match.

A quick sanity check for dangling configuration links: with
C<nostrict> every C<.myconfig> is returned, live or dead, and C<-e>
picks out the dead ones.

    use FindBin::Files qw( file=.myconfig export=config_f nostrict );

    my @dead = grep { ! -e } @config_f;

    @dead
    and die "Dangling config links: @dead\n";

=item abspath (default true)

Search from C<$Bin_p>, the physical path with symlinks resolved.
C<noabspath> uses C<$Bin_l>, the logical path, which follows the
directories as named in C<$0>.  See L<FindBin::Bin>.

=item ignore=DIR,DIR... (default C</,/usr>)

Parent directories that are not searched: the default skips
C</FILE> and C</usr/FILE>.  Entries are absolute directory paths
compared as given.  C<ignore=> (empty) searches every parent.

=item fail (default true)

Carp if no file is found.  C<nofail> is silent; the export still
happens, empty.

=item verbose, print

C<verbose> reports the search paths and the export on STDERR;
C<print> reports the files found.  Both default from
C<$ENV{ VERBOSE_FINDBIN_FILES }>, then C<$ENV{ VERBOSE }>.

=item debug

True if C<debug> is passed or C<$ENV{ FBF_DEBUG }> is true.  Warns
C<Basename '...' lacks any word chars> when the default export name
cannot come from the basename, and sets C<$DB::single> so C<perl -d>
stops while handling the arguments.

=back

=head1 OUTCOMES

=over 4

=item One or more matches

C<@NAME> holds every match nearest first; C<$NAME> the nearest.

=item No matches

C<@NAME> is empty, C<$NAME> is C<''>, and C<fail> carps.

=item Dangling symlink

Skipped by default; returned with C<nostrict>.

=back

=head1 SEE ALSO

L<FindBin::libs>, L<FindBin::Bin>, L<FindBin::Parents>

=cut
