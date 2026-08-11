# Self-upgrade command

Developer Dashboard provides the same self-upgrade flow through both public
entrypoints:

```text
dashboard upgrade
d2 upgrade
```

The command selects the canonical installer for the active platform:

- Unix-like systems use the HTTPS `install.sh` asset and execute it with `sh`.
- Windows uses the HTTPS `install.ps1` asset and executes it with `pwsh` when
  available, otherwise Windows PowerShell, with `-NoProfile` and a
  process-scoped `-ExecutionPolicy Bypass`.

Before execution, the command requires a successful HTTPS response, rejects
empty or oversized content, and verifies platform-specific Developer Dashboard
installer markers. It writes the validated response to an owner-only temporary
file and passes that path to the platform interpreter as a separate argument;
remote content is never interpolated into a shell command string. Installer
stdout and stderr remain visible, and installer failures are returned as the
command exit status.

Preview the exact platform, installer URL, and interpreter plan without a
network request or host mutation:

```text
dashboard upgrade --dry-run
d2 upgrade --dry-run
```

Unsupported operands or options fail with the concise command usage. A Windows
upgrade also fails explicitly when neither supported PowerShell executable is
available.

For development, run the acceptance contract with:

```text
prove -lv t/122-upgrade-cli.t
```

Release-grade verification also requires the normal source-suite, all-metric
coverage, packaged-install, and platform gates. Exercise `d2 upgrade --dry-run`
and `dashboard upgrade --dry-run` after installing the built distribution in a
blank environment. Run the Unix path on the supported Linux container matrix
and a real macOS QEMU guest, and run the PowerShell path on a real Windows QEMU
guest.
