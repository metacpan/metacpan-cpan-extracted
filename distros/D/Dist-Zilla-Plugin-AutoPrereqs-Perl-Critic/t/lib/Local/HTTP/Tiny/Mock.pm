package Local::HTTP::Tiny::Mock;

use 5.006;
use strict;
use warnings;

sub get_200 {

    # perl -e 'use HTTP::Tiny; use Data::Dumper; print Dumper(HTTP::Tiny->new->get(q{http://cpanmetadb.plackperl.org/v1.0/package/Perl::Critic}));'

    return sub {

        return {
            'url'     => 'http://cpanmetadb.plackperl.org/v1.0/package/Perl::Critic',
            'content' => '---
distfile: P/PE/PETDANCE/Perl-Critic-1.130.tar.gz
provides:
  Perl::Critic: 1.130
  Perl::Critic::Annotation: 1.130
  Perl::Critic::Command: 1.130
  Perl::Critic::Config: 1.130
  Perl::Critic::Document: 1.130
  Perl::Critic::Exception: 1.130
  Perl::Critic::Exception::AggregateConfiguration: 1.130
  Perl::Critic::Exception::Configuration: 1.130
  Perl::Critic::Exception::Configuration::Generic: 1.130
  Perl::Critic::Exception::Configuration::NonExistentPolicy: 1.130
  Perl::Critic::Exception::Configuration::Option: 1.130
  Perl::Critic::Exception::Configuration::Option::Global: 1.130
  Perl::Critic::Exception::Configuration::Option::Global::ExtraParameter: 1.130
  Perl::Critic::Exception::Configuration::Option::Global::ParameterValue: 1.130
  Perl::Critic::Exception::Configuration::Option::Policy: 1.130
  Perl::Critic::Exception::Configuration::Option::Policy::ExtraParameter: 1.130
  Perl::Critic::Exception::Configuration::Option::Policy::ParameterValue: 1.130
  Perl::Critic::Exception::Fatal: 1.130
  Perl::Critic::Exception::Fatal::Generic: 1.130
  Perl::Critic::Exception::Fatal::Internal: 1.130
  Perl::Critic::Exception::Fatal::PolicyDefinition: 1.130
  Perl::Critic::Exception::IO: 1.130
  Perl::Critic::Exception::Parse: 1.130
  Perl::Critic::OptionsProcessor: 1.130
  Perl::Critic::Policy: 1.130
  Perl::Critic::Policy::BuiltinFunctions::ProhibitBooleanGrep: 1.130
  Perl::Critic::Policy::BuiltinFunctions::ProhibitComplexMappings: 1.130
  Perl::Critic::Policy::BuiltinFunctions::ProhibitLvalueSubstr: 1.130
  Perl::Critic::Policy::BuiltinFunctions::ProhibitReverseSortBlock: 1.130
  Perl::Critic::Policy::BuiltinFunctions::ProhibitSleepViaSelect: 1.130
  Perl::Critic::Policy::BuiltinFunctions::ProhibitStringyEval: 1.130
  Perl::Critic::Policy::BuiltinFunctions::ProhibitStringySplit: 1.130
  Perl::Critic::Policy::BuiltinFunctions::ProhibitUniversalCan: 1.130
  Perl::Critic::Policy::BuiltinFunctions::ProhibitUniversalIsa: 1.130
  Perl::Critic::Policy::BuiltinFunctions::ProhibitUselessTopic: 1.130
  Perl::Critic::Policy::BuiltinFunctions::ProhibitVoidGrep: 1.130
  Perl::Critic::Policy::BuiltinFunctions::ProhibitVoidMap: 1.130
  Perl::Critic::Policy::BuiltinFunctions::RequireBlockGrep: 1.130
  Perl::Critic::Policy::BuiltinFunctions::RequireBlockMap: 1.130
  Perl::Critic::Policy::BuiltinFunctions::RequireGlobFunction: 1.130
  Perl::Critic::Policy::BuiltinFunctions::RequireSimpleSortBlock: 1.130
  Perl::Critic::Policy::ClassHierarchies::ProhibitAutoloading: 1.130
  Perl::Critic::Policy::ClassHierarchies::ProhibitExplicitISA: 1.130
  Perl::Critic::Policy::ClassHierarchies::ProhibitOneArgBless: 1.130
  Perl::Critic::Policy::CodeLayout::ProhibitHardTabs: 1.130
  Perl::Critic::Policy::CodeLayout::ProhibitParensWithBuiltins: 1.130
  Perl::Critic::Policy::CodeLayout::ProhibitQuotedWordLists: 1.130
  Perl::Critic::Policy::CodeLayout::ProhibitTrailingWhitespace: 1.130
  Perl::Critic::Policy::CodeLayout::RequireConsistentNewlines: 1.130
  Perl::Critic::Policy::CodeLayout::RequireTidyCode: 1.130
  Perl::Critic::Policy::CodeLayout::RequireTrailingCommas: 1.130
  Perl::Critic::Policy::ControlStructures::ProhibitCStyleForLoops: 1.130
  Perl::Critic::Policy::ControlStructures::ProhibitCascadingIfElse: 1.130
  Perl::Critic::Policy::ControlStructures::ProhibitDeepNests: 1.130
  Perl::Critic::Policy::ControlStructures::ProhibitLabelsWithSpecialBlockNames: 1.130
  Perl::Critic::Policy::ControlStructures::ProhibitMutatingListFunctions: 1.130
  Perl::Critic::Policy::ControlStructures::ProhibitNegativeExpressionsInUnlessAndUntilConditions: 1.130
  Perl::Critic::Policy::ControlStructures::ProhibitPostfixControls: 1.130
  Perl::Critic::Policy::ControlStructures::ProhibitUnlessBlocks: 1.130
  Perl::Critic::Policy::ControlStructures::ProhibitUnreachableCode: 1.130
  Perl::Critic::Policy::ControlStructures::ProhibitUntilBlocks: 1.130
  Perl::Critic::Policy::ControlStructures::ProhibitYadaOperator: 1.130
  Perl::Critic::Policy::Documentation::PodSpelling: 1.130
  Perl::Critic::Policy::Documentation::RequirePackageMatchesPodName: 1.130
  Perl::Critic::Policy::Documentation::RequirePodAtEnd: 1.130
  Perl::Critic::Policy::Documentation::RequirePodLinksIncludeText: 1.130
  Perl::Critic::Policy::Documentation::RequirePodSections: 1.130
  Perl::Critic::Policy::ErrorHandling::RequireCarping: 1.130
  Perl::Critic::Policy::ErrorHandling::RequireCheckingReturnValueOfEval: 1.130
  Perl::Critic::Policy::InputOutput::ProhibitBacktickOperators: 1.130
  Perl::Critic::Policy::InputOutput::ProhibitBarewordFileHandles: 1.130
  Perl::Critic::Policy::InputOutput::ProhibitExplicitStdin: 1.130
  Perl::Critic::Policy::InputOutput::ProhibitInteractiveTest: 1.130
  Perl::Critic::Policy::InputOutput::ProhibitJoinedReadline: 1.130
  Perl::Critic::Policy::InputOutput::ProhibitOneArgSelect: 1.130
  Perl::Critic::Policy::InputOutput::ProhibitReadlineInForLoop: 1.130
  Perl::Critic::Policy::InputOutput::ProhibitTwoArgOpen: 1.130
  Perl::Critic::Policy::InputOutput::RequireBracedFileHandleWithPrint: 1.130
  Perl::Critic::Policy::InputOutput::RequireBriefOpen: 1.130
  Perl::Critic::Policy::InputOutput::RequireCheckedClose: 1.130
  Perl::Critic::Policy::InputOutput::RequireCheckedOpen: 1.130
  Perl::Critic::Policy::InputOutput::RequireCheckedSyscalls: 1.130
  Perl::Critic::Policy::InputOutput::RequireEncodingWithUTF8Layer: 1.130
  Perl::Critic::Policy::Miscellanea::ProhibitFormats: 1.130
  Perl::Critic::Policy::Miscellanea::ProhibitTies: 1.130
  Perl::Critic::Policy::Miscellanea::ProhibitUnrestrictedNoCritic: 1.130
  Perl::Critic::Policy::Miscellanea::ProhibitUselessNoCritic: 1.130
  Perl::Critic::Policy::Modules::ProhibitAutomaticExportation: 1.130
  Perl::Critic::Policy::Modules::ProhibitConditionalUseStatements: 1.130
  Perl::Critic::Policy::Modules::ProhibitEvilModules: 1.130
  Perl::Critic::Policy::Modules::ProhibitExcessMainComplexity: 1.130
  Perl::Critic::Policy::Modules::ProhibitMultiplePackages: 1.130
  Perl::Critic::Policy::Modules::RequireBarewordIncludes: 1.130
  Perl::Critic::Policy::Modules::RequireEndWithOne: 1.130
  Perl::Critic::Policy::Modules::RequireExplicitPackage: 1.130
  Perl::Critic::Policy::Modules::RequireFilenameMatchesPackage: 1.130
  Perl::Critic::Policy::Modules::RequireNoMatchVarsWithUseEnglish: 1.130
  Perl::Critic::Policy::Modules::RequireVersionVar: 1.130
  Perl::Critic::Policy::NamingConventions::Capitalization: 1.130
  Perl::Critic::Policy::NamingConventions::ProhibitAmbiguousNames: 1.130
  Perl::Critic::Policy::Objects::ProhibitIndirectSyntax: 1.130
  Perl::Critic::Policy::References::ProhibitDoubleSigils: 1.130
  Perl::Critic::Policy::RegularExpressions::ProhibitCaptureWithoutTest: 1.130
  Perl::Critic::Policy::RegularExpressions::ProhibitComplexRegexes: 1.130
  Perl::Critic::Policy::RegularExpressions::ProhibitEnumeratedClasses: 1.130
  Perl::Critic::Policy::RegularExpressions::ProhibitEscapedMetacharacters: 1.130
  Perl::Critic::Policy::RegularExpressions::ProhibitFixedStringMatches: 1.130
  Perl::Critic::Policy::RegularExpressions::ProhibitSingleCharAlternation: 1.130
  Perl::Critic::Policy::RegularExpressions::ProhibitUnusedCapture: 1.130
  Perl::Critic::Policy::RegularExpressions::ProhibitUnusualDelimiters: 1.130
  Perl::Critic::Policy::RegularExpressions::ProhibitUselessTopic: 1.130
  Perl::Critic::Policy::RegularExpressions::RequireBracesForMultiline: 1.130
  Perl::Critic::Policy::RegularExpressions::RequireDotMatchAnything: 1.130
  Perl::Critic::Policy::RegularExpressions::RequireExtendedFormatting: 1.130
  Perl::Critic::Policy::RegularExpressions::RequireLineBoundaryMatching: 1.130
  Perl::Critic::Policy::Subroutines::ProhibitAmpersandSigils: 1.130
  Perl::Critic::Policy::Subroutines::ProhibitBuiltinHomonyms: 1.130
  Perl::Critic::Policy::Subroutines::ProhibitExcessComplexity: 1.130
  Perl::Critic::Policy::Subroutines::ProhibitExplicitReturnUndef: 1.130
  Perl::Critic::Policy::Subroutines::ProhibitManyArgs: 1.130
  Perl::Critic::Policy::Subroutines::ProhibitNestedSubs: 1.130
  Perl::Critic::Policy::Subroutines::ProhibitReturnSort: 1.130
  Perl::Critic::Policy::Subroutines::ProhibitSubroutinePrototypes: 1.130
  Perl::Critic::Policy::Subroutines::ProhibitUnusedPrivateSubroutines: 1.130
  Perl::Critic::Policy::Subroutines::ProtectPrivateSubs: 1.130
  Perl::Critic::Policy::Subroutines::RequireArgUnpacking: 1.130
  Perl::Critic::Policy::Subroutines::RequireFinalReturn: 1.130
  Perl::Critic::Policy::TestingAndDebugging::ProhibitNoStrict: 1.130
  Perl::Critic::Policy::TestingAndDebugging::ProhibitNoWarnings: 1.130
  Perl::Critic::Policy::TestingAndDebugging::ProhibitProlongedStrictureOverride: 1.130
  Perl::Critic::Policy::TestingAndDebugging::RequireTestLabels: 1.130
  Perl::Critic::Policy::TestingAndDebugging::RequireUseStrict: 1.130
  Perl::Critic::Policy::TestingAndDebugging::RequireUseWarnings: 1.130
  Perl::Critic::Policy::ValuesAndExpressions::ProhibitCommaSeparatedStatements: 1.130
  Perl::Critic::Policy::ValuesAndExpressions::ProhibitComplexVersion: 1.130
  Perl::Critic::Policy::ValuesAndExpressions::ProhibitConstantPragma: 1.130
  Perl::Critic::Policy::ValuesAndExpressions::ProhibitEmptyQuotes: 1.130
  Perl::Critic::Policy::ValuesAndExpressions::ProhibitEscapedCharacters: 1.130
  Perl::Critic::Policy::ValuesAndExpressions::ProhibitImplicitNewlines: 1.130
  Perl::Critic::Policy::ValuesAndExpressions::ProhibitInterpolationOfLiterals: 1.130
  Perl::Critic::Policy::ValuesAndExpressions::ProhibitLeadingZeros: 1.130
  Perl::Critic::Policy::ValuesAndExpressions::ProhibitLongChainsOfMethodCalls: 1.130
  Perl::Critic::Policy::ValuesAndExpressions::ProhibitMagicNumbers: 1.130
  Perl::Critic::Policy::ValuesAndExpressions::ProhibitMismatchedOperators: 1.130
  Perl::Critic::Policy::ValuesAndExpressions::ProhibitMixedBooleanOperators: 1.130
  Perl::Critic::Policy::ValuesAndExpressions::ProhibitNoisyQuotes: 1.130
  Perl::Critic::Policy::ValuesAndExpressions::ProhibitQuotesAsQuotelikeOperatorDelimiters: 1.130
  Perl::Critic::Policy::ValuesAndExpressions::ProhibitSpecialLiteralHeredocTerminator: 1.130
  Perl::Critic::Policy::ValuesAndExpressions::ProhibitVersionStrings: 1.130
  Perl::Critic::Policy::ValuesAndExpressions::RequireConstantVersion: 1.130
  Perl::Critic::Policy::ValuesAndExpressions::RequireInterpolationOfMetachars: 1.130
  Perl::Critic::Policy::ValuesAndExpressions::RequireNumberSeparators: 1.130
  Perl::Critic::Policy::ValuesAndExpressions::RequireQuotedHeredocTerminator: 1.130
  Perl::Critic::Policy::ValuesAndExpressions::RequireUpperCaseHeredocTerminator: 1.130
  Perl::Critic::Policy::Variables::ProhibitAugmentedAssignmentInDeclaration: 1.130
  Perl::Critic::Policy::Variables::ProhibitConditionalDeclarations: 1.130
  Perl::Critic::Policy::Variables::ProhibitEvilVariables: 1.130
  Perl::Critic::Policy::Variables::ProhibitLocalVars: 1.130
  Perl::Critic::Policy::Variables::ProhibitMatchVars: 1.130
  Perl::Critic::Policy::Variables::ProhibitPackageVars: 1.130
  Perl::Critic::Policy::Variables::ProhibitPerl4PackageNames: 1.130
  Perl::Critic::Policy::Variables::ProhibitPunctuationVars: 1.130
  Perl::Critic::Policy::Variables::ProhibitReusedNames: 1.130
  Perl::Critic::Policy::Variables::ProhibitUnusedVariables: 1.130
  Perl::Critic::Policy::Variables::ProtectPrivateVars: 1.130
  Perl::Critic::Policy::Variables::RequireInitializationForLocalVars: 1.130
  Perl::Critic::Policy::Variables::RequireLexicalLoopIterators: 1.130
  Perl::Critic::Policy::Variables::RequireLocalizedPunctuationVars: 1.130
  Perl::Critic::Policy::Variables::RequireNegativeIndices: 1.130
  Perl::Critic::PolicyConfig: 1.130
  Perl::Critic::PolicyFactory: 1.130
  Perl::Critic::PolicyListing: 1.130
  Perl::Critic::PolicyParameter: 1.130
  Perl::Critic::PolicyParameter::Behavior: 1.130
  Perl::Critic::PolicyParameter::Behavior::Boolean: 1.130
  Perl::Critic::PolicyParameter::Behavior::Enumeration: 1.130
  Perl::Critic::PolicyParameter::Behavior::Integer: 1.130
  Perl::Critic::PolicyParameter::Behavior::String: 1.130
  Perl::Critic::PolicyParameter::Behavior::StringList: 1.130
  Perl::Critic::ProfilePrototype: 1.130
  Perl::Critic::Statistics: 1.130
  Perl::Critic::TestUtils: 1.130
  Perl::Critic::Theme: 1.130
  Perl::Critic::ThemeListing: 1.130
  Perl::Critic::UserProfile: 1.130
  Perl::Critic::Utils: 1.130
  Perl::Critic::Utils::Constants: 1.130
  Perl::Critic::Utils::DataConversion: 1.130
  Perl::Critic::Utils::McCabe: 1.130
  Perl::Critic::Utils::POD: 1.130
  Perl::Critic::Utils::POD::ParseInteriorSequence: 1.130
  Perl::Critic::Utils::PPI: 1.130
  Perl::Critic::Utils::Perl: 1.130
  Perl::Critic::Violation: 1.130
  Test::Perl::Critic::Policy: 1.130
version: 1.130
',
            'protocol' => 'HTTP/1.1',
            'headers'  => {
                'server'         => 'nginx/1.6.3',
                'cache-control'  => 'max-age=1800',
                'content-type'   => 'text/yaml',
                'x-timer'        => 'S1506018172.065497,VS0,VE2',
                'x-cache-hits'   => '1, 1',
                'content-length' => '12653',
                'date'           => 'Thu, 21 Sep 2017 18:22:52 GMT',
                'connection'     => 'keep-alive',
                'x-cache'        => 'HIT, HIT',
                'age'            => '130393',
                'via'            => [
                    '1.1 varnish',
                    '1.1 varnish'
                ],
                'accept-ranges'       => 'bytes',
                'fastly-debug-digest' => '5bd2af97315cd0addda0fd4657bbd4cf437331d546f05b2adba5573b6c88c030',
                'x-runtime'           => '0.085299',
                'x-served-by'         => 'cache-sjc3147-SJC, cache-hhn1546-HHN'
            },
            'status'  => '200',
            'success' => 1,
            'reason'  => 'OK'
        };
    };
}

sub get_404 {

    # perl -e 'use HTTP::Tiny; use Data::Dumper; print Dumper(HTTP::Tiny->new->get(q{http://cpanmetadb.plackperl.org/v1.0/package/Perl::Critic_does_not_exist}));'

    return sub {
        return {
            'headers' => {
                'accept-ranges' => 'bytes',
                'x-cache'       => 'MISS, MISS',
                'date'          => 'Thu, 21 Sep 2017 19:16:05 GMT',
                'server'        => 'nginx/1.6.3',
                'content-type'  => 'text/plain',
                'via'           => [
                    '1.1 varnish',
                    '1.1 varnish'
                ],
                'fastly-debug-digest' => 'abe8f8abc3c33a054b261732aa0cb98d62f1ca227a5aafd2fa53981ccd3d1f62',
                'connection'          => 'keep-alive',
                'x-served-by'         => 'cache-sjc3151-SJC, cache-hhn1538-HHN',
                'x-timer'             => 'S1506021365.113918,VS0,VE208',
                'x-cache-hits'        => '0, 0',
                'x-runtime'           => '0.046718',
                'content-length'      => '10',
                'age'                 => '0'
            },
            'protocol' => 'HTTP/1.1',
            'content'  => 'Not found
',
            'success' => '',
            'status'  => '404',
            'url'     => 'http://cpanmetadb.plackperl.org/v1.0/package/Perl::Critic_does_not_exist',
            'reason'  => 'Not Found'
        };
    };
}

1;

# vim: ts=4 sts=4 sw=4 et: syntax=perl
