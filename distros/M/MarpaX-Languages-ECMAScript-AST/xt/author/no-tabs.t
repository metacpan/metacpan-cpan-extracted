use strict;
use warnings;

# this test was generated with Dist::Zilla::Plugin::Test::NoTabs 0.09

use Test::More 0.88;
use Test::NoTabs;

my @files = (
    'lib/MarpaX/Languages/ECMAScript/AST.pm',
    'lib/MarpaX/Languages/ECMAScript/AST/Exceptions.pm',
    'lib/MarpaX/Languages/ECMAScript/AST/Grammar.pm',
    'lib/MarpaX/Languages/ECMAScript/AST/Grammar/Base.pm',
    'lib/MarpaX/Languages/ECMAScript/AST/Grammar/Base/DefaultSemanticsPackage.pm',
    'lib/MarpaX/Languages/ECMAScript/AST/Grammar/CharacterClasses.pm',
    'lib/MarpaX/Languages/ECMAScript/AST/Grammar/ECMAScript_262_5.pm',
    'lib/MarpaX/Languages/ECMAScript/AST/Grammar/ECMAScript_262_5/Base.pm',
    'lib/MarpaX/Languages/ECMAScript/AST/Grammar/ECMAScript_262_5/CharacterClasses.pm',
    'lib/MarpaX/Languages/ECMAScript/AST/Grammar/ECMAScript_262_5/JSON.pm',
    'lib/MarpaX/Languages/ECMAScript/AST/Grammar/ECMAScript_262_5/Lexical/NumericLiteral.pm',
    'lib/MarpaX/Languages/ECMAScript/AST/Grammar/ECMAScript_262_5/Lexical/RegularExpressionLiteral.pm',
    'lib/MarpaX/Languages/ECMAScript/AST/Grammar/ECMAScript_262_5/Lexical/StringLiteral.pm',
    'lib/MarpaX/Languages/ECMAScript/AST/Grammar/ECMAScript_262_5/Lexical/StringLiteral/Semantics.pm',
    'lib/MarpaX/Languages/ECMAScript/AST/Grammar/ECMAScript_262_5/Pattern.pm',
    'lib/MarpaX/Languages/ECMAScript/AST/Grammar/ECMAScript_262_5/Pattern/Semantics.pm',
    'lib/MarpaX/Languages/ECMAScript/AST/Grammar/ECMAScript_262_5/Program.pm',
    'lib/MarpaX/Languages/ECMAScript/AST/Grammar/ECMAScript_262_5/Program/Semantics.pm',
    'lib/MarpaX/Languages/ECMAScript/AST/Grammar/ECMAScript_262_5/SpacesAny.pm',
    'lib/MarpaX/Languages/ECMAScript/AST/Grammar/ECMAScript_262_5/StringNumericLiteral.pm',
    'lib/MarpaX/Languages/ECMAScript/AST/Grammar/ECMAScript_262_5/StringNumericLiteral/NativeNumberSemantics.pm',
    'lib/MarpaX/Languages/ECMAScript/AST/Grammar/ECMAScript_262_5/Template.pm',
    'lib/MarpaX/Languages/ECMAScript/AST/Grammar/ECMAScript_262_5/URI.pm',
    'lib/MarpaX/Languages/ECMAScript/AST/Impl.pm',
    'lib/MarpaX/Languages/ECMAScript/AST/Impl/Logger.pm',
    'lib/MarpaX/Languages/ECMAScript/AST/Impl/Singleton.pm',
    'lib/MarpaX/Languages/ECMAScript/AST/Util.pm',
    't/00-compile.t',
    't/00-report-prereqs.dd',
    't/00-report-prereqs.t',
    't/JSON.t',
    't/URI.t',
    't/asi.t',
    't/backbone-1.1.0.min.t',
    't/backbone-1.1.0.t',
    't/github_issue_0001.t',
    't/github_issue_0003.t',
    't/github_issue_0004.t',
    't/jquery-1.10.2.min.t',
    't/jquery-1.10.2.t',
    't/jquery-2.0.3.min.t',
    't/jquery-2.0.3.t',
    't/pattern.t',
    't/stringNumericLiteralBigFloat.t',
    't/stringNumericLiteralNative.t',
    't/underscore-1.5.2.min.t',
    't/underscore-1.5.2.t'
);

notabs_ok($_) foreach @files;
done_testing;
