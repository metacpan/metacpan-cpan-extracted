# Compose networking and reachability

> Read when: one service cannot reach another or a port is exposed unexpectedly.

Use service DNS names and **container ports** for container-to-container traffic on a shared Compose network. A host publication such as `127.0.0.1:8080:80` is for clients reaching the daemon host; peers use `service:80`. `localhost` inside the application container is that container, not the database or developer laptop.

Separate ingress-facing and backend networks when it limits unnecessary connectivity. `internal: true` expresses an isolated network, not a general application authorization policy. A service connected to multiple networks or carrying host mounts can still bridge trust boundaries through its own behavior.

## Four-hop diagnosis

1. Verify both services share the intended network and the DNS name resolves there.
2. Verify the server process listens on its container interface, not only loopback.
3. Connect to the container port from the same network namespace as the failing client.
4. Only then inspect published ports, host routing, firewall rules, proxies, and external DNS.

Use existing tools first. Installing curl into a production image during an incident changes evidence. A temporary diagnostic container requires approval and network-scoped placement; it may not have the same credentials or policy as the failing service.

Avoid fixed container IP addresses and `container_name` as a discovery strategy. Recreated containers receive new identities/IPs; applications should reconnect by service name. Host networking is platform-specific and changes isolation, so it is not a generic fix for DNS problems.

When a service must reach the host, use the documented host-gateway/Desktop mechanism for that platform and test it. Do not assume Docker Desktop's host alias is automatically present on every Linux daemon. Registry pulls occur from the daemon/runtime or builder, not from the future application's namespace; use the registry skill for those failures.

## Primary sources

- [Docker networking](https://docs.docker.com/engine/network/)
- [Compose services reference](https://docs.docker.com/reference/compose-file/services/)
- [Packet filtering and firewalls](https://docs.docker.com/engine/network/packet-filtering-firewalls/)
