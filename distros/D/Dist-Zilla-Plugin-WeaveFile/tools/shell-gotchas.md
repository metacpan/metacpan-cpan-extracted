# Shell Gotchas

Gotchas discovered during development. Recorded per Gate 9 / D2L&D.

## 2026-04-22: Pod::Markdown 3.300 crashes without output_string

`Pod::Markdown->new->parse_file($f); $p->as_markdown` crashes with
"Can't use an undefined value as a symbol reference" at line 629/633.
Must call `$parser->output_string(\$md)` before `parse_file`.

## 2026-04-22: TT single-pass — snippets with tags need pre-rendering

Template::Toolkit does NOT re-process the output of `[% snippets.foo %]`.
If a snippet contains `[% dist.author %]`, it comes through literally.
Solution: pre-render snippets through TT before passing them as vars.

## 2026-04-22: Perl regex /x mode and # character class

`(#+)` in a `/x` regex is interpreted as a comment start.
Use `([#]+)` or `[#]` inside character class to match literal `#`.
