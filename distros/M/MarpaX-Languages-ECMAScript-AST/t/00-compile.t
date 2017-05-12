use 5.006;
use strict;
use warnings;

# this test was generated with Dist::Zilla::Plugin::Test::Compile 2.051

use Test::More;

plan tests => 27 + ($ENV{AUTHOR_TESTING} ? 1 : 0);

my @module_files = (
    'MarpaX/Languages/ECMAScript/AST.pm',
    'MarpaX/Languages/ECMAScript/AST/Exceptions.pm',
    'MarpaX/Languages/ECMAScript/AST/Grammar.pm',
    'MarpaX/Languages/ECMAScript/AST/Grammar/Base.pm',
    'MarpaX/Languages/ECMAScript/AST/Grammar/Base/DefaultSemanticsPackage.pm',
    'MarpaX/Languages/ECMAScript/AST/Grammar/CharacterClasses.pm',
    'MarpaX/Languages/ECMAScript/AST/Grammar/ECMAScript_262_5.pm',
    'MarpaX/Languages/ECMAScript/AST/Grammar/ECMAScript_262_5/Base.pm',
    'MarpaX/Languages/ECMAScript/AST/Grammar/ECMAScript_262_5/CharacterClasses.pm',
    'MarpaX/Languages/ECMAScript/AST/Grammar/ECMAScript_262_5/JSON.pm',
    'MarpaX/Languages/ECMAScript/AST/Grammar/ECMAScript_262_5/Lexical/NumericLiteral.pm',
    'MarpaX/Languages/ECMAScript/AST/Grammar/ECMAScript_262_5/Lexical/RegularExpressionLiteral.pm',
    'MarpaX/Languages/ECMAScript/AST/Grammar/ECMAScript_262_5/Lexical/StringLiteral.pm',
    'MarpaX/Languages/ECMAScript/AST/Grammar/ECMAScript_262_5/Lexical/StringLiteral/Semantics.pm',
    'MarpaX/Languages/ECMAScript/AST/Grammar/ECMAScript_262_5/Pattern.pm',
    'MarpaX/Languages/ECMAScript/AST/Grammar/ECMAScript_262_5/Pattern/Semantics.pm',
    'MarpaX/Languages/ECMAScript/AST/Grammar/ECMAScript_262_5/Program.pm',
    'MarpaX/Languages/ECMAScript/AST/Grammar/ECMAScript_262_5/Program/Semantics.pm',
    'MarpaX/Languages/ECMAScript/AST/Grammar/ECMAScript_262_5/SpacesAny.pm',
    'MarpaX/Languages/ECMAScript/AST/Grammar/ECMAScript_262_5/StringNumericLiteral.pm',
    'MarpaX/Languages/ECMAScript/AST/Grammar/ECMAScript_262_5/StringNumericLiteral/NativeNumberSemantics.pm',
    'MarpaX/Languages/ECMAScript/AST/Grammar/ECMAScript_262_5/Template.pm',
    'MarpaX/Languages/ECMAScript/AST/Grammar/ECMAScript_262_5/URI.pm',
    'MarpaX/Languages/ECMAScript/AST/Impl.pm',
    'MarpaX/Languages/ECMAScript/AST/Impl/Logger.pm',
    'MarpaX/Languages/ECMAScript/AST/Impl/Singleton.pm',
    'MarpaX/Languages/ECMAScript/AST/Util.pm'
);



# fake home for cpan-testers
use File::Temp;
local $ENV{HOME} = File::Temp::tempdir( CLEANUP => 1 );


my $inc_switch = -d 'blib' ? '-Mblib' : '-Ilib';

use File::Spec;
use IPC::Open3;
use IO::Handle;

open my $stdin, '<', File::Spec->devnull or die "can't open devnull: $!";

my @warnings;
for my $lib (@module_files)
{
    # see L<perlfaq8/How can I capture STDERR from an external command?>
    my $stderr = IO::Handle->new;

    my $pid = open3($stdin, '>&STDERR', $stderr, $^X, $inc_switch, '-e', "require q[$lib]");
    binmode $stderr, ':crlf' if $^O eq 'MSWin32';
    my @_warnings = <$stderr>;
    waitpid($pid, 0);
    is($?, 0, "$lib loaded ok");

    if (@_warnings)
    {
        warn @_warnings;
        push @warnings, @_warnings;
    }
}



is(scalar(@warnings), 0, 'no warnings found')
    or diag 'got warnings: ', ( Test::More->can('explain') ? Test::More::explain(\@warnings) : join("\n", '', @warnings) ) if $ENV{AUTHOR_TESTING};


