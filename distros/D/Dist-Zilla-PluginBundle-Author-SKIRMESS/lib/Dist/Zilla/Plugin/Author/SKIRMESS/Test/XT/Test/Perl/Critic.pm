package Dist::Zilla::Plugin::Author::SKIRMESS::Test::XT::Test::Perl::Critic;

use 5.006;
use strict;
use warnings;

our $VERSION = '0.009';

use Moose;

use Carp;

has 'filename' => (
    is      => 'ro',
    isa     => 'Str',
    default => 'xt/author/critic.t',
);

with qw(
  Dist::Zilla::Role::Author::SKIRMESS::Test::XT
);

has _perlcriticrc => (
    is      => 'ro',
    isa     => 'Str',
    lazy    => 1,
    builder => '_build__perlcriticrc',
);

use Config::Std { def_sep => q{=} };
use Path::Tiny;

use namespace::autoclean;

after 'before_build' => sub {
    my ($self) = @_;

    my $myself    = ref $self;
    my $myversion = $self->VERSION;

    my $perlcriticrc_tmp = Path::Tiny->tempfile();
    $perlcriticrc_tmp->spew( $self->_perlcriticrc );

    read_config $perlcriticrc_tmp, my %perlcriticrc;

    my $perlcriticrc_local = path('perlcriticrc.local');
    if ( -f $perlcriticrc_local ) {
        $self->log("Adjusting Perl::Critic config from '$perlcriticrc_local'");

        read_config $perlcriticrc_local, my %perlcriticrc_local;

        my %local_seen = ();

      POLICY:
        for my $policy ( keys %perlcriticrc_local ) {

            if ( $policy eq q{-} ) {
                $self->log_fatal('We cannot disable the global settings');

                # log_fatal should die.
                croak 'internal error';
            }

            my $policy_name = $policy =~ m{ ^ - (.+) }xsm ? $1 : $policy;
            my $disable     = $policy =~ m{ ^ - . }xsm    ? 1  : 0;

            if ( exists $local_seen{$policy_name} ) {
                $self->log_fatal("There are multiple entries for policy '$policy_name' in '$perlcriticrc_local'.");

                # log_fatal should die.
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

    write_config %perlcriticrc, '.perlcriticrc';

    return;
};

sub test_body {
    my ($self) = @_;

    return <<'TEST_BODY';
use File::Spec;

use Perl::Critic::Utils qw(all_perl_files);
use Test::More;
use Test::Perl::Critic;

my @dirs = qw(bin lib t xt);

my @ignores = ();

my %ignore = map { $_ => 1 } @ignores;

my @files = grep { !exists $ignore{$_} } all_perl_files(@dirs);

if ( @files == 0 ) {
    BAIL_OUT('no files to criticize found');
}

all_critic_ok(@files);
TEST_BODY
}

sub _build__perlcriticrc {
    my ($self) = @_;

    my $data = "# Automatically generated file\n# ";
    $data .= ref $self;
    $data .= q{ } . $self->VERSION . "\n\n";

    local $/ = undef;
    $data .= <DATA>;
    close DATA or croak "Cannot close DATA handle: $!";

    # Conig::Std will not preserve a comment on the last line, therefore
    # we append at least one empty line at the end
    $data .= "\n\n";
    return $data;
}

__PACKAGE__->meta->make_immutable;

1;

# vim: ts=4 sts=4 sw=4 et: syntax=perl

__DATA__
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
[Modules::ProhibitExcessMainComplexity]
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
