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
  sub hook_hash {
    is($_[0], {name => 'Mark is down', draft => 'false', number => 42}, 'read map YAML');
  }
  $p->set_hooks(yaml_metadata => \&hook_hash);
  $p->convert($page);
}

# Check if we can get a string value
{
  sub hook_list {
    is($_[0], [qw(abc def)], 'read list YAML');
  }
  $p->set_hooks(yaml_metadata => \&hook_list);
  $p->convert($list_yaml);
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

done_testing;
