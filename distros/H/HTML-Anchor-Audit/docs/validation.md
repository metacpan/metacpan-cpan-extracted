# Validation

Validated on 6 October 2026.

* Native Windows: Strawberry Perl 5.42.3, HTML::Parser 3.85,
  ExtUtils::MakeMaker 7.76, Test::More 1.302222.
  All 109 assertions in three test files passed through the standard build/test
  process. POD syntax passed Pod::Checker.
* A second runtime: Git/MSYS Perl 5.42.2, HTML::Parser 3.83.
  Parser/API and command-line tests passed. Its stripped installation does not
  include Pod::Checker or ExtUtils::MakeMaker, so full distribution/POD testing
  was performed with Strawberry Perl.
* Covered: forward/missing references, duplicates, ambiguity, Arabic,
  percent encoding, HTML entities, non-BMP characters, normalization hints,
  matching precedence, comments, raw text, templates, base URLs, URL whitespace,
  legacy names, CR/LF/CRLF locations, BOM, invalid UTF-8, size/diagnostic caps,
  5,000 references on a single line, bounded ambiguity details, JSON output,
  multi-file errors, command exit codes and preservation of input files.
* A portable official Strawberry ZIP was SHA256-verified before extraction.
  No system-wide Perl installation or persistent environment change was made.

Perl 5.16 is the declared minimum based on language/API requirements; it has not
been executed here. Neither Linux nor macOS has been tested here.
The release is small and source-only; it reuses HTML::Parser and does not
implement a complete HTML5 tree builder.
