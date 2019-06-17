#!perl -w
use strict;
use warnings;
use utf8;
use Test::More;

use HTML::Lint::Pluggable;

my $html5 = q{
<html>
<head><title>hoge</title></head>
<body><h1 data-fuga="hoge" xxx="yyy">hoge</h1><footer>exeeee</footer></body>
</html>
};

my $passing_html5 = q{
<html>
<head><title>Test</title></head>
<body>
<div tabindex="42"></div>
<div translate="no">Test&pm;</div>
<input type="number" min="2" max="42">
<iframe allowfullscreen></iframe>
<button type="submit" formaction="/save">Save</button>
<video controls>
  <source src="myVideo.mp4" type="video/mp4">
  <source src="myVideo.webm" type="video/webm">
  <p>Your browser doesn't support HTML5 video. Here is
     a <a href="myVideo.mp4">link to the video</a> instead.</p>
</video>
</body>
</html>
};

my $has_entites_html = q{
<html>
<head><title>hoge</title></head>
<body><h1>やまだ&</h1></body>
</html>
};

my $has_entites_html5 = q{
<html>
<head><title>hoge</title></head>
<body><h1 data-fuga="hoge" xxx="yyy">やまだ&</h1><footer>exeeee</footer></body>
</html>
};

subtest 'html5' => sub {
    my $base_errors = do {
        my $lint = HTML::Lint->new;
        $lint->parse($html5);
        $lint->eof;
        $lint->errors;
    };

    subtest 'default' => sub {
        my $lint = HTML::Lint::Pluggable->new;
        $lint->parse($html5);
        $lint->eof;
        is scalar($lint->errors), $base_errors;
    };

    subtest 'load HTML5' => sub {
        my $lint = HTML::Lint::Pluggable->new;
        $lint->load_plugins(qw/HTML5/);
        $lint->parse($html5);
        $lint->eof;
        is scalar($lint->errors), $base_errors - 2;
    };

    subtest 'default back' => sub {
        my $lint = HTML::Lint::Pluggable->new;
        $lint->parse($html5);
        $lint->eof;
        is scalar($lint->errors), $base_errors;
    };

    subtest 'passing html5' => sub {
        my $lint = HTML::Lint::Pluggable->new;
        $lint->load_plugins(qw/HTML5/);
        $lint->parse($passing_html5);
        $lint->eof;
        is scalar($lint->errors), 0
            or diag explain [$lint->errors];
    }
};

subtest 'tiny entities escape rule' => sub {
    local $SIG{__WARN__} = sub {};

    my $base_errors = do {
        my $lint = HTML::Lint->new;
        $lint->parse($has_entites_html);
        $lint->eof;
        $lint->errors;
    };

    subtest 'default' => sub {
        my $lint = HTML::Lint::Pluggable->new;
        $lint->parse($has_entites_html);
        $lint->eof;
        is scalar($lint->errors), $base_errors;
    };

    subtest 'load TinyEntitesEscapeRule' => sub {
        my $lint = HTML::Lint::Pluggable->new;
        $lint->load_plugins(qw/TinyEntitesEscapeRule/);
        $lint->parse($has_entites_html);
        $lint->eof;
        is scalar($lint->errors), $base_errors - 3;
    };

    subtest 'default back' => sub {
        my $lint = HTML::Lint::Pluggable->new;
        $lint->parse($has_entites_html);
        $lint->eof;
        is scalar($lint->errors), $base_errors;
    };
};

subtest 'html5 and tiny entities escape rule' => sub {
    local $SIG{__WARN__} = sub {};

    my $base_errors = do {
        my $lint = HTML::Lint->new;
        $lint->parse($has_entites_html5);
        $lint->eof;
        $lint->errors;
    };

    subtest 'default' => sub {
        my $lint = HTML::Lint::Pluggable->new;
        $lint->parse($has_entites_html5);
        $lint->eof;
        is scalar($lint->errors), $base_errors;
    };

    subtest 'load TinyEntitesEscapeRule and HTML5' => sub {
        my $lint = HTML::Lint::Pluggable->new;
        $lint->load_plugins(qw/TinyEntitesEscapeRule HTML5/);
        $lint->parse($has_entites_html5);
        $lint->eof;
        is scalar($lint->errors), $base_errors - 5;
    };

    subtest 'default back' => sub {
        my $lint = HTML::Lint::Pluggable->new;
        $lint->parse($has_entites_html5);
        $lint->eof;
        is scalar($lint->errors), $base_errors;
    };
};

done_testing;
