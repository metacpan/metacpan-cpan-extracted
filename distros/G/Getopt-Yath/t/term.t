use Test2::V0;

use Getopt::Yath::Term qw/USE_COLOR color fit_to_width/;

subtest USE_COLOR => sub {
    my $val = USE_COLOR();
    ok(defined $val, 'USE_COLOR returns a defined value');
    ok($val == 0 || $val == 1, 'USE_COLOR returns 0 or 1');
};

subtest color => sub {
    my $result = color('red');
    ok(defined $result, 'color returns a defined value');
    # If Term::ANSIColor is available, it returns an escape sequence; otherwise ''
    if (USE_COLOR()) {
        like($result, qr/\e\[/, 'color returns ANSI escape when color is available');
    }
    else {
        is($result, '', 'color returns empty string when color is unavailable');
    }
};

subtest 'fit_to_width basic' => sub {
    my $text = "short text";
    my $out = fit_to_width(" ", $text, width => 80);
    is($out, "short text", 'short text passes through unchanged');
};

subtest 'fit_to_width wrapping' => sub {
    my $text = "word " x 30;    # ~150 chars
    my $out = fit_to_width(" ", $text, width => 40);
    my @lines = split /\n/, $out;
    ok(@lines > 1, 'long text is wrapped into multiple lines');
    for my $line (@lines) {
        ok(length($line) <= 44, "line does not grossly exceed width: '$line'");
    }
};

subtest 'fit_to_width with prefix' => sub {
    my $text = "hello world this is a test";
    my $out = fit_to_width(" ", $text, width => 80, prefix => ">> ");
    my @lines = split /\n/, $out;
    for my $line (@lines) {
        like($line, qr/^>> /, "line starts with prefix: '$line'");
    }
};

subtest 'fit_to_width with arrayref' => sub {
    my $parts = [qw/alpha beta gamma/];
    my $out = fit_to_width(", ", $parts, width => 80);
    is($out, "alpha, beta, gamma", 'arrayref input joined correctly');
};

subtest 'fit_to_width narrow width forces wrapping' => sub {
    my $text = "one two three four five";
    my $out = fit_to_width(" ", $text, width => 10);
    my @lines = split /\n/, $out;
    ok(@lines >= 2, 'narrow width causes wrapping');
};

subtest 'fit_to_width no prefix' => sub {
    my $out = fit_to_width(" ", "hello world", width => 80);
    unlike($out, qr/^  /, 'no prefix means no indentation');
};

subtest 'fit_to_width empty prefix string' => sub {
    my $out = fit_to_width(" ", "hello world", width => 80, prefix => "");
    is($out, "hello world", 'empty prefix adds empty string (no visible change)');
};

subtest 'fit_to_width custom prefix' => sub {
    my $out = fit_to_width(" ", "hello world", width => 80, prefix => "--- ");
    like($out, qr/^--- /, 'custom prefix applied');
};

subtest 'fit_to_width single word' => sub {
    my $out = fit_to_width(" ", "superlongword", width => 5);
    is($out, "superlongword", 'single word longer than width is not broken');
};

subtest 'fit_to_width empty text' => sub {
    my $out = fit_to_width(" ", "", width => 80);
    is($out, "", 'empty text returns empty string');
};

subtest 'fit_to_width multiline prefix' => sub {
    my $out = fit_to_width(" ", "aaa bbb ccc ddd", width => 8, prefix => "> ");
    my @lines = split /\n/, $out;
    for my $line (@lines) {
        like($line, qr/^> /, "each wrapped line has prefix: '$line'");
    }
};

subtest 'fit_to_width custom join' => sub {
    my $out = fit_to_width(", ", [qw/a b c/], width => 80);
    is($out, "a, b, c", 'custom join string used');
};

subtest 'fit_to_width default width' => sub {
    # Just verify it doesn't die when no width is given
    my $out = fit_to_width(" ", "some text here for testing default width calculation");
    ok(defined $out, 'default width produces output');
};

done_testing;
