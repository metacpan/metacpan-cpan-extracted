# Kurs — every kind of underworld

Each `[kur.<name>]` hash in the config defines one kur. A kur is
either a *real* kur — a process wrapping one
`Net::Firewall::BlockerHelper` backend, with its own socket, PID
file, and clay tablet — or a *gate*, a `fan_out` list that opens onto
several real kurs.

This page covers the settings every kur shares and points at the
detail page for each kind. Each detail page goes deep: what the
backend creates, the exact commands or API calls behind every
operation, every option, host prerequisites, how `self_heal`
interacts with it, and its particular footguns.

## Every kind of kur

- [gate](kurs/gate.md) — the `fan_out` gate: one name opening onto
  several underworlds; validation, command fan out, response shapes,
  and the authorization model that is its reason to exist
- [dummy](kurs/dummy.md) — an underworld of pure imagination, for
  testing

Local packet filters...

- [pf](kurs/pf.md) — pf on FreeBSD/OpenBSD; table in an anchor,
  and the `anchor "kur/*"` line pf.conf must carry
- [ipfw](kurs/ipfw.md) — ipfw on FreeBSD; table plus a rule
  number, and why that number must be unique per kur
- [iptables](kurs/iptables.md) — Linux iptables/ip6tables plus
  ipset; also carries the `tarpit`/`delude` types via xtables-addons
- [nftables](kurs/nftables.md) — Linux nft; everything in one
  dedicated table
- [firewalld](kurs/firewalld.md) — Linux hosts firewalld manages;
  ipsets plus direct interface rules, and what a firewalld reload
  does to them
- [ufw](kurs/ufw.md) — Ubuntu's uncomplicated firewall; per-IP
  prepended rules
- [shorewall](kurs/shorewall.md) — Shorewall's dynamic blacklist
- [npf](kurs/npf.md) — npf on NetBSD; the table and rule npf.conf
  must declare
- [linux_ip_route](kurs/linux_ip_route.md) — null routes via
  iproute2; no firewall needed at all
- [xdp](kurs/xdp.md) — XDP/eBPF drops before the network stack,
  via xdp-filter
- [hosts_deny](kurs/hosts_deny.md) — TCP wrappers; a marked
  region in /etc/hosts.deny

Network gear and appliances...

- [openwrt](kurs/openwrt.md) — OpenWrt fw4 driven through UCI, on the
  router itself or across the network over ubus JSON-RPC
- [routeros](kurs/routeros.md) — MikroTik RouterOS over ssh;
  creates its own address-lists and rules
- [routeros_api](kurs/routeros_api.md) — MikroTik RouterOS over
  REST (7.1+); membership in your address-lists
- [opnsense](kurs/opnsense.md) — an OPNsense firewall alias via
  its REST API
- [pfsense](kurs/pfsense.md) — a pfSense firewall alias via the
  pfSense-API package
- [vyos](kurs/vyos.md) — VyOS firewall address-groups via its
  HTTP API
- [panos](kurs/panos.md) — Palo Alto PAN-OS; tag registrations
  feeding a Dynamic Address Group, no commit needed
- [fortigate](kurs/fortigate.md) — Fortinet FortiGate; address
  objects and group membership via the FortiOS REST API
- [cisco_fmc](kurs/cisco_fmc.md) — Cisco Firepower network group
  literals via the FMC REST API; mind the deployment caveat
- [checkpoint](kurs/checkpoint.md) — Check Point host objects and
  a group via the Management API; mind the install-policy caveat
- [juniper_srx](kurs/juniper_srx.md) — Juniper SRX address-book
  and address-set via the Junos REST API, committed live
- [f5_bigip](kurs/f5_bigip.md) — an F5 BIG-IP AFM address-list
  via iControl REST
- [netscaler](kurs/netscaler.md) — policy dataset bindings on a
  Citrix NetScaler/ADC
- [bgp_rtbh](kurs/bgp_rtbh.md) — BGP Remote Triggered Black Hole
  (or FlowSpec); host routes with the RFC 7999 blackhole community
  via ExaBGP, GoBGP, or FRR

Cloud and edge services...

- [cloudflare](kurs/cloudflare.md) — IP access rules at the
  Cloudflare edge
- [fastly](kurs/fastly.md) — Fastly Edge ACL entries
- [akamai](kurs/akamai.md) — Akamai network lists; mind the
  activation caveat
- [aws_wafv2](kurs/aws_wafv2.md) — AWS WAFv2 IP sets via the aws
  CLI
- [cloud_armor](kurs/cloud_armor.md) — a GCP Cloud Armor rule via
  gcloud; mind the 10-range limit
- [azure](kurs/azure.md) — an Azure NSG deny rule's source
  prefixes via the az CLI

DNS...

- [nsupdate](kurs/nsupdate.md) — an RBL-style DNS blocklist in a
  BIND zone (IPv4 only)
- [dns_rpz](kurs/dns_rpz.md) — Response Policy Zone triggers;
  block clients from resolving, or answers from resolving to them

Reporting...

- [abuseipdb](kurs/abuseipdb.md) — report the banished to
  AbuseIPDB; reporting only, pairs with a blocker inside a gate

Generic...

- [file_reload](kurs/file_reload.md) — render the ban list to a
  file, run a reload hook; web servers, RPZ zones, EDLs, ipset
  restore files
- [shell](kurs/shell.md) — commands you specify; the escape hatch

The authoritative reference for any backend remains its POD on
MetaCPAN, under `Net::Firewall::BlockerHelper::backends::<backend>`.

## Settings every kur shares

| key                | default         | what                                                                  |
|--------------------|-----------------|-----------------------------------------------------------------------|
| `backend`          | *(required)*    | one of the backends above; mutually exclusive with `fan_out`          |
| `fan_out`          | *(unset)*       | array of other kur names; makes this a [gate](kurs/gate.md)           |
| `ports`            | `[]`            | ports to block for; all if unset                                      |
| `protocols`        | `[]`            | protocols to block for; backend-dependent default if unset            |
| `prefix`           | `"kur"`         | rule/table/chain/set name prefix; must match `/^[a-zA-Z0-9]+$/`       |
| `self_heal`        | `1`             | check the firewall setup before each ban/unban, re-init if gone       |
| `ban_time`         | top level / 600 | this kur's default sentence in seconds; `0` = eternal residence       |
| `checkpoint`       | top level / 60  | seconds between tablet recopies; `0` = mutations/stop only            |
| `enable_cidr`      | top level / off | whether this kur banishes whole ranges; needs a range-capable backend |
| `cidr_silent_drop` | top level / off | drop rather than error range commands where CIDR is unavailable       |
| `options`          | `{}`            | backend specific options table; see each backend's page               |
| `authed_users`     | `[]`            | users granted access to this kur (with `enable_auth`)                 |
| `authed_groups`    | `[]`            | groups granted access to this kur (with `enable_auth`)                |

Notes that apply across the board...

- Kur names must match `/^[a-zA-Z0-9-]+$/`. The name and prefix also
  become firewall object names (`<prefix>_<name>` tables, chains, and
  sets), so the packet filter backends impose combined length limits
  — pf 31, ipfw 63, iptables 28, firewalld 29, openwrt 250
  characters; each page has the why.
- `ports` entries may be ints (1–65535) or service names resolvable
  via `getservbyname`; `protocols` entries are checked against
  `/etc/protocols`. Duplicates are dropped.
- `options` values must be plain scalars. The one exception is
  `interfaces`, which backends like xdp want as an array and which may
  be given as one; any other array or table valued option is refused
  at config load rather than reaching the backend as a stringified
  ref.
- `self_heal` is the fail2ban actioncheck-before-action behavior:
  each ban/unban first asks the backend to `check` its setup and
  re-inits it if something external (a firewall reload, a flushed
  table) swept it away. It costs one probe per ban/unban; leave it on
  unless that matters to you. What `check` actually probes — and
  where it can probe nothing — varies per backend; see each page.
  `ereshkigal re-init` forces the same rebuild on demand, which is
  what you want when `self_heal` is off, when the next ban is a long
  way off, or when a backend's `check` cannot see the damage.
- Only the seven packet filter backends (`pf`, `ipfw`, `iptables`,
  `nftables`, `firewalld`, `ufw`, `openwrt`) block by port and
  protocol. The rest block the whole IP, or work somewhere ports have
  no meaning.
  Configure `ports` or `protocols` on one of those and it goes one of
  two ways:
    - **fatal** — `npf`, `linux_ip_route`, `routeros_api`, `pfsense`,
      `vyos`, `panos`, `fortigate`, `cisco_fmc`, `checkpoint`,
      `juniper_srx`, `f5_bigip`, `netscaler`, `cloudflare`, `fastly`,
      `akamai`, `nsupdate`, `dns_rpz`, `abuseipdb`. The kur refuses
      to start.
    - **ignored** — `shorewall`, `xdp`, `hosts_deny`, `routeros`,
      `opnsense`, `bgp_rtbh`, `aws_wafv2`, `cloud_armor`, `azure`,
      `file_reload`, `shell`, `dummy`. Accepted for parity, then
      dropped — so on these, a configured `ports` list scopes nothing.
- IPv6 addresses are lowercased everywhere, so case variants of one
  IP cannot become two bans.

## Choosing an underworld

| backend          | platform / where                   | granularity                 | kill support               |
|------------------|------------------------------------|-----------------------------|----------------------------|
| `pf`             | FreeBSD, OpenBSD, etc              | ports/protocols             | yes (states)               |
| `ipfw`           | FreeBSD                            | ports/protocols             | TCP only (tcpdrop)         |
| `iptables`       | Linux (+ tarpit/delude)            | ports/protocols             | yes (conntrack)            |
| `nftables`       | Linux                              | ports/protocols             | yes (conntrack)            |
| `firewalld`      | Linux with firewalld               | ports/protocols             | yes (conntrack)            |
| `ufw`            | Linux with ufw                     | ports/protocols             | yes (ss/conntrack)         |
| `shorewall`      | Linux with Shorewall               | whole IP                    | no                         |
| `npf`            | NetBSD                             | whole IP (rule in npf.conf) | no                         |
| `linux_ip_route` | Linux (iproute2)                   | whole IP                    | no                         |
| `xdp`            | Linux, NIC-level                   | whole IP                    | unneeded (all packets die) |
| `hosts_deny`     | anywhere with libwrap              | per daemon                  | no                         |
| `openwrt`        | OpenWrt (local or ubus)            | ports/protocols             | yes (conntrack)            |
| `routeros`       | MikroTik (ssh)                     | whole IP (rules it creates) | no                         |
| `routeros_api`   | MikroTik (REST, 7.1+)              | via your rules              | no                         |
| `opnsense`       | OPNsense                           | via your rules              | no                         |
| `pfsense`        | pfSense (pfSense-API pkg)          | via your rules              | no                         |
| `vyos`           | VyOS (HTTP API)                    | via your rules              | no                         |
| `panos`          | Palo Alto PAN-OS                   | via your policies           | no                         |
| `fortigate`      | Fortinet FortiGate                 | via your policies           | no                         |
| `cisco_fmc`      | Cisco Firepower (needs deploy)     | via your policies           | no                         |
| `checkpoint`     | Check Point (needs install-policy) | via your policies           | no                         |
| `juniper_srx`    | Juniper SRX (commits live)         | via your policies           | no                         |
| `f5_bigip`       | F5 BIG-IP AFM                      | via your policies           | no                         |
| `netscaler`      | Citrix NetScaler/ADC               | via responder policies      | n/a (remote)               |
| `bgp_rtbh`       | your BGP edge                      | whole IP (network-wide)     | no                         |
| `cloudflare`     | Cloudflare edge                    | whole IP                    | n/a (remote)               |
| `fastly`         | Fastly edge                        | via your VCL                | n/a (remote)               |
| `akamai`         | Akamai edge (needs activation)     | via your policies           | n/a (remote)               |
| `aws_wafv2`      | AWS WAF                            | via your WebACL             | n/a (remote)               |
| `cloud_armor`    | GCP edge (max 10 IPs)              | via the rule                | n/a (remote)               |
| `azure`          | Azure NSGs                         | via the rule                | n/a (remote)               |
| `nsupdate`       | BIND zone (DNS RBL)                | whole IP, IPv4 only         | n/a (remote)               |
| `dns_rpz`        | BIND RPZ (resolver)                | resolution, not packets     | n/a (remote)               |
| `abuseipdb`      | AbuseIPDB (reporting)              | reports only                | n/a                        |
| `file_reload`    | anywhere                           | whatever consumes the file  | no                         |
| `shell`          | anywhere                           | whatever you script         | whatever you script        |
| `dummy`          | the imagination                    | none                        | n/a                        |

On "kill support": a firewall rule only stops **new** connections;
`kill` severs the established ones too. For ban-on-abuse you almost
certainly want it on where it exists — [security](security.md)
explains.
