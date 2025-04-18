use strict;
use warnings;
use utf8;

use Markdown::Perl 'convert', 'set_hooks';
use Test2::V0;

my $p = Markdown::Perl->new();
my $page = <<EOF;
---
name: Mark is down
draft: false
number: 42
---
# Mark is down!

I repeat: "Mark is down!"
EOF

my $list_yaml = <<EOF;
---
- abc
- def
---
# Mark is down!

I repeat: "Mark is down!"
EOF

my $invalid_page = <<EOF;
---
name: Mark is down
  draft: false
	number: 42
---
# Mark is down!

I repeat: "Mark is down!"
EOF

# Check that we can read a hash-map for map document.
{
  my $hook_called = 0;
  sub hook_hash {
    $hook_called = 1;
    is($_[0], {name => 'Mark is down', draft => 'false', number => 42}, 'read map YAML');
  }
  $p->set_hooks(yaml_metadata => \&hook_hash);
  $p->convert($page);
  ok($hook_called, "Hook for hash was called.");
}

# Check if we can get a string value
{
  my $hook_called = 0;
  sub hook_list {
    $hook_called = 1;
    is($_[0], [qw(abc def)], 'read list YAML');
  }
  $p->set_hooks(yaml_metadata => \&hook_list);
  $p->convert($list_yaml);
  ok($hook_called, "Hook for list was called.");
}

# Validate that hook is not called if yaml is invalid and that this causes a
# call to carp().
{
  my $hook_called = 0;
  sub hook_called {
    $hook_called = 1;
  }
  $p->set_hooks(yaml_metadata => \&hook_called);
  like(warning { $p->convert($invalid_page) }, qr/invalid/, "Got expected warning");
  ok(!$hook_called, "Hook was not called because metadata was invalid.");
}

# Hook exceptions are propagated
{
  sub hook_die {
    die "last words";
  }
  $p->set_hooks(yaml_metadata => \&hook_die);
  like( dies { $p->convert($page) }, qr/last words/, "The hook correctly died.");
}

# Check that we can get a multi-line value
{
  my $hook_called = 0;
  sub hook_multi_line {
    $hook_called = 1;
    is($_[0], { title => 'some title', notes => "This is a paragraph\nThis is another paragraph.\n"}, 'read multi-line YAML');
  }
  $p->set_hooks(yaml_metadata => \&hook_multi_line);
  my $yaml = <<EOF;
---
title: some title
notes: |
    This is a paragraph

    This is another paragraph.
---
# Markdown
EOF
  $p->convert($yaml);
  ok(!$hook_called, "Hook for multi-line was not called.");

  $p->convert($yaml, yaml_file_metadata_allows_empty_lines => 1);
  ok($hook_called, "Hook for multi-line was called.");

  my $hook_called2 = 0;
  sub hook_multi_line2 {
    $hook_called2 = 1;
    # YAMLP::PP keeps the two newlines, YAML::Tiny does not.
    is($_[0], { title => 'some title', notes => "This is a paragraph\n\nThis is another paragraph.\n"}, 'read multi-line YAML::PP');
  }

  $p->set_hooks(yaml_metadata => \&hook_multi_line2);
  $p->convert($yaml, yaml_file_metadata_allows_empty_lines => 1, yaml_parser => 'YAML::PP');
  ok($hook_called2, "Hook for multi-line with YAML::PP was called.");
}

done_testing;
