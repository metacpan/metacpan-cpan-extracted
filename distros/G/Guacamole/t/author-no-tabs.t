
BEGIN {
  unless ($ENV{AUTHOR_TESTING}) {
    print qq{1..0 # SKIP these tests are for testing by the author\n};
    exit
  }
}

use strict;
use warnings;

# this test was generated with Dist::Zilla::Plugin::Test::NoTabs 0.15

use Test::More 0.88;
use Test::NoTabs;

my @files = (
    'lib/Guacamole.pm',
    'lib/Guacamole/Deparse.pm',
    'lib/Guacamole/Dumper.pm',
    'lib/Guacamole/Test.pm',
    'lib/standard.pm',
    't/00-report-prereqs.dd',
    't/00-report-prereqs.t',
    't/Statements/Block.t',
    't/Statements/Condition.t',
    't/Statements/Ellipsis.t',
    't/Statements/Expressions/ExprComma.t',
    't/Statements/Expressions/ExprNameNot.t',
    't/Statements/Expressions/OpListKeywordExpr/OpKeywordBinmodeExpr.t',
    't/Statements/Expressions/OpListKeywordExpr/OpKeywordChmodExpr.t',
    't/Statements/Expressions/OpListKeywordExpr/OpKeywordOpenExpr.t',
    't/Statements/Expressions/OpListKeywordExpr/OpKeywordPrintExpr.t',
    't/Statements/Expressions/OpListKeywordExpr/OpKeywordPrintfExpr.t',
    't/Statements/Expressions/OpListKeywordExpr/OpKeywordSayExpr.t',
    't/Statements/Expressions/OpListKeywordExpr/OpKeywordSortExpr.t',
    't/Statements/Expressions/OpListKeywordExpr/OpKeywordSpliceExpr.t',
    't/Statements/Expressions/OpListKeywordExpr/OpKeywordSplitExpr.t',
    't/Statements/Expressions/OpListKeywordExpr/OpKeywordSprintfExpr.t',
    't/Statements/Expressions/OpNullaryKeywordExpr/OpKeywordSubExpr.t',
    't/Statements/Expressions/OpUnaryKeywordExpr/OpKeywordReadlineExpr.t',
    't/Statements/Expressions/OpUnaryKeywordExpr/OpKeywordStatExpr.t',
    't/Statements/Expressions/Value/ArrowDerefVariable.t',
    't/Statements/Expressions/Value/Literal.t',
    't/Statements/Expressions/Value/Literal/LitString.t',
    't/Statements/Expressions/Value/NonLiteral/DerefVariable.t',
    't/Statements/Expressions/Value/NonLiteral/DiamondExpr.t',
    't/Statements/Expressions/Value/NonLiteral/SubCall.t',
    't/Statements/Expressions/Value/NonLiteral/Variable.t',
    't/Statements/Expressions/Value/QLikeValue.t',
    't/Statements/Expressions/arrow.t',
    't/Statements/Expressions/basic.t',
    't/Statements/Expressions/unary.t',
    't/Statements/Expressions/variable.t',
    't/Statements/LoopStatement.t',
    't/Statements/PackageStatement.t',
    't/Statements/PhaseStatements.t',
    't/Statements/RequireStatement.t',
    't/Statements/SubStatement.t',
    't/Statements/UseNoStatement.t',
    't/Statements/WhileStatement.t',
    't/author-no-tabs.t',
    't/author-pod-syntax.t',
    't/bugs/rt_132920_regex_subset.t'
);

notabs_ok($_) foreach @files;
done_testing;
