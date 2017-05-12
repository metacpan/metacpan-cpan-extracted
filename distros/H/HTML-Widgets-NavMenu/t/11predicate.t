#!/usr/bin/perl -w

use strict;

use Test::More tests => 65;

use HTML::Widgets::NavMenu::Predicate;

# Spec for this test suite:
# 1. Test the individual components. (bool, re, and cb)
# 2. Test them as non-hashrefed values.
# 3. Test precedence within a hash-ref.

# Test the bool == 0 predicate
{
    my $pred =
        HTML::Widgets::NavMenu::Predicate->new(
            'spec' => +{ 'bool' => 0, },
        );

    # TEST
    ok(!$pred->evaluate(
        'path_info' => "Hoola/Yoola",
        'current_host' => "default",
    ), "bool==0 test 1");
    # TEST
    ok(!$pred->evaluate(
        'path_info' => "Shragah/Spinoza/",
        'current_host' => "majesty",
    ), "bool==0 test 2");
}

# Test the bool == 1 predicate
{
    my $pred =
        HTML::Widgets::NavMenu::Predicate->new(
            'spec' => +{ 'bool' => 1, },
        );

    # TEST
    ok($pred->evaluate(
        'path_info' => "Hoola/Yoola",
        'current_host' => "default",
    ), "bool==1 test 1");
    # TEST
    ok($pred->evaluate(
        'path_info' => "Shragah/Spinoza/",
        'current_host' => "majesty",
    ), "bool==1 test 2");
}

# Test the regexp evaluation.
{
    my $pred =
        HTML::Widgets::NavMenu::Predicate->new(
            'spec' => +{ 're' => "^hello/(world|good)/", },
        );

    # TEST
    ok($pred->evaluate(
        'path_info' => "hello/world/",
        'current_host' => "default",
    ), "regexp 1");
    # TEST
    ok($pred->evaluate(
        'path_info' => "hello/good/",
        'current_host' => "default",
    ), "regexp 2");
    # TEST
    ok($pred->evaluate(
        'path_info' => "hello/world/some/more/components.html",
        'current_host' => "default",
    ), "regexp 3");
    # TEST
    ok($pred->evaluate(
        'path_info' => "hello/good/other/comps/",
        'current_host' => "default",
    ), "regexp 4");
    # TEST
    ok(!$pred->evaluate(
        'path_info' => "Shragah/Spinoza/",
        'current_host' => "majesty",
    ), "regexp 5 - should be false");
    # TEST
    ok(!$pred->evaluate(
        'path_info' => "hello/something-else/",
        'current_host' => "default",
    ), "regexp 6 - close, but not enough");
}

# Another regex test - this time without anchors
{
    my $pred =
        HTML::Widgets::NavMenu::Predicate->new(
            'spec' => +{ 're' => "start(mid|center)+finish", },
        );

    # TEST
    ok($pred->evaluate(
        'path_info' => "hello/startmidfinish/",
        'current_host' => "default",
    ), "non-anchored regexp 1");
    # TEST
    ok(!$pred->evaluate(
        'path_info' => "hello/good/",
        'current_host' => "default",
    ), "non-anchored regexp 2");
    # TEST
    ok($pred->evaluate(
        'path_info' => "hello/startmidcentermidfinish/",
        'current_host' => "default",
    ), "non-anchored regexp 3");
    # TEST
    ok(!$pred->evaluate(
        'path_info' => "startfinish/",
        'current_host' => "default",
    ), "non-anchored regexp 4");
}

sub predicate_cb1
{
    my %args = (@_);
    my $host = $args{'current_host'};
    my $path = $args{'path_info'};
    return (($host eq "true") && ($path eq "mypath/"));
}

# Test the 'cb' argument
{
    my $pred =
        HTML::Widgets::NavMenu::Predicate->new(
            'spec' => +{ 'cb' => \&predicate_cb1, },
        );

    # TEST
    ok($pred->evaluate(
        'path_info' => "mypath/",
        'current_host' => "true",
    ), "cb 1 - true");
    # TEST
    ok(!$pred->evaluate(
        'path_info' => "mypath/",
        'current_host' => "false",
    ), "cb 2 - false");
    # TEST
    ok(!$pred->evaluate(
        'path_info' => "hello/",
        'current_host' => "true",
    ), "cb 3 - false");
    # TEST
    ok(!$pred->evaluate(
        'path_info' => "anuba/",
        'current_host' => "false",
    ), "cb 4 - both false");
}

# Now testing the non-hashrefed values.

# Test the bool == 0 predicate
{
    # TEST*2*4
    foreach my $false_value (qw(0 no false False))
    {
        my $pred =
            HTML::Widgets::NavMenu::Predicate->new(
                'spec' => $false_value,
            );

        ok(!$pred->evaluate(
            'path_info' => "Hoola/Yoola",
            'current_host' => "default",
        ), "bool==0 test 1");
        ok(!$pred->evaluate(
            'path_info' => "Shragah/Spinoza/",
            'current_host' => "majesty",
        ), "bool==0 test 2");
    }
}

# Test the bool == 1 predicate
{
    # TEST*2*4
    for my $true_value (qw(1 yes true True))
    {
        my $pred =
            HTML::Widgets::NavMenu::Predicate->new(
                'spec' => +{ 'bool' => 1, },
            );

        ok($pred->evaluate(
            'path_info' => "Hoola/Yoola",
            'current_host' => "default",
        ), "bool==1 test 1");
        ok($pred->evaluate(
            'path_info' => "Shragah/Spinoza/",
            'current_host' => "majesty",
        ), "bool==1 test 2");
    }
}

# Test the regexp evaluation.
{
    my $pred =
        HTML::Widgets::NavMenu::Predicate->new(
            'spec' => "^hello/(world|good)/",
        );

    # TEST
    ok($pred->evaluate(
        'path_info' => "hello/world/",
        'current_host' => "default",
    ), "implicit regexp 1");
    # TEST
    ok($pred->evaluate(
        'path_info' => "hello/good/",
        'current_host' => "default",
    ), "implicit regexp 2");
    # TEST
    ok($pred->evaluate(
        'path_info' => "hello/world/some/more/components.html",
        'current_host' => "default",
    ), "implicit regexp 3");
    # TEST
    ok($pred->evaluate(
        'path_info' => "hello/good/other/comps/",
        'current_host' => "default",
    ), "implicit regexp 4");
    # TEST
    ok(!$pred->evaluate(
        'path_info' => "Shragah/Spinoza/",
        'current_host' => "majesty",
    ), "implicit regexp 5 - should be false");
    # TEST
    ok(!$pred->evaluate(
        'path_info' => "hello/something-else/",
        'current_host' => "default",
    ), "implicit regexp 6 - close, but not enough");
}

# Test the implicit 'cb' argument
{
    my $pred =
        HTML::Widgets::NavMenu::Predicate->new(
            'spec' => \&predicate_cb1,
        );

    # TEST
    ok($pred->evaluate(
        'path_info' => "mypath/",
        'current_host' => "true",
    ), "ipmlicit cb 1 - true");
    # TEST
    ok(!$pred->evaluate(
        'path_info' => "mypath/",
        'current_host' => "false",
    ), "ipmlicit cb 2 - false");
    # TEST
    ok(!$pred->evaluate(
        'path_info' => "hello/",
        'current_host' => "true",
    ), "ipmlicit cb 3 - false");
    # TEST
    ok(!$pred->evaluate(
        'path_info' => "anuba/",
        'current_host' => "false",
    ), "ipmlicit cb 4 - both false");
}

##############

# Precendence tests.

# 're' precedes 'bool'
{
    my $pred =
        HTML::Widgets::NavMenu::Predicate->new(
            'spec' =>
                +{
                    're' => "^hello/(world|good)/",
                    'bool' => 0,
                },
        );

    # TEST
    ok($pred->evaluate(
        'path_info' => "hello/world/",
        'current_host' => "default",
    ), "re precedes bool 1");
    # TEST
    ok($pred->evaluate(
        'path_info' => "hello/good/",
        'current_host' => "default",
    ), "re precedes bool 2");
    # TEST
    ok($pred->evaluate(
        'path_info' => "hello/world/some/more/components.html",
        'current_host' => "default",
    ), "re precedes bool 3");
    # TEST
    ok($pred->evaluate(
        'path_info' => "hello/good/other/comps/",
        'current_host' => "default",
    ), "re precedes bool 4");
}

# 'cb' precedes 're'
{
    my $pred =
        HTML::Widgets::NavMenu::Predicate->new(
            'spec' =>
                +{
                    're' => "^hello/(world|good)/",
                    'cb' => \&predicate_cb1,
                },
        );

    # TEST
    ok(!$pred->evaluate(
        'path_info' => "hello/world/",
        'current_host' => "default",
    ), "cb precedes re 1");
    # TEST
    ok($pred->evaluate(
        'path_info' => "mypath/",
        'current_host' => "true",
    ), "cb precedes re 2");
}

# 'cb' precedes 'bool'
{
    my $pred =
        HTML::Widgets::NavMenu::Predicate->new(
            'spec' =>
                +{
                    'cb' => \&predicate_cb1,
                    'bool' => 1,
                },
        );

    # TEST
    ok($pred->evaluate(
        'path_info' => "mypath/",
        'current_host' => "true",
    ), "cb precedes bool 1 - true");
    # TEST
    ok(!$pred->evaluate(
        'path_info' => "mypath/",
        'current_host' => "false",
    ), "cb precedes bool  2 - false");
    # TEST
    ok(!$pred->evaluate(
        'path_info' => "hello/",
        'current_host' => "true",
    ), "cb precedes bool  3 - false");
    # TEST
    ok(!$pred->evaluate(
        'path_info' => "anuba/",
        'current_host' => "false",
    ), "cb precedes bool 4 - both false");
}

# 'cb' precedes both 'bool' and 're'

{
    my $pred =
        HTML::Widgets::NavMenu::Predicate->new(
            'spec' =>
                +{
                    'cb' => \&predicate_cb1,
                    'bool' => 1,
                    're' => "anuba",
                },
        );

    # TEST
    ok($pred->evaluate(
        'path_info' => "mypath/",
        'current_host' => "true",
    ), "cb precedes bool and re 1 - true");
    # TEST
    ok(!$pred->evaluate(
        'path_info' => "mypath/",
        'current_host' => "false",
    ), "cb precedes bool and re 2 - false");
    # TEST
    ok(!$pred->evaluate(
        'path_info' => "hello/",
        'current_host' => "true",
    ), "cb precedes bool and re 3 - false");
    # TEST
    ok(!$pred->evaluate(
        'path_info' => "anuba/",
        'current_host' => "false",
    ), "cb precedes bool and re 4 - both false");
}

# Test the regexp evaluation when 're' is empty.
{
    my $pred =
        HTML::Widgets::NavMenu::Predicate->new(
            'spec' => +{ 're' => "", },
        );

    my $string = "Yowza Cowza Nowza";
    $string =~ s!Yowza!!;

    # TEST
    ok($pred->evaluate(
        'path_info' => "/nothing/here",
        'current_host' => "default",
    ), "regexp 1");
}

# Test the implicit bool predicate
{
    my $pred =
        HTML::Widgets::NavMenu::Predicate->new(
            'spec' => 1,
        );

    # TEST
    ok($pred->evaluate(
        'path_info' => "Hoola/Yoola",
        'current_host' => "default",
    ), "bool==1 test 1");
    # TEST
    ok($pred->evaluate(
        'path_info' => "Shragah/Spinoza/",
        'current_host' => "majesty",
    ), "bool==1 test 2");
}

# Test the implicit regexp predicate
{
    my $pred =
        HTML::Widgets::NavMenu::Predicate->new(
            'spec' => "^Hoola",
        );

    # TEST
    ok($pred->evaluate(
        'path_info' => "Hoola/Yoola",
        'current_host' => "default",
    ), "bool==1 test 1");
    # TEST
    ok(!$pred->evaluate(
        'path_info' => "Shragah/Spinoza/",
        'current_host' => "majesty",
    ), "bool==1 test 2");
}

# Test the implicit regexp predicate
{
    eval {
    my $pred =
        HTML::Widgets::NavMenu::Predicate->new(
            'spec' => { 'hoalsdkasldk' => 1},
        );
    };

    # TEST
    like($@, qr{^Neither},
        "Exception should be thrown.");
}

# Test an incorrect spec
{
    eval {
    my $pred =
        HTML::Widgets::NavMenu::Predicate->new(
            'spec' => [],
        );
    };

    # TEST
    like($@, qr{^Unknown spec type},
        "Exception should be thrown.");
}

