# Tests related to JVN53973084

use strict;
use warnings;
use Test::More;

use_ok('HTML::Scrubber');

my @allow = qw[
    hr
];

my $html_1 = q[<hr><a href="javascript:alert(1)"<hr>abc];
my $html_2 = q[<img src="javascript:alert(1)"];
foreach my $comment_value ( 0, 1 ) {
    my $scrubber = HTML::Scrubber->new( allow => \@allow, comment => $comment_value );
    is( $scrubber->scrub($html_1), '<hr>abc', "correct result (1) - with comment => $comment_value" );
    is( $scrubber->scrub($html_2), '',            "correct result (2) - with comment => $comment_value" );
}

done_testing;
