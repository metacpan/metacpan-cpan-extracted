---
name: mcp-k8s-core
description: Load before editing p5-mcp-k8s — the RBAC-aware stdio MCP server, SelfSubjectRulesReview discovery, the generic tools, resource plural lookup, the auth tiers.
user-invocable: false
model: inherit
---

# mcp-k8s-core

MCP::K8s ist ein stdio MCP-Server, der einem LLM Zugriff auf einen Kubernetes-Cluster
gibt. Der Kern der Idee: **RBAC ist die einzige Autorisierungsschicht.** Der Server
fragt den Cluster per `SelfSubjectRulesReview`, was der verbundene ServiceAccount darf,
und formt daraus die Tool-Beschreibungen. Es gibt **keine** applikationsseitige
Permission-Filterung — was RBAC erlaubt, darf das LLM.

## Vocabulary

| Begriff | Bedeutung |
|---|---|
| **tool** | Eines der 10 MCP-Tools (`k8s_list`, `k8s_get`, …), registriert in `_register_tools` |
| **discovery** | `SelfSubjectRulesReview` pro Namespace → interne Permission-Map. Lazy, nicht bei `new` |
| **plural** | RBAC-Name einer Ressource (`Pod` → `pods`). RBAC spricht nur Plural, die API spricht Kind |
| **verb** | RBAC-Verb (`list`, `get`, `create`, `patch`, `delete`) — der Schlüssel jeder Prüfung |
| **cluster scope** | Namespace `''` — eigene Zeile in der Permission-Map, eigener Discovery-Call |
| **desc map** | `_tool_desc_map`: `[$tool, $base_description, $verb]` je Tool, für nachträgliches Umschreiben der Beschreibungen |

## Layer Map

```
bin/mcp-k8s                   # Entry point: MCP::K8s->run_stdio
lib/MCP/K8s.pm                # Server (extends MCP::Server), Tools, Formatting, Auth, Plurals
lib/MCP/K8s/Permissions.pm    # RBAC-Discovery + can_do/allowed_* /summary
lib/MCP/Kubernetes.pm         # Leere Subklasse von MCP::K8s, nur für CPAN-Auffindbarkeit
examples/*.yaml               # RBAC-Beispiele (readonly / deployer / full-ops)
examples/raider-configmap-demo.pl  # Live-Demo mit Langertha::Raider
```

`MCP::K8s` **erbt** von `MCP::Server` (seit 0.002), komponiert ihn nicht mehr.
`sub server { $_[0] }` existiert nur als Rückwärtskompatibilität für Code, der
`$k8s->server` an `Net::Async::MCP` übergibt — das ist der dokumentierte
Raider-Pfad im README, also nicht entfernen.

## Core invariants

- **Discovery ist lazy, und das ist eine Zusage.** `BUILD` registriert nur Tools.
  Der erste RBAC-Call passiert in `ensure_discovered` — ausgelöst durch einen
  Tool-Call oder `run_stdio`. Damit ist `MCP::K8s->new` ohne Cluster konstruierbar,
  worauf die halbe Testsuite baut. Nichts in `BUILD` schieben, das `->api` anfasst.
- **Jeder Tool-Call prüft vorher `can_do`.** Kein Tool ruft die API ohne
  vorangehende Permission-Prüfung — auch dann nicht, wenn die API-Antwort ohnehin
  403 wäre. Die Prüfung ist das, was dem LLM eine lesbare Absage statt eines
  Stacktraces gibt.
- **`can_do` matcht auf dem Plural, nicht auf dem Kind.** Wer `can_do('list', 'Pod')`
  aufruft, bekommt still `0`. Immer erst `_resource_plural` durchlaufen.
- **Wildcards gelten in beide Richtungen.** `can_do` trifft bei explizitem Verb,
  Wildcard-Verb (`*` auf der Ressource), Wildcard-Ressource mit Verb, und
  Wildcard/Wildcard. Alle vier Zweige sind live; wer einen wegoptimiert, bricht
  cluster-admin.
- **Discovery-Fehler pro Namespace sind nicht fatal.** Ein unerreichbarer Namespace
  wird gewarnt und übersprungen, die anderen werden trotzdem entdeckt. Das gilt
  auch für den cluster-scope-Call.
- **Tool-Beschreibungen werden nachträglich umgeschrieben**, genau einmal, in
  `_update_tool_descriptions` (Guard: `_descriptions_updated`). Sie hängen an
  `_tool_desc_map`; ein neu registriertes Tool ohne Eintrag dort behält für immer
  seine statische Beschreibung.
- **Die Beschreibungen sind Teil der Funktionalität, nicht Kosmetik.** Sie sagen dem
  LLM „Available: default: pods, deployments; production: pods", damit es nicht raten
  muss. Bei >10 Ressourcen wird auf 10 + `...` gekürzt, bei `*` steht „all resources".

## Resource plurals — 4-Tier Lookup

`_resource_plural($kind)`, in dieser Reihenfolge:

1. **Statische `%RESOURCE_PLURALS`-Map** — schnell, kein I/O
2. **`IO::K8s`-Klasse** via `expand_class` + `resource_plural()` — deckt CRD-Klassen ab
3. **API-Discovery** (`/api/v1` und `/apis` + `/apis/$groupVersion`), einmalig
   gecacht in `_resource_plurals_cache`. Subresources (`name` enthält `/`) werden
   übersprungen
4. **Heuristik** — lowercase, `s` anhängen, `ys` → `ies`

Tier 3 schluckt alle Fehler still: schlägt die Discovery fehl, bleibt der Cache leer
und Tier 4 greift. Das ist Absicht — ein Cluster ohne Discovery-Rechte soll den
Server nicht umbringen. Der Preis: eine falsche Pluralisierung sieht aus wie ein
Permission-Denied. Bei „Permission denied", das nicht sein dürfte, immer zuerst den
Plural prüfen.

CRD-Support hängt komplett an Tier 2+3. Cilium & Co. funktionieren ohne Konfiguration
genau deshalb.

## Auth — 3-Tier, in dieser Reihenfolge

| Tier | Auslöser | Endpoint |
|---|---|---|
| 1 | `MCP_K8S_TOKEN` gesetzt | `MCP_K8S_SERVER`, sonst in-cluster default |
| 2 | `/var/run/secrets/kubernetes.io/serviceaccount/token` existiert | dito |
| 3 | Fallback | `Kubernetes::REST::Kubeconfig` mit `MCP_K8S_CONTEXT` |

Tier 1 und 2 hängen `ssl_ca_file` an, **wenn** die in-cluster CA-Datei existiert —
auch bei explizitem Token. Die Pfade sind File-scoped `my`-Variablen in `MCP/K8s.pm`;
Tests, die Auth-Tiers durchspielen, müssen sie über das Dateisystem beeinflussen oder
den Tier über Attribute erzwingen.

## Namespaces

`_build_namespaces`: `MCP_K8S_NAMESPACES` → in-cluster-Namespace-Datei (dann Versuch,
alle zu listen, mit dem gemounteten als Fallback) → Auto-Discovery über `list('Namespace')`
→ `['default']`. Jede API-Nutzung darin ist in `eval` gewickelt; es gibt keinen Pfad,
auf dem `_build_namespaces` stirbt.

`_resolve_namespace` füllt den Namespace **nur** auf, wenn genau einer erreichbar ist,
sonst `undef` — das Tool muss den Fall selbst behandeln. Nicht auf „nimm den ersten"
ändern: bei mehreren Namespaces wäre das eine stille Fehlbedienung mit echten Folgen.

## Die 10 Tools

`k8s_permissions` (immer erlaubt, ruft `summary`), `k8s_list`, `k8s_get`,
`k8s_create`, `k8s_patch`, `k8s_delete`, `k8s_logs`, `k8s_events`,
`k8s_rollout_restart`, `k8s_apply`.

Zwei davon sind zusammengesetzt und verdienen Aufmerksamkeit:

- **`k8s_rollout_restart`** patcht die Pod-Template-Annotation
  `kubectl.kubernetes.io/restartedAt` mit einem Timestamp — derselbe Mechanismus wie
  `kubectl rollout restart`. Es braucht `patch`, nicht `update`.
- **`k8s_apply`** versucht `create` und fällt bei 409/AlreadyExists auf einen
  Strategic-Merge-Patch zurück. Die Fehlererkennung ist ein Regex auf
  `/409|AlreadyExists/i` gegen den Fehlerstring — ein anderer Client-Layer mit anderem
  Fehlerformat bricht das lautlos in Richtung „Create schlug fehl".

**Warum 10 generische Tools statt hunderter spezifischer:** Kubernetes hat 50+
Built-in-Typen plus beliebige CRDs. Generische Tools mit `resource`-Parameter spiegeln
`kubectl get <resource>` und halten die Tool-Liste für MCP-Clients handhabbar.
Ein `list_pods`-Tool hinzuzufügen ist eine Richtungsänderung, kein Feature.

## Ausgabeformat

`_format_resource_summary` liefert bewusst eine **kompakte** Zusammenfassung für den
LLM-Kontext (Metadata, Kind, Status-Phase/Replicas/Conditions, Container/Ports/Type) —
für alles Weitere ist `k8s_get` mit `output => 'json'|'yaml'` da. Wer das Summary
aufbläht, bezahlt es in jedem `k8s_list` mit N Items.

## Tests

Alles läuft gegen handgeschriebene Mock-Pakete im jeweiligen Testfile
(`MockK8sAPI`, `MockSSRR`, `MockK8sObject`, …) — kein Test braucht einen Cluster,
und keiner darf einen brauchen. Die Mocks implementieren die von `Kubernetes::REST`
genutzte Oberfläche (`new_object`, `create`, `list`, `get`, `delete`, `patch`,
`expand_class`, `_request`).

| Datei | Deckt ab |
|---|---|
| `t/00-load.t` | Ladbarkeit der drei Module |
| `t/01-permissions.t` | RBAC-Discovery, `can_do`-Wildcards, `allowed_*`, `summary` |
| `t/02-resource-plurals.t` | 4-Tier-Pluralisierung |
| `t/03-namespace-resolution.t` | Auto-Fill genau bei einem Namespace |
| `t/04-format-helpers.t` | Summary-/List-Formatierung |
| `t/05-server-tools.t` | Tool-Registrierung und -Ausführung inkl. `force_409`-Pfad von `k8s_apply`, `k8s_patch`-Statuspfad, `IO::K8s::Unstructured` |
| `t/06-kubernetes-alias.t` | `MCP::Kubernetes` ist `MCP::K8s` |
| `t/07-auth-alternatives.t` | Token-/in-cluster-/Kubeconfig-Tiers |
| `t/08-resource-discovery.t` | API-Discovery-Endpunkte, Subresource-Filter, Tier 2 ohne Request |

`prove -l t/` ist der Lauf. Die Suite braucht `Kubernetes::REST` und `IO::K8s`
installiert — fehlen sie, kompiliert `MCP::K8s` nicht und *alle* Files scheitern mit
Exit 2 ohne Plan. Das ist ein Umgebungsproblem, kein Testfehler.

## Env-Vars

| Variable | Default | Wirkung |
|---|---|---|
| `KUBECONFIG` | `~/.kube/config` | Kubeconfig-Pfad (Tier 3) |
| `MCP_K8S_CONTEXT` | current-context | Kubeconfig-Context |
| `MCP_K8S_TOKEN` | — | Bearer Token, aktiviert Auth-Tier 1 |
| `MCP_K8S_SERVER` | in-cluster default | API-Server-URL |
| `MCP_K8S_NAMESPACES` | Auto-Discovery | Komma-getrennte Namespace-Liste |

Es gibt **keine** Kommandozeilen-Flags. Die Konfiguration ist vollständig
env-basiert, damit sie in MCP-Client-JSON (`.mcp.json`, Claude Desktop) ausdrückbar
ist. Ein Flag hinzuzufügen bricht diese Zusage.

## Conventions

POD folgt durchgehend der Deklaration, nicht umgekehrt: `sub foo {` gefolgt von
`=method foo` … `=cut`, dann der Body; `has bar => (…)` gefolgt von `=attr bar`
… `=cut`. Das ist der `[@Author::GETTY]`-Stil dieser Distribution — nicht nach
oben verschieben. `$VERSION` steht in allen drei Modulen und wird vom
Release-Bundle gepflegt.

Release-Mechanik: skill `getty-perl-release-author-getty`. dist.ini: skill
`perl-release-dist-ini`. Moo-Muster: skill `getty-perl-moo`. MCP-Server-Grundlagen:
skill `perl-mcp`.
