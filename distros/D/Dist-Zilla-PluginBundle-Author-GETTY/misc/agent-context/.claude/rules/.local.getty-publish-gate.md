---
description: Getty's publish gate — nothing leaves the machine or speaks in the maintainer's name without an explicit go-ahead.
---

# Publish gate — never without permission

Local work — build, test, commit — is fine anytime. Everything that leaves this machine or
speaks in the maintainer's name waits for the maintainer's explicit go-ahead, even when a
plan, ticket or status document lists it as the next step:

- releases and uploads — CPAN, npm, any package registry or store, `gh release`
- pushing commits or tags, publishing images, deploying, changing a repository's visibility
- any write on a public tracker — issues, pull requests, comments, reviews

A go-ahead covers what it names. Heading toward any of these: stop and ask.

**Public trackers are not a queue.** karr is the agent board — internal, churned freely.
Public issues and pull requests (GitHub, Codeberg, …) carry real people's reports under the
maintainer's name: never list, read, comment on, close or create one on your own initiative
— only when the user names the specific issue or pull request to handle.
