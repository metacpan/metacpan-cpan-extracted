# NAME

Liveman::MinillaPod2Markdown - bung for Minilla. It not make README.md

# SYNOPSIS

```perl
use Liveman::MinillaPod2Markdown;

my $mark = Liveman::MinillaPod2Markdown->new;

$mark->isa("Pod::Markdown")  # -> 1

use File::Slurper qw/write_text/;
write_text "X.md", "hi!";
write_text "X.pm", "our \$VERSION = 1.0;";

$mark->parse_from_file("X.pm");
$mark->{path}  # => X.md

$mark->as_markdown  # => hi!
```

# DESCRIPION

Add `markdown_maker = "Liveman::MinillaPod2Markdown"` to `minil.toml`, and Minilla do'nt make README.md.

# SUBROUTINES

## as_markdown ()

The bung.

## new ()

The constructor.

## parse_from_file ($path)

The bung.

# INSTALL

For install this module in your system run next [command](https://metacpan.org/pod/App::cpm):

```sh
sudo cpm install -gvv Liveman::MinillaPod2Markdown
```

# AUTHOR

Yaroslav O. Kosmina [dart@cpan.org](dart@cpan.org)

# LICENSE

⚖ **GPLv3**

# COPYRIGHT

The Liveman::MinillaPod2Markdown module is copyright © 2023 Yaroslav O. Kosmina. Rusland. All rights reserved.
