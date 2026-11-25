## Docker Service Toggle

Use `d2 docker disable <service>` to create the isolated-service
`disabled.yml` marker without editing files manually. Use
`d2 docker enable <service>` to remove that marker again.
Development compose overlays are independently opt-in. Use
`d2 docker development enable <service>` to create `develop.yml`, or
`d2 docker development disable <service>` to remove it.
Use `d2 docker list` to inspect the effective enabled and disabled
service state, `d2 docker list --disabled` to keep only disabled
services, and `d2 docker list --enabled` to keep only enabled ones.

The toggle writes to the deepest runtime docker root:

- home-only runtime: `~/.developer-dashboard/config/docker/<service>/disabled.yml`
- child project runtime: `./.developer-dashboard/config/docker/<service>/disabled.yml`

That means a child project layer can locally disable an inherited home docker
service by creating its own marker file and can later re-enable the inherited
service by removing that same child-layer marker.

Examples:

```bash
d2 docker list
d2 docker list --disabled
d2 docker list --enabled
d2 docker disable green
d2 docker enable green
d2 docker development enable green
d2 docker development disable green
d2 docker compose config green
```

After `d2 docker disable green`, plain `d2 docker compose config`
auto-discovery skips `green` until the matching marker is removed.

For each enabled service folder, `compose.yml` is always the base and is loaded
when present. `development.compose.yml` is loaded after it only when the
effective service folder contains `develop.yml`. Without the marker, the
development file is ignored even if present. If `develop.yml` exists but
`development.compose.yml` does not, the resolver quietly loads only the base.
Development mode does not enable a service that has been disabled with
`disabled.yml`; that separate marker still excludes the entire service folder.
