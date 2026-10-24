# Hardening and agent/CI access to Docker

> Read when: giving an agent, runner, or application Docker control.

Treat access to a rootful Docker daemon as host-administrative capability. Mounting `/var/run/docker.sock` read-only does not create a read-only HTTP API: the client can still send state-changing requests through the socket. A socket proxy's URL allowlist is insufficient if an allowed create endpoint accepts host mounts or privileged settings.

## Least-privilege workload baseline

Prefer a non-root application user, a read-only root filesystem, explicit writable mounts, dropped unnecessary capabilities, `no-new-privileges`, default seccomp/LSM protection, resource limits, and limited network reachability. Verify application behavior under each restriction. Do not disable seccomp, SELinux/AppArmor, or use `privileged` as the first troubleshooting step.

Non-root inside the container, user-namespace remapping, and a rootless daemon are different controls. None substitutes for a trusted daemon API caller. A client able to create arbitrary containers may read accessible host/user files even when the daemon is rootless.

## Agent policy

Separate read-only observation from mutation authorization. Require explicit intent and exact target identity for deletion, volume access, host networking, devices, privileged containers, daemon config, registry credentials, and public port exposure. Keep an audit record that omits secrets. Use dedicated isolated workers for untrusted builds instead of sharing the main daemon socket.

For remote control, use SSH or mutually authenticated TLS with narrowly controlled identities and network access. TLS authenticates and encrypts; it does not itself constrain operations. A policy-enforcing broker must inspect request bodies and reconcile ownership, not just relay HTTP verbs.

## Incident boundary

If an untrusted process had daemon control, treat secrets and workloads on that daemon as potentially exposed. Stopping that one container is not a complete remediation. Rotate affected credentials and rebuild trust using the organization's incident procedure. Do not claim that a mount or network sandbox protected data that the daemon API could itself expose.

## Primary sources

- [Protect the daemon socket](https://docs.docker.com/engine/security/protect-access/)
- [Rootless mode](https://docs.docker.com/engine/security/rootless/)
- [Container resource constraints](https://docs.docker.com/engine/containers/resource_constraints/)
- [Bind mounts](https://docs.docker.com/engine/storage/bind-mounts/)
