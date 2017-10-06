package Dist::Zilla::Plugin::Author::SKIRMESS::RepositoryBase;

use 5.006;
use strict;
use warnings;

our $VERSION = '0.024';

use Moose;

with(
    'Dist::Zilla::Role::BeforeBuild',
    'Dist::Zilla::Role::FileFinderUser' => {
        method           => 'found_module_files',
        finder_arg_names => ['module_finder'],
        default_finders  => [':InstallModules'],
    },
    'Dist::Zilla::Role::FileFinderUser' => {
        method           => 'found_script_files',
        finder_arg_names => ['script_finder'],
        default_finders  => [':PerlExecFiles'],
    },
    'Dist::Zilla::Role::FileMunger',
    'Dist::Zilla::Role::TextTemplate',
);

sub mvp_multivalue_args { return (qw( skip stopwords travis_ci_ignore_perl )) }

has skip => (
    is      => 'ro',
    isa     => 'Maybe[ArrayRef]',
    default => sub { [] },
);

has stopwords => (
    is      => 'ro',
    isa     => 'Maybe[ArrayRef]',
    default => sub { [] },
);

has travis_ci_ignore_perl => (
    is      => 'ro',
    isa     => 'Maybe[ArrayRef]',
    default => sub { [] },
);

has _travis_available_perl => (
    is      => 'ro',
    isa     => 'ArrayRef[Str]',
    default => sub { [qw(5.26 5.24 5.22 5.20 5.18 5.16 5.14 5.12 5.10 5.8)] },
    traits  => ['Array'],
);

use Carp;
use Config::Std { def_sep => q{=} };
use File::Spec;
use List::MoreUtils qw(uniq);
use Path::Tiny;

use namespace::autoclean;

sub before_build {
    my ($self) = @_;

    # Files must exist during the "gather files" phase and therefore we're
    # forced to create them in the "before build" phase.
    $self->_write_files();

    return;
}

sub munge_files {
    my ($self) = @_;

    # Files are already generated in the before build phase.

    # This module is part of the Author::SKIRMESS plugin bundle. The bundle
    # is either used to release itself, but also to release other
    # distributions. We must know which kind of build the current build is
    # because if we build another distribution we are done, the files were
    # already correctly generated during the "before build" phase.
    #
    # But if we are using the bundle to release itself we have to recreate
    # the generated files because the new version of this plugin was not
    # known during the "before build" phase.
    #
    # If __FILE__ is inside lib of the cwd we are run with Bootstrap::lib
    # which means we are building the bundle. Otherwise we use the bundle to
    # build another distribution.
    if ( exists $ENV{DZIL_RELEASING} && path('lib')->realpath->subsumes( path(__FILE__)->realpath() ) ) {

        # Ok, we are releasing the bundle itself. That means that $VERSION of
        # this module is not set correctly as the module was require'd before
        # the $VERSION was adjusted in the file (during the "munge files"
        # phase). We have to fix this now to write the correct version to the
        # generated files.

        # NOTE: Just a reminder if someone wants to refactor this module.
        # $self->zilla->version() must not be called in the "before build"
        # phase because it calls _build_version which is going to fail the
        # build. Besides that, VersionFromMainModule is run during the
        # "munge files" phase and before that we can't even know the new
        # version of the bundle.

        ## no critic (ValuesAndExpressions::RequireConstantVersion)
        ## no critic (Variables::ProhibitLocalVars)
        local $VERSION = $self->zilla->version;

        # re-write all generated files
        $self->_write_files();

        return;
    }

    # We are building, or releasing something else - not the bundle itself.

    # We always have to write t/00-load.t during the munge files phase
    # because this file is not created correctly during the before
    # build phase because the FileFinderUser isn't initialized that
    # early
    $self->_write_file('t/00-load.t');
    return;
}

sub _write_files {
    my ($self) = @_;

    my %file_to_skip = map { $_ => 1 } grep { defined && !m{ ^ \s* $ }xsm } @{ $self->skip };

  FILE:
    for my $file ( sort $self->files() ) {
        if ( exists $file_to_skip{$file} ) {
            next FILE;
        }

        $self->_write_file($file);
    }

    return;
}

sub _write_file {
    my ( $self, $file ) = @_;

    $file = path($file);

    if ( -e $file ) {
        $file->remove();
    }
    else {
        # If the file does not yet exist, the basedir might also not
        # exist. Create it if required.
        my $parent = $file->parent();
        if ( !-e $parent ) {
            $self->log("Creating directory $parent");
            $parent->mkpath();
        }
    }

    $self->log("Generate file $file");

    # write the file to disk
    $file->spew( $self->file($file) );

    return;
}

=pod

=encoding UTF-8

=head1 NAME

Dist::Zilla::Plugin::Author::SKIRMESS::RepositoryBase - Automatically create and update files

=head1 VERSION

Version 0.024

=head1 SYNOPSIS

This plugin is part of the
L<Dist::Zilla::PluginBundle::Author::SKIRMESS|Dist::Zilla::PluginBundle::Author::SKIRMESS>
bundle and should not be used outside of that.

=head1 DESCRIPTION

This plugin creates a collection of files that are shared between all my
CPAN distributions which makes it easy to keep them all up to date.

The following files are created in the repository and in the distribution:

=cut

{
    # Files to generate
    my %file;

    sub files {
        my ($self) = @_;

        return keys %file;
    }

    sub file {
        my ( $self, $filename ) = @_;

        if ( !exists $file{$filename} ) {
            $self->log_fatal("File '$filename' is not defined");

            # log_fatal should die
            croak 'internal error';
        }

        my $file_content = $file{$filename};
        if ( ref $file_content eq ref sub { } ) {
            $file_content = $file_content->($self);
        }

        # process the file template
        return $self->fill_in_string(
            $file_content,
            {
                plugin => \$self,
            }
        );
    }

=head2 .perlcriticrc

The configuration for L<Perl::Critic|Perl::Critic>. This file is created from
a default contained in this plugin and from distribution specific settings in
F<perlcriticrc.local>.

=cut

    $file{q{.perlcriticrc}} = sub {
        my ($self) = @_;

        my $perlcriticrc_template = <<'PERLCRITICRC_TEMPLATE';
# Automatically generated file
# {{ ref $plugin }} {{ $plugin->VERSION() }}

severity = 1
only = 1

[BuiltinFunctions::ProhibitBooleanGrep]
[BuiltinFunctions::ProhibitComplexMappings]
[BuiltinFunctions::ProhibitLvalueSubstr]
[BuiltinFunctions::ProhibitReverseSortBlock]
[BuiltinFunctions::ProhibitSleepViaSelect]
[BuiltinFunctions::ProhibitStringyEval]
[BuiltinFunctions::ProhibitStringySplit]
[BuiltinFunctions::ProhibitUniversalCan]
[BuiltinFunctions::ProhibitUniversalIsa]
[BuiltinFunctions::ProhibitUselessTopic]
[BuiltinFunctions::ProhibitVoidGrep]
[BuiltinFunctions::ProhibitVoidMap]
[BuiltinFunctions::RequireBlockGrep]
[BuiltinFunctions::RequireBlockMap]
[BuiltinFunctions::RequireGlobFunction]
[BuiltinFunctions::RequireSimpleSortBlock]
[ClassHierarchies::ProhibitAutoloading]
[ClassHierarchies::ProhibitExplicitISA]
[ClassHierarchies::ProhibitOneArgBless]
[CodeLayout::ProhibitHardTabs]
[CodeLayout::ProhibitParensWithBuiltins]
[CodeLayout::ProhibitQuotedWordLists]
[CodeLayout::ProhibitTrailingWhitespace]
[CodeLayout::RequireConsistentNewlines]
[CodeLayout::RequireTidyCode]
[CodeLayout::RequireTrailingCommas]
[ControlStructures::ProhibitCStyleForLoops]
[ControlStructures::ProhibitCascadingIfElse]
[ControlStructures::ProhibitDeepNests]
[ControlStructures::ProhibitLabelsWithSpecialBlockNames]
[ControlStructures::ProhibitMutatingListFunctions]
[ControlStructures::ProhibitNegativeExpressionsInUnlessAndUntilConditions]
[ControlStructures::ProhibitPostfixControls]
[ControlStructures::ProhibitUnlessBlocks]
[ControlStructures::ProhibitUnreachableCode]
[ControlStructures::ProhibitUntilBlocks]
[ControlStructures::ProhibitYadaOperator]
[Documentation::PodSpelling]
[Documentation::RequirePackageMatchesPodName]
[Documentation::RequirePodAtEnd]
[Documentation::RequirePodLinksIncludeText]
[ErrorHandling::RequireCarping]
[ErrorHandling::RequireCheckingReturnValueOfEval]
[InputOutput::ProhibitBacktickOperators]
[InputOutput::ProhibitBarewordFileHandles]
[InputOutput::ProhibitExplicitStdin]
[InputOutput::ProhibitInteractiveTest]
[InputOutput::ProhibitJoinedReadline]
[InputOutput::ProhibitOneArgSelect]
[InputOutput::ProhibitReadlineInForLoop]
[InputOutput::ProhibitTwoArgOpen]
[InputOutput::RequireBracedFileHandleWithPrint]
[InputOutput::RequireCheckedClose]
[InputOutput::RequireCheckedOpen]
[InputOutput::RequireCheckedSyscalls]
[InputOutput::RequireEncodingWithUTF8Layer]
[Miscellanea::ProhibitFormats]
[Miscellanea::ProhibitTies]
[Miscellanea::ProhibitUnrestrictedNoCritic]
[Miscellanea::ProhibitUselessNoCritic]
[Modules::ProhibitAutomaticExportation]
[Modules::ProhibitConditionalUseStatements]
[Modules::ProhibitEvilModules]
[Modules::ProhibitMultiplePackages]
[Modules::RequireBarewordIncludes]
[Modules::RequireEndWithOne]
[Modules::RequireExplicitPackage]
[Modules::RequireFilenameMatchesPackage]
[Modules::RequireNoMatchVarsWithUseEnglish]
[NamingConventions::Capitalization]
[NamingConventions::ProhibitAmbiguousNames]
[Objects::ProhibitIndirectSyntax]
[References::ProhibitDoubleSigils]
[RegularExpressions::ProhibitCaptureWithoutTest]
[RegularExpressions::ProhibitComplexRegexes]
[RegularExpressions::ProhibitEnumeratedClasses]
[RegularExpressions::ProhibitEscapedMetacharacters]
[RegularExpressions::ProhibitFixedStringMatches]
[RegularExpressions::ProhibitSingleCharAlternation]
[RegularExpressions::ProhibitUnusedCapture]
[RegularExpressions::ProhibitUnusualDelimiters]
[RegularExpressions::ProhibitUselessTopic]
[RegularExpressions::RequireBracesForMultiline]
[RegularExpressions::RequireDotMatchAnything]
[RegularExpressions::RequireExtendedFormatting]
[RegularExpressions::RequireLineBoundaryMatching]
[Subroutines::ProhibitAmpersandSigils]
[Subroutines::ProhibitBuiltinHomonyms]
[Subroutines::ProhibitExcessComplexity]
[Subroutines::ProhibitExplicitReturnUndef]
[Subroutines::ProhibitManyArgs]
[Subroutines::ProhibitNestedSubs]
[Subroutines::ProhibitReturnSort]
[Subroutines::ProhibitSubroutinePrototypes]
[Subroutines::ProhibitUnusedPrivateSubroutines]
private_name_regex = _(?!build_)\w+
[Subroutines::ProtectPrivateSubs]
[Subroutines::RequireArgUnpacking]
[Subroutines::RequireFinalReturn]
[TestingAndDebugging::ProhibitNoStrict]
[TestingAndDebugging::ProhibitNoWarnings]
[TestingAndDebugging::ProhibitProlongedStrictureOverride]
[TestingAndDebugging::RequireTestLabels]
[TestingAndDebugging::RequireUseStrict]
[TestingAndDebugging::RequireUseWarnings]
[ValuesAndExpressions::ProhibitCommaSeparatedStatements]
[ValuesAndExpressions::ProhibitComplexVersion]
[ValuesAndExpressions::ProhibitConstantPragma]
[ValuesAndExpressions::ProhibitEmptyQuotes]
[ValuesAndExpressions::ProhibitEscapedCharacters]
[ValuesAndExpressions::ProhibitImplicitNewlines]
[ValuesAndExpressions::ProhibitInterpolationOfLiterals]
[ValuesAndExpressions::ProhibitLeadingZeros]
[ValuesAndExpressions::ProhibitLongChainsOfMethodCalls]
[ValuesAndExpressions::ProhibitMagicNumbers]
[ValuesAndExpressions::ProhibitMismatchedOperators]
[ValuesAndExpressions::ProhibitMixedBooleanOperators]
[ValuesAndExpressions::ProhibitNoisyQuotes]
[ValuesAndExpressions::ProhibitQuotesAsQuotelikeOperatorDelimiters]
[ValuesAndExpressions::ProhibitSpecialLiteralHeredocTerminator]
[ValuesAndExpressions::ProhibitVersionStrings]
[ValuesAndExpressions::RequireConstantVersion]
[ValuesAndExpressions::RequireInterpolationOfMetachars]
[ValuesAndExpressions::RequireNumberSeparators]
[ValuesAndExpressions::RequireQuotedHeredocTerminator]
[ValuesAndExpressions::RequireUpperCaseHeredocTerminator]
[Variables::ProhibitAugmentedAssignmentInDeclaration]
[Variables::ProhibitConditionalDeclarations]
[Variables::ProhibitEvilVariables]
[Variables::ProhibitLocalVars]
[Variables::ProhibitMatchVars]
[Variables::ProhibitPackageVars]
[Variables::ProhibitPerl4PackageNames]
[Variables::ProhibitPunctuationVars]
allow = $! $/
[Variables::ProhibitReusedNames]
[Variables::ProhibitUnusedVariables]
[Variables::ProtectPrivateVars]
[Variables::RequireInitializationForLocalVars]
[Variables::RequireLexicalLoopIterators]
[Variables::RequireLocalizedPunctuationVars]
[Variables::RequireNegativeIndices]

[Moose::ProhibitDESTROYMethod]
[Moose::ProhibitLazyBuild]
[Moose::ProhibitMultipleWiths]
[Moose::ProhibitNewMethod]
[Moose::RequireCleanNamespace]
[Moose::RequireMakeImmutable]
PERLCRITICRC_TEMPLATE

        # Conig::Std will not preserve a comment on the last line, therefore
        # we append at least one empty line at the end
        $perlcriticrc_template .= "\n\n";

        read_config \$perlcriticrc_template, my %perlcriticrc;

        my $perlcriticrc_local = 'perlcriticrc.local';

        if ( -f $perlcriticrc_local ) {
            $self->log("Adjusting Perl::Critic config from '$perlcriticrc_local'");

            read_config $perlcriticrc_local, my %perlcriticrc_local;

            my %local_seen = ();

          POLICY:
            for my $policy ( keys %perlcriticrc_local ) {

                if ( $policy eq q{-} ) {
                    $self->log_fatal('We cannot disable the global settings');

                    # log_fatal should die
                    croak 'internal error';
                }

                my $policy_name = $policy =~ m{ ^ - (.+) }xsm ? $1 : $policy;
                my $disable     = $policy =~ m{ ^ - . }xsm    ? 1  : 0;

                if ( exists $local_seen{$policy_name} ) {
                    $self->log_fatal("There are multiple entries for policy '$policy_name' in '$perlcriticrc_local'.");

                    # log_fatal should die
                    croak 'internal error';
                }

                $local_seen{$policy_name} = 1;

                delete $perlcriticrc{$policy_name};

                if ( $policy =~ m{ ^ - }xsm ) {
                    $self->log("Disabling policy '$policy_name'");
                    next POLICY;
                }

                if ( $policy eq q{} ) {
                    $self->log('Custom global settings');
                }
                else {
                    $self->log("Custom configuration for policy '$policy_name'");
                }

                $perlcriticrc{$policy_name} = $perlcriticrc_local{$policy_name};
            }
        }

        if ( ( !exists $perlcriticrc{q{}}{only} ) or ( $perlcriticrc{q{}}{only} ne '1' ) ) {
            $self->log(q{Setting global option 'only' back to '1'});
            $perlcriticrc{q{}}{only} = '1';
        }

        my $content;
        write_config %perlcriticrc, \$content;

        return $content;
    };

=head2 .perltidyrc

The configuration file for B<perltidy>.

=cut

    $file{q{.perltidyrc}} = <<'PERLTIDYRC';
# Automatically generated file
# {{ ref $plugin }} {{ $plugin->VERSION() }}

--maximum-line-length=0
--break-at-old-comma-breakpoints
--backup-and-modify-in-place
--output-line-ending=unix
PERLTIDYRC

=head2 .travis.yml

The configuration file for TravisCI. All known supported Perl versions are
enabled unless disabled with B<travis_ci_ignore_perl>.

=cut

    $file{q{.travis.yml}} = sub {
        my ($self) = @_;

        my $travis_yml = <<'TRAVIS_YML_1';
# Automatically generated file
# {{ ref $plugin }} {{ $plugin->VERSION() }}

language: perl
perl:
TRAVIS_YML_1

        my %perl;
        @perl{ @{ $self->_travis_available_perl } } = ();
        if ( @{ $self->travis_ci_ignore_perl } ) {
            delete @perl{ @{ $self->travis_ci_ignore_perl } };
        }
        my @perl = reverse sort keys %perl;

        croak "No perl versions selected for TravisCI\n" if !@perl;

        for my $perl (@perl) {
            $travis_yml .= "  - '$perl'\n";
        }

        $travis_yml .= <<'TRAVIS_YML';
before_install:
  - export AUTOMATED_TESTING=1
install:
  - cpanm --quiet --installdeps --notest --skip-satisfied --with-develop .
script:
  - perl Makefile.PL && make test
  - test -d xt/author && prove -lr xt/author
TRAVIS_YML

        return $travis_yml;
    };

    # test header
    my $test_header = <<'_TEST_HEADER';
#!perl

use 5.006;
use strict;
use warnings;

# this test was generated with
# {{ ref $plugin }} {{ $plugin->VERSION() }}

_TEST_HEADER

=head2 t/00-load.t

Verifies that all modules and perl scripts can be compiled with require_ok
from L<Test::More|Test::More>.

=cut

    $file{q{t/00-load.t}} = sub {
        my ($self) = @_;

        my %use_lib_args = (
            lib  => undef,
            q{.} => undef,
        );

        my @modules;
      MODULE:
        for my $module ( map { $_->name } @{ $self->found_module_files() } ) {
            next MODULE if $module =~ m{ [.] pod $}xsm;

            my @dirs = File::Spec->splitdir($module);
            if ( $dirs[0] eq 'lib' && $dirs[-1] =~ s{ [.] pm $ }{}xsm ) {
                shift @dirs;
                push @modules, join q{::}, @dirs;
                $use_lib_args{lib} = 1;
                next MODULE;
            }

            $use_lib_args{q{.}} = 1;
            push @modules, $module;
        }

        my @scripts = map { $_->name } @{ $self->found_script_files() };
        if (@scripts) {
            $use_lib_args{q{.}} = 1;
        }

        my $content = $test_header . <<'T_OO_LOAD_T';
use Test::More;

T_OO_LOAD_T

        if ( !@scripts && !@modules ) {
            $content .= qq{BAIL_OUT("No files found in distribution");\n};

            return $content;
        }

        $content .= 'use lib qw(';
        if ( defined $use_lib_args{lib} ) {
            if ( defined $use_lib_args{q{.}} ) {
                $content .= 'lib .';
            }
            else {
                $content .= 'lib';
            }
        }
        else {
            $content .= q{.};
        }
        $content .= ");\n\n";

        $content .= "my \@modules = qw(\n";

        for my $module ( @modules, @scripts ) {
            $content .= "  $module\n";
        }
        $content .= <<'T_OO_LOAD_T';
);

plan tests => scalar @modules;

for my $module (@modules) {
    require_ok($module) || BAIL_OUT();
}
T_OO_LOAD_T

        return $content;
    };

=head2 xt/author/clean-namespaces.t

L<Test::CleanNamespaces|Test::CleanNamespaces> author test.

=cut

    $file{q{xt/author/clean-namespaces.t}} = $test_header . <<'XT_AUTHOR_CLEAN_NAMESPACES_T';
use Test::More;
use Test::CleanNamespaces;

if ( !Test::CleanNamespaces->find_modules() ) {
    plan skip_all => 'No files found to test.';
}

all_namespaces_clean();
XT_AUTHOR_CLEAN_NAMESPACES_T

=head2 xt/author/critic.t

L<Test::Perl::Critic|Test::Perl::Critic> author test.

=cut

    $file{q{xt/author/critic.t}} = $test_header . <<'XT_AUTHOR_CRITIC_T';
use File::Spec;

use Perl::Critic::Utils qw(all_perl_files);
use Test::More;
use Test::Perl::Critic;

my @dirs = qw(bin lib t xt);

my @ignores = ();
my %file;
@file{ all_perl_files(@dirs) } = ();
delete @file{@ignores};
my @files = keys %file;

if ( @files == 0 ) {
    BAIL_OUT('no files to criticize found');
}

all_critic_ok(@files);
XT_AUTHOR_CRITIC_T

=head2 xt/author/minimum_version.t

L<Test::MinimumVersion|Test::MinimumVersion> author test.

=cut

    $file{q{xt/author/minimum_version.t}} = $test_header . <<'XT_AUTHOR_MINIMUM_VERSION_T';
use Test::MinimumVersion 0.008;

all_minimum_version_from_metayml_ok();
XT_AUTHOR_MINIMUM_VERSION_T

=head2 xt/author/mojibake.t

L<Test::Mojibake|Test::Mojibake> author test.

=cut

    $file{q{xt/author/mojibake.t}} = $test_header . <<'XT_AUTHOR_MOJIBAKE_T';
use Test::Mojibake;

all_files_encoding_ok( grep { -d } qw( bin lib t xt ) );
XT_AUTHOR_MOJIBAKE_T

=head2 xt/author/no-tabs.t

L<Test::NoTabs|Test::NoTabs> author test.

=cut

    $file{q{xt/author/no-tabs.t}} = $test_header . <<'XT_AUTHOR_NO_TABS_T';
use Test::NoTabs;

all_perl_files_ok( grep { -d } qw( bin lib t xt ) );
XT_AUTHOR_NO_TABS_T

=head2 xt/author/pod-no404s.t

L<Test::Pod::No404s|Test::Pod::No404s> author test.

=cut

    $file{q{xt/author/pod-no404s.t}} = $test_header . <<'XT_AUTHOR_POD_NO404S_T';
if ( exists $ENV{AUTOMATED_TESTING} ) {
    print "1..0 # SKIP these tests during AUTOMATED_TESTING\n";
    exit 0;
}

use Test::Pod::No404s;

all_pod_files_ok();
XT_AUTHOR_POD_NO404S_T

=head2 xt/author/pod-spell.t

L<Test::Spelling|Test::Spelling> author test. B<stopwords> are added as stopwords.

=cut

    $file{q{xt/author/pod-spell.t}} = sub {
        my ($self) = @_;

        my $content = $test_header . <<'XT_AUTHOR_POD_SPELL_T';
use Test::Spelling 0.12;
use Pod::Wordlist;

add_stopwords(<DATA>);

all_pod_files_spelling_ok( grep { -d } qw( bin lib t xt ) );
__DATA__
XT_AUTHOR_POD_SPELL_T

        my @stopwords = grep { defined && !m{ ^ \s* $ }xsm } @{ $self->stopwords };
        push @stopwords, split /\s/xms, join q{ }, @{ $self->zilla->authors };

        $content .= join "\n", uniq( sort @stopwords ), q{};

        return $content;
    };

=head2 xt/author/pod-syntax.t

L<Test::Pod|Test::Pod> author test.

=cut

    $file{q{xt/author/pod-syntax.t}} = $test_header . <<'XT_AUTHOR_POD_SYNTAX_T';
use Test::Pod 1.26;

all_pod_files_ok( grep { -d } qw( bin lib t xt) );
XT_AUTHOR_POD_SYNTAX_T

=head2 xt/author/portability.t

L<Test::Portability::Files|Test::Portability::Files> author test.

=cut

    $file{q{xt/author/portability.t}} = $test_header . <<'XT_AUTHOR_PORTABILITY_T';
BEGIN {
    if ( !-f 'MANIFEST' ) {
        print "1..0 # SKIP No MANIFEST file\n";
        exit 0;
    }
}

use Test::Portability::Files;

options( test_one_dot => 0 );
run_tests();
XT_AUTHOR_PORTABILITY_T

=head2 xt/author/test-version.t

L<Test::Version|Test::Version> author test.

=cut

    $file{q{xt/author/test-version.t}} = $test_header . <<'XT_AUTHOR_TEST_VERSION_T';
use Test::More 0.88;
use Test::Version 0.04 qw( version_all_ok ), {
    consistent  => 1,
    has_version => 1,
    is_strict   => 0,
    multiple    => 0,
};

version_all_ok;
done_testing();
XT_AUTHOR_TEST_VERSION_T

=head2 xt/release/changes.t

L<Test::CPAN::Changes|Test::CPAN::Changes> release test.

=cut

    $file{q{xt/release/changes.t}} = $test_header . <<'XT_RELEASE_CHANGES_T';
use Test::CPAN::Changes;

changes_ok();
XT_RELEASE_CHANGES_T

=head2 xt/release/distmeta.t

L<Test::CPAN::Meta|Test::CPAN::Meta> release test.

=cut

    $file{q{xt/release/distmeta.t}} = $test_header . <<'XT_RELEASE_DISTMETA_T';
use Test::CPAN::Meta;

meta_yaml_ok();
XT_RELEASE_DISTMETA_T

=head2 xt/release/eol.t

L<Test::EOL|Test::EOL> release test.

=cut

    $file{q{xt/release/eol.t}} = $test_header . <<'XT_RELEASE_EOL_T';
use Test::EOL;

all_perl_files_ok( { trailing_whitespace => 1 }, grep { -d } qw( bin lib t xt) );
XT_RELEASE_EOL_T

=head2 xt/release/kwalitee.t

L<Test::Kwalitee|Test::Kwalitee> release test.

=cut

    $file{q{xt/release/kwalitee.t}} = $test_header . <<'XT_RELEASE_KWALITEE_T';
use Test::More 0.88;
use Test::Kwalitee 'kwalitee_ok';

# Module::CPANTS::Analyse does not find the LICENSE in scripts that don't end in .pl
kwalitee_ok(qw{-has_license_in_source_file -has_abstract_in_pod});

done_testing();
XT_RELEASE_KWALITEE_T

=head2 xt/release/manifest.t

L<Test::DistManifest|Test::DistManifest> release test.

=cut

    $file{q{xt/release/manifest.t}} = $test_header . <<'XT_RELEASE_MANIFEST_T';
use Test::DistManifest 1.003;

manifest_ok();
XT_RELEASE_MANIFEST_T

=head2 xt/release/meta-json.t

L<Test::CPAN::Meta::JSON|Test::CPAN::Meta::JSON> release test.

=cut

    $file{q{xt/release/meta-json.t}} = $test_header . <<'XT_RELEASE_META_JSON_T';
use Test::CPAN::Meta::JSON;

meta_json_ok();
XT_RELEASE_META_JSON_T

=head2 xt/release/meta-yaml.t

L<Test::CPAN::Meta|Test::CPAN::Meta> release test.

=cut

    $file{q{xt/release/meta-yaml.t}} = $test_header . <<'XT_RELEASE_META_YAML_T';
use Test::CPAN::Meta 0.12;

meta_yaml_ok();
XT_RELEASE_META_YAML_T
}

__PACKAGE__->meta->make_immutable;

1;

__END__

=head1 USAGE

The following configuration options are supported:

=over 4

=item *

C<skip> - Defines files to be skipped (not generated).

=item *

C<stopwords> - Defines stopwords for the spell checker.

=item *

C<travis_ci_ignore_perl> - By default, the generated F<.travis.yml> file
runs on all Perl version known to exist on TravisCI. Use the
C<travis_ci_ignore_perl> option to define Perl versions to not check.

=back

=head1 SUPPORT

=head2 Bugs / Feature Requests

Please report any bugs or feature requests through the issue tracker
at L<https://github.com/skirmess/Dist-Zilla-PluginBundle-Author-SKIRMESS/issues>.
You will be notified automatically of any progress on your issue.

=head2 Source Code

This is open source software. The code repository is available for
public review and contribution under the terms of the license.

L<https://github.com/skirmess/Dist-Zilla-PluginBundle-Author-SKIRMESS>

  git clone https://github.com/skirmess/Dist-Zilla-PluginBundle-Author-SKIRMESS.git

=head1 AUTHOR

Sven Kirmess <sven.kirmess@kzone.ch>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2017 by Sven Kirmess.

This is free software, licensed under:

  The (two-clause) FreeBSD License

=head1 SEE ALSO

L<Dist::Zilla::PluginBundle::Author::SKIRMESS|Dist::Zilla::PluginBundle::Author::SKIRMESS>

=cut

# vim: ts=4 sts=4 sw=4 et: syntax=perl
