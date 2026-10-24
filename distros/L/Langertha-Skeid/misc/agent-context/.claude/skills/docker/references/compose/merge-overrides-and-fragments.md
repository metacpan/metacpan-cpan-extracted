# Merge, overrides, extension fields, and fragments

> Read when: splitting development/production settings or removing an inherited port/mount.

`-f base.yaml -f production.yaml` merges models in order. It is not textual inclusion, and not every value is simply replaced. Resolve relative paths using the first/base file's project directory unless the CLI project-directory option changes it. This differs from `include`.

Mappings merge keys. Many sequences append. `command`, `entrypoint`, and `healthcheck.test` replace rather than concatenate. Service volumes, secrets, configs, and ports have special uniqueness rules; ports include binding address, target, published port, and protocol. Changing a published port can therefore leave the old one present.

```yaml
# production.yaml: requires Compose supporting !override (2.24.4+)
services:
  app:
    ports: !override
      - "127.0.0.1:8443:8080"
```

Use `!reset []` to clear an inherited list when supported, or `!override` to replace it explicitly. Validate the final model, not only the override text. Generic YAML parsers may reject these Compose-specific tags; their failure is not a Compose validation result.

## Anchors and extension fields

`x-...` extension fields plus YAML anchors reduce repeated structures within a YAML document. They are not cross-file imports or parameterized templates. YAML merge keys operate on mappings, not arbitrary sequences. Keep anchors local and readable; copying half a service through several anchors makes reviews harder, not more modular.

## Safe production composition

Specify production files explicitly. Otherwise the conventional automatic `compose.override.yaml` may import development bind mounts or debug ports. Render using the same directory and variables as deployment. Review image digests, published addresses, mounts, users, resource constraints, secret sources, and enabled services.

A useful test asserts that production has **no** source bind mounts and **only** intended published ports. For every override, keep one positive assertion and one absence assertion: “8443 is present” is weaker than “8443 is present and 8080 is absent.” Read the include reference for independently owned subprojects rather than extending an override chain indefinitely.

## Primary sources

- [Compose merge rules](https://docs.docker.com/reference/compose-file/merge/)
- [Multiple Compose files](https://docs.docker.com/compose/how-tos/multiple-compose-files/merge/)
- [Compose include](https://docs.docker.com/reference/compose-file/include/)
