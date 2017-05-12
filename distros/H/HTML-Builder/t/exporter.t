use strict;
use warnings;

use v5.10;

use Test::More 0.88;
use List::MoreUtils 'uniq';
use HTML::Builder -minimal => { -prefix => 'html_' };

my @tags = HTML::Builder::minimal_tags();
my %SKIPS = map { $_ => 1 } (); #qw{ applet area article };

for my $tag (@tags) {

    subtest "checking: $tag" => sub {

        plan skip_all => "$tag needs work" if $SKIPS{$tag};

        my $tag_gen = "html_$tag";

        is eval("$tag_gen {}"),
            qq{<$tag></$tag>}, "simple $tag works";
        is eval("$tag_gen { one gets 'two' }"),
            qq{<$tag one="two"></$tag>}, "$tag w/attribute";
        is eval("$tag_gen { 'content!' }"),
            qq{<$tag>content!</$tag>}, "$tag w/content";
        is eval("$tag_gen { one gets 'two'; 'content!' }"),
            qq{<$tag one="two">content!</$tag>}, "$tag w/attribute and content";
    };
}

subtest 'check STDOUT capture' => sub {

    is
        html_p { print html_img { 'hi there' }; 'something else' },
        "<p><img>hi there</img>something else</p>",
        'STDOUT capture worked correctly',
        ;

    is
        html_p { html_img { 'hi there' }; 'something else' },
        "<p><img>hi there</img>something else</p>",
        'inner STDOUT capture and print worked correctly',
        ;
};

done_testing;
