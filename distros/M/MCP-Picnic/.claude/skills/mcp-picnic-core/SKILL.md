---
name: mcp-picnic-core
description: Load when implementing, refactoring, testing or reviewing MCP::Picnic — the auth/2FA gate, the standard tool-handler shape, WWW::Picnic delegation and the _*_to_hash projection convention that every tool in lib/MCP/Picnic.pm follows.
---

<oneliner>
MCP::Picnic is one Moo module (lib/MCP/Picnic.pm) exposing the Picnic supermarket
API as MCP tools. Every tool is: auth-gate, then eval-wrapped WWW::Picnic call,
then projection through a _*_to_hash helper, then _to_json, returned via
$tool->text_result. Generic MCP::Server mechanics live in the perl-mcp skill —
this skill is the Picnic-specific composition on top of it.
</oneliner>

<shape>
## One module, three entry points

The whole server lives in `lib/MCP/Picnic.pm`: the Moo attributes (`user`, `pass`,
`country`, `picnic`, `json`, `server`, `_auth_state`), the `_build_server` tool
registry, the `_*_to_hash` projection helpers, `_ensure_auth`, `_to_json` and
`run_stdio`. There are no sibling modules, so `our $VERSION` lives here and nowhere
else; the `bin/` scripts read `$MCP::Picnic::VERSION`.

Three entry points must all keep working:
- `bin/mcp-picnic` — stdio server (Claude Desktop and other MCP clients)
- `bin/mcp-picnic-http` — Mojolicious: `/mcp` MCP endpoint plus a REST API
- `bin/mcp-picnic-setup` — interactive config wizard (writes MCP client config)

Attributes are `lazy` with env-backed defaults: `user`/`pass` croak if
`PICNIC_USER`/`PICNIC_PASS` are unset, `country` defaults to `PICNIC_COUNTRY // 'de'`.
Construction touches no network — login is deferred to first tool use.
</shape>

<tool-handler-shape>
## The standard tool-handler block

Every capability is a `$server->tool(...)` registration inside `_build_server`.
`$self` is the `MCP::Picnic` instance, captured from the enclosing closure — do NOT
confuse it with the handler's first arg (`$tool`, the `MCP::Tool` instance; see the
perl-mcp skill for that signature rule). Handler signature here is written
`sub { my ($tool, $args) = @_; ... }`.

Every tool except `verify_2fa` is exactly this four-step block, in this order:

```perl
$server->tool(
  name         => 'get_cart',
  description  => '...English, one line...',
  input_schema => { type => 'object', properties => { ... }, required => [...] },
  code => sub {
    my ($tool, $args) = @_;

    my $auth = $self->_ensure_auth;                                   # 1. gate
    return $tool->text_result($auth->{message}, 1) if ref $auth && $auth->{error};

    my $cart = eval { $self->picnic->get_cart };                     # 2. backend, always eval'd
    return $tool->text_result("Could not load cart: $@", 1) if $@;

    return $tool->text_result($self->_to_json($self->_cart_to_hash($cart))); # 3+4. project, encode
  },
);
```

When adding a tool, copy an existing block of the same shape rather than writing
one from scratch — the four steps and their error paths are the contract, not a
suggestion. A tool that skips the gate, calls the backend outside `eval`, returns
an unprojected object, or bypasses `text_result` is wrong even if it runs.
</tool-handler-shape>

<auth-gate>
## Auth gate and the 2FA state machine

`_auth_state` (rw) is a three-state machine: `none` → `pending_2fa` →
`authenticated`. `_ensure_auth` is the single gate every tool but `verify_2fa`
calls first, and its return value is a contract:

- `authenticated` → returns `1`.
- `pending_2fa` → returns `{ error => 1, message => "...verify_2fa..." }`.
- `none` → attempts a lazy `$self->picnic->login` (eval'd). If login reports
  `requires_2fa`, it flips state to `pending_2fa`, requests an SMS code via
  `generate_2fa_code`, and returns the error hash. Otherwise it flips to
  `authenticated` and returns `1`.

So a handler's gate line is always:

```perl
my $auth = $self->_ensure_auth;
return $tool->text_result($auth->{message}, 1) if ref $auth && $auth->{error};
```

`verify_2fa` is the one ungated tool: it takes the SMS `code`, only acts when state
is `pending_2fa` (otherwise it reports nothing is pending), calls
`verify_2fa_code($code)` under `eval`, and on success flips state to
`authenticated`. Login is never a separate user-facing step — it is lazy and
automatic; 2FA is the only interactive part, driven entirely through `verify_2fa`.
</auth-gate>

<backend-and-projection>
## WWW::Picnic delegation and entity projection

`WWW::Picnic` is the only thing that talks to the Picnic service — nothing else,
ever. Every backend call is wrapped in `eval` and a failure becomes a returned
error via `$tool->text_result("...: $@", 1)`, never an uncaught die.

Projection: map each `WWW::Picnic` entity through a small `_*_to_hash` helper
(`_article_to_hash`, `_cart_to_hash`, `_slot_to_hash`, `_user_to_hash`) before
encoding, and expose **only fields that have a real consumer** — do not dump the
whole backend object. Add a new helper when you introduce a new entity type rather
than hand-building a hash inside a handler.

Encode with `_to_json`, the shared `JSON::MaybeXS` encoder held in the `json`
attribute. Do not build a second encoder or call `encode_json` directly — one
canonical encoder keeps output stable (`canonical`) and lets blessed entities
serialize (`convert_blessed`).
</backend-and-projection>

<hazards>
## What the naive change gets wrong

- **`$self` vs `$tool`.** Inside a handler, `$self` (the MCP::Picnic object) comes
  from the closure, not from `@_`. Writing `my ($self, $args) = @_` silently
  rebinds `$self` to the `MCP::Tool` and every `$self->picnic` call breaks.
- **Returning a bare string.** `MCP::Tool` auto-wraps a bare string return but
  drops the `is_error` flag, so an error returned as a plain string reaches the
  client looking like success. Always go through `text_result`, and pass the
  second arg `1` on every error path.
- **Ungated tool.** Any tool other than `verify_2fa` that forgets the
  `_ensure_auth` line will hit `WWW::Picnic` before login and die inside the eval
  with a confusing auth error instead of the clean 2FA prompt.
- **English only in shipped strings.** All tool `description`s, result messages
  and POD are English (this ships to CPAN and to assistants worldwide). The one
  exception is `bin/mcp-picnic-setup`, which carries an `en`/`de` translation
  table — keep `en` complete and primary.
- **Changes bullet.** Any user-facing change (new tool, new parameter, behaviour
  change, bug fix) gets a `  - ` bullet under `{{$NEXT}}` in `Changes` in the same
  change. Never hand-edit the version line — `[@Author::GETTY]` owns it.
</hazards>

<verification>
## Verifying a change

`prove -l t/` — must stay **network-free**. Never hit the real Picnic API or send a
real 2FA SMS from `t/`. Stub the `picnic` attribute (pass a mock, or
`local *WWW::Picnic::method = sub {...}`) to exercise tool code; drive `_auth_state`
directly to test the gate. `t/load.t` is the smoke test; `t/auth.t` and `t/tools.t`
cover the state machine and tool registration.

`dzil build` when touching dist config — confirm the three `bin/` scripts are
packaged. Never `dzil release`.
</verification>
