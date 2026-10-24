# Runtime secrets, configs, and trust boundaries

> Read when: distributing credentials or configuration to Compose services.

Use configs for non-secret configuration and secrets for sensitive files granted to specific services. Mounting a secret does not automatically teach an application how to read it. Environment names ending in `_FILE` are application/image conventions, not universal Docker behavior.

Local Compose file-backed secrets are not the same security mechanism as Swarm-managed encrypted secrets. Protect the source files, host, backup path, and container access. Changing the source may not cause an application to reread it; document whether reload or recreation is required.

```yaml
services:
  app:
    image: "${APP_IMAGE:?Set APP_IMAGE}"
    secrets:
      - api_token
    environment:
      API_TOKEN_FILE: /run/secrets/api_token
secrets:
  api_token:
    file: ./secrets/api-token.txt
```

This is a template; the application must implement `API_TOKEN_FILE`. Do not store the real secret in the example repository. On local file-backed implementations, requested uid/gid/mode remapping may not be implemented as expected; verify readability by the actual runtime user rather than relying only on YAML.

## Operational policy

Generate credentials through your approved secret manager or provisioning mechanism. Keep them out of Git, command history, image layers, interpolation reports, and debug logs. Use different identities for application access, registry pull, registry push, and daemon control. Rotate a credential by updating its source, restarting/reloading consumers as required, testing the new identity, and revoking the previous one.

When reviewing configs, distinguish a TLS server certificate, its private key, a trust anchor, and a client certificate. Mounting a CA into the application container does not update daemon or BuildKit registry trust. A container with the Docker socket can often extract secrets and alter other containers; socket access is a host-control boundary, not another config mount.

## Primary sources

- [Compose secrets](https://docs.docker.com/compose/how-tos/use-secrets/)
- [Compose services reference](https://docs.docker.com/reference/compose-file/services/)
- [Protect the daemon socket](https://docs.docker.com/engine/security/protect-access/)
