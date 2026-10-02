# Raider Hall — Claude Code Plugin

> **Not implemented.** The hall does not open the `.raider-hall.mcp` socket
> yet; `mcp: { enable: true }` has no effect, and none of the configuration
> below works. This page describes the planned adapter only.

This plugin is meant to let Claude Code connect to a running `raider hall` daemon via its
MCP adapter socket (`.raider-hall.mcp`).

## Requirements

- `raider hall` running with `mcp: { enable: true }` in `.raider-hall.yml`
- Claude Code with MCP support

## Configuration

Add to your project's `.claude/mcp.json` (or the global Claude Code MCP
settings):

```json
{
  "mcpServers": {
    "raider-hall": {
      "command": "nc",
      "args": ["-U", ".raider-hall.mcp"]
    }
  }
}
```

## Available Tools

Once connected, the following tools are available:

### `spawn_raider`
Spawn a named raider with a mission.

```json
{ "name": "Bjorn", "mission": "list files in /tmp" }
```

### `list_raiders`
List all running raiders in the hall.

```json
{}
```

### `schedule_raid`
Schedule a recurring raid using cron syntax.

```json
{ "name": "Bjorn", "cron": "0 9 * * *", "mission": "send daily report" }
```

### `cancel_job`
Cancel a scheduled job by name.

```json
{ "id": "Bjorn" }
```

### `send_telegram`
Send a Telegram message via a configured bot.

```json
{ "bot": "mybot", "chat_id": 123456789, "text": "Hello!" }
```

### `hall_status`
Get current hall status — running raiders, slots, root directory.

```json
{}
```

## Example Session

```
You: Use the raider-hall MCP to spawn a raider named Bjorn with mission "echo hello"

Claude Code → spawn_raider({ name: "Bjorn", mission: "echo hello" })
→ { id: "Bjorn-1713861234", pid: 12345, slot: "Bjorn" }

You: List running raiders
Claude Code → list_raiders({})
→ { raiders: [{ slot: "Bjorn", pid: 12345, base_name: "Bjorn", ... }] }
```

## Hall Configuration

To enable the MCP adapter, add to your `.raider-hall.yml`:

```yaml
mcp:
  enable: true
```

The socket will be created at `.raider-hall.mcp` in your hall root directory.