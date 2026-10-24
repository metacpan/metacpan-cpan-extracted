# Compose CI, production deployment, and rollback

> Read when: designing a release pipeline or operating a single-host production stack.

## Test lifecycle

Give each CI job an isolated project name and avoid fixed container names and host ports. Build the tested image, run tests against that artifact, capture exit status, collect bounded redacted logs, and remove only the job's resources. Do not turn a shared worker into a global prune target. Keep test-volume deletion explicitly scoped to disposable fixtures.

For a test service, `up --abort-on-container-exit --exit-code-from tests` can transfer its exit code to CI. This is a foreground test pattern, not a detached production deployment command. Test the project's dependency graph and timeouts so an unrelated service does not end the run prematurely.

## Deployment sequence

Record context, project, ordered file set, variables, approved image digests, and prior release. Validate the rendered model. Check backup and migration readiness. Pull approved artifacts. Apply `up -d` with the same inputs. Use the CLI's supported wait/timeout behavior or a separate bounded readiness test. Verify an external application request in addition to container health. Record what actually ran.

Do not imply `up --wait` is a transaction: a failure can leave some new containers running. Keep a partial-deployment inventory. `restart` does not apply new image/config values. `--force-recreate` is not a substitute for choosing the intended image digest.

## Rollback contract

An image rollback is valid only if the old application remains compatible with the current schema/data. Use expand/contract migrations where possible and define the irreversible boundary. Restore data only through a reviewed recovery plan; do not overwrite live volumes merely to match an older image.

Production should not accidentally discover development overrides. Use explicit file selection and assert absence of source mounts, debug ports, weak credentials, and floating release tags. Single-host Compose still has a host-level availability limit. Multiple containers on the same daemon do not solve host failure or supply a distributed rollout controller.

## Primary sources

- [Compose in production](https://docs.docker.com/compose/how-tos/production/)
- [Compose services reference](https://docs.docker.com/reference/compose-file/services/)
- [Compose startup and shutdown](https://docs.docker.com/compose/how-tos/startup-order/)
- [Multiple Compose files](https://docs.docker.com/compose/how-tos/multiple-compose-files/merge/)
