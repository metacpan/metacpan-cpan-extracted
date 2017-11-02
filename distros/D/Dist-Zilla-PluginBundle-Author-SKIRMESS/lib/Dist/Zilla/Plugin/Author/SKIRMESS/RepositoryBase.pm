package Dist::Zilla::Plugin::Author::SKIRMESS::RepositoryBase;

use 5.006;
use strict;
use warnings;

our $VERSION = '0.031';

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

sub mvp_multivalue_args { return (qw( skip stopwords travis_ci_ignore_perl travis_ci_no_author_testing_perl travis_ci_osx_perl )) }

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

has travis_ci_no_author_testing_perl => (
    is      => 'ro',
    isa     => 'Maybe[ArrayRef]',
    default => sub { [qw(5.8)] },
);

has travis_ci_osx_perl => (
    is      => 'ro',
    isa     => 'ArrayRef[Str]',
    default => sub { [qw(5.18)] },
);

has _travis_available_perl => (
    is      => 'ro',
    isa     => 'ArrayRef[Str]',
    default => sub { [qw( 5.8 5.10 5.12 5.14 5.16 5.18 5.20 5.22 5.24 5.26)] },
    traits  => ['Array'],
);

use Carp;
use Config::Std { def_sep => q{=} };
use File::Spec;
use List::SomeUtils qw(uniq);
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

Version 0.031

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
            },
        );
    }

=head2 .appveyor.yml

The configuration file for AppVeyor.

=cut

    $file{q{.appveyor.yml}} = <<'APPVEYOR_YML';
# Automatically generated file
# {{ ref $plugin }} {{ $plugin->VERSION() }}

skip_tags: true

cache:
  - C:\strawberry -> appveyor.yml

install:
  - if not exist "C:\strawberry" cinst strawberryperl
  - set PATH=C:\strawberry\perl\bin;C:\strawberry\perl\site\bin;C:\strawberry\c\bin;%PATH%
  - cd %APPVEYOR_BUILD_FOLDER%
  - cpanm --quiet --installdeps --notest --skip-satisfied --with-develop .

build_script:
  - perl Makefile.PL
  - gmake

test_script:
  - set AUTOMATED_TESTING=1
  - gmake test
  - prove -lr xt/author
APPVEYOR_YML

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

only = 1
severity = 1
verbose = [%p] %m at %f line %l, near '%r'\n

# ----------------------------------------------------------
# Core policies
# ----------------------------------------------------------

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
#[Documentation::PodSpelling]
[Documentation::RequirePackageMatchesPodName]
[Documentation::RequirePodAtEnd]
[Documentation::RequirePodLinksIncludeText]
#[Documentation::RequirePodSections]

[ErrorHandling::RequireCarping]
allow_in_main_unless_in_subroutine = 1

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
#[InputOutput::RequireBriefOpen]
[InputOutput::RequireCheckedClose]
[InputOutput::RequireCheckedOpen]

[InputOutput::RequireCheckedSyscalls]
functions = :builtins
exclude_functions = print say sleep

[InputOutput::RequireEncodingWithUTF8Layer]
[Miscellanea::ProhibitFormats]
[Miscellanea::ProhibitTies]
[Miscellanea::ProhibitUnrestrictedNoCritic]
[Miscellanea::ProhibitUselessNoCritic]
[Modules::ProhibitAutomaticExportation]
[Modules::ProhibitConditionalUseStatements]

[Modules::ProhibitEvilModules]
modules = Class::ISA {Found use of Class::ISA. This module is deprecated by the Perl 5 Porters.} Pod::Plainer {Found use of Pod::Plainer. This module is deprecated by the Perl 5 Porters.} Shell {Found use of Shell. This module is deprecated by the Perl 5 Porters.} Switch {Found use of Switch. This module is deprecated by the Perl 5 Porters.} Readonly {Found use of Readonly. Please use constant.pm or Const::Fast.} base {Found use of base. Please use parent instead.} File::Slurp {Found use of File::Slurp. Please use Path::Tiny instead.} common::sense {Found use of common::sense. Please use strict and warnings instead.} Class::Load {Found use of Class::Load. Please use Module::Runtime instead.} Any::Moose {Found use of Any::Moose. Please use Moo instead.} Error {Found use of Error.pm. Please use Throwable.pm instead.} Getopt::Std {Found use of Getopt::Std. Please use Getopt::Long instead.} HTML::Template {Found use of HTML::Template. Please use Template::Toolkit.} IO::Socket::INET6 {Found use of IO::Socket::INET6. Please use IO::Socket::IP.} JSON {Found use of JSON. Please use JSON::MaybeXS or Cpanel::JSON::XS.} JSON::XS {Found use of JSON::XS. Please use JSON::MaybeXS or Cpanel::JSON::XS.} JSON::Any {Found use of JSON::Any. Please use JSON::MaybeXS.} List::MoreUtils {Found use of List::MoreUtils. Please use List::Util or List::UtilsBy.} Mouse {Found use of Mouse. Please use Moo.} Net::IRC {Found use of Net::IRC. Please use POE::Component::IRC, Net::Async::IRC, or Mojo::IRC.} XML::Simple {Found use of XML::Simple. Please use XML::LibXML, XML::TreeBuilder, XML::Twig, or Mojo::DOM.} Sub::Infix {Found use of Sub::Infix. Please do not use it.}

#[Modules::ProhibitExcessMainComplexity]
[Modules::ProhibitMultiplePackages]
[Modules::RequireBarewordIncludes]
[Modules::RequireEndWithOne]
[Modules::RequireExplicitPackage]
[Modules::RequireFilenameMatchesPackage]
[Modules::RequireNoMatchVarsWithUseEnglish]
#[Modules::RequireVersionVar]
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
forbid_use_version = 1

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
allow = $@ $! $/ $0

[Variables::ProhibitReusedNames]
[Variables::ProhibitUnusedVariables]
[Variables::ProtectPrivateVars]
[Variables::RequireInitializationForLocalVars]
[Variables::RequireLexicalLoopIterators]
[Variables::RequireLocalizedPunctuationVars]
[Variables::RequireNegativeIndices]

# ----------------------------------------------------------
# Perl::Critic::Bangs
# ----------------------------------------------------------

[Bangs::ProhibitBitwiseOperators]
#[Bangs::ProhibitCommentedOutCode]
[Bangs::ProhibitDebuggingModules]
[Bangs::ProhibitFlagComments]
#[Bangs::ProhibitNoPlan]
[Bangs::ProhibitNumberedNames]
[Bangs::ProhibitRefProtoOrProto]
[Bangs::ProhibitUselessRegexModifiers]
#[Bangs::ProhibitVagueNames]

# ----------------------------------------------------------
# Perl::Critic::Moose
# ----------------------------------------------------------

[Moose::ProhibitDESTROYMethod]
equivalent_modules = Moo Moo::Role

[Moose::ProhibitLazyBuild]
equivalent_modules = Moo Moo::Role

[Moose::ProhibitMultipleWiths]
equivalent_modules = Moo Moo::Role

[Moose::ProhibitNewMethod]
equivalent_modules = Moo Moo::Role

[Moose::RequireCleanNamespace]
[Moose::RequireMakeImmutable]

# ----------------------------------------------------------
# Perl::Critic::Freenode
# ----------------------------------------------------------

[Freenode::AmpersandSubCalls]
[Freenode::ArrayAssignAref]
[Freenode::BarewordFilehandles]
[Freenode::ConditionalDeclarations]
[Freenode::ConditionalImplicitReturn]
[Freenode::DeprecatedFeatures]
[Freenode::DiscouragedModules]
[Freenode::DollarAB]
[Freenode::Each]
#[Freenode::EmptyReturn]
[Freenode::IndirectObjectNotation]
[Freenode::ModPerl]
[Freenode::OpenArgs]
[Freenode::OverloadOptions]
[Freenode::PackageMatchesFilename]
[Freenode::POSIXImports]
[Freenode::Prototypes]
[Freenode::StrictWarnings]
[Freenode::Threads]
[Freenode::Wantarray]
[Freenode::WarningsSwitch]
[Freenode::WhileDiamondDefaultAssignment]

# ----------------------------------------------------------
# Perl::Critic::Policy::HTTPCookies
# ----------------------------------------------------------

[HTTPCookies]

# ----------------------------------------------------------
# Perl::Critic::Itch
# ----------------------------------------------------------

#[CodeLayout::ProhibitHashBarewords]

# ----------------------------------------------------------
# Perl::Critic::Lax
# ----------------------------------------------------------

[Lax::ProhibitComplexMappings::LinesNotStatements]
#[Lax::ProhibitEmptyQuotes::ExceptAsFallback]
#[Lax::ProhibitLeadingZeros::ExceptChmod]
#[Lax::ProhibitStringyEval::ExceptForRequire]
#[Lax::RequireConstantOnLeftSideOfEquality::ExceptEq]
#[Lax::RequireEndWithTrueConst]
#[Lax::RequireExplicitPackage::ExceptForPragmata]

# ----------------------------------------------------------
# Perl::Critic::More
# ----------------------------------------------------------

#[CodeLayout::RequireASCII]
#[Editor::RequireEmacsFileVariables]
#[ErrorHandling::RequireUseOfExceptions]
[Modules::PerlMinimumVersion]
[Modules::RequirePerlVersion]
#[ValuesAndExpressions::RequireConstantOnLeftSideOfEquality]
#[ValuesAndExpressions::RestrictLongStrings]

# ----------------------------------------------------------
# Perl::Critic::PetPeeves::JTRAMMELL
# ----------------------------------------------------------

[Variables::ProhibitUselessInitialization]

# ----------------------------------------------------------
# Perl::Critic::Policy::BuiltinFunctions::ProhibitDeleteOnArrays
# ----------------------------------------------------------

[BuiltinFunctions::ProhibitDeleteOnArrays]

# ----------------------------------------------------------
# Perl::Critic::Policy::BuiltinFunctions::ProhibitReturnOr
# ----------------------------------------------------------

[BuiltinFunctions::ProhibitReturnOr]

# ----------------------------------------------------------
# Perl::Critic::Policy::Moo::ProhibitMakeImmutable
# ----------------------------------------------------------

[Moo::ProhibitMakeImmutable]

# ----------------------------------------------------------
# Perl::Critic::Policy::ValuesAndExpressions::ProhibitSingleArgArraySlice
# requires Perl 5.12
# ----------------------------------------------------------

#[ValuesAndExpressions::ProhibitSingleArgArraySlice]

# ----------------------------------------------------------
# Perl::Critic::Policy::Perlsecret
# ----------------------------------------------------------

[Perlsecret]

# ----------------------------------------------------------
# Perl::Critic::Policy::TryTiny::RequireBlockTermination
# ----------------------------------------------------------

[TryTiny::RequireBlockTermination]

# ----------------------------------------------------------
# Perl::Critic::Policy::TryTiny::RequireUse
# ----------------------------------------------------------

[TryTiny::RequireUse]

# ----------------------------------------------------------
# Perl::Critic::Policy::ValuesAndExpressions::PreventSQLInjection
# ----------------------------------------------------------

[ValuesAndExpressions::PreventSQLInjection]

# ----------------------------------------------------------
# Perl::Critic::Policy::Variables::ProhibitUnusedVarsStricter
# ----------------------------------------------------------

[Variables::ProhibitUnusedVarsStricter]
allow_unused_subroutine_arguments = 1

# ----------------------------------------------------------
# Perl::Critic::Pulp
# ----------------------------------------------------------

[CodeLayout::ProhibitFatCommaNewline]
#[CodeLayout::ProhibitIfIfSameLine]
[CodeLayout::RequireFinalSemicolon]
[CodeLayout::RequireTrailingCommaAtNewline]
[Compatibility::ConstantLeadingUnderscore]
[Compatibility::ConstantPragmaHash]
#[Compatibility::Gtk2Constants]
[Compatibility::PerlMinimumVersionAndWhy]
#[Compatibility::PodMinimumVersion]
[Compatibility::ProhibitUnixDevNull]
[Documentation::ProhibitAdjacentLinks]
[Documentation::ProhibitBadAproposMarkup]
[Documentation::ProhibitDuplicateHeadings]
#[Documentation::ProhibitDuplicateSeeAlso]
[Documentation::ProhibitLinkToSelf]
[Documentation::ProhibitParagraphEndComma]
[Documentation::ProhibitParagraphTwoDots]
[Documentation::ProhibitUnbalancedParens]
[Documentation::ProhibitVerbatimMarkup]
[Documentation::RequireEndBeforeLastPod]
[Documentation::RequireFilenameMarkup]
#[Documentation::RequireFinalCut]
[Documentation::RequireLinkedURLs]
#[Miscellanea::TextDomainPlaceholders]
#[Miscellanea::TextDomainUnused]
[Modules::ProhibitModuleShebang]
[Modules::ProhibitPOSIXimport]
[Modules::ProhibitUseQuotedVersion]
[ValuesAndExpressions::ConstantBeforeLt]
[ValuesAndExpressions::NotWithCompare]
[ValuesAndExpressions::ProhibitArrayAssignAref]
[ValuesAndExpressions::ProhibitBarewordDoubleColon]
[ValuesAndExpressions::ProhibitDuplicateHashKeys]
[ValuesAndExpressions::ProhibitEmptyCommas]
#[ValuesAndExpressions::ProhibitFiletest_f]
[ValuesAndExpressions::ProhibitNullStatements]
[ValuesAndExpressions::ProhibitUnknownBackslash]
[ValuesAndExpressions::RequireNumericVersion]
[ValuesAndExpressions::UnexpandedSpecialLiteral]

# ----------------------------------------------------------
# Perl::Critic::StricterSubs
# ----------------------------------------------------------

[Modules::RequireExplicitInclusion]
#[Subroutines::ProhibitCallsToUndeclaredSubs]
#[Subroutines::ProhibitCallsToUnexportedSubs]
[Subroutines::ProhibitExportingUndeclaredSubs]
[Subroutines::ProhibitQualifiedSubDeclarations]

# ----------------------------------------------------------
# Perl::Critic::Tics
# ----------------------------------------------------------

#[Tics::ProhibitLongLines]
[Tics::ProhibitManyArrows]
[Tics::ProhibitUseBase]
PERLCRITICRC_TEMPLATE

        # Conig::Std will not preserve a comment on the last line, therefore
        # we append at least one empty line at the end
        $perlcriticrc_template .= "\n\n";

        read_config \$perlcriticrc_template, my %perlcriticrc;

        my $perlcriticrc_local = 'perlcriticrc.local';

        if ( -f $perlcriticrc_local ) {
            $self->log("Adjusting Perl::Critic config from '$perlcriticrc_local'");

            read_config $perlcriticrc_local, my %perlcriticrc_local;

            my %local_seen;

          POLICY:
            for my $policy ( keys %perlcriticrc_local ) {

                if ( $policy eq q{-} ) {
                    $self->log_fatal('We cannot disable the global settings');

                    # log_fatal should die
                    croak 'internal error';
                }

                my $policy_name = $policy =~ m{ ^ - (.+) }xsm ? $1 : $policy;

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

With B<travis_ci_osx_perl> you can specify one or multiple Perl versions to
be tested on OSX, in addition to on Linux. If omitted it defaults to one
single version.

Use the B<travis_ci_no_author_testing_perl> option to disable author tests on
some Perl versions.

=cut

    $file{q{.travis.yml}} = sub {
        my ($self) = @_;

        my $travis_yml = <<'TRAVIS_YML_1';
# Automatically generated file
# {{ ref $plugin }} {{ $plugin->VERSION() }}

language: perl

cache:
  directories:
    - ~/perl5

env:
  global:
    - AUTOMATED_TESTING=1

matrix:
  include:
TRAVIS_YML_1

        my %ignore_perl;
        @ignore_perl{ @{ $self->travis_ci_ignore_perl } } = ();

        my %no_auth;
        @no_auth{ @{ $self->travis_ci_no_author_testing_perl } } = ();

        my %osx_perl;
        @osx_perl{ @{ $self->travis_ci_osx_perl } } = ();

      PERL:
        for my $perl ( @{ $self->_travis_available_perl } ) {
            next PERL if exists $ignore_perl{$perl};

            my @os = (undef);
            if ( exists $osx_perl{$perl} ) {
                push @os, 'osx';
            }

            for my $os (@os) {
                $travis_yml .= "    - perl: '$perl'\n";

                if ( !exists $no_auth{$perl} ) {
                    $travis_yml .= "      env: AUTHOR_TESTING=1\n";
                }

                if ( defined $os ) {
                    $travis_yml .= "      os: $os\n";
                }

                $travis_yml .= "\n";
            }
        }

        $travis_yml .= <<'TRAVIS_YML';
before_install:
  - |
    case "${TRAVIS_OS_NAME}" in
      "linux" )
        ;;
      "osx"   )
        # TravisCI extracts the broken perl archive with sudo which creates the
        # $HOME/perl5 directory with owner root:staff. Subdirectories under
        # perl5 are owned by user travis.
        sudo chown "$USER" "$HOME/perl5"

        # The perl distribution TravisCI extracts on OSX is incomplete
        sudo rm -rf "$HOME/perl5/perlbrew"

        # Install cpanm and local::lib
        curl -L https://cpanmin.us | perl - App::cpanminus local::lib
        eval $(perl -I $HOME/perl5/lib/perl5/ -Mlocal::lib)
        ;;
    esac

install:
  - |
    if [ -n "$AUTHOR_TESTING" ]
    then
      cpanm --quiet --installdeps --notest --skip-satisfied --with-develop .
    else
      cpanm --quiet --installdeps --notest --skip-satisfied .
    fi

script:
  - perl Makefile.PL && make test
  - |
    if [ -n "$AUTHOR_TESTING" ]
    then
      prove -lr xt/author
    fi
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

my @ignores;
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
use Test::Pod::No404s;

if ( exists $ENV{AUTOMATED_TESTING} ) {
    print "1..0 # SKIP these tests during AUTOMATED_TESTING\n";
    exit 0;
}

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

if ( exists $ENV{AUTOMATED_TESTING} ) {
    print "1..0 # SKIP these tests during AUTOMATED_TESTING\n";
    exit 0;
}

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
kwalitee_ok(qw{-has_license_in_source_file});

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
