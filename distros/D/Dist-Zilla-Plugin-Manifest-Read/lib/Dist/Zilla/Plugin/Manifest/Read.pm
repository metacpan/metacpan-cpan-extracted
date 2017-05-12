#   ---------------------------------------------------------------------- copyright and license ---
#
#   file: lib/Dist/Zilla/Plugin/Manifest/Read.pm
#
#   Copyright © 2015, 2016 Van de Bugger.
#
#   This file is part of perl-Dist-Zilla-Plugin-Manifest-Read.
#
#   perl-Dist-Zilla-Plugin-Manifest-Read is free software: you can redistribute it and/or modify it
#   under the terms of the GNU General Public License as published by the Free Software Foundation,
#   either version 3 of the License, or (at your option) any later version.
#
#   perl-Dist-Zilla-Plugin-Manifest-Read is distributed in the hope that it will be useful, but
#   WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A
#   PARTICULAR PURPOSE. See the GNU General Public License for more details.
#
#   You should have received a copy of the GNU General Public License along with
#   perl-Dist-Zilla-Plugin-Manifest-Read. If not, see <http://www.gnu.org/licenses/>.
#
#   ---------------------------------------------------------------------- copyright and license ---

#pod =for :this This is C<Dist::Zilla::Plugin::Manifest::Read> module documentation. Read this if you are going to hack or
#pod extend C<Manifest::Read>, or use it programmatically.
#pod
#pod =for :those If you want to have annotated source manifest, read the L<user manual|Dist::Zilla::Plugin::Manifest::Read::Manual>.
#pod General topics like getting source, building, installing, bug reporting and some others are covered
#pod in the F<README>.
#pod
#pod =for test_synopsis my $self;
#pod
#pod =head1 SYNOPSIS
#pod
#pod In your plugin:
#pod
#pod     # Iterate through the distribution files listed in MANIFEST:
#pod     my $finder = $self->zilla->plugin_named( 'Manifest::Read/:AllFiles' );
#pod     for my $file ( @{ $finder->find_files() } ) {
#pod         ...
#pod     };
#pod
#pod =head1 DESCRIPTION
#pod
#pod This class consumes L<Dist::Zilla::Role::FileGatherer> and C<Dist::Zilla::Role::FileFinder> roles.
#pod In order to fulfill requirements, the class implements C<gather_files> and C<find_files> methods.
#pod Other methods are supporting.
#pod
#pod The class also consumes L<Dist::Zilla::Role::ErrorLogger> role. It allows the class not to stop
#pod at the first problem but continue and report multiple errors to user.
#pod
#pod =cut

# --------------------------------------------------------------------------------------------------

package Dist::Zilla::Plugin::Manifest::Read;

use Moose;
use namespace::autoclean;
use version 0.77;

# ABSTRACT: Read annotated source manifest
our $VERSION = 'v0.5.0'; # VERSION

with 'Dist::Zilla::Role::FileGatherer';
with 'Dist::Zilla::Role::FileFinder';
with 'Dist::Zilla::Role::ErrorLogger' => { -version => 0.006 }; # need log_errors_in_file

use Dist::Zilla::File::OnDisk;
use List::Util qw{ min max };
use Path::Tiny;
use Set::Object qw{ set };
use Try::Tiny;

# --------------------------------------------------------------------------------------------------

#pod =attr manifest_name
#pod
#pod Name of manifest file to read.
#pod
#pod C<Str>, read-only, default value is C<MANIFEST>, C<init_arg> is C<manifest>.
#pod
#pod =cut

has manifest_name => (
    isa         => 'Str',
    is          => 'ro',
    default     => 'MANIFEST',
    init_arg    => 'manifest',
);

# --------------------------------------------------------------------------------------------------

#pod =attr manifest_file
#pod
#pod Manifest file as a C<Dist::Zilla> file object (C<Dist::Zilla::File::OnDisk>).
#pod
#pod C<Object>, read-only.
#pod
#pod =cut

has manifest_file => (
    isa         => 'Dist::Zilla::File::OnDisk',
    is          => 'ro',
    lazy        => 1,
    builder     => '_build_manifest_file',
    init_arg    => undef,
);

sub _build_manifest_file {
    my ( $self ) = @_;
    #   Straightforward appoach
    #       path( $self->manifest_name )
    #   is incorrect: it works only if the root directory is the current one, which is not always
    #   true. Following expression for manifest path is correct, but gives absolute (and often too
    #   long) name:
    #       path( $self->zilla->root )->child( $self->manifest )
    #   Let's try to shorten it. Hope this works:
    #       path( $self->zilla->root )->child( $self->manifest )->relative
    #   ...until someone changes the current directory...
    return Dist::Zilla::File::OnDisk->new( {
        name => path( $self->zilla->root )->child( $self->manifest_name )->relative . '',
    } );
};

# --------------------------------------------------------------------------------------------------

#pod =method BUILD
#pod
#pod This method creates bunch of file finders: C<Manifest::Read/:AllFiles>, C<Manifest::Read/:ExecFiles>, C<Manifest::Read/:ExtraTestFiles>, C<Manifest::Read/:IncModules>, C<Manifest::Read/:InstallModules>, C<Manifest::Read/:NoFiles>, C<Manifest::Read/:PerlExecFiles>, C<Manifest::Read/:ShareFiles>, C<Manifest::Read/:TestFiles>.
#pod
#pod =cut

sub BUILD {
    my ( $self ) = @_;
    require Dist::Zilla::Plugin::FinderCode;
    my $parent = $self;
    my $zilla  = $self->zilla;
    my @finders = qw{ :AllFiles :ExecFiles :ExtraTestFiles :IncModules :InstallModules :NoFiles :PerlExecFiles :ShareFiles :TestFiles };
    for my $name ( @finders ) {
        my $finder = Dist::Zilla::Plugin::FinderCode->new( {
            plugin_name => $parent->plugin_name . '/' . $name,
            zilla       => $zilla,
            style       => 'list',
            code        => sub {
                my ( $self ) = @_;
                my $plugin = $self->zilla->plugin_named( $name );
                if ( not defined( $plugin ) ) {
                    $parent->abort( [ "Can't find plugin %s", $name ] );
                };
                my $files = $parent->_incl_file_set * set( @{ $plugin->find_files() // [] } );
                    # `:NoFiles` in `Dist::Zilla` 6.008 returns `undef`, not `[]`.  ^^^^^
                return [ $files->members ];
            },
        } );
        # Let's provide old finder names for compatibility:
        # TODO: Drop it in one or two releases.
        my $compat = Dist::Zilla::Plugin::FinderCode->new( {
            plugin_name => do { $_ = $finder->plugin_name; $_ =~ s{/:}{/}x; $_ },
            zilla       => $finder->zilla,
            style       => $finder->style,
            code        => $finder->code,
        } );
        push( @{ $zilla->plugins }, $finder, $compat );
    };
    return;
};

# --------------------------------------------------------------------------------------------------

#pod =method gather_files
#pod
#pod This method fulfills L<Dist::Zilla::Role::FileGatherer> role requirement. It adds files listed in
#pod manifest to distribution. Files marked to exclude from distribution and directories are not added.
#pod
#pod =cut

sub gather_files {
    my ( $self ) = @_;
    for my $file ( $self->_incl_file_set->members ) {
        $self->add_file( $file );
    };
    return;
};

# --------------------------------------------------------------------------------------------------

#pod =method find_files
#pod
#pod This method fulfills L<Dist::Zilla::Role::FileFinder> role requirement. It returns the I<complete>
#pod list (strictly speaking, arrayref) of files read from the manifest, in order of appearance.
#pod
#pod Note: The list includes files which are I<not> added to the distribution.
#pod
#pod Note: The method always returns the same list of files. Plugins which remove files from
#pod distribution (i. e. plugins which do C<Dist::Zilla::Role::FilePruner> role) do not affect result of
#pod the method.
#pod
#pod If you are interested in distribution files, have look to file finders generated by C<BUILD>.
#pod
#pod =cut

has _complete_file_list => (
    isa         => 'ArrayRef',
    is          => 'ro',
    lazy        => 1,
    builder     => '_build_complete_file_list',
);

sub _build_complete_file_list {
    my ( $self ) = @_;
    return [
        map(
            { $_->{ file } }
            sort(
                { $a->{ line } <=> $b->{ line } }
                values( %{ $self->_manifest_bulk } )
            )
        )
    ];
};

sub find_files {
    my ( $self ) = @_;
    return [ @{ $self->_complete_file_list } ];
};

# --------------------------------------------------------------------------------------------------

#pod =attr _incl_file_set
#pod
#pod Set of files (object which do C<Dist::Zilla::Role::File> role) listed in the manifest I<and> marked
#pod for inclusion to the distribution.
#pod
#pod =cut

has _incl_file_set => (
    isa         => 'Set::Object',
    is          => 'ro',
    lazy        => 1,
    builder     => '_build_incl_file_set',
    init_arg    => undef,
);

sub _build_incl_file_set {
    my ( $self ) = @_;
    my $m = $self->_manifest_bulk;
    return set( map( { $_->{ file } } grep( { $_->{ mark } ne '-' } values( %$m ) ) ));
};

# --------------------------------------------------------------------------------------------------

#pod =attr _manifest_bulk
#pod
#pod Parsed manifest. HashRef. Keys are file names, values are HashRefs to inner hashes. Each inner hash
#pod has keys and associated values:
#pod
#pod =for :list
#pod =   name
#pod Parsed filename (single-quoted filenames are unquoted, escape sequences are evaluated, if any).
#pod =   file
#pod Object which does C<Dist::Zilla::Role::File> role.
#pod =   mark
#pod Mark.
#pod =   comment
#pod File comment, leading and trailing whitespaces are stripped.
#pod =   line
#pod Number of manifest line the file listed in.
#pod
#pod C<HasfRef>, read-only, lazy, initialized with builder.
#pod
#pod =cut

has _manifest_bulk => (
    isa         => 'HashRef[HashRef]',
    is          => 'ro',
    lazy        => 1,
    builder     => '_build_manifest_bulk',
    init_arg    => undef,
);

sub _build_manifest_bulk {
    my ( $self ) = @_;
    my $items = {};
    my @errors;
    my $error = sub {
        my ( $item, $message ) = @_;
        my $err = sprintf(
            '%s %s at %s line %d.',
            $item->{ name }, $message, $self->manifest_name, $item->{ line },
        );
        push( @errors, $item->{ line } => $err );
        return $self->log_error( $err );
    };
    foreach my $item ( $self->_parse_lines() ) {
        -e $item->{ name } or $error->( $item, 'does not exist' ) and next;
        if ( $item->{ mark } eq '/' ) {
            -d _ or $error->( $item, 'is not a directory' ) and next;
        } else {
            -f _ or $error->( $item, 'is not a plain file' ) and next;
            $item->{ file } = Dist::Zilla::File::OnDisk->new( { name => $item->{ name } } );
            $items->{ $item->{ name } } = $item;
        };
    };
    if ( @errors ) {
        $self->log_errors_in_file( $self->manifest_file, @errors );
    };
    $self->abort_if_error();
    return $items;
};

# --------------------------------------------------------------------------------------------------

#pod =attr _manifest_lines
#pod
#pod Array of chomped manifest lines, including comments and empty lines.
#pod
#pod C<ArrayRef[Str]>, read-only, lazy, initialized with builder.
#pod
#pod =cut

has _manifest_lines => (
    isa         => 'ArrayRef[Str]',
    is          => 'ro',
    lazy        => 1,
    init_arg    => undef,
    builder     => '_build_manifest_lines',
);

sub _build_manifest_lines {
    my ( $self ) = @_;
    my $lines = [];
    try {
        @$lines = split( "\n", $self->manifest_file->content );
    } catch {
        my $ex = $_;
        if ( blessed( $ex ) and $ex->isa( 'Path::Tiny::Error' ) ) {
            $self->abort( [ '%s: %s', $ex->{ file }, $ex->{ err } ] );
        } else {
            $self->abort( "$ex" );
        };
    };
    chomp( @$lines );
    return $lines;
};

# --------------------------------------------------------------------------------------------------

#pod =method _parse_lines
#pod
#pod This method parses manifest lines. Each line is parsed separately (there is no line continuation).
#pod
#pod If the method fails to parse a line, error is reported by calling method C<log_error> (implemented
#pod in L<Dist::Zilla::Role::ErrorLogger>). This means that parsing is not stopped at the first failure,
#pod but entire manifest will be parsed and all the found errors will be reported.
#pod
#pod The method returns list of hashrefs, a hash per file. Each hash has following keys and values:
#pod
#pod =for :list
#pod =   name
#pod Parsed filename (single-quoted filenames are unquoted, escape sequences are evaluated, if any).
#pod =   mark
#pod Mark.
#pod =   comment
#pod File comment, leading and trailing whitespaces are stripped.
#pod =   line
#pod Number of manifest line (one-based) the file is listed in.
#pod
#pod =cut

my %RE = (
    name    => qr{ ' (*PRUNE) (?: [^'\\] ++ | \\ ['\\] ?+ ) ++ ' | \S ++ }x,
        # ^ TODO: Use Regexp::Common for quoted filename?
    mark    => qr{ [#/+-] }x,
    comment => qr{ . *? }x,
);

sub _parse_lines {
    my ( $self ) = @_;
    my $manifest = $self->manifest_name;         # Shorter name.
    my ( %files, @files );
    my @errors;
    my $n = 0;
    for my $line ( @{ $self->_manifest_lines } ) {
        ++ $n;
        if ( $line =~ m{ \A \s * (?: \# | \z ) }x ) {   # Comment or empty line.
            next;
        };
        ## no critic ( ProhibitComplexRegexes )
        $line =~ m{
            \A
            \s *+                           # requires perl v5.10
            ( $RE{ name } )
            (*PRUNE)                        # requires perl v5.10
            (?:
                \s ++
                ( $RE{ mark } )
                (*PRUNE)
                (?:
                    \s ++
                    ( $RE{ comment } )
                ) ?
            ) ?
            \s *
            \z
        }x and do {
            my ( $name, $mark, $comment ) = ( $1, $2, $3 );
            if ( $name =~ s{ \A ' ( . * ) ' \z }{ $1 }ex ) {
                $name =~ s{  \\ ( ['\\] ) }{ $1 }gex;
            };
            if ( exists( $files{ $name } ) ) {
                my $f = $files{ $name };
                $self->log_error( [ '%s at %s line %d', $name, $manifest, $n ] );
                $self->log_error( [ '    also listed at %s line %d.', $manifest, $f->{ line } ] );
                push( @errors,
                    $n           => 'The file also listed at line ' . $f->{ line } . '.',
                    $f->{ line } => 'The file also listed at line ' . $n . '.',
                );
                next;
            };
            my $file = {
                name    => $name,
                mark    => $mark  // '+',     # requires perl v5.10
                comment => $comment,
                line    => $n,
            };
            $files{ $name } = $file;
            push( @files, $file );
            1;
        } or do {
            my $error = sprintf( 'Syntax error at %s line %d.', $manifest, $n );
            $self->log_error( $error );
            push( @errors, $n => $error );
            next;
        };
    };
    if ( @errors ) {
        $self->log_errors_in_file( $self->manifest_file, @errors );
        $self->abort();
    };
    return @files;
};

# --------------------------------------------------------------------------------------------------

__PACKAGE__->meta->make_immutable;

1;

# --------------------------------------------------------------------------------------------------

#pod =pod
#pod
#pod =encoding UTF-8
#pod
#pod =head1 WHAT?
#pod
#pod C<Dist-Zilla-Plugin-Manifest-Read> (or C<Manifest::Read> for brevity) is a C<Dist::Zilla> plugin. It reads
#pod I<annotated source> manifest, checks existence of all listed files and directories, and adds
#pod selected files to the distribution. C<Manifest::Read> also does C<FileFinder> role, providing the
#pod list of files for other plugins.
#pod
#pod =cut


#pod =head1 SEE ALSO
#pod
#pod =for :list
#pod = L<Dist::Zilla>
#pod = L<Dist::Zilla::Role::FileGatherer>
#pod = L<Dist::Zilla::Role::ErrorLogger>
#pod
#pod =head1 COPYRIGHT AND LICENSE
#pod
#pod Copyright (C) 2015, 2016 Van de Bugger
#pod
#pod License GPLv3+: The GNU General Public License version 3 or later
#pod <http://www.gnu.org/licenses/gpl-3.0.txt>.
#pod
#pod This is free software: you are free to change and redistribute it. There is
#pod NO WARRANTY, to the extent permitted by law.
#pod
#pod
#pod =cut

# end of file #

__END__

=pod

=encoding UTF-8

=head1 NAME

Dist::Zilla::Plugin::Manifest::Read - Read annotated source manifest

=head1 VERSION

Version v0.5.0, released on 2016-11-21 19:18 UTC.

=head1 WHAT?

C<Dist-Zilla-Plugin-Manifest-Read> (or C<Manifest::Read> for brevity) is a C<Dist::Zilla> plugin. It reads
I<annotated source> manifest, checks existence of all listed files and directories, and adds
selected files to the distribution. C<Manifest::Read> also does C<FileFinder> role, providing the
list of files for other plugins.

This is C<Dist::Zilla::Plugin::Manifest::Read> module documentation. Read this if you are going to hack or
extend C<Manifest::Read>, or use it programmatically.

If you want to have annotated source manifest, read the L<user manual|Dist::Zilla::Plugin::Manifest::Read::Manual>.
General topics like getting source, building, installing, bug reporting and some others are covered
in the F<README>.

=for test_synopsis my $self;

=head1 SYNOPSIS

In your plugin:

    # Iterate through the distribution files listed in MANIFEST:
    my $finder = $self->zilla->plugin_named( 'Manifest::Read/:AllFiles' );
    for my $file ( @{ $finder->find_files() } ) {
        ...
    };

=head1 DESCRIPTION

This class consumes L<Dist::Zilla::Role::FileGatherer> and C<Dist::Zilla::Role::FileFinder> roles.
In order to fulfill requirements, the class implements C<gather_files> and C<find_files> methods.
Other methods are supporting.

The class also consumes L<Dist::Zilla::Role::ErrorLogger> role. It allows the class not to stop
at the first problem but continue and report multiple errors to user.

=head1 OBJECT ATTRIBUTES

=head2 manifest_name

Name of manifest file to read.

C<Str>, read-only, default value is C<MANIFEST>, C<init_arg> is C<manifest>.

=head2 manifest_file

Manifest file as a C<Dist::Zilla> file object (C<Dist::Zilla::File::OnDisk>).

C<Object>, read-only.

=head2 _incl_file_set

Set of files (object which do C<Dist::Zilla::Role::File> role) listed in the manifest I<and> marked
for inclusion to the distribution.

=head2 _manifest_bulk

Parsed manifest. HashRef. Keys are file names, values are HashRefs to inner hashes. Each inner hash
has keys and associated values:

=over 4

=item name

Parsed filename (single-quoted filenames are unquoted, escape sequences are evaluated, if any).

=item file

Object which does C<Dist::Zilla::Role::File> role.

=item mark

Mark.

=item comment

File comment, leading and trailing whitespaces are stripped.

=item line

Number of manifest line the file listed in.

=back

C<HasfRef>, read-only, lazy, initialized with builder.

=head2 _manifest_lines

Array of chomped manifest lines, including comments and empty lines.

C<ArrayRef[Str]>, read-only, lazy, initialized with builder.

=head1 OBJECT METHODS

=head2 BUILD

This method creates bunch of file finders: C<Manifest::Read/:AllFiles>, C<Manifest::Read/:ExecFiles>, C<Manifest::Read/:ExtraTestFiles>, C<Manifest::Read/:IncModules>, C<Manifest::Read/:InstallModules>, C<Manifest::Read/:NoFiles>, C<Manifest::Read/:PerlExecFiles>, C<Manifest::Read/:ShareFiles>, C<Manifest::Read/:TestFiles>.

=head2 gather_files

This method fulfills L<Dist::Zilla::Role::FileGatherer> role requirement. It adds files listed in
manifest to distribution. Files marked to exclude from distribution and directories are not added.

=head2 find_files

This method fulfills L<Dist::Zilla::Role::FileFinder> role requirement. It returns the I<complete>
list (strictly speaking, arrayref) of files read from the manifest, in order of appearance.

Note: The list includes files which are I<not> added to the distribution.

Note: The method always returns the same list of files. Plugins which remove files from
distribution (i. e. plugins which do C<Dist::Zilla::Role::FilePruner> role) do not affect result of
the method.

If you are interested in distribution files, have look to file finders generated by C<BUILD>.

=head2 _parse_lines

This method parses manifest lines. Each line is parsed separately (there is no line continuation).

If the method fails to parse a line, error is reported by calling method C<log_error> (implemented
in L<Dist::Zilla::Role::ErrorLogger>). This means that parsing is not stopped at the first failure,
but entire manifest will be parsed and all the found errors will be reported.

The method returns list of hashrefs, a hash per file. Each hash has following keys and values:

=over 4

=item name

Parsed filename (single-quoted filenames are unquoted, escape sequences are evaluated, if any).

=item mark

Mark.

=item comment

File comment, leading and trailing whitespaces are stripped.

=item line

Number of manifest line (one-based) the file is listed in.

=back

=head1 SEE ALSO

=over 4

=item L<Dist::Zilla>

=item L<Dist::Zilla::Role::FileGatherer>

=item L<Dist::Zilla::Role::ErrorLogger>

=back

=head1 AUTHOR

Van de Bugger <van.de.bugger@gmail.com>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2015, 2016 Van de Bugger

License GPLv3+: The GNU General Public License version 3 or later
<http://www.gnu.org/licenses/gpl-3.0.txt>.

This is free software: you are free to change and redistribute it. There is
NO WARRANTY, to the extent permitted by law.

=cut
