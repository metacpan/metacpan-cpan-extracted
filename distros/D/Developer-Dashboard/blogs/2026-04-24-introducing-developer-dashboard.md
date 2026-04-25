# Introducing Developer Dashboard

Developer Dashboard is a command-line workspace for developers who live in terminals and want their tools, project context, and local automation gathered into one place.

It is not trying to replace your editor, your shell, your browser, or your existing project layout. It is trying to give them a shared operating surface.

## Why It Exists

A typical development machine ends up with the same recurring problems:

- too many one-off scripts
- too many project-specific commands to remember
- too many environment variables and local conventions hidden in shell history
- too much context switching between terminal, browser, config files, and helper tools

Developer Dashboard is built to reduce that friction.

Instead of making you memorize another stack of ad-hoc commands, it gives you a single entry point:

```bash
dashboard
```

From there, you can manage pages, skills, collectors, local services, runtime state, project layers, and terminal-facing helper commands in one consistent system.

## What Makes It Different

Developer Dashboard is designed around local development reality.

It understands that developers work across:

- a home-level personal environment
- one or more project folders
- nested workspaces inside those projects
- local scripts and helper commands that need to behave differently depending on where you are

That is why Developer Dashboard uses layered `.developer-dashboard` directories instead of assuming everything belongs in one global config or one single project root.

The result is a system where:

- home-level tools can be shared
- project-level tools can override them
- deeper folders can add more context without breaking the rest

## Core Ideas

The first release of any tool should make its model obvious, so here is the short version.

### 1. One command surface

Developer Dashboard gives you a single command namespace for your day-to-day tools:

```bash
dashboard version
dashboard page
dashboard skills install
dashboard restart
```

It also supports the short alias:

```bash
d2
```

### 2. Thin command entrypoint

The public `dashboard` command stays thin.

It acts as a switchboard that stages and dispatches helper commands only when they are needed. That keeps lightweight commands fast and avoids loading the whole application for simple tasks.

### 3. Skills

Skills are installable capability bundles.

A skill can bring:

- commands
- configuration
- dependency manifests
- pages
- supporting automation

This makes it possible to grow your local developer environment in small pieces instead of building one giant custom dotfiles system.

### 4. Pages

Pages are reusable interface definitions for dashboard-driven workflows.

They give you a structured way to expose useful developer interactions without forcing everything into shell aliases or throwaway scripts.

### 5. Runtime awareness

Developer Dashboard is not just a file organizer. It also knows how to manage runtime pieces such as collectors, background helpers, and the local web service when those are enabled.

## What You Can Use It For

Developer Dashboard is useful anywhere you want local tooling to feel more intentional.

Some examples:

- keeping project-specific command helpers close to the project
- exposing repeatable workflows through stable CLI commands
- installing reusable skills for tasks like browser workflows, dashboards, or local automation
- managing layered configuration across home, project, and nested workspaces
- giving teams a more structured local setup without forcing everyone into the same shell customizations

## A Small Example

After installation, a developer can start with something as simple as:

```bash
dashboard version
dashboard init
d2 skills install browser
```

That flow is intentionally direct:

- verify the command is available
- initialize the local dashboard environment
- add a skill to extend what the dashboard can do

The goal is not ceremony. The goal is to get from zero to useful quickly.

## Who It Is For

Developer Dashboard is for developers who want:

- a terminal-first workflow
- reusable local tooling
- project-aware command dispatch
- less shell-history archaeology
- a cleaner path from personal scripts to structured automation

It is especially useful if you have ever built a pile of helper scripts and later realized you had accidentally created your own fragile internal platform.

Developer Dashboard is that idea, made explicit and made maintainable.

## What This Blog Series Will Cover

This is the first post in the series, so it is intentionally high level.

Next posts can go deeper into topics like:

- how layered `.developer-dashboard` directories work
- how skills are installed and updated
- how pages fit into local developer workflows
- how runtime helpers and collectors work
- how to bootstrap Developer Dashboard on a fresh machine

## Closing

Developer Dashboard is a practical tool for organizing local developer power without hiding it behind magic.

It keeps the terminal at the center, treats project structure seriously, and gives developers a cleaner way to build up reusable local workflows over time.

If your current setup is a mix of shell aliases, copied scripts, sticky notes, and muscle memory, this project is built for exactly that situation.
