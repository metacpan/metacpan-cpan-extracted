# Interpolation versus container environment

> Read when: an environment value is wrong, missing, or different between config and runtime.

There are **two evaluations**, not one precedence chain.

## 1. Resolve the Compose model

Compose reads `${NAME}` expressions using its interpolation environment. The shell has priority. Without `--env-file`, a working-directory `.env` can supply values; explicit env files and project-directory `.env` behavior depend on invocation/project resolution. Use the official interpolation rules for unusual working-directory or `COMPOSE_FILE` cases.

```yaml
services:
  app:
    image: "${APP_IMAGE:?Set APP_IMAGE to an approved image}"
    environment:
      MODE: "${APP_MODE:-development}"
```

A shell variable named `MODE` does **not** replace an unrelated literal `MODE: production` in the model. It matters only where Compose imports or interpolates it. `.env` is not automatically injected into every container.

## 2. Construct the container environment

Image `ENV` supplies defaults. Service `env_file` adds values. Service `environment` overrides them, including explicitly empty values. `docker compose run -e` supplies one-off CLI overrides. Interpolated values in `environment` or `env_file` can inherit their values from the shell or interpolation env files; that is why the full official precedence table is more nuanced than a single flat ordering.

```yaml
services:
  app:
    env_file: ./app.env
    environment:
      MODE: production
      EMPTY_VALUE: ""
```

Here `MODE` is `production` regardless of an unrelated shell `MODE=debug`. An entry with no value can request pass-through or result in an unset value; distinguish absent, empty, and literal strings in tests. Quote boolean-looking values.

## Expansion and file formats

`${VAR:-default}` uses a default when unset or empty; `${VAR-default}` only when unset. `${VAR:?message}` makes missing/empty deployment inputs fail early. `$$` preserves a literal dollar for later container-side expansion. Service `env_file` interpolation is a Compose feature and differs from `docker run --env-file`. `format: raw` and `required: false` are version-gated options.

## Debug without leaking secrets

Check the exact invocation and `config --environment` locally, then inspect only the specific non-sensitive runtime variable. Do not dump all container environment values. For CI, run a small matrix covering unset, empty, shell override, env-file override, and multiple Compose files. The included environment fixture demonstrates the literal-versus-interpolated distinction.

## Primary sources

- [Compose interpolation sources](https://docs.docker.com/compose/how-tos/environment-variables/variable-interpolation/)
- [Container environment precedence](https://docs.docker.com/compose/how-tos/environment-variables/envvars-precedence/)
- [Setting container environment variables](https://docs.docker.com/compose/how-tos/environment-variables/set-environment-variables/)
