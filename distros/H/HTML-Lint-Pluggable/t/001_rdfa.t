#!perl -w
use strict;
use warnings;
use utf8;
use Test::More;

use HTML::Lint::Pluggable;

my $rdfa = q{
<html>
<head><title>hoge</title></head>
<body><div typeof="schema:Person"><h1 property="name">hoge</h1></div>
</html>
};

my $passing_rdfa = q{
<html>
<head><title>hoge</title></head>
<body>
 <div typeof="schema:Person"><h1 property="name">hoge</h1></div>
</body>
</html>
};

subtest 'rdfa' => sub {
    my $base_errors = do {
        my $lint = HTML::Lint->new;
        $lint->parse($rdfa);
        $lint->eof;
        $lint->errors;
    };

    subtest 'default' => sub {
        my $lint = HTML::Lint::Pluggable->new;
        $lint->load_plugins(qw/HTML5/);
        $lint->parse($rdfa);
        $lint->eof;
        is scalar($lint->errors), $base_errors;
    };

    subtest 'load RDFa' => sub {
        my $lint = HTML::Lint::Pluggable->new;
        $lint->load_plugins(qw/HTML5 RDFa/);
        $lint->parse($rdfa);
        $lint->eof;
        is scalar($lint->errors), $base_errors - 2;
    };

    subtest 'default back' => sub {
        my $lint = HTML::Lint::Pluggable->new;
        $lint->parse($rdfa);
        $lint->eof;
        is scalar($lint->errors), $base_errors;
    };

    subtest 'passing rdfa' => sub {
        my $lint = HTML::Lint::Pluggable->new;
        $lint->load_plugins(qw/HTML5 RDFa/);
        $lint->parse($passing_rdfa);
        $lint->eof;
        is scalar($lint->errors), 0
            or diag explain [$lint->errors];
    }
};

done_testing;
