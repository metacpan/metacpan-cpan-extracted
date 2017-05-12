#!perl

use strict;
use warnings;

use FindBin;
use lib "$FindBin::Bin/lib";

# use Test::More "no_plan";
use Test::More tests => 152;

my $class = "Lingua::EN::Titlecase";

use_ok($class);

{
    ok( my $tc = Lingua::EN::Titlecase->new(),
        "$class->new()");

    isa_ok($tc, $class);
}

# Check the SYNOPSIS code to ensure it's working as advertised.
{
    ok( my $tc = Lingua::EN::Titlecase->new("CAN YOU FIX A TITLE?"),
        "Calling new with a string" );

    is("$tc",
       "Can You Fix a Title?",
       "Stringification works from new(string)" );

# use YAML; diag( Dump $tc ); diag( $tc );

    is($tc->title(),
       "Can You Fix a Title?",
       "title() from new");

    is($tc->title("and again but differently"),
       "And Again but Differently",
       "Inline title([string]) with same object");

    ok($tc->title("cookbook don't work, do she?"),
       "New string set via title() on same object");

    is("$tc",
       "Cookbook Don't Work, Do She?",
       "Stringification works" );
}


my @test_strings;
{
    my $data = join "", <DATA>;
    for my $test ( split /\n\n/, $data )
    {
        chomp $test;
        my ( $original, $title, $wc, $mixed ) = split /\n/, $test;
        $mixed = eval $mixed;
        push @test_strings, {
                             original => $original,
                             title => $title,
                             wc => $wc,
                             mixedcase => $mixed,
                            };
    }
}

{
    my $tc = Lingua::EN::Titlecase->new;

    for my $testcase ( @test_strings )
    {
        ok( $tc->title($testcase->{original}),
            "Setting original/title string: $testcase->{original}");

        is( $tc->original(), $testcase->{original},
            "Original string returns correctly");

        is( $tc->title(), $testcase->{title},
            "Title(cased)");

        is( join(" ", $tc->mixedcase), $testcase->{mixedcase},
            "Mixedcase counted: $testcase->{title}");

        is( scalar($tc->wc), $testcase->{wc},
            "Wordish (wc) counted: $testcase->{title}");

        is( $tc->titlecase, "$tc",
            "Object is quote overloaded");
    }

    # Now repeat tests using new() as raw string setter.
    for my $testcase ( @test_strings ) {
        my $tc = Lingua::EN::Titlecase->new($testcase->{original});

        is( $tc->original(), $testcase->{original},
            "Original string returns correctly");

        is( $tc->title(), $testcase->{title},
            "Title(cased)");

        is( join(" ", $tc->mixedcase), $testcase->{mixedcase},
            "Mixedcase counted: $testcase->{title}");

        is( scalar($tc->wc), $testcase->{wc},
            "Wordish (wc) counted: $testcase->{title}");

        is( $tc->titlecase, "$tc",
            "Object is quote overloaded");
    }
}

1;

# TEST DATA FORMAT
#    Original string
#    Properly titlecased target string
#    number found by wc
#    space joined array of mixedcase letters caught

# This fails right now but maybe hyphens should allow it to work
# cold-Cocked the guy with my black-jack
# Cold-Cocked the Guy with My Black-jack
# 6
# "C"


__END__
library Of Perl In between tools
Library of Perl in between Tools
6
""

Things That Are Properly Titled
Things That Are Properly Titled
5
""

And this with that but the capitalizing cat
And This with That but the Capitalizing Cat
8
""

a ring around the rosies
A Ring around the Rosies
5
""

tHaT pROBABly WiLl nevEr BE CorrectlY hanDled bY tHIs
That Probably Will Never Be Correctly Handled by This
9
"H T R O B A B W L E C Y D Y H I"

fountainhead, the
Fountainhead, the
2
""

nice one, McSnarky
Nice One, McSnarky
3
"M S"

won't work right, right?
Won't Work Right, Right?
4
""

STOP SHOUTING, JACKASS
Stop Shouting, Jackass
3
""

the USA, the USSR with their six-guns to the sky
The USA, the USSR with Their Six-guns to the Sky
10
""

U.S. Vs. C.C.C.P.
U.S. vs. C.C.C.P.
3
""

'twas the night before christmas
'Twas the Night before Christmas
5
""

triple-threat-hypen and int'l'z'n
Triple-threat-hypen and Int'l'z'n
3
""
