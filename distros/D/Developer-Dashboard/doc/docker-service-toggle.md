## Docker Service Toggle

Use `dashboard docker disable <service>` to create the isolated-service
`disabled.yml` marker without editing files manually. Use
`dashboard docker enable <service>` to remove that marker again.
Use `dashboard docker list` to inspect the effective enabled and disabled
service state, `dashboard docker list --disabled` to keep only disabled
services, and `dashboard docker list --enabled` to keep only enabled ones.

The toggle writes to the deepest runtime docker root:

- home-only runtime: `~/.developer-dashboard/config/docker/<service>/disabled.yml`
- child project runtime: `./.developer-dashboard/docker/<service>/disabled.yml`

That means a child project layer can locally disable an inherited home docker
service by creating its own marker file and can later re-enable the inherited
service by removing that same child-layer marker.

Examples:

```bash
dashboard docker list
dashboard docker list --disabled
dashboard docker list --enabled
dashboard docker disable green
dashboard docker enable green
dashboard docker compose config green
```

After `dashboard docker disable green`, plain `dashboard docker compose config`
auto-discovery skips `green` until the matching marker is removed.
