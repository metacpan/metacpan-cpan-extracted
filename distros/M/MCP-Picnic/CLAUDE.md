# CLAUDE.md — MCP::Picnic

A Moo-based MCP (Model Context Protocol) server that exposes the Picnic Supermarket API
(via `WWW::Picnic`) to AI assistants such as Claude. One main module registers a set of MCP
tools (product search, cart management, delivery slots, user info) behind an interactive 2FA
login flow.

This distribution ships its own house rules (`.claude/rules/`), agents (`.claude/agents/`)
and skills (`.claude/skills/`). The build/test/POD/release machinery comes from the
`[@Author::GETTY]` plugin bundle — see the **getty-perl-release-author-getty** and
**perl-release-dist-ini** skills. This file documents only what's specific to MCP::Picnic.

## House rules

Engineering discipline, the delegation lock, coordination and release rules live in
`.claude/rules/mcp-picnic-rules.md` (auto-loaded every turn). The Perl/Moo, MCP and
architecture conventions live in the skills named below — don't look for them here.

## Delegation

Delegate behavior-relevant code to the right agent instead of touching it yourself — the
principle and lanes are in `.claude/rules/mcp-picnic-rules.md`.

| Task | Agent |
|---|---|
| Implement / refactor / debug behavior-relevant code | `mcp-picnic-worker` (default) |
| Write or improve POD | `mcp-picnic-pod-writer` |
| Add / extend tests | `mcp-picnic-test-writer` |
| Pre-release audit (cpanfile pins, version placement, Changes, build) | `mcp-picnic-release-checker` |

Agents carry their skills via `briefing.skills` (the `briefing` plugin is enabled in
`.claude/settings.json`); the main agent delegates rather than loading them. Skill sources
live under `.claude/skills/`: `mcp-picnic-core` (project-owned) plus the hardlinked shared
skills (`getty-perl-core`, `getty-perl-moo`, `perl-mcp`, `perl-release-dist-ini`,
`getty-perl-release-author-getty`, `kanban-issues-karr-cli`).

## Structure

```
lib/MCP/Picnic.pm        # The whole server: Moo attrs, _build_server tool registry, helpers
bin/mcp-picnic           # stdio entry point (Claude Desktop and other MCP clients)
bin/mcp-picnic-http      # Mojolicious server: /mcp MCP endpoint + REST API
bin/mcp-picnic-setup     # Interactive setup wizard (writes MCP client config)
t/load.t                 # module load smoke test
```

## Design notes

- **Tools** (`_build_server`): `verify_2fa`, `search_products`, `get_product_details`,
  `get_suggestions`, `get_cart`, `add_to_cart`, `remove_from_cart`, `clear_cart`,
  `get_delivery_slots`, `set_delivery_slot`, `get_user`, `get_categories`. Each (except
  `verify_2fa`) gates on `_ensure_auth`, wraps the `WWW::Picnic` call in `eval`, projects the
  result through a `_*_to_hash` helper, encodes it with `_to_json` and returns it via
  `$tool->text_result(...)` — error paths use `$tool->text_result($msg, 1)` so the `is_error`
  flag reaches the client.
- **Auth** is a three-state machine on `_auth_state` (`none` → `pending_2fa` →
  `authenticated`). First use triggers a lazy `login`; if Picnic demands 2FA, an SMS code is
  requested and the assistant must call `verify_2fa` before any other tool will work.
- **Config** comes from `PICNIC_USER` / `PICNIC_PASS` / `PICNIC_COUNTRY` (default `de`).
- **JSON** uses one shared `JSON::MaybeXS` encoder (`utf8`, `canonical`, `convert_blessed`).

## Testing

`prove -l t/` — must stay network-free. Never hit the real Picnic API or send real 2FA SMS in
`t/`. Stub the `picnic` attribute to exercise tool code and the auth state machine. `dzil build`
to verify packaging (the `bin/` scripts must be included).

## Related

- `mcp-picnic-core` skill — the Picnic-specific composition: tool-handler shape, the auth/2FA
  gate, `WWW::Picnic` delegation, `_*_to_hash` projection
- `perl-mcp` skill — MCP server patterns in Perl (`MCP::Server`, `$server->tool`, handler
  signature, `text_result`)
- `getty-perl-core` / `getty-perl-moo` skills — house Perl style and Moo patterns
- `getty-perl-release-author-getty` / `perl-release-dist-ini` skills — build/POD/release workflow
- `WWW::Picnic` — the backend client this server wraps
- Picnic: <https://picnic.app/>
```
