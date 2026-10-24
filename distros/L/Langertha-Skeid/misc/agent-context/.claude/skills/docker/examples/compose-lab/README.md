# Compose lab: include, health, storage, profiles, and Watch

This **local teaching fixture** uses a standard-library Python HTTP server and a helper job. It is not a production web service. Requirements: a Linux-container Engine, Compose supporting `include` and the chosen overrides (2.24.4+ or suitable v5), registry access to pull the Python image, and a free loopback port. The Python minor-version tag is intentionally readable; resolve and pin approved digests for controlled use.

## Run from this directory

```sh
cp .env.example .env
docker compose -f compose.yaml config -q
docker compose -f compose.yaml up -d --build --wait --wait-timeout 60
curl --fail http://127.0.0.1:18080/health
docker compose -f compose.yaml run --rm check
```

The `check` service is in a separately included model. Its `./check.py` mount resolves relative to `modules/tools/`, not the parent directory. It addresses `app:8080` over the project network. Explicit `run check` targets a profiled service; it does not enable every hypothetical tool in that profile.

The image owns `/state` as UID 10001. A new named volume is seeded from that path. Verify persistence with `docker compose exec app cat /state/last-start.txt`. This file is merely a demonstration, not a backup mechanism. Keep the project's volumes across normal cleanup:

```sh
docker compose -f compose.yaml down
```

Volume destruction is intentionally not in the run sequence. Remove only the verified disposable lab volume after explicit review. Do not add `-v` to a production command copied from another project.

## Override semantics

```sh
docker compose -f compose.yaml -f compose.port-override.yaml config
```

Expected: only loopback port 18081 is published for the app, not 18080 as well. Generic YAML syntax checkers need custom-tag support; use Compose for authoritative merge behavior.

## Watch

```sh
docker compose -f compose.yaml -f compose.dev.yaml up --watch
```

A source change syncs and restarts the service; a Dockerfile change rebuilds. The development override deliberately permits writes to `/app`; this does not belong in a production model. Stop the earlier run first if needed to avoid competing invocations. Source code must remain owned/writable by UID 10001.

## Isolation and limitations

Use `-p UNIQUE_NAME` and distinct `APP_PORT` values for simultaneous copies. The demo does not test TLS, database migrations, authentication, multi-node availability, or Docker Desktop-specific file sharing. The delivery's validation report states whether live Compose execution was available; syntax checks alone do not prove runtime success.
