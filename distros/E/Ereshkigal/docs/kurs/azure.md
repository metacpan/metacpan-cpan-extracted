# azure — an Azure NSG deny rule

Blocks in Azure by rewriting the source address prefixes of one
inbound deny rule in a Network Security Group, via the `az` CLI. The
NSG, the rule, and its subnet/NIC association are yours; the kur
owns the rule's `--source-address-prefixes`, rendered wholesale from
its ban book on every change. One rule carries both IPv4 and IPv6.

```toml
[kur.web]
backend = "azure"

[kur.web.options]
resource_group = "prod-rg"
nsg            = "web-nsg"
rule           = "kur-web-deny"
```

## Azure-side setup — required first

- The NSG, associated with the subnets/NICs to protect.
- An **inbound deny rule already existing** under the configured
  name, with its priority, protocol, and port scoping set the way
  you want — the kur only ever touches the source prefixes:

```shell
az network nsg rule create --resource-group prod-rg --nsg-name web-nsg \
    --name kur-web-deny --priority 100 --direction Inbound --access Deny \
    --protocol '*' --source-address-prefixes 192.0.2.255/32 \
    --destination-address-prefixes '*' --destination-port-ranges '*'
```

- `az login` (or a service principal / managed identity the kur's
  environment resolves) with
  `Microsoft.Network/networkSecurityGroups/securityRules/write`.

## Requirements

- The `az` CLI in the `PATH` of the kur process (or `az_cmd`),
  authenticated.

## Settings

- `ports` / `protocols` — accepted for parity but **ignored**; the
  rule's own protocol/port fields are the scoping, set by you at
  rule creation.
- `enable_cidr` — supported; source prefixes are prefixes already,
  so ranges land as themselves.
- `prefix` — unused.

## Options

| option           | default      | what                                    |
|------------------|--------------|------------------------------------------|
| `resource_group` | *(required)* | resource group holding the NSG          |
| `nsg`            | *(required)* | the NSG name                            |
| `rule`           | *(required)* | the deny rule the kur owns              |
| `subscription`   | *(unset)*    | adds `--subscription <sub>` when set    |
| `az_cmd`         | `az`         | the az CLI binary                       |

## What each operation runs

| operation  | command                                                              |
|------------|--------------------------------------------------------------------------|
| `init`     | `az network nsg rule show --resource-group <rg> --nsg-name <nsg> --name <rule>` |
| `ban`      | `az network nsg rule update ... --source-address-prefixes <ip1>/32 <ip2>/128 ...` — the full sorted book |
| `unban`    | the same render, minus the IP                                        |
| `list`     | no command — the kur's own ban book                                  |
| `check`    | the same show as init                                                |
| `flush`    | the update with an empty prefix list                                 |
| `re_init`  | teardown (best effort), init, update with the full book              |
| `teardown` | update with empty prefixes (ban book kept)                           |

## self_heal

`check` verifies the rule exists and az auth works — not its
prefixes. Hand-edits are overwritten at the next mutation, wholesale
rendering being self-correcting as usual.

## Gotchas

- **An NSG deny rule with an empty source prefix list matches
  nothing** — after flush/teardown the rule sits inert, which is the
  intended state, but don't be surprised that it still exists.
- NSG rules take a large number of prefixes (well into the
  thousands), so volume is fine; each mutation is one `az` CLI
  invocation, which is slow (seconds) — cloud pace, not packet pace.
- `az` sessions/service principal tokens can expire under a
  long-running kur; auth errors on ban mean credentials, not code.
- Errors carry Error::Helper flags (`resourceGroupNotDefined`,
  `nsgNotDefined`, `ruleNotDefined`, …) — [`Net::Firewall::BlockerHelper::backends::azure`](https://metacpan.org/pod/Net::Firewall::BlockerHelper::backends::azure) has the full table.
