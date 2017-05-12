#   ---------------------------------------------------------------------- copyright and license ---
#
#   file: lib/Dist/Zilla/Plugin/Manifes/Write.pm
#
#   Copyright © 2015, 2016 Van de Bugger.
#
#   This file is part of perl-Dist-Zilla-Plugin-Manifest-Write.
#
#   perl-Dist-Zilla-Plugin-Manifest-Write is free software: you can redistribute it and/or modify
#   it under the terms of the GNU General Public License as published by the Free Software
#   Foundation, either version 3 of the License, or (at your option) any later version.
#
#   perl-Dist-Zilla-Plugin-Manifest-Write is distributed in the hope that it will be useful, but
#   WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A
#   PARTICULAR PURPOSE. See the GNU General Public License for more details.
#
#   You should have received a copy of the GNU General Public License along with
#   perl-Dist-Zilla-Plugin-Manifest-Write. If not, see <http://www.gnu.org/licenses/>.
#
#   ---------------------------------------------------------------------- copyright and license ---

#pod =for :this This is C<Dist::Zilla::Plugin::Manifest::Write> module documentation. Read this if you are going to hack or
#pod extend C<Manifest::Write>.
#pod
#pod =for :those If you want to have annotated distribution manifest, read the L<plugin user
#pod manual|Dist::Zilla::Plugin::Manifest::Write::Manual>. General topics like getting source, building, installing, bug
#pod reporting and some others are covered in the F<README>.
#pod
#pod =head1 DESCRIPTION
#pod
#pod In order to add a manifest file to the distribution, C<Dist::Zilla::Plugin::Manifest::Write> class consumes
#pod C<Dist::Zilla::Role::FileGatherer> role. To meet the role requirements, the class implements
#pod C<gather_files> method. Other methods are supporting helpers for this one.
#pod
#pod Most of attributes are initialized by builders for easier customization by subclassing. Code is
#pod also divided into small methods for the same purpose.
#pod
#pod =head1 SEE ALSO
#pod
#pod =for :list
#pod = L<Dist::Zilla>
#pod = L<Dist::Zilla::Role>
#pod = L<Dist::Zilla::Role::Plugin>
#pod = L<Dist::Zilla::Role::FileInjector>
#pod = L<Dist::Zilla::Role::FileGatherer>
#pod = L<Dist::Zilla::Plugin::Manifest>
#pod = L<Dist::Zilla::Plugin::Manifest::Write::Manual>
#pod
#pod =cut

# --------------------------------------------------------------------------------------------------

package Dist::Zilla::Plugin::Manifest::Write;

use Moose;          # Let `perlcritic` shut up: it complains on code (`$VERSION`) before `strict`.
use namespace::autoclean;

# PODNAME: Dist::Zilla::Plugin::Manifest::Write
# ABSTRACT: Have annotated distribution manifest
our $VERSION = 'v0.9.7'; # VERSION

with 'Dist::Zilla::Role::FileGatherer';
with 'Dist::Zilla::Role::BeforeBuild';
with 'Dist::Zilla::Role::BeforeArchive';
with 'Dist::Zilla::Role::ErrorLogger';
with 'Dist::Zilla::Role::FileFinderUser' => {
    finder_arg_names => [ qw{ exclude_files } ],
    default_finders  => [ ':NoFiles' ],
};

use Dist::Zilla::File::FromCode;
use ExtUtils::Manifest qw{};
use List::Util;
use Module::Util qw{ is_valid_module_name };
use Path::Tiny qw{};
use Readonly;
use Set::Object qw{};
use String::RewritePrefix;

use Dist::Zilla::Role::File 5.023 ();       # Hint for `AutoPrereqs`.
    #   We do not consume the role but just require the specified version. Before this version
    #   `_added_by` was a `Str`, not `ArrayRef`.

# --------------------------------------------------------------------------------------------------

# File deeds:
Readonly our $SOURCE => 1;
Readonly our $META   => 2;
Readonly our $OTHER  => 3;
# File breeds:
Readonly our $ADDED  => 4;
Readonly our $BUILT  => 5;

# --------------------------------------------------------------------------------------------------

#pod =head1 FUNCTIONS
#pod
#pod I would expect to find these functions in C<Dist::Zilla>. Actually, C<Dist::Zilla::Util> defines
#pod the function C<expand_config_package_name>, but that function "is likely to change or go away" and
#pod there is no reverse transformation.
#pod
#pod =cut

# --------------------------------------------------------------------------------------------------

#pod =func __plugin_moniker
#pod
#pod     $str = __plugin_moniker( 'Dist::Zilla::Plugin::Name' );     # 'Name'
#pod     $str = __plugin_moniker( 'Non::Standard::Name' );           # '=Non::Standard::Name'
#pod     $str = __plugin_moniker( $plugin );
#pod
#pod The function takes either reference to a plugin object or a string, package name, and returns
#pod C<Dist::Zilla> plugin moniker: If its package name begins with C<Dist::Zilla::Plugin::>, this
#pod common prefix is dropped, otherwise the package name prepended with C<=>.
#pod
#pod =cut

{

my $package2moniker = {
    'Dist::Zilla::Plugin::' => '',
    'Dist::Zilla::Role::'   => '*',
    ''                      => '=',
};

sub __plugin_moniker($) {      ## no critic ( ProhibitSubroutinePrototypes )
    my ( $arg ) = @_;
    if ( my $blessed = blessed( $arg ) ) {
        $arg = $blessed;
    };
    return String::RewritePrefix->rewrite( $package2moniker, $arg );
};

}

# --------------------------------------------------------------------------------------------------

#pod =func __package_name
#pod
#pod     $str = __package_name( 'Name' );   # returns 'Dist::Zilla::Plugin::Name'
#pod     $str = __package_name( '=Name' );  # returns 'Name'
#pod     $str = __package_name( $plugin );
#pod
#pod This is operation opposite to C<__plugin_moniker>. It takes either reference to plugin object, or
#pod string, plugin moniker, and returns package name.
#pod
#pod This function is similar to C<expand_config_package_name> from C<Dist::Zilla::Util>, with minor
#pod difference: this function works with plugins only (not with plugin bundles and stashes), and
#pod accepts also reference to plugin object.
#pod
#pod =cut

{

my $moniker2package = {
    '=' => '',
    ''  => 'Dist::Zilla::Plugin::',
};

sub __package_name($) {     ## no critic ( ProhibitSubroutinePrototypes )
    my ( $arg ) = @_;
    if ( my $blessed = blessed( $arg ) ) {
        return $blessed;
    };
    return String::RewritePrefix->rewrite( $moniker2package, $arg );
};

}

# --------------------------------------------------------------------------------------------------

#pod =Method BUILDARGS
#pod
#pod The method splits values of C<source_providers> option into separate plugin names using whitespaces
#pod as delimiters, combines result of splitting with C<source_provider> option values, then filters out
#pod empty values. Resulting C<ArrayRef> saved as C<source_providers> options.
#pod
#pod The same for C<metainfo_providers> and C<metainfo_provider> options.
#pod
#pod =cut

around BUILDARGS => sub {
    my ( $orig, $class, $args ) = @_;
    for my $type ( qw{ source metainfo } ) {
        my $provider  = $type . '_provider';
        my $providers = $type . '_providers';
        if ( exists( $args->{ $provider } ) or exists( $args->{ $providers } ) ) {
            $args->{ $providers } = [
                grep(       # Filter out empty values.
                    { $_ ne '' }
                    @{ $args->{ $provider } or [] },    # Get singular option values as-is.
                    map( { split( m{\s+}x, $_ ) } @{ $args->{ $providers } or [] } )
                        #   Split plural option values.
                )
            ];
        };
    };
    return $class->$orig( $args );
};

# --------------------------------------------------------------------------------------------------

has _heading => (
    isa     => 'Str',
    is      => 'ro',
    lazy    => 1,
    builder => '_build_heading',
);

sub _build_heading {
    my ( $self ) = @_;
    return sprintf( "# This file was generated with %s %s.", blessed( $self ), $self->VERSION );
};

# --------------------------------------------------------------------------------------------------

#pod =attr manifest
#pod
#pod Name of manifest file to write.
#pod
#pod C<Str>, read-only. Default value is C<'MANIFEST'>.
#pod
#pod =cut

has manifest => (
    isa         => 'Str',
    is          => 'ro',
    default     => 'MANIFEST',
);

has _manifest_file => (
    isa         => 'Dist::Zilla::Role::File',
    is          => 'ro',
    lazy        => 1,
    init_arg    => undef,
    builder     => '_build_manifest_file',
);

sub _build_manifest_file {
    my ( $self ) = @_;
    my $zilla = $self->zilla;
    return Dist::Zilla::File::FromCode->new( {
        name                => $self->manifest,
        code_return_type    => 'bytes',
        code                => sub {
            my @list;
            my $files = Set::Object->new( @{ $zilla->files } );
            $files->remove( @{ $self->found_files } );
            #   Process all files in alphbetical order.
            for my $file ( sort( { $a->name cmp $b->name } @{ $files } ) ) {
                push( @list, {
                    name    => $self->_file_name( $file ),
                    comment => $self->_file_comment( $file )
                } );
            };
            $self->abort_if_error();    # `_file_comment` methods may generate errors.
            #   Find width of filename column.
            my $width = List::Util::max( map( { length( $_->{ name } ) } @list ) );
            #   Output formats.
            my $body = "%*s # %s";
            return
                join(
                    "\n",
                    $self->_heading,
                    map( { sprintf( $body, - $width, $_->{ name }, $_->{ comment } ) } @list ),
                ) . "\n";
        },
    } );
};

# --------------------------------------------------------------------------------------------------

#pod =attr manifest_skip
#pod
#pod Name of manifest.skip file to write.
#pod
#pod C<Str>, read-only. Default value is C<'MANIFEST.SKIP'>.
#pod
#pod =cut

has manifest_skip => (
    isa         => 'Str',
    is          => 'ro',
    default     => 'MANIFEST.SKIP',
);


has _manifest_skip_file => (
    isa         => 'Maybe[Dist::Zilla::Role::File]',
    is          => 'ro',
    lazy        => 1,
    init_arg    => undef,
    builder     => '_build_manifest_skip',
);

sub _build_manifest_skip {
    my ( $self ) = @_;
    return if $self->manifest_skip eq '';
    return Dist::Zilla::File::FromCode->new( {
        name                => $self->manifest_skip,
        code_return_type    => 'bytes',
        code                => sub {
            my $default = Path::Tiny::path( $ExtUtils::Manifest::DEFAULT_MSKIP );
            return join( "\n",
                $self->_heading,
                '',
                map( { "^" . quotemeta( $_->name ) . "\$" } @{ $self->found_files } ),
                '',
                #   `ExtUtils::Manifest` recognizes `#!include_default` directive. Unfortunately,
                #   `Module::Manifest` does not. So I have to copy default `MANIFEST.SKIP`.
                "# The rest is a copy of $default file:",
                '',
                $default->slurp_utf8(),
                '# end of file #'
            ) . "\n";
        },
    } );
};

# --------------------------------------------------------------------------------------------------

#pod =attr source_providers
#pod
#pod List of plugin names. Enlisted plugins are considered as source file providers. A file added to
#pod distribution by any of these plugins is considered as source file.
#pod
#pod C<ArrayRef[Str]>, read-only, default value is empty array. Init argument (and config file
#pod multi-value option) name is C<source_provider>. (C<BUILDARGS> also handles C<source_providers>
#pod option.)
#pod
#pod =cut

has source_providers => (
    isa         => 'ArrayRef[Str]',
    is          => 'ro',
    required    => 1,
    lazy        => 1,
    builder     => '_build_source_providers',
);

sub _build_source_providers {
    return [];
};

# --------------------------------------------------------------------------------------------------

#pod =attr metainfo_providers
#pod
#pod Like C<source_providers> but enlists meta info file providers.
#pod
#pod C<ArrayRef[Str]>, read-only, default value is C<CPANFile>, C<Manifest>, C<MetaYAML>, C<MetaJSON>,
#pod and the plugin itself. Init argument (and config file multi-value option) name is
#pod C<metainfo_provider>. (C<BUILDARGS> also handles C<metainfo_providers> option.)
#pod
#pod Note: Do not confuse C<Manifest::Write>'s term I<metainfo providers> with C<Dist::Zilla>'s
#pod C<MetaProvider> role. Plugins do C<MetaProvider> role provide I<metadata>, while C<Manifest::Write>
#pod is interested in plugins which adds I<files> containing metadata to the distribution (such plugins
#pod do C<FileInjector> role, not C<MetaProvider>).
#pod
#pod =cut

has metainfo_providers => (
    isa         => 'ArrayRef[Str]',
    is          => 'ro',
    required    => 1,
    lazy        => 1,
    builder     => '_build_metainfo_providers',
);

sub _build_metainfo_providers {
    my ( $self ) = @_;
    my @list = ( qw{ CPANFile Manifest MetaYAML MetaJSON }, $self->plugin_name );
    if ( $self->strict >= 0 ) {
        @list = grep( { $self->_is_injector( $_ ) } @list );
    };
    return \@list;
};

sub _is_injector {
    my ( $self, $name ) = @_;
    my $plugin = $self->zilla->plugin_named( $name );
    return $plugin && $plugin->does( 'Dist::Zilla::Role::FileInjector' );
};

# --------------------------------------------------------------------------------------------------

#pod =attr strict
#pod
#pod Strictness of checking source and metainfo provider names: -1 (no checks), 0 (some mistakes are
#pod fatal, some are not), or 1 (all mistakes are fatal).
#pod
#pod C<Int>, read-only. Default is 1.
#pod
#pod See L<Dist::Zilla::Plugin::Manifest::Write::Manual/"strict">.
#pod
#pod =cut

has strict => (
    isa     => 'Int',
    is      => 'ro',
    default => 1,
);

# --------------------------------------------------------------------------------------------------

#pod =attr show_mungers
#pod
#pod If C<1>, file mungers will be included into annotation. By default mungers are not included.
#pod
#pod C<Bool>, read-only. Default is C<0>.
#pod
#pod =cut

has show_mungers => (
    isa     => 'Bool',
    is      => 'ro',
    default => 0,
);

# --------------------------------------------------------------------------------------------------

#pod =attr deeds
#pod
#pod This attribute maps internal file deed constants (C<SOURCE>, C<META>, C<OTHER>) to user-visible
#pod names used in manifest (project name, C<metainfo>, and C<3rd party> respectively).
#pod
#pod C<HashRef[Str]>, read-only.
#pod
#pod =cut

has deeds => (
    isa      => 'HashRef[Str]',
    is       => 'ro',
    lazy     => 1,
    builder  => '_build_deeds',
    init_arg => undef,
);

sub _build_deeds {
    my ( $self ) = @_;
    return {
        $SOURCE => $self->zilla->name,
        $META   => 'metainfo',
        $OTHER  => '3rd party',
    };
};

# --------------------------------------------------------------------------------------------------

#pod =attr breeds
#pod
#pod This attribute maps internal file deed constants (C<$ADDED> and C<$BUILT>) to user-visible names
#pod used in manifest. By default user-visible breed names are the same as internal identifiers.
#pod
#pod C<HashRef[Str]>, read-only.
#pod
#pod =cut

has breeds => (
    isa      => 'HashRef[Str]',
    is       => 'ro',
    lazy     => 1,
    builder  => '_build_breeds',
    init_arg => undef,
);

sub _build_breeds {
    my ( $self ) = @_;
    return {
        $ADDED => 'added',
        $BUILT => 'built',
    };
};

# --------------------------------------------------------------------------------------------------

#pod =attr _providers
#pod
#pod This attribute maps provider names to file deeds. It makes C<_file_deed> method implementation
#pod simpler and faster.
#pod
#pod C<HashRef[Str]>, read-only, not an init arg.
#pod
#pod =cut

has _providers => (
    isa      => 'HashRef[Int]',
    is       => 'ro',
    required => 1,
    lazy     => 1,
    builder  => '_build_providers',
    init_arg => undef,
);

sub _build_providers {
    my ( $self ) = @_;
    my $providers = {};
    for my $provider ( @{ $self->source_providers } ) {
        $providers->{ $provider } = $SOURCE;
    };
    for my $provider ( @{ $self->metainfo_providers } ) {
        if ( exists( $providers->{ $provider } ) and $providers->{ $provider } != $META ) {
            # The same plugin name may be specified in the same option multiple times.
            $self->log_error( [
                "%s cannot be a source provider and a metainfo provider simultaneously",
                $provider
            ] );
        } else {
            $providers->{ $provider } = $META;
        };
    };
    return $providers;
};

# --------------------------------------------------------------------------------------------------

#pod =attr _dw
#pod
#pod Max length of user-visible deed names.
#pod
#pod C<Int>, read-only, not an init arg.
#pod
#pod =cut

has _dw => (
    isa      => 'Int',
    is       => 'ro',
    lazy     => 1,
    builder  => '_build_dw',
    init_arg => undef,
);

sub _build_dw {
    my ( $self ) = @_;
    return List::Util::max( map( { length( $_ ) } values( %{ $self->deeds } ) ) );
};

# --------------------------------------------------------------------------------------------------

around found_files => sub {
    my ( $orig, $self ) = @_;
    my $found = $self->$orig();
    push( @$found, $self->_manifest_skip_file ) if defined $self->_manifest_skip_file;
    return $found;
};

# --------------------------------------------------------------------------------------------------

#pod =method before_build
#pod
#pod This method is called by C<Dist::Zilla> automatically before build. The method checks validity of
#pod source and metainfo provider names.
#pod
#pod =cut

sub before_build {
    my ( $self ) = @_;
    if ( $self->strict >= 0 ) {
        my $log_warning = $self->strict > 0 ? 'log_error' : 'log';
        my $zilla = $self->zilla;
        for my $provider ( @{ $self->source_providers }, @{ $self->metainfo_providers } ) {
            if ( my $plugin = $zilla->plugin_named( $provider ) ) {
                if ( not $plugin->does( 'Dist::Zilla::Role::FileInjector' ) ) {
                    $self->log_error( [ "%s does not do FileInjector role", $provider ] );
                };
            } else {
                $self->$log_warning( [ "%s is not a plugin", $provider ] );
            };
        };
        $self->_providers();    # Initiate building the attribute. It can report errors.
        $self->abort_if_error();
    };
    return;
};

# --------------------------------------------------------------------------------------------------

#pod =method before_archive
#pod
#pod This method is called by C<Dist::Zilla> automatically before build the archive. The method prunes
#pod files found by file finders specified in the C<exclude_files> option.
#pod
#pod =cut

sub before_archive {
    my ( $self ) = @_;
    my $zilla = $self->zilla;
    for my $file ( @{ $self->found_files } ) {
        $zilla->prune_file( $file );
    };
    return;
};

# --------------------------------------------------------------------------------------------------

#pod =method gather_files
#pod
#pod This is the main method of the class. It adds a file with name C<< $self->manifest >> to the
#pod distribution. File content is specified by C<CodeRef> to postpone actual file creation. Being
#pod evaluated, the code iterates through all the files in distribution in alphabetical order, and
#pod fulfills the manifest with filenames and comments.
#pod
#pod =cut

sub gather_files {
    my ( $self, $arg ) = @_;
    $self->add_file( $self->_manifest_file );
    $self->add_file( $self->_manifest_skip_file ) if defined $self->_manifest_skip_file;
    return;
};

# --------------------------------------------------------------------------------------------------

#pod =method _file_name
#pod
#pod     $str = $self->_file_name( $file );
#pod
#pod Returns filename to be used in manifest. If filename does not include special characters (spaces,
#pod backslashes (C<\>), apostrophes (C<'>), hashes (C<#>)), it is the same as real filename, otherwise
#pod filename encoded like Perl single-quoted string: backslashes and apostrophes are escaped, and
#pod entire filename is enclosed into apostrophes.
#pod
#pod =cut

sub _file_name {
    my ( $self, $file ) = @_;
    my $name = $file->name;
    if ( $name =~ m{[\ '\\#]}x ) {
        $name =~ s{([\\'])}{\\$1}gx;
        $name = "'" . $name . "'";
    };
    return $name;
};

# --------------------------------------------------------------------------------------------------

#pod =method _file_comment
#pod
#pod     $str = $self->_file_comment( $file );    # Without leading sharp.
#pod
#pod The method returns comment to be used with the specified file. Comment should not include leading
#pod sharp character (C<#>).
#pod
#pod =cut

sub _file_comment {
    my ( $self, $file ) = @_;
    my $history = $self->_file_history( $file );
    my $deed    = $self->_file_deed(  $file, $history );
    my $breed   = $self->_file_breed( $file, $history );
    my $adder   = $self->_file_adder( $file, $history );
    my @mungers = $self->_file_mungers( $file, $history );
    my $comment =
        sprintf(
            "%*s file %s by %s",
                $self->_dw,
                $self->deeds->{ $deed   } || $deed  || '(*UNKNOWN*)',
                $self->breeds->{ $breed } || $breed || '(*UNKNOWN*)',
                $adder
        ) .
        (
            @mungers ? (
                ' and munged by ' . join( ', ', @mungers )
            ) : (
                ''
            )
        );
    return $comment;
};

# --------------------------------------------------------------------------------------------------

#pod =method _file_history
#pod
#pod     $arrayref = $self->_file_history( $file );
#pod
#pod The method calls C<_file_added_by> then does post-processing: all C<filename set> records are
#pod filtered out as insignificant and makes sure the log is not empty.
#pod
#pod =cut

sub _file_history {
    my ( $self, $file ) = @_;
    my $added_by = $file->{ added_by };
    my $history = $self->_file_added_by( $file );
    #   Filter out 'filename set' entries.
    $history = [ grep( { $_->{ action } ne 'filename set' } @$history ) ];
    #   Just in case make sure history is not empty.
    if ( not @$history ) {
        $self->log_error( [ '%s file history is empty', $file->name ] );
    };
    return $history;
};

# --------------------------------------------------------------------------------------------------

#pod =method _file_added_by
#pod
#pod     $arrayref = $self->_file_added_by( $file );
#pod
#pod The method parses file's C<added_by> log. Internally, C<added_by> log is a list of strings. Here
#pod are few examples:
#pod
#pod     content added by COPYING (Dist::Zilla::Plugin::GenerateFile line 114)
#pod     filename set by GatherFromManifest (Dist::Zilla::Plugin::GatherFromManifest line 125)
#pod     encoded_content added by GatherFromManifest (Dist::Zilla::Plugin::GatherFromManifest line 126)
#pod     text from coderef added by MetaJSON (Dist::Zilla::Plugin::MetaJSON line 83)
#pod     content set by TemplateFiles (Dist::Zilla::Plugin::TemplateFiles line 35)
#pod     content set by OurPkgVersion (Dist::Zilla::Plugin::OurPkgVersion line 82)
#pod     content set by PodWeaver (Dist::Zilla::Plugin::PodWeaver line 175)
#pod
#pod Thus, each string in C<added_by> log follows the format:
#pod
#pod     <action> by <name> (<package> line <number>)
#pod
#pod The method parses these strings and returns a more convenient for further processing form:
#pod
#pod     [ { action => …, name => …, package => …, line => … }, { … }, … ]
#pod
#pod Do not call this method directly, use C<_file_history> instead.
#pod
#pod =cut

sub _file_added_by {
    my ( $self, $file ) = @_;
    my $added_by = $file->{ added_by };
        # ^ Do not use accessor — it will convert array of strings into single string.
    my $history = [];
    my $n = 0;
    for my $entry ( @$added_by ) {
        ++ $n;
        if ( $entry =~ m{\A (.*?) \s by \s (.*) \s \( ([a-z_0-9:]+) \s line \s (\d+) \) \z}ix ) {
            my ( $action, $name, $package, $line ) = ( $1, $2, $3, $4 );
            push(
                @$history,
                { action => $action, name => $name, package => $package, line => $line }
            );
        } else {
            $self->log_error( [
                "Can't parse entry #%d in file %s added_by log:\n%s",
                $n, $file->name,
                join(
                    "\n",
                    map(
                        { ( $_ == $n ? '>>> ' : '    ' ) . $added_by->[ $_ - 1 ] }
                        1 .. @$added_by
                    )
                )
            ] );
        };
    };
    return $history;
};

# --------------------------------------------------------------------------------------------------

#pod =method _file_deed
#pod
#pod     $str = $self->_file_deed( $file, $history );    # $SOURCE, $META, or $OTHER.
#pod
#pod Returns internal identifier of file deed.
#pod
#pod =cut

sub _file_deed {
    my ( $self, $file, $history ) = @_;
    my $deed;
    if ( my $first = $history->[ 0 ] ) {
        $deed = $self->_providers->{ $first->{ name } } || $OTHER;
    } else {
        $self->log_error( [ "can't find file %s deed: file history is empty", $file->name ] );
    };
    return $deed;
};

# --------------------------------------------------------------------------------------------------

#pod =method _file_breed
#pod
#pod     $str = $self->_file_breed( $file, $history );   # ADDED or BUILT.
#pod
#pod Returns internal identifier of file breed, either C<$ADDED> or C<$BUILT>.
#pod
#pod Current implementation checks file object class: if it is a C<Dist::Zilla::File::OnDisk>, the file
#pod is added to distribution, otherwise the file is built.
#pod
#pod =cut

sub _file_breed {
    my ( $self, $file, $history ) = @_;
    my $breed;
    if ( $file->isa( 'Dist::Zilla::File::OnDisk' ) ) {
        $breed = $ADDED;
    } else {
        $breed = $BUILT;
    };
    return $breed;
};

# --------------------------------------------------------------------------------------------------

#pod =method _file_adder
#pod
#pod     $str = $self->_file_adder( $file, $history );
#pod
#pod Returns moniker of the plugin added the file to the distribution.
#pod
#pod =cut

sub _file_adder {
    my ( $self, $file, $history ) = @_;
    my $adder = '(*UNKNOWN*)';
    if ( my $first = $history->[ 0 ] ) {
        my $name = $first->{ name };
        if ( my $plugin = $self->zilla->plugin_named( $name ) ) {
            $adder = __plugin_moniker( $plugin );
            # Just in case make sure found plugin does `FileInjector` role.
            $plugin->does( 'Dist::Zilla::Role::FileInjector' ) or
                $self->log_error( [
                    "oops: found file adder %s does not do FileInjector role", $name
                ] );
        } else {
            $self->log_error( [
                "can't find file %s adder: %s is not a plugin", $file->name, $name
            ] );
        };
    } else {
        $self->log_error( [ "can't find file %s adder: file history is empty", $file->name ] );
    };
    return $adder;
};

# --------------------------------------------------------------------------------------------------

#pod =method _file_mungers
#pod
#pod     @list = $self->_file_mungers( $file, $history );
#pod
#pod If C<show_mungers> attribute is C<true>, returns list of monikers of the plugins munged the file.
#pod Otherwise returns empty list.
#pod
#pod =cut

sub _file_mungers {
    my ( $self, $file, $history ) = @_;
    my @mungers;
    if ( $self->show_mungers ) {
        for my $i ( 1 .. @$history - 1 ) {
            push( @mungers, $self->_file_munger( $file, $history->[ $i ] ) );
        };
    };
    return @mungers;
};

# --------------------------------------------------------------------------------------------------

#pod =method _file_munger
#pod
#pod     $str = $self->_file_munger( $file, $history->[ $n ] );
#pod
#pod The method is supposed to return a moniker of plugin munged the file. But… see
#pod L<Dist::Zilla::Plugin::Manifest::Write/"Correctness of Information">.
#pod
#pod =cut

sub _file_munger {
    my ( $self, $file, $entry ) = @_;
    #   Try to find a plugin with given name.
    if ( my $plugin = $self->zilla->plugin_named( $entry->{ name } ) ) {
        #   Bingo! Return (correct) plugin moniker.
        return __plugin_moniker( $plugin );
    };
    #   Oops, bad luck. We have:
    #       *   a plugin name which is not a plugin name but moniker of *some* plugin.
    #       *   a package name which can be a plugin package name or not.
    #   We have to guess.
    #   BTW, I have tried to mark guessed monikers with a question mark, but *all* file mungers
    #   will carry this mark. Looks ugly,so I rejected it.
    return __plugin_moniker( $entry->{ package } );
};

# --------------------------------------------------------------------------------------------------

#pod =method mvp_multivalue_args
#pod
#pod This method tells C<Dist::Zilla> that C<source_provider>, C<source_providers>,
#pod C<metainfo_provider>, and C<metainfo_providers> are multi-value options (i. e. can be specified in
#pod several times).
#pod
#pod =cut

around mvp_multivalue_args => sub {
    my ( $orig, $self ) = @_;
    return (
        $self->$orig(),
        qw{ source_provider source_providers metainfo_provider metainfo_providers }
    );
};

# --------------------------------------------------------------------------------------------------

__PACKAGE__->meta->make_immutable;

1;

# --------------------------------------------------------------------------------------------------

#pod =head1 SYNOPSIS
#pod
#pod     package ManifestWithFileSize;
#pod
#pod     use Moose;
#pod     use namespace::autoclean;
#pod     extends 'Dist::Zilla::Plugin::Manifest::Write';
#pod     our $VERSION = '0.007';
#pod
#pod     #   Overload any method or modify it with all the Moose power, e. g.:
#pod     around _file_comment => sub {
#pod         my ( $orig, $self, $file ) = @_;
#pod         my $comment = $self->$orig( $file );
#pod         if ( $file->name ne $self->manifest ) { # Avoid infinite recursion.
#pod             $comment .= sprintf( ' (%d bytes)', length( $file->encoded_content ) );
#pod         };
#pod         return $comment;
#pod     };
#pod
#pod     __PACKAGE__->meta->make_immutable;
#pod     1;
#pod
#pod =example Manifest with File Size
#pod
#pod A module shown in Synopsis is a real example. Its result looks like:
#pod
#pod     # This file was generated with ManifestWithFileSize 0.007.
#pod     MANIFEST     #  metainfo file built by =ManifestWithFileSize
#pod     dist.ini     #     Dummy file added by GatherDir (239 bytes)
#pod     lib/Dummy.pm #     Dummy file added by GatherDir (22 bytes)
#pod
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

#   ------------------------------------------------------------------------------------------------
#
#   file: doc/what.pod
#
#   This file is part of perl-Dist-Zilla-Plugin-Manifest-Write.
#
#   ------------------------------------------------------------------------------------------------

#pod =encoding UTF-8
#pod
#pod =head1 WHAT?
#pod
#pod C<Dist-Zilla-Plugin-Manifest-Write> (or C<Manifest::Write> for brevity) is a plugin for C<Dist::Zilla>, a replacement
#pod for standard plugin C<Manifest>. C<Manifest::Write> writes I<annotated> distribution manifest: each
#pod filename is followed by a comment explaining origin of the file: if it is a part of software, meta
#pod information, or 3rd-party file. Also it can B<I<exclude> built files from distribution>, e. g.
#pod extra tests have to be built (to run) but need not be distributed.
#pod
#pod =cut

# end of file #


# end of file #

__END__

=pod

=encoding UTF-8

=head1 NAME

Dist::Zilla::Plugin::Manifest::Write - Have annotated distribution manifest

=head1 VERSION

Version v0.9.7, released on 2016-12-14 22:51 UTC.

=head1 WHAT?

C<Dist-Zilla-Plugin-Manifest-Write> (or C<Manifest::Write> for brevity) is a plugin for C<Dist::Zilla>, a replacement
for standard plugin C<Manifest>. C<Manifest::Write> writes I<annotated> distribution manifest: each
filename is followed by a comment explaining origin of the file: if it is a part of software, meta
information, or 3rd-party file. Also it can B<I<exclude> built files from distribution>, e. g.
extra tests have to be built (to run) but need not be distributed.

This is C<Dist::Zilla::Plugin::Manifest::Write> module documentation. Read this if you are going to hack or
extend C<Manifest::Write>.

If you want to have annotated distribution manifest, read the L<plugin user
manual|Dist::Zilla::Plugin::Manifest::Write::Manual>. General topics like getting source, building, installing, bug
reporting and some others are covered in the F<README>.

=head1 SYNOPSIS

    package ManifestWithFileSize;

    use Moose;
    use namespace::autoclean;
    extends 'Dist::Zilla::Plugin::Manifest::Write';
    our $VERSION = '0.007';

    #   Overload any method or modify it with all the Moose power, e. g.:
    around _file_comment => sub {
        my ( $orig, $self, $file ) = @_;
        my $comment = $self->$orig( $file );
        if ( $file->name ne $self->manifest ) { # Avoid infinite recursion.
            $comment .= sprintf( ' (%d bytes)', length( $file->encoded_content ) );
        };
        return $comment;
    };

    __PACKAGE__->meta->make_immutable;
    1;

=head1 DESCRIPTION

In order to add a manifest file to the distribution, C<Dist::Zilla::Plugin::Manifest::Write> class consumes
C<Dist::Zilla::Role::FileGatherer> role. To meet the role requirements, the class implements
C<gather_files> method. Other methods are supporting helpers for this one.

Most of attributes are initialized by builders for easier customization by subclassing. Code is
also divided into small methods for the same purpose.

=head1 CLASS METHODS

=head2 BUILDARGS

The method splits values of C<source_providers> option into separate plugin names using whitespaces
as delimiters, combines result of splitting with C<source_provider> option values, then filters out
empty values. Resulting C<ArrayRef> saved as C<source_providers> options.

The same for C<metainfo_providers> and C<metainfo_provider> options.

=head1 OBJECT ATTRIBUTES

=head2 manifest

Name of manifest file to write.

C<Str>, read-only. Default value is C<'MANIFEST'>.

=head2 manifest_skip

Name of manifest.skip file to write.

C<Str>, read-only. Default value is C<'MANIFEST.SKIP'>.

=head2 source_providers

List of plugin names. Enlisted plugins are considered as source file providers. A file added to
distribution by any of these plugins is considered as source file.

C<ArrayRef[Str]>, read-only, default value is empty array. Init argument (and config file
multi-value option) name is C<source_provider>. (C<BUILDARGS> also handles C<source_providers>
option.)

=head2 metainfo_providers

Like C<source_providers> but enlists meta info file providers.

C<ArrayRef[Str]>, read-only, default value is C<CPANFile>, C<Manifest>, C<MetaYAML>, C<MetaJSON>,
and the plugin itself. Init argument (and config file multi-value option) name is
C<metainfo_provider>. (C<BUILDARGS> also handles C<metainfo_providers> option.)

Note: Do not confuse C<Manifest::Write>'s term I<metainfo providers> with C<Dist::Zilla>'s
C<MetaProvider> role. Plugins do C<MetaProvider> role provide I<metadata>, while C<Manifest::Write>
is interested in plugins which adds I<files> containing metadata to the distribution (such plugins
do C<FileInjector> role, not C<MetaProvider>).

=head2 strict

Strictness of checking source and metainfo provider names: -1 (no checks), 0 (some mistakes are
fatal, some are not), or 1 (all mistakes are fatal).

C<Int>, read-only. Default is 1.

See L<Dist::Zilla::Plugin::Manifest::Write::Manual/"strict">.

=head2 show_mungers

If C<1>, file mungers will be included into annotation. By default mungers are not included.

C<Bool>, read-only. Default is C<0>.

=head2 deeds

This attribute maps internal file deed constants (C<SOURCE>, C<META>, C<OTHER>) to user-visible
names used in manifest (project name, C<metainfo>, and C<3rd party> respectively).

C<HashRef[Str]>, read-only.

=head2 breeds

This attribute maps internal file deed constants (C<$ADDED> and C<$BUILT>) to user-visible names
used in manifest. By default user-visible breed names are the same as internal identifiers.

C<HashRef[Str]>, read-only.

=head2 _providers

This attribute maps provider names to file deeds. It makes C<_file_deed> method implementation
simpler and faster.

C<HashRef[Str]>, read-only, not an init arg.

=head2 _dw

Max length of user-visible deed names.

C<Int>, read-only, not an init arg.

=head1 OBJECT METHODS

=head2 before_build

This method is called by C<Dist::Zilla> automatically before build. The method checks validity of
source and metainfo provider names.

=head2 before_archive

This method is called by C<Dist::Zilla> automatically before build the archive. The method prunes
files found by file finders specified in the C<exclude_files> option.

=head2 gather_files

This is the main method of the class. It adds a file with name C<< $self->manifest >> to the
distribution. File content is specified by C<CodeRef> to postpone actual file creation. Being
evaluated, the code iterates through all the files in distribution in alphabetical order, and
fulfills the manifest with filenames and comments.

=head2 _file_name

    $str = $self->_file_name( $file );

Returns filename to be used in manifest. If filename does not include special characters (spaces,
backslashes (C<\>), apostrophes (C<'>), hashes (C<#>)), it is the same as real filename, otherwise
filename encoded like Perl single-quoted string: backslashes and apostrophes are escaped, and
entire filename is enclosed into apostrophes.

=head2 _file_comment

    $str = $self->_file_comment( $file );    # Without leading sharp.

The method returns comment to be used with the specified file. Comment should not include leading
sharp character (C<#>).

=head2 _file_history

    $arrayref = $self->_file_history( $file );

The method calls C<_file_added_by> then does post-processing: all C<filename set> records are
filtered out as insignificant and makes sure the log is not empty.

=head2 _file_added_by

    $arrayref = $self->_file_added_by( $file );

The method parses file's C<added_by> log. Internally, C<added_by> log is a list of strings. Here
are few examples:

    content added by COPYING (Dist::Zilla::Plugin::GenerateFile line 114)
    filename set by GatherFromManifest (Dist::Zilla::Plugin::GatherFromManifest line 125)
    encoded_content added by GatherFromManifest (Dist::Zilla::Plugin::GatherFromManifest line 126)
    text from coderef added by MetaJSON (Dist::Zilla::Plugin::MetaJSON line 83)
    content set by TemplateFiles (Dist::Zilla::Plugin::TemplateFiles line 35)
    content set by OurPkgVersion (Dist::Zilla::Plugin::OurPkgVersion line 82)
    content set by PodWeaver (Dist::Zilla::Plugin::PodWeaver line 175)

Thus, each string in C<added_by> log follows the format:

    <action> by <name> (<package> line <number>)

The method parses these strings and returns a more convenient for further processing form:

    [ { action => …, name => …, package => …, line => … }, { … }, … ]

Do not call this method directly, use C<_file_history> instead.

=head2 _file_deed

    $str = $self->_file_deed( $file, $history );    # $SOURCE, $META, or $OTHER.

Returns internal identifier of file deed.

=head2 _file_breed

    $str = $self->_file_breed( $file, $history );   # ADDED or BUILT.

Returns internal identifier of file breed, either C<$ADDED> or C<$BUILT>.

Current implementation checks file object class: if it is a C<Dist::Zilla::File::OnDisk>, the file
is added to distribution, otherwise the file is built.

=head2 _file_adder

    $str = $self->_file_adder( $file, $history );

Returns moniker of the plugin added the file to the distribution.

=head2 _file_mungers

    @list = $self->_file_mungers( $file, $history );

If C<show_mungers> attribute is C<true>, returns list of monikers of the plugins munged the file.
Otherwise returns empty list.

=head2 _file_munger

    $str = $self->_file_munger( $file, $history->[ $n ] );

The method is supposed to return a moniker of plugin munged the file. But… see
L<Dist::Zilla::Plugin::Manifest::Write/"Correctness of Information">.

=head2 mvp_multivalue_args

This method tells C<Dist::Zilla> that C<source_provider>, C<source_providers>,
C<metainfo_provider>, and C<metainfo_providers> are multi-value options (i. e. can be specified in
several times).

=head1 FUNCTIONS

I would expect to find these functions in C<Dist::Zilla>. Actually, C<Dist::Zilla::Util> defines
the function C<expand_config_package_name>, but that function "is likely to change or go away" and
there is no reverse transformation.

=head2 __plugin_moniker

    $str = __plugin_moniker( 'Dist::Zilla::Plugin::Name' );     # 'Name'
    $str = __plugin_moniker( 'Non::Standard::Name' );           # '=Non::Standard::Name'
    $str = __plugin_moniker( $plugin );

The function takes either reference to a plugin object or a string, package name, and returns
C<Dist::Zilla> plugin moniker: If its package name begins with C<Dist::Zilla::Plugin::>, this
common prefix is dropped, otherwise the package name prepended with C<=>.

=head2 __package_name

    $str = __package_name( 'Name' );   # returns 'Dist::Zilla::Plugin::Name'
    $str = __package_name( '=Name' );  # returns 'Name'
    $str = __package_name( $plugin );

This is operation opposite to C<__plugin_moniker>. It takes either reference to plugin object, or
string, plugin moniker, and returns package name.

This function is similar to C<expand_config_package_name> from C<Dist::Zilla::Util>, with minor
difference: this function works with plugins only (not with plugin bundles and stashes), and
accepts also reference to plugin object.

=head1 EXAMPLES

=head2 Manifest with File Size

A module shown in Synopsis is a real example. Its result looks like:

    # This file was generated with ManifestWithFileSize 0.007.
    MANIFEST     #  metainfo file built by =ManifestWithFileSize
    dist.ini     #     Dummy file added by GatherDir (239 bytes)
    lib/Dummy.pm #     Dummy file added by GatherDir (22 bytes)

=head1 SEE ALSO

=over 4

=item L<Dist::Zilla>

=item L<Dist::Zilla::Role>

=item L<Dist::Zilla::Role::Plugin>

=item L<Dist::Zilla::Role::FileInjector>

=item L<Dist::Zilla::Role::FileGatherer>

=item L<Dist::Zilla::Plugin::Manifest>

=item L<Dist::Zilla::Plugin::Manifest::Write::Manual>

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
