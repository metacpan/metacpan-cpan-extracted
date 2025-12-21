# 🧩 jq-lite — Lightweight jq in Pure Perl

![JQ::Lite](./images/JQ_Lite_sm_2.png)

[![MetaCPAN](https://img.shields.io/cpan/v/JQ-Lite.svg)](https://metacpan.org/release/JQ-Lite)
[![Alpine Linux](https://img.shields.io/badge/Alpine-Linux%20community-0D597F?logo=alpinelinux\&logoColor=white)](https://pkgs.alpinelinux.org/package/edge/community/x86_64/jq-lite)
[![Perl](https://img.shields.io/badge/Perl-5.14%2B-39457E?logo=perl\&logoColor=white)](https://www.perl.org/)

🌐 [Project homepage](https://kawamurashingo.github.io/JQ-Lite/index-en.html)

---

## ✨ What is jq-lite?

**jq-lite** is a **pure-Perl JSON query engine** inspired by [`jq`](https://stedolan.github.io/jq/).

It lets you **query and transform JSON using jq-like syntax**
— **without external binaries, native libraries, or compilation**.

> ✅ **Official Alpine Linux package**
>
> ```bash
> apk add jq-lite
> ```

JQ::Lite is designed for **minimal environments** such as:

* Alpine Linux
* containers & CI pipelines
* legacy / restricted / air-gapped systems

where **simplicity, readability, and low dependency footprint** matter.

---

## 🚀 Why jq-lite (in one glance)

* 🪶 **Pure Perl** — no XS, no C, no shared libraries
* 🔍 **jq-style filters**: `.users[].name`, `select(...)`, `map(...)`
* 🔢 **Arithmetic & conditionals**: `if ... then ... else ... end`
* 🔧 **CLI tool**: `jq-lite`

  * `--null-input`, `--slurp`, `--from-file`
  * `--yaml`, `--arg`, `--rawfile`, `--argjson`, `--ascii-output`
* 📊 **100+ built-in jq functions**
  → see [`FUNCTIONS.md`](FUNCTIONS.md)
* 💻 **Interactive mode** for exploring JSON
* 🧰 **JSON & YAML input**
* 🌐 **Runs almost anywhere Perl runs**
  → even legacy or air-gapped systems
  → see [`DESIGN.md`](DESIGN.md)

---

## ⚡ Quick Start (CLI)

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

## 🧱 Environment Support

| Environment          | jq | jq-lite |
| -------------------- | -- | ------- |
| Legacy CentOS / RHEL | ❌  | ✅       |
| Alpine Linux         | ⚠️ | ✅       |
| Air-gapped systems   | ❌  | ✅       |
| No root privilege    | ⚠️ | ✅       |

✅ **Runs on Perl ≥ 5.14**
(e.g. CentOS 6, Debian 7 via `perlbrew` or local install)

---

## 💡 Why Pure Perl?

### 🧩 Portability

No compilation, no shared libraries.
If Perl runs, jq-lite runs.

Perfect for:

* minimal containers
* legacy servers
* restricted or offline environments

---

### 🧰 Extensibility

Extend jq-like behavior **directly in Perl**.

You can integrate CPAN modules such as:

* `LWP` (HTTP / APIs)
* `DBI` (databases)
* filesystem or OS tools

---

### 🧱 Seamless Perl Integration

```perl
use JQ::Lite;

my $jq = JQ::Lite->new;
say for $jq->run_query($json, '.users[].name');
```

No external command calls.
No parsing of CLI output.

---

### ⚙️ Lightweight Installation

* No XS / C toolchain
* No system-wide install required
* Ideal for CI/CD or user-local installs

---

### 🔍 Maintainability

* Faster iteration than C-based jq
* Easier debugging
* Community contributions are simpler

---

## ⚙️ Installation

### 🛠 From CPAN

```bash
cpanm JQ::Lite
```

---

### 🐧 Alpine Linux (Official)

```bash
apk add jq-lite
```

---

### 🍺 Homebrew (macOS)

```bash
brew tap kawamurashingo/jq-lite
brew install --HEAD jq-lite
```

---

## 🐳 Containers (Recommended)

**Alpine-based image**

```dockerfile
FROM alpine
RUN apk add --no-cache jq-lite
```

jq-lite is ideal as a **container-standard JSON tool**:

* tiny footprint
* predictable behavior
* no native dependencies

---

## 🐧 Portable Installer (Online → Offline)

For **air-gapped or offline systems**:

1. **Download (on connected machine)**

```bash
./download.sh [-v <version>] [-o /path/to/usb]
```

2. **Transfer** `JQ-Lite-<version>.tar.gz`

3. **Install**

```bash
./install.sh [-p <prefix>] [--skip-tests] JQ-Lite-<version>.tar.gz
```

Default:

```bash
$HOME/.local
```

Environment setup:

```bash
export PATH="$HOME/.local/bin:$PATH"
export PERL5LIB="$HOME/.local/lib/perl5/site_perl:$PERL5LIB"
```

---

## 🪟 Windows (PowerShell)

```powershell
.\install-jq-lite.ps1 [-Prefix <path>] [--SkipTests] JQ-Lite-<version>.tar.gz
```

Verify:

```powershell
jq-lite -v
```

---

## 🔍 Example Queries

```bash
jq-lite '.users[] | select(.profile.active) | .name' users.json
jq-lite '.users | sort_by(.age) | map(.name) | join(", ")' users.json
jq-lite '.users[].nickname? // .name' users.json
```

---

## 📚 Documentation

* 📘 **Functions**: [`FUNCTIONS.md`](FUNCTIONS.md)
* 🧭 **Design**: [`DESIGN.md`](DESIGN.md)
* 📦 **MetaCPAN**: [https://metacpan.org/pod/JQ::Lite](https://metacpan.org/pod/JQ::Lite)

---

## 👤 Author

**川村慎吾 (Shingo Kawamura)**
📧 [pannakoota1@gmail.com](mailto:pannakoota1@gmail.com)

---

## 📜 License

Same terms as Perl itself.








