package Debian::AptContents;

use strict;
use warnings;

our $VERSION = '0.96';

=head1 NAME

Debian::AptContents - parse/search through apt-file's Contents files

=head1 SYNOPSIS

    my $c = Debian::AptContents->new( { homedir => '~/.dh-make-perl' } );
    my @pkgs = $c->find_file_packages('/usr/bin/foo');
    my $dep = $c->find_perl_module_package('Foo::Bar');

=head1 TODO

This needs to really work not only for Perl modules.

A module specific to Perl modules is needed by dh-make-perl, but it can
subclass Debian::AptContents, which needs to become more generic.

=cut

use base qw(Class::Accessor);
__PACKAGE__->mk_accessors(
    qw(
        cache homedir cache_file contents_files verbose
        source dist
        )
);

use Config;
use Debian::Dependency;
use DhMakePerl::Utils qw(find_core_perl_dependency is_core_perl_package);
use File::Spec::Functions qw( catfile catdir splitpath );
use IO::Uncompress::Gunzip;
use List::MoreUtils qw(uniq);
use Module::CoreList ();
use Storable;
use AptPkg::Config;

$AptPkg::Config::_config->init();

our $oldstable_perl = '5.14.2';

=head1 CONSTRUCTOR

=over

=item new

Constructs new instance of the class. Expects at least C<homedir> option.

=back

=head1 FIELDS

=over

=item homedir

(B<mandatory>) Directory where the object stores its cache.

=item dist

Used for filtering on the C<distributon> part of the repository paths listed in
L<sources.list>. Default is empty, meaning no filtering.

=item contents_files

Arrayref of F<Contents> file names. Default is to let B<apt-file> find them.

=item cache_file

Path to the file with cached parsed information from all F<Contents> files.
Default is F<Contents.cache> under C<homedir>.

=item cache

Filled by C<read_cache>. Used by C<find_file_packages> and (obviously)
C<store_cache>

=item verbose

Verbosity level. 0 means silent, the bigger the more the jabber. Default is 1.

=back

=cut

sub new {
    my $class = shift;
    $class = ref($class) if ref($class);
    my $self = $class->SUPER::new(@_);

    # required options
    $self->homedir
        or die "No homedir given";

    # some defaults
    $self->contents_files( $self->get_contents_files )
        unless $self->contents_files;
    $self->cache_file( catfile( $self->homedir, 'Contents.cache' ) )
        unless $self->cache_file;
    $self->verbose(1) unless defined( $self->verbose );

    $self->read_cache();

    return $self;
}

=head1 OBJECT METHODS

=over

=item warning

Used internally. Given a verbosity level and a message, prints the message to
STDERR if the verbosity level is greater than or equal of the value of
C<verbose>.

=cut

sub warning {
    my ( $self, $level, $msg ) = @_;

    warn "$msg\n" if $self->verbose >= $level;
}

=item get_contents_files

Reads F<sources.list>, gives the repository paths to
C<repo_source_to_contents_paths> and returns an arrayref of file names of
Contents files.

=cut

sub get_contents_files {
    my $self = shift;

    my $archspec = `dpkg --print-architecture`;
    chomp($archspec);

    my @res;

    # stolen from apt-file, contents_file_paths()
    my @cmd = (
        'apt-get',  'indextargets',
        '--format', '$(CREATED_BY) $(ARCHITECTURE) $(SUITE) $(FILENAME)'
    );
    open( my $fd, '-|', @cmd )
        or die "Cannot execute apt-get indextargets: $!\n";
    while ( my $line = <$fd> ) {
        chomp($line);
        next unless $line =~ m/^Contents-deb/;
        my ( $index_name, $arch, $suite, $filename ) = split( ' ', $line, 4 );
        next unless $arch eq $archspec;
        if ( $self->dist ) {
            next unless $suite eq $self->dist;
        }
        push @res, $filename;
    }
    close($fd);

    return [ uniq sort @res ];
}

=item read_cache

Reads the cached parsed F<Contents> files. If there are F<Contents> files with
more recent mtime than that of the cache (or if there is no cache at all),
parses all F<Contents> and stores the cache via C<store_cache> for later
invocation.

=cut

sub read_cache {
    my $self = shift;

    my $cache;

    if ( -r $self->cache_file ) {
        $cache = eval { Storable::retrieve( $self->cache_file ) };
        undef($cache) unless ref($cache) and ref($cache) eq 'HASH';
    }

    # see if the cache is stale
    if ( $cache and $cache->{stamp} and $cache->{contents_files} ) {
        undef($cache)
            unless join( '><', @{ $self->contents_files } ) eq
                join( '><', @{ $cache->{contents_files} } );

        # file lists are the same?
        # see if any of the files has changed since we
        # last read it
        if ($cache) {
            for ( @{ $self->contents_files } ) {
                if ( ( stat($_) )[9] > $cache->{stamp} ) {
                    undef($cache);
                    last;
                }
            }
        }
    }
    else {
        undef($cache);
    }

    unless ($cache) {
        if ( scalar @{ $self->contents_files } ) {
            $self->source('parsed files');
            $cache->{stamp}          = time;
            $cache->{contents_files} = [];
            $cache->{apt_contents}   = {};

            push @{ $cache->{contents_files} }, @{ $self->contents_files };
            my @cat_cmd = (
                '/usr/lib/apt/apt-helper', 'cat-file', @{ $self->contents_files }
            );
            open( my $f, "-|", @cat_cmd )
                or die
                "Can't run '/usr/lib/apt/apt-helper cat-file' on Contents files: $!\n";

            $self->warning( 1,
                "Parsing Contents files:\n\t"
                    . join( "\n\t", @{ $self->contents_files } ) );
            my $line;
            while ( defined( $line = $f->getline ) ) {
                my ( $file, $packages ) = split( /\s+/, $line );
                next unless $file =~ s{
                    ^usr/
                    (?:share|lib)/
                    (?:perl\d+/            # perl5/
                    | perl/(?:\d[\d.]+)/   # or perl/5.10/
                    | \S+-\S+-\S+/perl\d+/(?:\d[\d.]+)/  # x86_64-linux-gnu/perl5/5.22/
                    )
                }{}x;
                $cache->{apt_contents}{$file} = exists $cache->{apt_contents}{$file}
                    ? $cache->{apt_contents}{$file}.','.$packages
                    : $packages;

                # $packages is a comma-separated list of
                # section/package items. We'll parse it when a file
                # matches. Otherwise we'd parse thousands of entries,
                # while checking only a couple
            }
            close($f);

            if ( %{ $cache->{apt_contents} } ) {
                $self->cache($cache);
                $self->store_cache;
            }
        }
    }
    else {
        $self->source('cache');
        $self->warning( 1,
            "Using cached Contents from " . localtime( $cache->{stamp} ) );

        $self->cache($cache);
    }
}

=item store_cache

Writes the contents of the parsed C<cache> to the C<cache_file>.

Storable is used to stream the data. Along with the information from
F<Contents> files, a time stamp is stored.

=cut

sub store_cache {
    my $self = shift;

    my ( $vol, $dir, $file ) = splitpath( $self->cache_file );

    $dir = catdir( $vol, $dir );
    unless ( -d $dir ) {
        mkdir $dir
            or die "Error creating directory '$dir': $!\n";
    }

    Storable::nstore( $self->cache, $self->cache_file . '-new' );
    rename( $self->cache_file . '-new', $self->cache_file );
}

=item find_file_packages

Returns a list of packages where the given file was found.

F<Contents> files store the package section together with package name. That is
stripped.

Returns an empty list of the file is not found in any package.

=cut

sub find_file_packages {
    my ( $self, $file ) = @_;

    my $packages = $self->cache->{apt_contents}{$file};

    return () unless $packages;

    my @packages = split( /,/, $packages );    # Contents contains a
                                               # comma-delimited list
                                               # of packages

    s{.+/}{} for @packages;                    # remove section. Greedy on purpose
                                               # otherwise it won't strip enough off Ubuntu's
                                               # usr/share/perl5/Config/Any.pm  universe/perl/libconfig-any-perl

    # in-core dependencies are given by find_core_perl_dependency
    @packages = grep { !is_core_perl_package($_) } @packages;

    return uniq @packages;
}

=item find_perl_module_package( $module, $version )

Given Perl module name (e.g. Foo::Bar), returns a L<Debian::Dependency> object
representing the required Debian package and version. If the module is a core
one, suitable dependency on perl is returned.

If the package is also available in a separate package, an alternative
dependency is returned.

In case the version of the currently running Perl interpreter is lower than the
version in which the wanted module is available in core, the separate package
is preferred. Otherwise the perl dependency is the first alternative.

=cut

sub find_perl_module_package {
    my ( $self, $module, $version ) = @_;

    # see if the module is included in perl core
    my $core_dep = find_core_perl_dependency( $module, $version );

    # try module packages
    my $module_file = $module;
    $module_file =~ s|::|/|g;

    my @matches = $self->find_file_packages("$module_file.pm");

    # rank non -perl packages lower
    @matches = sort {
        if    ( $a !~ /-perl$/ ) { return 1; }
        elsif ( $b !~ /-perl$/ ) { return -1; }
        else                     { return $a cmp $b; }    # or 0?
    } @matches;

    # we don't want perl packages here
    @matches = grep { !is_core_perl_package($_) } @matches;

    my $direct_dep;
    $direct_dep = Debian::Dependency->new(
          ( @matches > 1 )
        ? [ map ( { pkg => $_, rel => '>=', ver => $version }, @matches ) ]
        : ( $matches[0], $version )
    ) if @matches;

    my $running_perl = $Config::Config{version};

    if ($core_dep) {

        # the core dependency is satisfied by oldstable?
        if ( $core_dep->ver <= $oldstable_perl ) {
            # drop the direct dependency and remove the version
            undef($direct_dep);

            $core_dep->ver(undef);
            $core_dep->rel(undef);
        }

        if ($direct_dep) {
            # both in core and in a package.
            if( $running_perl >= $core_dep->ver ) {
                return Debian::Dependency->new("$core_dep | $direct_dep");
            }
            else {
                return Debian::Dependency->new("$direct_dep | $core_dep");
            }
        }
        else {
            # only in core
            return $core_dep;
        }
    }
    else {
        # maybe in a package
        return $direct_dep;
    }
}

1;

=back

=head1 AUTHOR

=over 4

=item Damyan Ivanov <dmn@debian.org>

=item gregor herrmann <gregoa@debian.org>

=back

=head1 COPYRIGHT & LICENSE

=over 4

=item Copyright (C) 2008, 2009, 2010 Damyan Ivanov <dmn@debian.org>

=item Copyright (C) 2016, gregor herrmann <gregoa@debian.org>

=back

This program is free software; you can redistribute it and/or modify it under
the terms of the GNU General Public License version 2 as published by the Free
Software Foundation.

This program is distributed in the hope that it will be useful, but WITHOUT ANY
WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A
PARTICULAR PURPOSE.  See the GNU General Public License for more details.

You should have received a copy of the GNU General Public License along with
this program; if not, write to the Free Software Foundation, Inc., 51 Franklin
Street, Fifth Floor, Boston, MA 02110-1301 USA.

=cut
