# Plan: MCP::Wiki - Markdown Wiki MCP Server

## Overview

Ein MCP Server der ein Wiki in einem Verzeichnis managed. Pages sind Markdown-Dateien.

## Core Modules

### MCP::Wiki::Server
- Main MCP Server class
- Holds wiki root directory
- `on_change` callback system
- Git integration options

### MCP::Wiki::Document
- Represents a single wiki page (markdown file)
- `get_toc()` - Returns table of contents (H1-H6 headlines with line numbers and content preview)
- `get_paragraph($heading)` - Get content under a specific heading
- `set_paragraph($heading, $content)` - Update content under a heading
- `get_section($start_line, $end_line)` - Get raw section by line range

### MCP::Wiki::TOC::Entry
- Represents a single TOC entry
- Fields: `level`, `heading`, `anchor`, `heading_path`, `line_start`, `line_end`, `content_preview`, `char_count`

## MCP Tools

### Tool Handler Signature (IMPORTANT)
```perl
$server->tool(
  name => 'list_pages',
  input_schema => {...},
  code => sub ($tool, $args) {
    # $tool is MCP::Tool instance, $args is deserialized JSON
    # Use $tool->text_result() or ->structured_result() for output
    # NOT $self->method() - tool handlers are closure-based
  }
);
```

### Security: Path Handling
- `root_dir` override MUST be canonicalized via `realpath()`
- Reject any path that escapes wiki root (check `starts_with($root_dir)`)
- Reject symlinks pointing outside wiki root
- Block `../` traversal attempts

### Tools

| Tool | Description | Options |
|------|-------------|---------|
| `list_pages` | List all wiki pages | `root_dir` optional override |
| `get_toc` | Get TOC of a page | `page`, `root_dir` |
| `get_paragraph` | Get paragraph under heading | `page`, `heading`, `root_dir` |
| `create_page` | Create new page | `page`, `content`, `root_dir` |
| `update_paragraph` | Update paragraph | `page`, `heading`, `content`, `reason`, `root_dir` |
| `rename_page` | Rename/move page | `from`, `to`, `root_dir` |
| `delete_page` | Delete page | `page`, `root_dir` |
| `get_section_history` | Get commit history for section | `page`, `heading`, `root_dir` |
| `restore_section` | Restore section to commit state | `page`, `heading`, `commit_hash`, `root_dir` |

## Section Identity (Critical for History)

**Line ranges are fragile after edits!** Instead, sections are identified by:
1. **Heading path**: e.g. "Installation#Ubuntu#Docker" (nested headings)
2. **Content hash**: SHA-256 of section content at commit time
3. **Heading anchors**: Store mapping of heading → commit snapshot

Restore operation:
- Fetch historical content via heading path
- Apply as diff against current content
- Detect conflicts if content diverged significantly
- On conflict: return conflict markers, don't auto-overwrite

## TOC Format

```json
{
  "page": "example.md",
  "entries": [
    {
      "level": 1,
      "heading": "Introduction",
      "anchor": "introduction",
      "heading_path": "Introduction",
      "line_start": 1,
      "line_end": 5,
      "content_preview": "This is the intro...",
      "char_count": 120
    },
    {
      "level": 2,
      "heading": "Background",
      "anchor": "background",
      "heading_path": "Introduction#Background",
      "line_start": 6,
      "line_end": 15,
      "content_preview": "Some background info...",
      "char_count": 450
    }
  ]
}
```

### TOC Parsing Edge Cases
- Ignore headings inside fenced code blocks (\`\`\`)
- Ignore headings inside indented code (4+ spaces)
- Ignore HTML comment blocks and raw HTML
- Ignore headings inside table cells
- Section boundary: ends at next heading of same or higher level
- Duplicate heading disambiguation: use heading_path (full ancestor chain)

## Git Integration (Optional via `use_git` config)

### MCP::Wiki::Git
- Lightweight Git history tracking for wiki pages
- NOT using git CLI commands - direct libgit2 via Git::Raw
- Per-page blame tracking
- Commit history with message + author + timestamp
- `get_section_history($page, $heading_path)` - Get history for section via heading path
- `restore_section($page, $heading_path, $commit_hash)` - Restore section from commit

### Commit Message Policy
- If `reason` option provided in update, use it as commit message
- Else auto-generate: "Update $page: $heading"

## on_change Callback System

```perl
$wiki->on_change(sub ($event) {
  # $event = { type => 'create'|'update'|'delete', page => '...', reason => '...' }
});
```

### Async-Safe Design
- Callbacks run AFTER atomic file write completes
- Git operations should NOT block the main thread
- Option: `async_callbacks => 1` uses Future/Promise queue
- Option: `git_background => 1` commits in background worker
- Callback errors are logged but don't fail the write
- Partial success handling: file write succeeds, callback may fail (logged)

## File Structure

```
p5-mcp-wiki/
├── dist.ini
├── cpanfile
├── Changes
├── README.md
├── lib/
│   └── MCP/
│       └── Wiki/
│           ├── Server.pm         # Main server + on_change
│           ├── Document.pm       # Page operations
│           ├── TOC/
│           │   ├── Entry.pm      # TOC entry object
│           │   └── Parser.pm     # Markdown TOC extraction
│           └── Git/
│               ├── History.pm    # Section history tracking
│               └── Blame.pm      # Per-line blame tracking
├── bin/
│   └── mcp-wiki                  # CLI runner
└── t/
    ├── 00-load.t
    ├── 10-server.t
    ├── 20-document.t
    ├── 30-toc.t
    └── 40-git.t
```

## Dependencies

```perl
requires 'MCP';                    # MCP server framework
requires 'Markdown::TableOfContents';  # TOC extraction (or custom)
requires 'Path::Tiny';             # File operations
requires 'Git::Raw';               # Git integration
requires 'Syntax::Keyword::Try';   # Try/catch
```

## Phased Implementation

### Phase 1: Core Infrastructure
- dist.ini, cpanfile, basic structure
- MCP::Wiki::TOC::Entry and Parser
- MCP::Wiki::Document basic (read page, get TOC, get paragraph)

### Phase 2: Write Operations
- create_page, update_paragraph, rename_page, delete_page
- on_change callback system

### Phase 3: Git Integration
- MCP::Wiki::Git::History and Blame
- git_auto_commit built-in handler
- Section history/restore

### Phase 4: Polish
- CLI tool, documentation, tests

## Production Concerns (Out of Scope for V1, but Documented)

- Auth/access control (future: per-page ACLs)
- Concurrent edits (future: file locking / OT)
- Optimistic version checks (future: ETag support)
- Backup/export (future: git bundle / zip)
- Size limits (future: max file size config)
- Markdown validation (future: Lint tool)
- Pagination/search (future: search_pages tool)
- Conflict reporting (future: 3-way merge UI)

## Notes

- TOC extracts H1-H6 from markdown
- Line ranges are 1-indexed, inclusive
- Git history uses Git::Raw (not CLI) for efficiency
- on_change is synchronous callback, runs after write completes
- Heading path uses `#` as separator (like URL anchors)