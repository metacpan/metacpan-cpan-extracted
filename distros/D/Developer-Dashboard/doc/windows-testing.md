# Windows Verification

## Purpose

This document defines how Developer Dashboard proves Windows compatibility
without relying on guesswork or POSIX-only assumptions.

The supported baseline on Windows is PowerShell plus Strawberry Perl. Git Bash optional. Scoop optional. They are setup helpers, not runtime
requirements for the installed `dashboard` command. The verification flow is
layered so fast tests catch regressions before the slower VM gate runs.

## Verification Layers

1. Forced-Windows unit tests in `t/`

- locally override the platform detector so Linux CI can still exercise Windows dispatch logic
- assert `dashboard shell ps` and PowerShell prompt bootstrap output
- assert `ps` resolves to PowerShell rather than the POSIX `PS1` variable
- assert `.pl`, `.ps1`, `.cmd`, and `.bat` command argv resolution
- assert Windows `PATHEXT` lookup behavior

2. Real Strawberry Perl smoke on Windows

- run `integration/windows/run-strawberry-smoke.ps1`
- install the built tarball with `cpanm`
- verify `dashboard shell ps` and `dashboard ps1`
- verify one PowerShell-backed collector command
- verify one saved Ajax PowerShell handler through `Invoke-WebRequest`
- verify browser DOM rendering through Edge or Chrome when available

3. Full-system QEMU smoke

- run the one-command host helper `integration/windows/run-host-windows-smoke.sh`
- that helper loads reusable `windows-qemu.env` settings, builds a fresh tarball when needed, and delegates to `integration/windows/run-qemu-windows-smoke.sh`
- `run-qemu-windows-smoke.sh` supports two host paths:
  - `WINDOWS_QEMU_MODE=prepared` for a prebuilt qcow2 image reached over SSH
  - `WINDOWS_QEMU_MODE=dockur` for a KVM-backed `dockurr/windows` container with OEM and shared-folder bootstrap files
- in the Dockur-backed path, the host launcher stages the Strawberry Perl MSI
  into the OEM bundle and can keep retained guests on configurable host web
  and RDP ports for reruns
- use this gate before claiming release-grade Windows compatibility

## Host Requirements

- `qemu-system-x86_64` and `/dev/kvm` access for the prepared-image VM gate
- Docker plus `/dev/kvm` access for the Dockur-backed VM gate
- a reusable env file at `WINDOWS_QEMU_ENV_FILE`, `./.developer-dashboard/windows-qemu.env`, or `~/.developer-dashboard/windows-qemu.env`
- either:
  - a prepared Windows qcow2 image with Strawberry Perl, PowerShell, OpenSSH, and optionally Edge or Chrome
  - or a Dockur OEM bootstrap configuration; `WINDOWS_STRAWBERRY_URL` is optional because the launcher can resolve the current 64-bit Strawberry Perl MSI from the official `releases.json` feed

Example `windows-qemu.env`:

```bash
WINDOWS_QEMU_MODE=dockur
WINDOWS_DOCKUR_VERSION=2022
WINDOWS_RAM_MB=8192
WINDOWS_CPU_COUNT=4
```

## Commands

Run the fast repo-side Windows logic coverage with:

```bash
prove -lv t/07-core-units.t t/05-cli-smoke.t
```

Run the Strawberry Perl smoke on a Windows host with:

```powershell
powershell -ExecutionPolicy Bypass -File integration/windows/run-strawberry-smoke.ps1 -Tarball C:\path\Developer-Dashboard-*.tar.gz
```

Run the full-system Windows VM gate from a Linux host with:

```bash
WINDOWS_QEMU_ENV_FILE=.developer-dashboard/windows-qemu.env \
integration/windows/run-host-windows-smoke.sh
```

The first Dockur-backed run can take a long time because it may need to
download Windows media, complete unattended guest setup, install Strawberry
Perl, and then run the smoke. The helper is meant to make that long path
rerunnable, not instant.

Inside the Windows guest smoke, the tarball install currently uses
`cpanm --notest` for third-party dependency setup. The release-grade
verification still comes from the Developer Dashboard smoke that runs after
that install step: `dashboard shell ps`, `dashboard ps1`, collector, saved
Ajax, web, and browser checks still execute in the guest.

## Release Rule

For Windows-targeted changes:

- the forced-Windows unit tests must pass
- the Strawberry Perl smoke must pass on a real Windows environment
- the QEMU smoke must pass before making a release-grade Windows compatibility claim
