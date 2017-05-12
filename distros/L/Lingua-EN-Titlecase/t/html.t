#!perl

use strict;
use warnings;

use FindBin;
use lib "$FindBin::Bin/lib";
use Lingua::EN::Titlecase::HTML;

# use Test::More "no_plan";
use Test::More tests => 77;


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
    my $tc = Lingua::EN::Titlecase::HTML->new;

    for my $testcase ( @test_strings )
    {
        ok( $tc->title($testcase->{original}),
            "html + Setting original/title string: $testcase->{original}");

        is( $tc->original(), $testcase->{original},
            "html + Original string returns correctly");

        is( $tc->title(), $testcase->{title},
            "html + Title(cased)");

        is( join(" ", $tc->mixedcase), $testcase->{mixedcase},
            "html + Mixedcase counted: $testcase->{title}");

        is( scalar($tc->wc), $testcase->{wc},
            "html + Wordish (wc) counted: $testcase->{title}");

        is( $tc->titlecase, "$tc",
            "html + Object is quote overloaded");
    }

    # Now repeat tests using new() as raw string setter.
    for my $testcase ( @test_strings ) {
        my $tc = Lingua::EN::Titlecase::HTML->new($testcase->{original});

        is( $tc->original(), $testcase->{original},
            "html + Original string returns correctly");

        is( $tc->title(), $testcase->{title},
            "html + Title(cased)");

        is( join(" ", $tc->mixedcase), $testcase->{mixedcase},
            "html + Mixedcase counted: $testcase->{title}");

        is( scalar($tc->wc), $testcase->{wc},
            "html + Wordish (wc) counted: $testcase->{title}");

        is( $tc->titlecase, "$tc",
            "html + Object is quote overloaded");
    }
}

1;

# TEST DATA FORMAT
#    Original string
#    Properly titlecased target string
#    number found by wc
#    space joined array of mixedcase letters caught

__END__
library Of <b>Perl</b> In between tools
Library of <b>Perl</b> in between Tools
6
""

<em>Things That Are Properly Titled</em>
<em>Things That Are Properly Titled</em>
5
""

<no such tag="><<\\><>\<\>>\\\\><>>><>><></>\\>\>" />And this with that but the capitalizing cat
<no such tag="><<\\><>\<\>>\\\\><>>><>><></>\\>\>" />And This with That but the Capitalizing Cat
8
""

<tag>the</tag> <tag>USA,</tag> <tag>the</tag> <tag>USSR</tag> <tag>with</tag> <tag>their</tag> <tag>six-guns</tag> <tag>to</tag> <tag>the</tag> <tag>sky</tag>
<tag>The</tag> <tag>USA,</tag> <tag>the</tag> <tag>USSR</tag> <tag>with</tag> <tag>Their</tag> <tag>Six-guns</tag> <tag>to</tag> <tag>the</tag> <tag>Sky</tag>
10
""

U.S. <tag alt="<">Vs.</tag> <tag>C.C.C.P.</tag>
U.S. <tag alt="<">vs.</tag> <tag>C.C.C.P.</tag>
3
""

<tag>'twas</tag> <tag>the</tag> <tag>night</tag> <tag>before</tag> christmas
<tag>'Twas</tag> <tag>the</tag> <tag>Night</tag> <tag>before</tag> Christmas
5
""

 <a name="<what a stupid attr>">no title for you</a>, <tag>triple-threat-hypen</tag> <tag>and</tag> <tag>int'l'z'n</tag>
 <a name="<what a stupid attr>">No Title for You</a>, <tag>Triple-threat-hypen</tag> <tag>and</tag> <tag>Int'l'z'n</tag>
7
""
