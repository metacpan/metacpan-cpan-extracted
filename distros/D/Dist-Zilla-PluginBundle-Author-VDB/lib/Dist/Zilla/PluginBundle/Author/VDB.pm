#   ---------------------------------------------------------------------- copyright and license ---
#
#   file: lib/Dist/Zilla/PluginBundle/Author/VDB.pm
#
#   Copyright © 2015 Van de Bugger
#
#   This file is part of perl-Dist-Zilla-PluginBundle-Author-VDB.
#
#   perl-Dist-Zilla-PluginBundle-Author-VDB is free software: you can redistribute it and/or modify
#   it under the terms of the GNU General Public License as published by the Free Software
#   Foundation, either version 3 of the License, or (at your option) any later version.
#
#   perl-Dist-Zilla-PluginBundle-Author-VDB is distributed in the hope that it will be useful, but
#   WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A
#   PARTICULAR PURPOSE. See the GNU General Public License for more details.
#
#   You should have received a copy of the GNU General Public License along with
#   perl-Dist-Zilla-PluginBundle-Author-VDB. If not, see <http://www.gnu.org/licenses/>.
#
#   ---------------------------------------------------------------------- copyright and license ---

#pod =head1 DESCRIPTION
#pod
#pod It is unlikely that someone else will want to use it, so I will not bother with documenting it, at
#pod least for now.
#pod
#pod =for Pod::Coverage configure
#pod
#pod =cut

package Dist::Zilla::PluginBundle::Author::VDB;

use Moose;
use namespace::autoclean;
use version 0.77;

# PODNAME: Dist::Zilla::PluginBundle::Author::VDB
# ABSTRACT: VDB's plugin bundle
our $VERSION = 'v0.11.3'; # VERSION

with 'Dist::Zilla::Role::PluginBundle::Easy';

#   These modules used by the bundle directly.
use Carp qw{ croak };
use Dist::Zilla::File::InMemory;
use Dist::Zilla::File::OnDisk;
use Path::Tiny;
use Sub::Exporter::ForMethods qw{ method_installer };
use Data::Section { installer => method_installer }, -setup;

#   These modules are used by hooks. Require all the modules explicitly now to avoid unexpected
#   failures in the middle of build or release.
use App::Prove          ();
use File::pushd         ();
use IPC::Run3           ();
use IPC::System::Simple ();
use Path::Tiny 0.070    ();

# --------------------------------------------------------------------------------------------------

#pod =option minimum_perl
#pod
#pod Desired minimum Perl version. Extra test F<minimum-version.t> fails if actually required Perl
#pod version is greater than desired.
#pod
#pod Optional, default value C<5.006>.
#pod
#pod =cut

has minimum_perl => (
    is          => 'ro',
    isa         => 'Str',
    lazy        => 1,
    default     => sub {
        my ( $self ) = @_;
        return $self->payload->{ minimum_perl } // '5.006';
    },
);

# --------------------------------------------------------------------------------------------------

#pod =option copying
#pod
#pod Name of POD file to generate distribution F<COPYING> text file. Empty value disables generation
#pod F<COPYING> file.
#pod
#pod C<Str>, optional, default value C<doc/copying.pod>.
#pod
#pod =cut

has copying => (
    is          => 'ro',
    isa         => 'Str',
    lazy        => 1,
    default     => sub {
        my ( $self ) = @_;
        return $self->payload->{ copying } // 'doc/copying.pod';
    },
);

# --------------------------------------------------------------------------------------------------

#pod =option readme
#pod
#pod Names of POD files to generate distribution F<README> text file. This is a multi-value option.
#pod Empty values are ignored. Empty list disables generating F<README> file.
#pod
#pod C<ArrayRef[Str]>, optional, default value C<[ 'doc/what.pod', 'doc/why.pod', 'doc/naming.pod', 'doc/forms.pod', 'doc/source.pod', 'doc/distribution.pod', 'doc/installing.pod', 'doc/hacking.pod', 'doc/documentation.pod', 'doc/feedback.pod', 'doc/glossary.pod' ]>.
#pod
#pod =cut

has readme => (
    is          => 'ro',
    isa         => 'Maybe[ArrayRef[Str]]',
    lazy        => 1,
    default     => sub {
        my ( $self ) = @_;
        my $readme = $self->payload->{ readme } // [ 'doc/what.pod', 'doc/why.pod', 'doc/naming.pod', 'doc/forms.pod', 'doc/source.pod', 'doc/distribution.pod', 'doc/installing.pod', 'doc/hacking.pod', 'doc/documentation.pod', 'doc/feedback.pod', 'doc/glossary.pod' ];
        $readme = [ grep( { $_ ne  '' } @$readme ) ];   # Ignore empty items.
        if ( not @$readme ) {
            $readme = undef;
        };
        return $readme;
    },
);

# --------------------------------------------------------------------------------------------------

#pod =option local_release
#pod
#pod If true, release will be a local one, i. e. no external operations will be done: C<UploadToCPAN>
#pod and C<hg push> will be skipped, <hg tag> will create a local tag.
#pod
#pod Option can be set trough F<dist.ini> file or with C<DZIL_LOCAL_RELEASE> environment variable.
#pod
#pod Optional, default value is 0.
#pod
#pod =cut

has local_release => (
    is          => 'ro',
    isa         => 'Bool',
    lazy        => 1,
    default     => sub {
        my ( $self ) = @_;
        return $self->payload->{ local_release } // $ENV{ DZIL_LOCAL_RELEASE };
    },
);

# --------------------------------------------------------------------------------------------------

#pod =option archive
#pod
#pod Directory to archive files to. If empty, release will not be archived. If such directory does not
#pod exist, it will be created before release.
#pod
#pod Optional, default value C<".releases">.
#pod
#pod =cut

has archive => (
    is          => 'ro',
    isa         => 'Str',
    lazy        => 1,
    default     => sub {
        my ( $self ) = @_;
        return $self->payload->{ archive } // ".releases";
    },
);

# --------------------------------------------------------------------------------------------------

#pod =option templates
#pod
#pod This option will be passed to C<Templates> plugin. If you no not want C<Templates> to process
#pod files, specify C<:NoFiles>. This is multi-value option (i. e. may be specified several times).
#pod
#pod Optional, default value C<[ ':InstallModules' ]>.
#pod
#pod =cut

has templates => (
    is          => 'ro',
    isa         => 'Maybe[ArrayRef[Str]]',
    lazy        => 1,
    default     => sub {
        my ( $self ) = @_;
        my $templates = $self->payload->{ templates } // [ ':InstallModules' ];
        $templates = [ grep( { $_ ne  '' } @$templates ) ];   # Ignore empty items.
        if ( not @$templates ) {
            $templates = undef;
        };
        return $templates;
    },
);

# --------------------------------------------------------------------------------------------------

#pod =option unwanted_module
#pod
#pod =option unwanted_modules
#pod
#pod C<Data::Printer> is a great module for debugging. But sometimes I forget to remove debug statements
#pod from the code before release. This option helps to check it.
#pod
#pod If any of enlisted modules appears in the distribution dependencies, release will be aborted.
#pod
#pod Default value C<[ qw{ DDP Data::Printer } ]>.
#pod
#pod =cut

has unwanted_modules => (
    isa         => 'ArrayRef[Str]',
    is          => 'ro',
    lazy        => 1,
    default     => sub {
        my ( $self ) = @_;
        my $p  = $self->payload;
        my $u1 = $p->{ unwanted_module  };
        my $u2 = $p->{ unwanted_modules };
        return $u1 || $u2 ? [ $u1 ? @$u1 : (), $u2 ? @$u2 : () ] : [ qw{ DDP Data::Printer } ];
    },
);

# --------------------------------------------------------------------------------------------------

#pod =option spellchecker
#pod
#pod Command to run spellchecker. Spellchecker command is expected to read text from stdin, and print to
#pod stdout misspelled words. If empty, spellchecking will be skipped. This option affects
#pod C<Test::PodSpelling> plugin and internally implemented checking the F<Changes> file.
#pod
#pod Optional, default value C<aspell list -l en -p ./xt/aspell-en.pws>.
#pod
#pod =cut

has spellchecker => (
    is          => 'ro',
    isa         => 'Str',
    lazy        => 1,
    default     => sub {
        my ( $self ) = @_;
        return $self->payload->{ spellchecker } // 'aspell list -l en -p ./xt/aspell-en.pws';
            #   Leading dot (in `./xt/aspell.en.pws`) is important! Whitout the dot `aspell`
            #   fails to find the dictionary.
    },
);

# --------------------------------------------------------------------------------------------------

#pod =option repository
#pod
#pod Mercurial repository to push changes after release to. Option may be specified multiple times to
#pod push changes into several repositories. By default changes are pushed to one repository C<default>.
#pod
#pod =cut

has repository => (
    isa         => 'ArrayRef[Str]',
    is          => 'ro',
    lazy        => 1,
    default     => sub {
        my ( $self ) = @_;
        return $self->payload->{ repository } // [ 'default' ];
    },
);

# --------------------------------------------------------------------------------------------------

#pod =option installer
#pod
#pod Installer plugin.
#pod
#pod Default value C<'ModuleBuildTiny'>.
#pod
#pod =cut

has installer => (
    isa         => 'Str',
    is          => 'ro',
    lazy        => 1,
    default     => sub {
        my ( $self ) = @_;
        return $self->payload->{ installer } // 'ModuleBuildTiny';
    },
);

# --------------------------------------------------------------------------------------------------

#pod =method mvp_multivalue_args
#pod
#pod =cut

sub mvp_multivalue_args {
    return qw{ templates unwanted_module unwanted_modules readme repository };
};

# --------------------------------------------------------------------------------------------------

#pod =method _quote
#pod
#pod Convert an attribute to a form suitable for using in source. C<Str> attribute is converted into a
#pod string literal, C<ArrayRef> attribute is converted to a list of string literals.
#pod
#pod =cut

sub _quote {
    my ( $self, @args ) = @_;
    my @names;
    for my $arg ( @args ) {
        for ( ref( $arg ) eq 'ARRAY' ? @$arg : $arg ) {
            my $name = $_;
            $name =~ s{([\\'])}{\$1}gx;
            push( @names, "'$name'" );
        };
    };
    return join( ', ', @names );
};

# --------------------------------------------------------------------------------------------------

# Helper func: Iterate through distribution prerequisities.

sub MY::prereqs($$) {                   ## no critic ( ProhibitSubroutinePrototypes )
    my ( $plugin, $callback ) = @_;
    my $prereqs = $plugin->zilla->prereqs->cpan_meta_prereqs;
    for my $phase ( $prereqs->__legal_phases ) {
        for my $type  ( $prereqs->__legal_types  ) {
            my $reqs = $prereqs->requirements_for( $phase, $type ) or next;
            for my $module ( keys( %{ $reqs->{ requirements } } ) ) {
                $callback->( $plugin, $module, $phase, $type, $reqs );
            };
        };
    };
    return;
};

sub MY::file {
    my ( $plugin, $name ) = @_;
    our $Self;                          ## no critic ( ProhibitPackageVars )
    my $data = $Self->merged_section_data;
    my $root = path( $plugin->zilla->root );
    my $file;
    if ( $root->child( $name )->exists ) {
        $file = Dist::Zilla::File::OnDisk->new( {
            name    => $name,
        } );
    } elsif ( $data->{ $name } ) {
        $file = Dist::Zilla::File::InMemory->new( {
            name    => $name,
            content => ${ $data->{ $name } },
        } );
    } else {
        croak "$name: file not found";
    };
    return $file;
};

# --------------------------------------------------------------------------------------------------

sub configure {

    my ( $self ) = @_;
    our $Self = $self;                  ## no critic ( ProhibitPackageVars )
    my $name = $self->name;

    $self->add_plugins(

        [ 'Hook' => 'prologue' => {
            # DOES NOT WORK because plugin name will be '$name/prologue'.
            'hook' => [ q{
                use autodie ':all';
                use IPC::System::Simple qw{ capture };
                use Path::Tiny;
            } ],
        } ],

        [ 'Author::VDB::Version::Read', ],

        [ 'Hook::Init' => 'init stuff' => {
            'hook' => [ q[
                $dist->license->{ program } = 'perl-' . $dist->name;
                { pack] . q[age MY;     # Hide declaration from `new-version.t`.
                    our $name           = $dist->name;
                    ( our $package      = $name ) =~ s{-}{::}g;
                    our $version        = $dist->version;
                    our $Abstract       = $dist->abstract;
                    our $abstract       = lcfirst( $Abstract );
                    our $author         = $dist->authors->[ -1 ];
                    our $metacpan       = "https://metacpan.org/release/$name";
                    our $cpan_rt_mailto = "mailto:bug-$name\@rt.cpan.org";
                    our $cpan_rt_browse = "https://rt.cpan.org/Public/Dist/Display.html?Name=$name";
                    our $cpan_rt_report = "https://rt.cpan.org/Public/Bug/Report.html?Queue=$name";
                    our $repo_type      ||= "hg";
                    our $repo_host      ||= "fedorapeople.org";
                    our $repo_url       ||= "https://vandebugger.$repo_host/hg/perl-$name";
                    our $repo_web       ||= undef;
                    our $repo_clone     = "$repo_type clone $repo_url" .
                        ( $repo_url =~ m{/\Qperl-$name\E\z} ? '' : " \\\\\\n        perl-$name" );
                    our $bundle         = $Dist::Zilla::PluginBundle::Author::VDB::Self;
                };
                $ENV{ 'TEST_FIX' . 'ME_FORMAT' } = 'perl';      # Hide keyword from `fixme.t`.
            ] ],
        } ],

        #
        #   Files to include
        #

        [ 'Manifest::Read' ],   # REQUIRED VERSION: v0.5.0
            # Colon-prefixed file finders (e. g. 'Manifest::Read/:AllFiles') are used.

        #
        #   Generated files
        #

        $self->copying ne '' ? (
            [ 'GenerateFile' => 'COPYING' => {
                'filename' => 'COPYING',
                'content'  => [
                    q[{] . q[{],
                    q[    include( MY::file( $plugin, ] . $self->_quote( $self->copying ) . q[ ) )  ],
                    q[        ->fill_in                                                             ],
                    q[        ->pod2text( width => 80, indent => 0, loose => 1, quotes => 'none' )  ],
                    q[        ->chomp;                                                              ],
                    #   Resulting file may have one or two empty lines at the end, it affects
                    #   testing. Let's try to chomp empty lines to avoid it.
                    q[}] . q[}],        # One newline will be added there.
                ],
            } ],
        ) : (
        ),

        $self->readme ? (
            [ 'GenerateFile' => 'README' => {
                'filename' => 'README',
                'content'  => [
                    q[{] . q[{],
                    q[join(                                                                                ],
                    q[    "\n\n",                                                                          ],
                    q[    map(                                                                             ],
                    q[        {                                                                            ],
                    q[            include( MY::file( $plugin, $_ ) )                                       ],
                    q[                ->fill_in                                                            ],
                    q[                ->pod2text( width => 80, indent => 0, loose => 1, quotes => 'none' ) ],
                    q[                ->chomp                                                              ],
                    q[        }                                                                            ],
                    q[        ] . $self->_quote( $self->readme ) . q[                                      ],
                    q[    )                                                                                ],
                    q[);                                                                                   ],
                    q[}] . q[}],        # One newline will be added there.
                ],
            } ],
        ) : (
        ),

        [ 'Manifest::Write' => { # REQUIRED VERSION: v0.9.7
            # `Manifest::Write` v0.9.0 strictly requires plugin names, not monikers.
            # `Manifest::Write` v0.9.6 provides `exclude_files` option.
            # `Manifest::Write` v0.9.7 provides `manifest_skip` option and feature.
            'source_provider' => [
                "$name/Manifest::Read",
                $self->copying ne '' ? "$name/COPYING" : (),
                $self->readme        ? "$name/README"  : (),
            ],
            'metainfo_provider' => [
                # Defaults are not suitable because they are just `MetaJSON` and `MetaYAML`.
                "$name/Manifest::Write",
                "$name/MetaJSON",
                "$name/MetaYAML",
            ],
            'exclude_files' => [
                ":ExtraTestFiles",          # REQUIRE: Dist::Zilla 5.038
            ],
        } ],

        #
        #   File mungers
        #

        [ 'Templates' => { # REQUIRED VERSION: v0.5.0 # for including `Dist::Zilla::File` objects.
            'templates' => [
                "$name/src doc",
                @{ $self->templates // [] },
            ],
        } ],

        [ 'OurPkgVersion' ],

        [ 'SurgicalPodWeaver' => {
            'config_plugin' => '@Author::VDB',  # REQUIRE: Pod::Weaver::PluginBundle::Author::VDB
            'replacer'      => 'replace_with_comment',
        } ],

        [ 'FileFinder::ByName' => 'src doc' => {
            # Plugin name will be `$name/doc`.
            'file' => [
                $self->copying ne '' ? ( 'COPYING' ) : (),
                $self->readme        ? ( 'README'  ) : (),
            ],
        } ],

        #
        #   Update sources
        #

        #   Copy built doc files back to source directory.
        [ 'Hook::AfterBuild' => 'update src doc' => {
            'hook' => [ q{
                use Path::Tiny;
                my $files = $zilla->plugin_named( '} . $name . q{/src doc' )->find_files();
                my $build = path( $arg->{ build_root } );
                my $root  = path( $dist->root );
                for my $file ( @$files ) {
                    my $new_file = $build->child( $file->name );
                    my $old_file = $root->child( $file->name );
                    my $new_bulk = $new_file->slurp;
                    my $old_bulk = $old_file->exists ? $old_file->slurp : undef;
                    if ( not defined( $old_bulk ) or $new_bulk ne $old_bulk ) {
                        $self->log( [ 'updating %s', $file->name ] );
                        $old_file->append( { truncate => 1 }, $new_bulk );
                            # `append` is not atomic, but does not reset file mode.
                    };
                };
            } ],
        } ],

        #
        #   Tests
        #

        [ 'Test::DiagINC' ],

        # Files

        [ 'Test::Portability' ],        # Checks filenames.

        [ 'Test::EOL' => {
            'finder' => "$name/Manifest::Read/:AllFiles",
        } ],

        [ 'Test::NoTabs' => {
            'finder' => "$name/Manifest::Read/:AllFiles",
        } ],

        [ 'MojibakeTests' ],

        # Code

        [ 'Test::Compile' => {
            'fake_home' => 1,
        } ],

        [ 'Test::Version' => {          # All modules have version.
            finder    => "$name/Manifest::Read/:InstallModules",
                # REQUIRE: Dist::Zilla::Plugin::Manifest::Read v0.4.0 # want `/:InstallModules`.
            is_strict => 0,             # Strict version test fails in trial releases.
        } ],

        #   I would like to set `Test::Version`'s `is_strict` option to `1`, but it will fail for
        #   trial releases. To avoid that let's do a trick: set `is_strict` to `1` only in case of
        #   non-trial release.
        [ 'Hook::BeforeBuild' => 'hack Test::Version' => {
            'hook' => [ q{
                my $tv = $zilla->plugin_named( '} . $name . q{/Test::Version' );
                $tv->{ is_strict } = $dist->is_trial ? '0' : '1';
            } ],
        } ],

        [ 'Test::NewVersion' ],         # This is not a version already uploaded to CPAN.

        [ 'Test::MinimumVersion' => {
            'max_target_perl' => $self->minimum_perl,
        } ],

        [ 'Test::Fixme' ],

        [ 'Test::Perl::Critic' => {
            'critic_config' => 'xt/perlcritic.ini',
                #   The test does not check tests. TODO: How to fix?
        } ],

        # POD

        [ 'PodSyntaxTests'   ],     # `Dist-Zilla`-bundled test, uses `Test::Pod`.

        [ 'PodCoverageTests' ],     # `Dist-Zilla`-bundled test, uses `Pod::Coverage::TrustPod`.

        $self->spellchecker ? (
            [ 'Test::PodSpelling' => {
                'spell_cmd' => $self->spellchecker,
            } ],
        ) : (
        ),

        [ 'Test::Pod::LinkCheck' ],

        [ 'Test::Pod::No404s' ],    # No dead URLs.

        [ 'Test::Synopsis' ],

        # Metadata

        [ 'MetaTests' ],    # `Dist-Zilla`-bundled test, uses `Test::CPAN::Meta`, checks `META.yml`.

        [ 'Test::CPAN::Meta::JSON' ],   # Uses `Test::CPAN::Meta::JSON`.

        [ 'Test::CPAN::Changes' ],
            #   Does not check that `Changes` has a record for current version, see
            #   <https://github.com/doherty/Dist-Zilla-Plugin-Test-CPAN-Changes/issues/6>.

        [ 'Test::DistManifest' ],

        # Overall

        [ 'Test::Kwalitee' ],

        #
        #   Metainfo
        #

        [ 'MinimumPerl' ],

        [ 'AutoPrereqs' => {
            'extra_scanners' => 'Hint', # REQUIRE: Perl::PrereqScanner::Scanner::Hint
        } ],

        #   `Prereqs::AuthorDeps` has a problem:
        #       <https://github.com/dagolden/Dist-Zilla-Plugin-Prereqs-AuthorDeps/issues/1>
        #   It adds local plugins (e. g. tools::GenerateHooks) to the dependencies,
        #   which obviously are not indexed on CPAN.
        [ 'Prereqs::AuthorDeps' => {
            #~ 'exclude' => [
                #~ #   Exclude option requires a list of specific files, while I want to ignore all
                #~ #   files in specific directory.
            #~ ],
        } ],

        #   TODO: Remove when possible.
        #   This is a dirty hack. Remove it when `Prereqs::AuthorDeps` allows me to ignore all the
        #   modules from `tools/` directory. Meanwhile, find and remove all the dependencies on
        #   modules with `tools::` prefix.
        [ 'Hook::PrereqSource' => 'tools' => {
            'hook' => [ q{
                MY::prereqs( $self, sub {
                    my ( $self, $module, $phase, $type, $reqs ) = @_;
                    if ( $module =~ m{^tools::} ) {
                        $self->log_debug( [
                            'found dependency on module %s (phase %s, type %s), deleting it',
                            $module, $phase, $type
                        ] );
                        delete( $reqs->{ requirements }->{ $module } );
                    };

                } );
            } ],
        } ],

        #   `use autodie ':all';` implicitly requires `IPC::System::Simple` module, but this
        #   dependency is not detected by `AutoPrereqs`. If there is dependency on `autodie`, let
        #   us add dependency on `IPC::System::Simple`.
        [ 'Hook::PrereqSource' => 'autodie' => {
            'hook' => [ q{
                MY::prereqs( $self, sub {
                    my ( $self, $module, $phase, $type ) = @_;
                    if ( $module eq 'autodie' ) {
                        $self->log_debug( [
                            'found dependency on module %s (phase %s, type %s), ' .
                                'adding dependency on IPC::System::Simple',
                            $module, $phase, $type
                        ] );
                        $dist->register_prereqs(
                            { phase => $phase, type => $type },
                            'IPC::System::Simple' => 0,
                        );
                    };
                } );
            } ],
        } ],

        [ 'MetaProvides::Package' ],

        [ 'MetaResources::Template' => {
            'delimiters'          => '{ }',
            'homepage'            => '{$MY::metacpan}',
            'license'             => '{$dist->license->url}',
            'repository.type'     => '{$MY::repo_type}',
            'repository.url'      => '{$MY::repo_url}',
            'repository.web'      => '{$MY::repo_web}',
            'bugtracker.mailto'   => '{$MY::cpan_rt_mailto}',
            'bugtracker.web'      => '{$MY::cpan_rt_browse}',
        } ],

        [ 'MetaYAML' ],                 # Generate `META.yml`.

        [ 'MetaJSON' ],                 # Generate `META.json`.

        #
        #   Installer
        #

        $self->installer ? (
            [ $self->installer ],
        ) : (
        ),

        #
        #   Release
        #

        $self->archive ? (
            #   Make sure archive directory exists. Do it in the very beginnig of release because
            #   it is simple and fast operation. It will be annoying to pass all the tests and
            #   stop release  because `dzil` fails to create archive directory.
            [ 'Hook::BeforeRelease' => 'archive directory' => {
                'hook' => [ q{
                    my $root = path( $self->zilla->root . '' );
                    my $dir = path( "} . $self->archive . q{" );
                    if ( $dir->is_absolute ) {
                        $self->log_error( [ 'bad archive directory: %s', "$dir" ] );
                        $self->log_error( [ 'absolute path not allowed' ] );
                        $self->abort();
                    };
                    if ( not $dir->is_dir ) {
                        $self->log( [ 'creating archive directory %s', "$dir" ] );
                        $dir->mkpath();
                    };
                } ],
            } ]
        ) : (
        ),

        #   I want to run xtest before release. Neither RunExtraTests nor CheckExtraTests work for
        #   me. The first one executes extra test when user runs `dzil test`. I do not want it,
        #   because it slows down regular testing. The second one unpacks tarball, builds it, and
        #   run extra tests… But tarball does not include extra tests.

        [ 'Hook::BeforeRelease' => 'xtest' => {
            'hook' => [ q{
                use File::pushd;
                my $wd = pushd( $zilla->ensure_built );
                $zilla->_ensure_blib();
                use App::Prove;
                local $ENV{ AUTHOR_TESTING  } = 1;
                local $ENV{ RELEASE_TESTING } = 1;
                my $prove = App::Prove->new({
                    blib    => 1,
                    recurse => 1,
                    argv    => [ 'xt' ],
                });
                $prove->run() or $self->log_error( "xtest failed" );
                $self->abort_if_errors();
            } ],
        } ],

        [ 'TestRelease'     ],          # Unpack tarball and run tests.

        #   Make sure the distro does not depend on unwanted modules. Unwanted module, for example,
        #   is `Data::Printer`. I use it often for debugging purposes and forget to remove
        #   debugging code.
        [ 'Hook::BeforeRelease' => 'unwanted deps' => {
            'hook' => [ q{
                my @unwanted = (} . $self->_quote( $self->unwanted_modules ) . q{);
                my %unwanted = map( { $_ => 1 } @unwanted );
                my $heading = 'unwanted modules found:';
                MY::prereqs( $self, sub {
                    my ( $self, $module, $phase, $type ) = @_;
                    if ( $unwanted{ $module  } ) {
                        if ( $heading ) {
                            $self->log_error( $heading );
                            $heading = undef;
                        };
                        $self->log_error( [
                            '    %s (phase %s, type %s)', $module, $phase, $type
                        ] );
                    };
                } );
                $self->abort_if_error();
            } ],
        } ],

        [ 'CheckPrereqsIndexed'   ],    # Make sure all prereqs are published in CPAN.

        [ 'CheckChangesHasContent' ],

        $self->spellchecker ? (
            [ 'Hook::BeforeRelease' => 'spellcheck changes' => {
                'hook' => [ q{
                    $self->log( 'spellchecking Changes' );
                    use File::pushd;
                    my $wd = pushd( $zilla->built_in );
                    #
                    #   Run spellchecker, collect list of unknown words.
                    #
                    use IPC::Run3;
                    my @list;
                    run3( '} . $self->spellchecker . q{', 'Changes', \@list );
                    if ( $? > 0 ) {
                        $self->abort();
                    };
                    chomp( @list );
                    #
                    #   Steal list of words to ignore from `PodSpelling` plugin.
                    #
                    my $podspelling = $zilla->plugin_named( '} . $name . q{/Test::PodSpelling' );
                    my %ignore = map( { $_ => 1 } @{ $podspelling->stopwords } );
                    #
                    #   Add all module names.
                    #
                    my $prereqs = $dist->prereqs->cpan_meta_prereqs;
                    for my $phase ( $prereqs->__legal_phases ) {
                    for my $type  ( $prereqs->__legal_types  ) {
                        my $reqs = $prereqs->requirements_for( $phase, $type ) or next;
                        for my $module ( keys( %{ $reqs->{ requirements } } ) ) {
                            $ignore{ $_ } = 1 for split( '::', $module );
                        };
                    };
                    };
                    #
                    #   Build maps: word => count and count => word.
                    #
                    my %w2c;  # word => count
                    $w2c{ $_ } += 1 for grep( { not $ignore{ $_ } and not $ignore{ lc( $_ ) } } @list );
                    my %c2w;   # count => word
                    push( @{ $c2w{ $w2c{ $_ } } }, $_ ) for keys( %w2c );
                    #
                    #   Now print the list of spelling errors.
                    #
                    for my $count ( sort( { $b <=> $a } keys( %c2w ) ) ) {
                        printf( "%2d: %s\n", $count, join( ', ', sort( @{ $c2w{ $count } } ) ) );
                    };
                    if ( %w2c ) {
                        $self->abort( 'spelling errors found in Changes' );
                    };
                } ],
            } ],
        ) : (
        ),

        [ 'Author::VDB::Hg::Tag::Check', ],

        [ 'Author::VDB::Hg::Status', ],

        $self->local_release ? (
            [ 'Hook::BeforeRelease' => 'release note' => {
                'hook' => [ q{
                    $self->log( '*** Preparing to *local* release ***' );
                } ],
            } ],
        ) : (
        ),
        [ 'ConfirmRelease' ],       # Ask confirmation before uploading the release.

        [ 'Hook::Releaser' => 'tgz' => {
            'hook' => [ q{
                $MY::tgz = $arg;
            } ],
        } ],

        #   `Archive` is a good plugin, but I need to copy, not move tarball, because I want to
        #   archive the tarball first, and then upload it to CPAN.
        $self->archive ? (
            [ 'Hook::Releaser' => 'archive release' => {
                'hook' => [ q{
                    use Path::Tiny;
                    my $tgz = path( $arg );
                    my $dir = path( "} . $self->archive . q{" );
                    $self->log( [ 'copying %s to %s', "$tgz", "$dir" ] );
                    $tgz->copy( $dir->child( $tgz->basename ) );
                } ],
            } ],
        ) : (
        ),

        $self->local_release ? (
            # No need in `FakeRelease`: we have at least one releaser, it is enough.
        ) : (
            [ 'UploadToCPAN' ],
        ),

        [ 'Author::VDB::Hg::Tag::Add', ],

        [ 'NextRelease' => {
            'format'      => '%V @ %{yyyy-MM-dd HH:mm zzz}d',
            'time_zone'   => 'UTC',
        } ],

        [ 'Author::VDB::Version::Bump', ],

        [ 'Author::VDB::Hg::Commit', {
            'files' => [
                '.hgtags',      # Changed by `Hg::Tag::Add`.
                'Changes',      # Changed by `NextRelease`.
                'VERSION',      # Changed by `Version::Bump`.
            ],
        } ],

        $self->local_release ? (
        ) : (
            [ 'Author::VDB::Hg::Push', {
                repository => $self->repository,
            } ],
        ),

        [ 'Hook::AfterRelease' => 'install' => {
            'hook' => [ q{
                use autodie ':all';
                use File::pushd;
                $self->log( [ 'installing %s-%s', $dist->name, $dist->version ] );
                my $wd = pushd( $zilla->built_in );
                system( 'cpanm', '--notest', '.' );
                    # ^ We run the tests on unpacked tarball before release, no need in running
                    #   tests one more time.
            } ],
        } ],

        [ 'Hook::AfterRelease' => 'clean' => {
            'hook' => [ q{
                $zilla->clean();
            } ],
        } ],

    );

    return;

};

__PACKAGE__->meta->make_immutable();

1;

#pod =head1 COPYRIGHT AND LICENSE
#pod
#pod Copyright (C) 2015 Van de Bugger
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
#   This file is part of perl-Dist-Zilla-PluginBundle-Author-VDB.
#
#   ------------------------------------------------------------------------------------------------

#pod =encoding UTF-8
#pod
#pod =head1 WHAT?
#pod
#pod C<Dist-Zilla-PluginBundle-Author-VDB> (or just C<@Author::VDB>) is a C<Dist-Zilla> plugin bundle used by VDB.
#pod
#pod =cut

# end of file #
#   ------------------------------------------------------------------------------------------------
#
#   doc/why.pod
#
#   This file is part of perl-Dist-Zilla-PluginBundle-Author-VDB.
#
#   ------------------------------------------------------------------------------------------------

#pod =encoding UTF-8
#pod
#pod =head1 WHY?
#pod
#pod I have published few distributions on CPAN. Every distribution have F<dist.ini> file. All the
#pod F<dist.ini> files are very similar. Maintaining multiple very similar F<dist.ini> files is boring.
#pod Plugin bundle solves the problem.
#pod
#pod =cut

# end of file #

=pod

=encoding UTF-8

=head1 NAME

Dist::Zilla::PluginBundle::Author::VDB - VDB's plugin bundle

=head1 VERSION

Version v0.11.3, released on 2016-12-21 19:58 UTC.

=head1 WHAT?

C<Dist-Zilla-PluginBundle-Author-VDB> (or just C<@Author::VDB>) is a C<Dist-Zilla> plugin bundle used by VDB.

=head1 DESCRIPTION

It is unlikely that someone else will want to use it, so I will not bother with documenting it, at
least for now.

=head1 OBJECT METHODS

=head2 mvp_multivalue_args

=head2 _quote

Convert an attribute to a form suitable for using in source. C<Str> attribute is converted into a
string literal, C<ArrayRef> attribute is converted to a list of string literals.

=head1 OPTIONS

=head2 minimum_perl

Desired minimum Perl version. Extra test F<minimum-version.t> fails if actually required Perl
version is greater than desired.

Optional, default value C<5.006>.

=head2 copying

Name of POD file to generate distribution F<COPYING> text file. Empty value disables generation
F<COPYING> file.

C<Str>, optional, default value C<doc/copying.pod>.

=head2 readme

Names of POD files to generate distribution F<README> text file. This is a multi-value option.
Empty values are ignored. Empty list disables generating F<README> file.

C<ArrayRef[Str]>, optional, default value C<[ 'doc/what.pod', 'doc/why.pod', 'doc/naming.pod', 'doc/forms.pod', 'doc/source.pod', 'doc/distribution.pod', 'doc/installing.pod', 'doc/hacking.pod', 'doc/documentation.pod', 'doc/feedback.pod', 'doc/glossary.pod' ]>.

=head2 local_release

If true, release will be a local one, i. e. no external operations will be done: C<UploadToCPAN>
and C<hg push> will be skipped, <hg tag> will create a local tag.

Option can be set trough F<dist.ini> file or with C<DZIL_LOCAL_RELEASE> environment variable.

Optional, default value is 0.

=head2 archive

Directory to archive files to. If empty, release will not be archived. If such directory does not
exist, it will be created before release.

Optional, default value C<".releases">.

=head2 templates

This option will be passed to C<Templates> plugin. If you no not want C<Templates> to process
files, specify C<:NoFiles>. This is multi-value option (i. e. may be specified several times).

Optional, default value C<[ ':InstallModules' ]>.

=head2 unwanted_module

=head2 unwanted_modules

C<Data::Printer> is a great module for debugging. But sometimes I forget to remove debug statements
from the code before release. This option helps to check it.

If any of enlisted modules appears in the distribution dependencies, release will be aborted.

Default value C<[ qw{ DDP Data::Printer } ]>.

=head2 spellchecker

Command to run spellchecker. Spellchecker command is expected to read text from stdin, and print to
stdout misspelled words. If empty, spellchecking will be skipped. This option affects
C<Test::PodSpelling> plugin and internally implemented checking the F<Changes> file.

Optional, default value C<aspell list -l en -p ./xt/aspell-en.pws>.

=head2 repository

Mercurial repository to push changes after release to. Option may be specified multiple times to
push changes into several repositories. By default changes are pushed to one repository C<default>.

=head2 installer

Installer plugin.

Default value C<'ModuleBuildTiny'>.

=head1 WHY?

I have published few distributions on CPAN. Every distribution have F<dist.ini> file. All the
F<dist.ini> files are very similar. Maintaining multiple very similar F<dist.ini> files is boring.
Plugin bundle solves the problem.

=for Pod::Coverage configure

=head1 AUTHOR

Van de Bugger <van.de.bugger@gmail.com>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2015 Van de Bugger

License GPLv3+: The GNU General Public License version 3 or later
<http://www.gnu.org/licenses/gpl-3.0.txt>.

This is free software: you are free to change and redistribute it. There is
NO WARRANTY, to the extent permitted by law.

=cut

__DATA__

__[ not a real section, just a comment ]__

#   `perldoc` interprets POD even after `__DATA__`, so module documentation will include all the
#   sections below. To avoid this undesired behavour, prepend each POD directive with backslash —
#   it will be stripped by `Data::Section`.

__[ doc/copying.pod ]__

\=encoding UTF-8

\=head1 COPYRIGHT AND LICENSE

{{$dist->license->notice();}}

C<perl-{{$MY::name}}> I<distribution> may contain files generated by C<Dist-Zilla> and/or its
plugins from third-party templates; copyright and license specified above are I<not> applicable to
that files.

\=cut

__[ doc/distribution.pod ]__

\=encoding UTF-8

\=head1 DISTRIBUTION

C<{{$MY::name}}> distributions are published on L<CPAN|{{$MY::metacpan}}>.

\=head2 Generated Files

Distribution may contain files preprocessed or generated by C<Dist-Zilla> and its plugins. Some
generated files are made from C<{{$MY::name}}> source, but some are generated from
third-party templates. Files generated from third-party templates usually include a comment near
the top of the file:

    This file was generated with NAME

(where I<NAME> is a name of the plugin generated the file). Such files are I<not> part of
C<{{$MY::name}}> source, and C<{{$MY::name}}> copyright and license are not applicable
to such files.

\=cut

__[ doc/documentation.pod ]__

\=encoding UTF-8

\=head1 DOCUMENTATION

\=head2 Online

The easiest way is browsing the documentation L<online at meta::cpan|{{$MY::metacpan}}>.

\=head2 Locally Installed

If you have the distribution installed, use C<perldoc> tool to browse locally
installed documentation:

    $ perldoc {{$MY::package}}::Manual
    $ perldoc {{$MY::package}}

\=head2 Built from Source

Build C<{{$MY::name}}> first (see L</"HACKING">), then:

    $ cd {{$MY::name}}-VERSION
    $ perldoc {{$MY::package}}::Manual
    $ perldoc {{$MY::package}}

where I<VERSION> is a version of built distribution.

\=cut

__[ doc/feedback.pod ]__

\=encoding UTF-8

\=head1 FEEDBACK

\=head2 CPAN Request Tracker

The quickest way to report a bug in C<{{$MY::name}}> is by sending email to
bug-{{$MY::name}} [at] rt.cpan.org.

CPAN request tracker can be used via web interface also:

\=over

\=item L<Browse bugs|{{$MY::cpan_rt_browse}}>

Browsing bugs does not require authentication.

\=item L<Report bugs|{{$MY::cpan_rt_report}}>

You need to be a CPAN author, have a L<BitCard|https://www.bitcard.org/> account, or OpenID in
order to report bugs via the web interface.

(On 2015-04-27 I have logged in successfully with my LiveJournal OpenID, but my Google OpenID did
not work for CPAN. I did not check other OpenID providers.)

\=back

\=head2 Send Email to Author

As a last resort, send email to author: {{$MY::author}}. Please start message subject with
"perl-{{$MY::name}}:".

\=cut

__[ doc/forms.pod ]__

\=encoding UTF-8

\=head1 FORMS

You may face C<{{$MY::name}}> in I<source> or I<distribution> forms.

If you are going to {{$MY::abstract}}, you will likely be interested in I<using>
C<{{$MY::name}}> I<distribution>. If you are going to I<develop> (or I<hack>) the
C<{{$MY::name}}> itself, you will likely need the I<source>, not distribution.

Since Perl is an interpreting language, modules in the distribution I<look> like sources. Actually,
they are Perl source files. But they are not I<actual> sources, because they are I<built>
(preprocessed or generated) by L<Dist-Zilla>.

How to distinguish source and distribution:

\=over

\=item *

Source may contain Mercurial files and directories F<.hgignore>, F<.hgtags>, F<.hg/>, while
distribution should not.

\=item *

Source should contain F<dist.ini> file, while distribution may not.

\=item *

Source should I<not> contain F<xt/> directory, while distribution should.

\=item *

Name of source directory does I<not> include version (e. g. C<{{$MY::name}}>), while name of
distribution does (e. g. C<{{$MY::name}}-v0.7.1>).

\=back

\=cut

__[ doc/glossary.pod ]__

\=encoding UTF-8

\=head1 GLOSSARY

\=over

\=item CPAN

Comprehensive Perl Archive Network, a B<large> collection of Perl software and documentation. See
L<cpan.org|http://www.cpan.org>, L<What is
CPAN?|http://www.cpan.org/misc/cpan-faq.html#What_is_CPAN>.

\=item Distribution

Tarball, containing Perl modules and accompanying files (documentation, metainfo, tests). Usually
distributions are uploaded to CPAN, and can be installed with dedicated tools (C<cpan>, C<cpanm>,
and others).

\=item Module

Perl library file, usually with C<.pm> suffix. Usually contains one package. See
L<perlmod|http://perldoc.perl.org/perlmod.html#Perl-Modules>.

\=item Package

Perl language construct. See L<package|http://perldoc.perl.org/functions/package.html> and
L<perlmod|http://perldoc.perl.org/perlmod.html#Packages>.

\=back

\=cut

__[ doc/hacking.pod ]__

\=encoding UTF-8

\=head1 HACKING

For hacking, you will need Mercurial, Perl interpreter and C<Dist-Zilla> (with some plugins), and
likely C<cpanm> to install missed parts.

Clone the repository first:

    $ {{$MY::repo_clone}}
    $ cd perl-{{$MY::name}}

To build a distribution from the source, run:

    $ dzil build

If required C<Dist-Zilla> plugins are missed, the C<dzil> tool will warn you and show the command
to install all the required plugins, e. g.:

    Required plugin Dist::Zilla::Plugin::Test::EOL isn't installed.

    Run 'dzil authordeps' to see a list of all required plugins.
    You can pipe the list to your CPAN client to install or update them:

        dzil authordeps --missing | cpanm

To run the tests (to check primary software functionality):

    $ dzil test

To run extended tests (to check source code style, documentation and other things which are not too
important for software end users):

    $ dzil xtest

To install the distribution:

    $ dzil install

or

    $ cpanm ./{{$MY::name}}-VERSION.tar.gz

where I<VERSION> is a version of built distribution.

To clean the directory:

    $ dzil clean

\=cut

__[ doc/installing.pod ]__

\=encoding UTF-8

\=head1 INSTALLING

\=head2 With C<cpanm>

C<cpanm> tool is (probably) the easiest way to install distribution. It automates downloading,
building, testing, installing, and uninstalling.

To install the latest version from CPAN:

    $ cpanm {{$MY::package}}

To install a specific version (e. g. I<v0.7.1>) from CPAN:

    $ cpanm {{$MY::package}}@v0.7.1

To install locally available distribution (e. g. previously downloaded from CPAN or built from
sources):

    $ cpanm ./{{$MY::name}}-v0.7.1.tar.gz

To uninstall the distribution:

    $ cpanm -U {{$MY::package}}

\=head2 Manually

To install distribution tarball manually (let us assume you have version I<v0.7.1> of the
distribution):

    $ tar xaf {{$MY::name}}-v0.7.1.tar.gz
    $ cd {{$MY::name}}-v0.7.1
    $ perl Build.PL
    $ ./Build build
    $ ./Build test
    $ ./Build install

\=head2 See Also

L<How to install CPAN modules|http://www.cpan.org/modules/INSTALL.html>

\=cut

__[ doc/naming.pod ]__

\=encoding UTF-8

\=head1 NAMING

C<perl-{{$MY::name}}> is official software name.

However, in Perl world prefix "perl-" is redundant and not used. For example, on
L<meta::cpan|https://metacpan.org/> this software is named as C<{{$MY::name}}>. In the rest
of the documentation shortened name C<{{$MY::name}}> is used as synonym for full name
C<perl-{{$MY::name}}>. We are in the Perl world, aren't we?

You may notice that name may be spelled with dashes (C<{{$MY::name}}>) or with double colons
(C<{{$MY::package}}>). Strictly speaking, there is difference: the first one is software
name, while the second is name of Perl package, but often these names are interchangeable
especially if software consists of single package.

\=cut

__[ doc/source.pod ]__

\=encoding UTF-8

\=head1 SOURCE

C<{{$MY::name}}> source is in Mercurial repository hosted on {{$MY::repo_host}}.
{{$MY::repo_web ? "You can either L<browse the source online|{{$MY::repo_web}}> or " : "To
"}} clone the entire repository:

    $ {{$MY::repo_clone}}

\=head2 Source Files

C<{{$MY::name}}> source files usually include a comment near the top of the file:

    This file is part of perl-{{$MY::name}}.

Not all source files are included into distribution. Some source files are used at distribution
build time only, and not required for installation.

\=cut

__END__

# end of file #
