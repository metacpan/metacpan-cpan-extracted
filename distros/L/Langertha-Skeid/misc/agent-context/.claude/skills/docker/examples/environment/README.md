# Environment precedence fixture

From this directory, render without starting containers:

```sh
MODE=debug docker compose -f compose.yaml config
```

Expected: `literal.environment.MODE` remains `production`; `interpolated.environment.MODE` becomes `debug`. This isolates why a shell variable is not a universal override of a literal service environment value. `$$MODE` preserves expansion for the shell inside the eventual container.

To run the demonstration in an approved disposable environment:

```sh
MODE=debug docker compose -p env-skill-lab -f compose.yaml run --rm literal
MODE=debug docker compose -p env-skill-lab -f compose.yaml run --rm interpolated
docker compose -p env-skill-lab -f compose.yaml down
```

Expected output is `MODE=production` and `MODE=debug`, respectively. `alpine:3` is a floating educational tag; pin a reviewed digest in reproducibility-sensitive tests. No secrets are used. These commands can pull an image and create a project network; rendering alone does neither.
