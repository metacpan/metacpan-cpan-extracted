# jq-lite

jq-lite is a jq-compatible JSON processor written in pure Perl.

It is designed for **long-term CLI stability** and **minimal dependencies**,
making it suitable as an **OS-level JSON utility** in constrained or long-lived environments.

- No external binaries
- No native libraries
- No compilation step
- Stable, test-backed CLI contract

---

## Overview

jq-lite allows querying and transforming JSON using jq-like syntax,
while remaining fully portable across systems where Perl is available.

It is particularly suited for:

- minimal Linux distributions
- containers and CI environments
- legacy or restricted systems
- offline / air-gapped deployments
- environments where jq cannot be installed

jq-lite is available as an **official Alpine Linux package**:

```bash
apk add jq-lite
````

---

## Design Goals

* **Stable CLI contract**
  Exit codes, stderr prefixes, and error behavior are treated as
  long-term compatibility promises.

* **Minimal dependency footprint**
  Implemented in pure Perl without XS, C extensions, or external libraries.

* **Predictable behavior**
  Intended for use in shell scripts, CI pipelines, and infrastructure automation.

jq-lite intentionally prioritizes **reliability over feature growth**.

---

## Stable CLI Contract

jq-lite defines a **fully implemented, test-backed CLI contract**
that serves as a strict backward-compatibility guarantee.

The contract specifies:

* Exit codes and their meanings
* Error categories and stderr prefixes
* stdout behavior on success and failure
* jq-compatible truthiness semantics (`-e/--exit-status`)
* Broken pipe (SIGPIPE/EPIPE) behavior suitable for pipelines and CI

📄 **Contract specification**:
👉 [`docs/cli-contract.md`](docs/cli-contract.md)

Any change that would violate this contract **requires a major version bump**
and is intentionally avoided.

---

## Environment Support

| Environment          | jq | jq-lite |
| -------------------- | -- | ------- |
| Alpine Linux         | △  | ✓       |
| Legacy CentOS / RHEL | ✗  | ✓       |
| Air-gapped systems   | ✗  | ✓       |
| No root privileges   | △  | ✓       |

Runs on **Perl ≥ 5.14**.

---

## Installation

### Package Manager

#### Alpine Linux

```bash
apk add jq-lite
```

---

### CPAN

```bash
cpanm JQ::Lite
```

---

## From Source (Latest, Simple)

This method installs the **latest released version** directly from CPAN
without requiring jq.

### Download (latest)

```bash
ver=$(curl -s http://fastapi.metacpan.org/v1/release/JQ-Lite \
  | perl -MJSON::PP -0777 -ne 'print decode_json($_)->{version}')
curl -sSfL http://cpan.metacpan.org/authors/id/S/SH/SHINGO/JQ-Lite-$ver.tar.gz -o JQ-Lite-$ver.tar.gz
```

### Install (user-local, no root, offline-friendly)

jq-lite can be installed without network access or system package managers.

Typical use cases:

* air-gapped environments
* restricted corporate networks
* systems without root privileges
* legacy hosts

```bash
tar xzf JQ-Lite-$ver.tar.gz
export PATH="$PWD/JQ-Lite-$ver/bin:$PATH"
```

Verify:

```bash
jq-lite -v
```

---

### Install (system-wide / root)

```bash
tar xzf JQ-Lite-$ver.tar.gz
cd JQ-Lite-$ver

perl Makefile.PL
make
make test
sudo make install
```

---

### Windows (PowerShell)

```powershell
.\install-jq-lite.ps1 JQ-Lite-<version>.tar.gz
```

Administrator privileges are not required.

---

## Containers

```dockerfile
FROM alpine
RUN apk add --no-cache jq-lite
```

jq-lite can be used as a **container-standard JSON processing tool**
without introducing native dependencies.

---

## Perl Integration

jq-lite can also be used directly from Perl code:

```perl
use JQ::Lite;

my $jq = JQ::Lite->new;
say for $jq->run_query($json, '.users[].name');
```

---

## Documentation

* [`docs/cli-contract.md`](docs/cli-contract.md) — **stable, test-backed CLI contract**
* [`docs/FUNCTIONS.md`](docs/FUNCTIONS.md) — supported jq functions
* [`docs/DESIGN.md`](docs/DESIGN.md) — design principles and scope
* [CPAN documentation](https://metacpan.org/pod/JQ::Lite)

---

## License

Same terms as Perl itself.
