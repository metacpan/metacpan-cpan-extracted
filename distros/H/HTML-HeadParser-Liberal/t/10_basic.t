use strict;
use Test::More;

use HTTP::Headers;
use HTML::HeadParser;
# use HTML::HeadParser::Liberal;

sub run_test {
    my $use_liberal = shift;

    if ($use_liberal) {
        require HTML::HeadParser::Liberal;
    }

    my $h = HTTP::Headers->new;
    my $p = HTML::HeadParser->new($h);

    eval {
        $p->parse(<<EOT);
<head>
    <meta name="twitter:card" content="summary">
</head>
EOT
    };
    if ($use_liberal) {
        is $@, "", "should not throw exceptions: $@";
        is $h->header('X-Meta-Twitter-Card'), 'summary';
    } else {
        isnt $@, "", "should throw exceptions: $@";
    }
}

run_test(0);
run_test(1);

done_testing;