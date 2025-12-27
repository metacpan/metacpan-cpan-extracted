# jq-lite — Lightweight jq

![JQ::Lite](./images/jq-lite_sm.png)

[![MetaCPAN](https://img.shields.io/cpan/v/JQ-Lite.svg)](https://metacpan.org/release/JQ-Lite)
[![Alpine Linux](https://img.shields.io/badge/Alpine-Linux%20community-0D597F?logo=alpinelinux\&logoColor=white)](https://pkgs.alpinelinux.org/package/edge/community/x86_64/jq-lite)
[![Perl](https://img.shields.io/badge/Perl-5.14%2B-39457E?logo=perl\&logoColor=white)](https://www.perl.org/)

頁 [Project homepage](https://kawamurashingo.github.io/JQ-Lite/)

---

## 概 What is jq-lite?

**jq-lite** is a **Pure Perl JSON query engine** inspired by `jq`.

It lets you **query and transform JSON using jq-like syntax**
— **without external binaries, native libraries, or compilation**.

正 **Official Alpine Linux package**

```bash
apk add jq-lite
````

JQ::Lite is designed for **minimal environments** such as:

* Alpine Linux
* containers & CI pipelines
* legacy / restricted / air-gapped systems

where **simplicity, readability, and low dependency footprint** matter.

---

## 要 Why jq-lite

* 軽 **Pure Perl** — no XS, no C, no shared libraries
* 探 **jq-style filters**: `.users[].name`, `select(...)`, `map(...)`
* 算 **Arithmetic & conditionals**: `if ... then ... else ... end`
* 具 **CLI tool**: `jq-lite`

  * `--null-input`, `--slurp`, `--from-file`
  * `--yaml`, `--arg`, `--rawfile`, `--argfile`, `--argjson`, `--ascii-output`
* 術 **100+ built-in jq functions**
* 対 **Interactive mode**
* 材 **JSON & YAML input**
* 域 **Runs almost anywhere Perl runs**

---

## 試 Quick Start (CLI)

```bash
jq-lite '.users[].name' users.json
jq-lite '.users[] | select(.age > 25)' users.json
jq-lite --yaml '.users[].name' users.yaml
```

Interactive exploration:

```bash
jq-lite users.json
```

---

## 境 Environment Support

| Environment          | jq | jq-lite |
| -------------------- | -- | ------- |
| Legacy CentOS / RHEL | 不X  | 可O  |
| Alpine Linux         | 条△  | 可O  |
| Air-gapped systems   | 不X  | 可O  |
| No root privilege    | 条△  | 可O  |

可 **Runs on Perl ≥ 5.14**
(e.g. CentOS 6, Debian 7 via perlbrew or local install)

---

## 理 Why Pure Perl?

### 携 Portability

No compilation, no shared libraries.
If Perl runs, jq-lite runs.

---

### 拡 Extensibility

Extend jq-like behavior **directly in Perl**.

* LWP
* DBI
* filesystem / OS tools

---

### 融 Seamless Perl Integration

```perl
use JQ::Lite;

my $jq = JQ::Lite->new;
say for $jq->run_query($json, '.users[].name');
```

No external command calls.
No parsing of CLI output.

---

### 軽 Lightweight Installation

* No XS / C toolchain
* No system-wide install
* Ideal for CI/CD

---

### 保 Maintainability

* Faster iteration than C-based jq
* Easier debugging
* Simple contributions

---

## 入 Installation

### 配 CPAN

```bash
cpanm JQ::Lite
```

---

### 林 Alpine Linux

```bash
apk add jq-lite
```

---

### 麦 Homebrew (macOS)

```bash
brew tap kawamurashingo/jq-lite
brew install --HEAD jq-lite
```

---

## 容 Containers

```dockerfile
FROM alpine
RUN apk add --no-cache jq-lite
```

jq-lite is ideal as a **container-standard JSON tool**.

---

## 移 Portable Installer (Offline)

```bash
./download.sh [-v <version>] [-o /path]
./install.sh [-p <prefix>] [--skip-tests] JQ-Lite-<version>.tar.gz
```

Default:

```bash
$HOME/.local
```

---

## 窓 Windows (PowerShell)

```powershell
.\install-jq-lite.ps1 [-Prefix <path>] [--SkipTests] JQ-Lite-<version>.tar.gz
```

---

## 例 Example Queries

```bash
jq-lite '.users[] | select(.profile.active) | .name'
jq-lite '.users | sort_by(.age) | map(.name) | join(", ")'
jq-lite '.users[].nickname? // .name'
```

---

## 書 Documentation

* [`FUNCTIONS.md`](FUNCTIONS.md)
* [`DESIGN.md`](DESIGN.md)
* [`CPAN`](https://metacpan.org/pod/JQ::Lite)

---

## 作 Author

川村慎吾 (Shingo Kawamura)
[pannakoota1@gmail.com](mailto:pannakoota1@gmail.com)

---

## 許 License

Same terms as Perl itself.









