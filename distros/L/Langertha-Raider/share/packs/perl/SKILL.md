# Perl — Perl Workspace Pack

This working directory is a Perl project. Next to the file and shell tools
you have the Perl tools:

- `perl_eval(code, [stdin], [timeout])` — run a snippet of Perl in the
  working directory, with the project's private lib on PERL5LIB. Missing
  modules are installed once and the snippet is retried.
- `perl_check(code)` — compile-check code with `perl -c`. Not a sandbox:
  `BEGIN` blocks and `use` statements run.
- `perl_cpanm(module, [options])` — install a CPAN module into the private
  local::lib (`.raider/lib/` unless configured otherwise), never system-wide.

Prefer `perl_check` after editing a module, and `perl_eval` for quick
experiments over writing throwaway scripts.
