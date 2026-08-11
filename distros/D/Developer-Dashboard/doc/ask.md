# Asking an AI backend: `dashboard ask`

`dashboard ask <question>` puts a question to an AI coding assistant straight
from the shell and prints a plain-text answer. The running conversation is
remembered **per workspace**, so a later `dashboard ask` in the same workspace
continues the same thread instead of starting over.

## Backends

One flag selects the backend for the turn, and the choice becomes **sticky** for
the workspace until you pick another:

- `--claude` (default) — answers over the Anthropic API when a key is available,
  otherwise falls back to the local `claude` CLI (Claude Code).
- `--codex` — shells out to the Codex CLI (`codex exec`), forced to a read-only
  sandbox so an ask can never mutate the tree.
- `--copilot` — shells out to the Copilot CLI (`copilot -p ... --allow-all-tools`).
- `--gemini` — shells out to the Gemini CLI (`gemini -p ...`).

Each CLI backend is invoked non-interactively. If the selected CLI is not
installed, `ask` reports which package to install rather than failing silently.

## Key resolution (claude backend)

1. `ANTHROPIC_API_KEY` in the environment.
2. `claude.api_key` in the merged dashboard config.
3. If no key is found, the local `claude` CLI is used instead.
4. If there is neither a key nor a `claude` CLI, `ask` reports the problem.

The model defaults to `claude-opus-4-8` and can be overridden per turn with
`--model` or globally with `claude.default_model`. `claude.base_url` and
`claude.max_tokens` are also honored.

## Conversation memory

The transcript is keyed by `WORKSPACE_REF` (or, when unset, the active project
root) and stored owner-only (`0600`) under the runtime state root. Prior turns
are replayed to the backend so follow-up questions carry context.

- `--new` (or `--reset`) starts a fresh conversation for the workspace.
- `--no-memory` skips the transcript for a single turn: no prior turns are sent
  and the turn is not saved.

## Attachments

`--file <path>` is repeatable. Text files are inlined beneath the question.
Image files are attached natively: Anthropic image blocks for the API path,
`-i` for codex, and `--attachment` for copilot. The `claude` CLI fallback and
gemini cannot attach images, so `ask` asks you to set a key or choose another
backend instead of dropping the attachment silently.

## Examples

```sh
# Ask the default claude backend; the turn is remembered for this workspace.
dashboard ask "How do I list collectors?"

# Switch to codex (sticky) and inline a text file.
dashboard ask --codex "Explain this stack trace" --file trace.txt

# Start over and override the model for one turn.
dashboard ask --new --model claude-sonnet-5 "Summarize the repo"

# Pipe context in on stdin.
git diff | dashboard ask "Review this change"
```
