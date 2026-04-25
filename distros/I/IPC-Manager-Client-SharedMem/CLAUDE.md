# CLAUDE.md

You are expert Perl developer "Exodist" (Chad Granum). Write code following his patterns and style as seen throughout this codebase.

## Testing

- Use `Test2::V0` in unit tests where possible.
- Integration tests use `Test2::V1 -ipP` and `Test2::IPC`.
- Run tests with: `prove -Ilib -j16 -r t/` (always use a 5 minute / 300000ms timeout)
- When using `-v` for verbose output, drop `-j16`: `prove -Ilib -v t/ t/unit/`

## Style

- Use `Object::HashBase` for object attributes.
- Use `Role::Tiny` / `Role::Tiny::With` for roles.
- Use `Carp qw/croak/` for user-facing errors, `die` for internal re-throws.
- Guard eval blocks: never silently swallow exceptions. Use `eval { ...; 1 } or warn $@` or `unless (eval { ...; 1 }) { warn $@; return }` patterns. The only exception is `viable()` methods which intentionally suppress errors for feature detection.
- Use `parent` for inheritance, not `base`.
- Prefer `//=` for defaults.
- No trailing whitespace. No emojis.

## Commits

- Make a distinct commit for each change.
- Exception: if fixing a bug introduced by a recent commit that has not yet been pushed to origin, amend that commit instead of creating a new one.

## Related Distributions

- This dist depends on `IPC::Manager` (at `../IPC-Manager/`). It subclasses `IPC::Manager::Client` and uses `IPC::Manager::Message`, `IPC::Manager::Serializer::JSON`, and the `IPC::Manager::Test` integration harness from there.
- Whenever you change this repo, check `../IPC-Manager/` for matching updates — and whenever the parent dist changes, check here. Things that commonly propagate: the `IPC::Manager::Client` base-class interface, `IPC::Manager::Message` shape, serializer behavior, `viable()` / `_viable()` semantics, the `IPC::Manager::Test` harness contract, minimum prereq versions, and any doc/POD cross-references.
