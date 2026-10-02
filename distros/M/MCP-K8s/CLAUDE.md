# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

MCP::K8s ist ein stdio MCP-Server, der einem LLM Zugriff auf einen Kubernetes-Cluster
gibt. Der Kern der Idee: **RBAC ist die einzige Autorisierungsschicht.** Der Server
fragt beim Start des ersten Tool-Calls per `SelfSubjectRulesReview`, was der verbundene
ServiceAccount darf, und formt daraus die Tool-Beschreibungen. Ein Read-only-Account
bekommt Read-only-Tools, ein cluster-admin bekommt alles. Es gibt **keine**
applikationsseitige Permission-Filterung — was RBAC erlaubt, darf das LLM.

Auf CPAN unter zwei Namen: `MCP::K8s` (kanonisch) und `MCP::Kubernetes` (leere
Subklasse, nur für Auffindbarkeit).

## Projektstruktur

```
p5-mcp-k8s/
├── bin/mcp-k8s                   # Entry point: MCP::K8s->run_stdio
├── lib/MCP/
│   ├── K8s.pm                    # Server (extends MCP::Server), Tools, Auth, Plurals, Formatting
│   ├── K8s/Permissions.pm        # RBAC-Discovery + can_do/allowed_*/summary
│   └── Kubernetes.pm             # Leere Subklasse, nur CPAN-Auffindbarkeit
├── examples/                     # 3 RBAC-Manifeste + Langertha::Raider-Demo
├── t/                            # Tests, alle gegen Inline-Mocks
└── dist.ini                      # [@Author::GETTY]
```

## Key Commands

```bash
prove -l t/                 # Tests
prove -l t/01-permissions.t # Einzeltest
dzil build                  # Distribution bauen
dzil test                   # Test mit dzil
```

Stirbt **jedes** Testfile mit Exit 2 und „No plan found in TAP output", fehlt eine
Dependency, nicht Code: `perl -Ilib -MMCP::K8s -e1` zeigt welche, `cpanm --installdeps .`
holt sie nach.

## Architektur

**MCP::K8s** (lib/MCP/K8s.pm) **erbt** von `MCP::Server` (seit 0.002), komponiert ihn
nicht mehr. `sub server { $_[0] }` ist Rückwärtskompatibilität für den dokumentierten
`Net::Async::MCP->new(server => $k8s->server)`-Pfad im README — nicht entfernen.
Der Pfad ist gegen MCP 0.15 + Net::Async::MCP 0.004 verifiziert; 0.003 scheitert an
der stateless Revision 2026-07-28 (`-32602 Missing protocol version`). Bei einem
Befund an dieser Stelle **zuerst die installierte Net::Async::MCP-Version prüfen.**

**Discovery ist lazy, und das ist eine Zusage.** `BUILD` registriert nur Tools; der
erste RBAC-Call passiert in `ensure_discovered`, ausgelöst durch einen Tool-Call oder
`run_stdio`. Damit ist `MCP::K8s->new` ohne Cluster konstruierbar — worauf die
Testsuite und jede Einbettung bauen. Nichts in `BUILD` schieben, das `->api` anfasst.

**Jeder Tool-Call prüft vorher `can_do`.** Kein Tool ruft die API ohne vorangehende
Permission-Prüfung, auch nicht wenn die API ohnehin 403 gäbe. Die Prüfung ist das, was
dem LLM eine lesbare Absage statt eines Stacktraces gibt.

**Tool-Beschreibungen sind Funktionalität, nicht Kosmetik.** Ausgelöst werden sie über
`_tools` — die von `MCP::Server` geerbte Methode, durch die **jeder** Transport bei
`tools/list` und `tools/call` läuft. Die Überschreibung ruft
`_update_tool_descriptions` und delegiert dann an `SUPER::_tools`, damit Listenkopie und
`emit('tools', ...)` nicht auseinanderlaufen. Bis 0.003 hing der Aufruf allein in
`run_stdio`, womit der README-Pfad über `Net::Async::MCP`, ein eingebettetes `to_stdio`
und der HTTP-Transport `to_action` die statischen Beschreibungen auslieferten. Wer den
Aufruf zurück nach `run_stdio` schiebt, bricht genau diese drei Pfade, ohne einen Test
in `t/05` zu brechen — es sei denn den einen, der `tools/list` über `handle` fährt.
`_update_tool_descriptions` schreibt sie genau einmal um (Guard `_descriptions_updated`), entlang `_tool_desc_map`
(`[$tool, $base_desc, $verb]` je Tool). Ergebnis: „List Kubernetes resources. Available:
default: pods, deployments; production: pods". Bei >10 Ressourcen wird auf 10 + `...`
gekürzt, bei Wildcard steht „all resources". Ein neu registriertes Tool ohne Eintrag in
der Map behält für immer seine statische Beschreibung.

### Die 10 Tools

`k8s_permissions` (immer erlaubt), `k8s_list`, `k8s_get`, `k8s_create`, `k8s_patch`,
`k8s_delete`, `k8s_logs`, `k8s_events`, `k8s_rollout_restart`, `k8s_apply` — alle in
`_register_tools`. Drei haben Besonderheiten:

- **`k8s_patch`** nimmt einen optionalen `subresource`-Parameter (`enum: ['status']`,
  plus Runtime-Check für Clients, die das Schema ignorieren). Mit `status` geht der
  Call auf `patch_status()` statt `patch()` und der Patch-Typ-Default kippt auf
  **merge** statt strategic — Custom Resources antworten auf einen Strategic-Merge mit
  415. Ein explizit übergebener `patch_type` gewinnt. Das ist kein Komfort-Feature:
  ohne den Subresource-Pfad streicht der API-Server jeden Status aus einem Write ans
  Haupt-Endpoint und antwortet **trotzdem 2xx** — das Tool meldete „patched" und nichts
  war gespeichert. Das RBAC-Gate prüft `<plural>/status`, nicht `<plural>`; ein
  Main-Endpoint-Patch verschenkt keinen Status-Write.

- **`k8s_rollout_restart`** patcht die Pod-Template-Annotation
  `kubectl.kubernetes.io/restartedAt` mit Timestamp — derselbe Mechanismus wie
  `kubectl rollout restart`. Braucht `patch`, nicht `update`.
- **`k8s_apply`** versucht `create` und fällt bei 409/AlreadyExists auf einen
  Strategic-Merge-Patch zurück. Die Conflict-Erkennung sitzt in `_is_conflict_error`
  und ist ein Regex gegen den Fehlerstring (`/409|AlreadyExists/i`) — nicht aus
  Bequemlichkeit: Kubernetes::REST 1.108 `croak`t einen reinen String
  (`Kubernetes API error (create <class>): <status> <body>`), typisierte Fehler gibt
  es nur in den v0-Kompatibilitätsmodulen. Ein engerer Match auf genau dieses Format
  wäre **schlechter** — jede Umformulierung upstream ergäbe ein False Negative,
  während der weite Match sie überlebt. Neu bewerten, sobald der Client typisierte
  Fehler bekommt.

**Warum 10 generische Tools statt hunderter spezifischer:** Kubernetes hat 50+
Built-in-Typen plus beliebige CRDs. Generische Tools mit `resource`-Parameter spiegeln
`kubectl get <resource>` und halten die Tool-Liste für MCP-Clients handhabbar. Ein
`list_pods`-Tool hinzuzufügen ist eine Richtungsänderung, kein Feature.

### Resource Plurals — 4-Tier

RBAC spricht Plural (`pods`), die API spricht Kind (`Pod`). `_resource_plural`
übersetzt: (1) statische `%RESOURCE_PLURALS`-Map, (2) `IO::K8s`-Klasse via
`expand_class`+`resource_plural()`, (3) API-Discovery über `/api/v1` und `/apis`,
einmalig gecacht, Subresources (`name` enthält `/`) übersprungen, (4) Heuristik
(lowercase, `s`, `ys`→`ies`).

**Tier 2 beantwortet seit 1.108 jeden Built-in-Kind.** IO::K8s 1.108 trägt die
Upstream-Plurale an den Klassen, und `Kubernetes::REST::expand_class` löst Namen der
eingebauten Map ohne Request auf — auch bei `resource_map_from_cluster` (weiterhin
Default 1). Ein Guard davor, wie bis 0.003, spart nichts mehr: der Tool-Call ruft direkt
danach selbst `list/get/...($kind)` mit demselben `expand_class`. Ein unbekannter Kind
kostet dem Client eine aggregated Discovery (`GET /api`, `/apis`, kein `/openapi/v2`
mehr) und landet als `IO::K8s::Unstructured` oder als nicht ladbarer Klassenname —
beide ohne `resource_plural`, also weiter zu Tier 3. **CRDs ohne Klasse kommen damit
aus Tier 3**, CRD-Provider-Klassen mit eigenem `resource_plural` aus Tier 2. Die
Floors `IO::K8s`/`Kubernetes::REST` 1.108 in der cpanfile stehen genau für diesen
Vertrag; `t/08` hält ihn gegen den echten Client fest (0 Requests).

Ein CRD ohne Klasse kommt seit Kubernetes::REST 1.108 als `IO::K8s::Unstructured`
zurück statt zu scheitern: `output=json`/`yaml` sind vollständig, die Summary zeigt
nur Metadaten und `kind` (kein `spec`/`status`-Accessor).

Tier 3 schluckt alle Fehler still — Absicht, damit ein Cluster ohne Discovery-Rechte
den Server nicht umbringt. Der Preis: **eine falsche Pluralisierung sieht aus wie ein
Permission-Denied.** Bei unerwartetem „Permission denied" immer zuerst den Plural
prüfen.

### Auth — 3-Tier

| Tier | Auslöser | Endpoint |
|---|---|---|
| 1 | `MCP_K8S_TOKEN` gesetzt | `MCP_K8S_SERVER`, sonst in-cluster default |
| 2 | `/var/run/secrets/kubernetes.io/serviceaccount/token` existiert | dito |
| 3 | Fallback | `Kubernetes::REST::Kubeconfig` mit `MCP_K8S_CONTEXT`, optional `kubeconfig_path` (nur Konstruktor, kein Env) |

Tier 1 und 2 hängen `ssl_ca_file` an, wenn die in-cluster CA-Datei existiert — auch bei
explizitem Token. Die Pfade sind file-scoped `my`-Variablen in `MCP/K8s.pm`.

### Namespaces

`_build_namespaces`: `MCP_K8S_NAMESPACES` → in-cluster-Namespace-Datei → Auto-Discovery
über `list('Namespace')` → `['default']`. Jede API-Nutzung darin ist in `eval`; es gibt
keinen Pfad, auf dem das stirbt.

`_resolve_namespace` füllt **nur** auf, wenn genau ein Namespace erreichbar ist, sonst
`undef`; das Tool behandelt den Fall selbst.

### Permissions (lib/MCP/K8s/Permissions.pm)

`discover` schickt je einen `SelfSubjectRulesReview` pro Namespace **plus einen mit
leerem Namespace für cluster-scoped Ressourcen** — der `''`-Key in der Map ist der
Cluster-Scope. Fehler pro Namespace werden gewarnt und übersprungen, nicht propagiert.

`can_do($verb, $plural, $ns)` trifft über vier Zweige: explizites Verb, Wildcard-Verb
auf der Ressource, Wildcard-Ressource mit Verb, Wildcard/Wildcard. Alle vier sind live —
wer einen wegoptimiert, bricht cluster-admin, ohne einen Narrow-Role-Test zu brechen.

**Subresources stehen in der Map**, so wie der API-Server sie meldet (`pods/log`,
`deployments/status`). RBAC behandelt sie als eigenständige Ressourcen — `patch` auf
`deployments` gewährt **kein** `patch` auf `deployments/status` —, also fragt der
Aufrufer mit dem vollen Namen: `can_do('patch', 'deployments/status', $ns)`. Kollision
mit einem Basis-Plural ist ausgeschlossen, der enthält nie ein `/`. Gefiltert wird auf
der Darstellungsseite: `allowed_resources` lässt sie weg, damit die Tool-Beschreibungen
bei den Haupt-Endpoints bleiben. (`summary` zeigt sie — hat es für `pods/log` immer
schon getan.)

Bis 0.003 warf `_discover_namespace` Subresources außer `pods/log` weg. Folge: eine
korrekt eng geschnittene Status-Writer-Role bekam eine **falsche Absage**. Nebeneffekt
der Reparatur: ein Namespace, dessen einzige Rechte Subresources sind, taucht jetzt in
`allowed_namespaces` auf — `discover` speichert nur bei `keys %$ns_rules`. Das kann
`_resolve_namespace` vom Auto-Fill abbringen, wenn dadurch mehr als ein Namespace
erreichbar wird. Richtige Richtung (fragen statt raten), aber eine echte
Verhaltensänderung.

## Env-Vars

| Variable | Default | Wirkung |
|---|---|---|
| `KUBECONFIG` | `~/.kube/config` | Kubeconfig-Pfad (Tier 3) |
| `MCP_K8S_CONTEXT` | current-context | Kubeconfig-Context |
| `MCP_K8S_TOKEN` | — | Bearer Token, aktiviert Auth-Tier 1 |
| `MCP_K8S_SERVER` | in-cluster default | API-Server-URL |
| `MCP_K8S_NAMESPACES` | Auto-Discovery | Komma-getrennte Namespace-Liste |

Es gibt **keine** Kommandozeilen-Flags. Die Konfiguration ist vollständig env-basiert,
damit sie in MCP-Client-JSON (`.mcp.json`, Claude Desktop) ausdrückbar ist. Ein Flag
hinzuzufügen bricht diese Zusage.

## Testing Notes

Alle Tests laufen gegen handgeschriebene Mock-Pakete im jeweiligen Testfile
(`MockK8sAPI`, `MockSSRR`, `MockK8sObject`, …), die die genutzte
`Kubernetes::REST`-Oberfläche nachbilden: `new_object`, `create`, `list`, `get`,
`delete`, `patch`, `expand_class`, `_request`. **Kein Test braucht einen Cluster, und
keiner darf einen brauchen.**

| Datei | Deckt ab |
|---|---|
| `t/00-load.t` | Ladbarkeit der drei Module |
| `t/01-permissions.t` | RBAC-Discovery, `can_do`-Wildcards, Subresources, `allowed_*`, `summary` |
| `t/02-resource-plurals.t` | 4-Tier-Pluralisierung |
| `t/03-namespace-resolution.t` | Auto-Fill genau bei einem Namespace |
| `t/04-format-helpers.t` | Summary-/List-Formatierung |
| `t/05-server-tools.t` | Tool-Registrierung und -Ausführung, `force_409`-Pfad von `k8s_apply`, `k8s_patch`-Statuspfad, `IO::K8s::Unstructured` |
| `t/06-kubernetes-alias.t` | `MCP::Kubernetes` ist `MCP::K8s` |
| `t/07-auth-alternatives.t` | Token-/in-cluster-/Kubeconfig-Tiers |
| `t/08-resource-discovery.t` | API-Discovery-Endpunkte, Subresource-Filter, Tier 2 ohne Request gegen den echten Client |
| `t/09-auth-regression.t` | Predicate-Fallen der Auth-Tiers (env-only, leerer String) |
| `t/10-kubeconfig-path.t` | `kubeconfig_path` gewinnt über `KUBECONFIG`, Fallback ohne Attribut unverändert |

Zwei Mock-Details, die falsch nachgebaut lautlos das Falsche testen: der
`SelfSubjectRulesReview` wird per `new_object` gebaut und per **`create`** submitted
(nicht `get`), und der Cluster-Scope ist der **leere** Namespace-String.

## Release

```bash
dzil release
```

`[@Author::GETTY]` bumpt `$VERSION`, taggt und legt das GitHub-Release an. Mechanik:
skill `getty-perl-release-author-getty`. Release nur mit ausdrücklicher Freigabe des
Maintainers — siehe `.claude/rules/mcp-k8s-rules.md`.

## Sharp Edges (für Entwickler)

- **`can_do` nimmt den Plural, nicht das Kind.** `can_do('list', 'Pod')` gibt still `0`
  und sieht aus wie eine fehlende Permission.
- **YAML kommt von `IO::K8s`, nicht von einem eigenen Dumper.** `k8s_get output=yaml`
  ruft `$obj->to_yaml` — das serialisiert `JSON::PP::Boolean` korrekt als `true`/`false`.
  Ein selbstgebautes `YAML::XS::Dump($obj->TO_JSON)` schrieb
  `!!perl/scalar:JSON::PP::Boolean 1` und damit kein Manifest, das `kubectl` annimmt.
  `YAML::PP` kommt als hartes `requires` über IO::K8s, keine optionale Dependency, kein
  stiller Rückfall auf JSON: wer YAML anfordert, bekommt YAML oder eine Absage.
- **Subresources sind eigene RBAC-Ressourcen.** `can_do('patch', 'deployments/status')`
  ist eine andere Frage als `can_do('patch', 'deployments')` — und das ist keine
  Pedanterie, sondern die Zusage, dass ein Main-Endpoint-Patch keinen Status-Write
  verschenkt. Der Plural-Cache hilft hier nicht: `_discover_resource_plurals`
  überspringt Namen mit `/`, den Basis-Plural über `_resource_plural` holen und
  `/status` selbst anhängen.
- **RBAC ist die einzige Autorisierungsschicht, absichtlich.** Kann der ServiceAccount
  Secrets lesen, kann das LLM es auch. Die Antwort darauf ist eine engere Role, kein
  Filter im Server.
- `_resolve_namespace` gibt `undef` zurück, wenn mehrere Namespaces erreichbar sind —
  „nimm den ersten" wäre eine stille Fehlbedienung gegen einen echten Cluster.
- Plural-Tier 3 schluckt jeden Fehler; falscher Plural und fehlende Permission sind von
  außen ununterscheidbar. Still lassen, aber keine neuen stillen Fallbacks danebenbauen.
- `k8s_apply`s Conflict-Erkennung ist ein Regex gegen den Fehlerstring. Ändert der
  Client-Layer sein Fehlerformat, degradiert apply lautlos zu „create failed".
- POD folgt der Deklaration, nicht umgekehrt: `sub foo {`, dann `=method foo` … `=cut`,
  dann der Body; `has` gefolgt von `=attr`. `[@Author::GETTY]`-Stil, nicht nach oben
  verschieben.
- `$VERSION` steht in allen drei Modulen und muss synchron bleiben.
- Die Tool-Liste existiert an vier Stellen: `lib/MCP/K8s.pm` POD, `bin/mcp-k8s` POD,
  `README.md` und `_register_tools`. Das ist die Drift, die am ehesten ausgeliefert wird.

## Delegation

Delegate behavior-relevant code to the right agent instead of touching it yourself —
principle and lane are in `.claude/rules/mcp-k8s-rules.md`.

| Task | Agent |
|---|---|
| Implement / refactor / debug behavior-relevant code | `mcp-k8s-worker` |
| Write or extend tests (mechanics) | `mcp-k8s-test-writer` |
| Commits, `Changes`, card → done, pre-release audit | `mcp-k8s-release-manager` |

The agents carry their skills via `briefing.skills` (see `.claude/agents/`); the main
agent delegates rather than loading them. Skill sources live under `.claude/skills/`.
The karr board (`refs/karr/*`) is the internal coordination channel — dieses Repo hat
noch keins, `karr init` legt es an.

## Links

- README.md — User-Dokumentation
- examples/ — RBAC-Manifeste (readonly / deployer / full-ops) + Raider-Demo
- dist.ini — [@Author::GETTY] config
