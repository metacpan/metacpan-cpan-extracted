# Profiles, optional services, and one-off jobs

> Read when: debug tools, migrations, test runners, or optional services are involved.

Profiles select services; they do not produce separate security boundaries. Keep required dependencies unprofiled unless the entire feature has a tested activation path. A disabled profile does not make a dangling required dependency harmless.

Explicitly targeting a profiled service activates that target even when its profile was not selected globally. It does not start every other service sharing that profile. Dependencies have their own eligibility rules; test cross-profile graphs rather than assuming any named dependency always becomes available.

```sh
docker compose --profile debug config -q
docker compose --profile debug up -d
docker compose run --rm tools
```

The final command requires a `tools` service in the project; it demonstrates target activation, not a built-in tool.

## One-off work

A migration or bootstrap job should normally have `restart: "no"`, an explicit exit code, a bounded timeout in the orchestrating workflow, and application-level idempotency or locking where repetition is possible. `on-failure` can rerun a partially applied migration; choose it only when that retry behavior is intentional and safe.

`service_completed_successfully` can gate another service on a job's successful completion. It does not establish that the job automatically runs exactly once per release or that schema changes are reversible. Tie migrations to a recorded release/schema identity, and make a failed migration block promotion.

## CI and profiles

Give every test invocation a unique project name and avoid fixed host ports. Select profiles explicitly, collect job exit status, retain failure logs with redaction, and clean up only that project's resources. Do not let `--remove-orphans` remove another workflow's services because both accidentally reused a project identity.

Test baseline, optional-profile, explicitly targeted job, and invalid dependency cases. Store the resolved service sets as assertions in the project's CI, not just in a diagram.

## Primary sources

- [Compose profiles](https://docs.docker.com/compose/how-tos/profiles/)
- [Compose startup and shutdown](https://docs.docker.com/compose/how-tos/startup-order/)
- [Compose services reference](https://docs.docker.com/reference/compose-file/services/)
