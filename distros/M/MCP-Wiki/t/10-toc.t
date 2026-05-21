use strict;
use warnings;
use Test::More;
use Path::Tiny;
use MCP::Wiki::TOC::Parser;
use MCP::Wiki::TOC::Entry;

subtest 'parse_content extracts headings' => sub {
    my $md = <<'MARKDOWN';
# Introduction

This is the intro.

## Background

Some background info.

## Installation

Step one.
Step two.
MARKDOWN

    my @entries = MCP::Wiki::TOC::Parser->parse_content($md);

    is(scalar(@entries), 3, 'three headings found');

    is($entries[0]->level, 1, 'H1 level');
    is($entries[0]->heading, 'Introduction', 'H1 heading');
    is($entries[0]->heading_path, 'Introduction', 'H1 path');
    ok($entries[0]->line_start, 'H1 has line_start');
    ok($entries[0]->line_end >= $entries[0]->line_start, 'line_end >= line_start');

    is($entries[1]->level, 2, 'H2 level');
    is($entries[1]->heading, 'Background', 'H2 heading');
    is($entries[1]->heading_path, 'Introduction#Background', 'H2 path with parent');

    is($entries[2]->level, 2, 'H2 level');
    is($entries[2]->heading, 'Installation', 'H2 heading');
};

subtest 'heading anchors are url-safe' => sub {
    my $md = "# Hello World! How Are You?";

    my @entries = MCP::Wiki::TOC::Parser->parse_content($md);

    is($entries[0]->anchor, 'hello-world-how-are-you', 'lowercase, spaces to hyphens');
};

subtest 'ignores headings in code blocks' => sub {
    my $md = <<'MARKDOWN';
# Real Heading

```
# Not a heading
```

## Another Real Heading
MARKDOWN

    my @entries = MCP::Wiki::TOC::Parser->parse_content($md);

    is(scalar(@entries), 2, 'only real headings found');
    is($entries[0]->heading, 'Real Heading');
    is($entries[1]->heading, 'Another Real Heading');
};

subtest 'as_hash returns correct structure' => sub {
    my $md = "# Test";

    my @entries = MCP::Wiki::TOC::Parser->parse_content($md);
    my $hash = $entries[0]->as_hash;

    ok(exists $hash->{level}, 'has level');
    ok(exists $hash->{heading}, 'has heading');
    ok(exists $hash->{anchor}, 'has anchor');
    ok(exists $hash->{heading_path}, 'has heading_path');
    ok(exists $hash->{line_start}, 'has line_start');
    ok(exists $hash->{line_end}, 'has line_end');
    ok(exists $hash->{content_preview}, 'has content_preview');
    ok(exists $hash->{char_count}, 'has char_count');
};

done_testing;