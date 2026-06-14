Install Bootstrap
=================

`install.sh` is the repo-root bootstrap entrypoint for a blank Unix-like
developer machine. `install.ps1` is the matching checkout-only bootstrap
entrypoint for Windows PowerShell hosts. Both files ship in the repository and
release tarball for explicit operator use, but CPAN and `cpanm` do not install
them into the global command namespace.

Supported platforms
-------------------

- Alpine
- Debian
- Ubuntu
- Fedora
- macOS
- Windows

Release-gate note
-----------------

Debian-family, Alpine Linux, and Fedora remain the required release gates for
packaged installation checks.
macOS support stays available for manual validation and Homebrew-specific
debugging, but it is not a mandatory release gate.

Basic usage
-----------

Run the Unix-like installer from a checkout:

```bash
./install.sh
```

Run the Windows installer from a checkout:

```powershell
powershell -ExecutionPolicy Bypass -File .\install.ps1
```

Or stream it into the current PowerShell session:

```powershell
irm https://raw.githubusercontent.com/manif3station/developer-dashboard/refs/heads/master/install.ps1 | iex
```

What it does
------------

1. Detects the current platform.
2. On Debian-family hosts, reads the repo-root `aptfile`, runs `apt-get update`,
   and installs the listed packages. When the current user is not root, it uses
   `sudo`. Before that prompt appears it prints a visible progress board and
   explains that the password request is for the operating-system account so
   the package manager can install the listed bootstrap packages.
3. On Alpine hosts, reads the repo-root `apkfile` and installs the listed
   packages through `apk add --no-cache`.
4. On Fedora hosts, reads the repo-root `dnfile` and installs the listed
   packages through `dnf install -y`.
5. On macOS, reads the repo-root `brewfile` and installs the listed packages
   through `brew install`. If `brew` is missing on a blank Mac, `install.sh`
   bootstraps Homebrew first and then continues through the normal package
   flow.
6. Verifies that `node`, `npm`, and `npx` are available after those package
   installs, because skill `package.json` dependency handling uses
   `npx --yes npm install`.
7. Bootstraps user-space Perl tooling under `~/perl5` with:

   ```bash
   cpanm --no-wget --notest --local-lib-contained "$HOME/perl5" local::lib App::cpanminus File::ShareDir::Install
   ```

8. Appends exactly one `local::lib` bootstrap line to the active shell startup
   file. Bash users get `~/.bashrc`, zsh users get `~/.zshrc`, and generic POSIX
   `sh` users fall back to `~/.profile`. On Debian-family bash hosts the
   installer now writes the dashboard-managed bootstrap lines above the
   standard non-interactive `return` guard in `~/.bashrc`, so tmux status
   commands and other non-interactive shells can still resolve `dashboard`.
9. Prefers Homebrew Perl on macOS when `brew --prefix perl` exposes a brewed
   interpreter, so the user-space runtime does not drift back to the system Perl.
10. On Debian-family, Alpine, or Fedora hosts where the packaged system Perl is older than `5.38`,
   bootstraps a user-space `perlbrew` Perl under `~/perl5/perlbrew` first so
   the checkout can still install on older stable releases such as Debian 12 or
   an unusually old Alpine image.
   The installer downloads the `App::perlbrew` tarball with `curl` first and
   then installs it from that local file so Alpine avoids the noisy
   `IO::Socket::IP` warning that can appear during networked `cpanm`
   package-resolution bootstrap.
   That rescue path uses `perlbrew --notest install perl-5.38.5` so the blank
   machine bootstrap does not fail on upstream Perl core test noise before
   Developer Dashboard itself is installed.
   On piped `curl ... | sh` runs, the installer never probes `/dev/tty`; if
   the shell is not terminal-backed it prints the exact activation file to
   source instead of emitting `/dev/tty` noise.
   When `SHELL` is not exported, as in blank Docker containers and piped
   `curl ... | sh` runs, the post-install activation runner resolves the same
   preferred shell as the bootstrap target (passwd entry or
   `DD_INSTALL_PREFERRED_SHELL`), so bash-flavoured activation files are never
   sourced through plain `sh`.
11. Installs Developer Dashboard into the user account from the current local
    checkout when `install.sh` is run from a checkout, or from a freshly
    cloned GitHub `master` checkout when the installer is streamed through
    `curl ... | sh` and no explicit `DD_INSTALL_CPAN_TARGET` override is set.
    If `DD_INSTALL_CPAN_TARGET` is set, the installer passes that exact value
    through to `cpanm --no-wget --notest`. The Unix-like bootstrap seeds
    `File::ShareDir::Install` into `~/perl5` before that checkout install so a
    blank host can run `Makefile.PL` without dying on the share-dir installer
    prerequisite.

12. Runs `dashboard init` so the runtime exists immediately after the install.
13. On Windows PowerShell hosts, `install.ps1` uses `winget` to install missing
    Git, Strawberry Perl, and Node.js LTS packages, downloads `cpanm` from
    `https://cpanmin.us/`, bootstraps `local::lib` together with
    `File::ShareDir::Install`, installs Developer Dashboard with `cpanm --notest`,
    updates the current-user PowerShell profile with the `~/perl5` PATH and
    Perl environment variables plus `dashboard shell ps`, seeds `env:HOME`
    from PowerShell `HOME` inside that managed profile block when Windows did
    not export `HOME`, writes a stable user-space `make.cmd` shim that points
    at Strawberry Perl's GNU make provider so skill `Makefile` workflows keep
    working in later sessions, activates that shell bootstrap in the current
    PowerShell session, and then runs `dashboard init`.
    The packaged install path avoids test-only dependencies such as
    `Plack::Test` and `Test::Pod` so blank Windows hosts do not have to pull
    the `Test::SharedFork` chain. When `DD_INSTALL_CPAN_TARGET` is set,
    `install.ps1` passes that exact value straight through to `cpanm --notest`.

Useful examples
---------------

Default install from a checkout:

```bash
./install.sh
```

Stream the current GitHub master checkout into a blank Unix-like host:

```bash
curl -fsSL https://raw.githubusercontent.com/manif3station/developer-dashboard/refs/heads/master/install.sh | sh
```

Force zsh startup-file selection:

```bash
SHELL=/bin/zsh ./install.sh
```

Test the installer against a specific tarball instead of the CPAN package name:

```bash
DD_INSTALL_CPAN_TARGET=./Developer-Dashboard-X.XX.tar.gz ./install.sh
```

Install from a Windows checkout:

```powershell
powershell -ExecutionPolicy Bypass -File .\install.ps1
```

Install from a streamed Windows bootstrap:

```powershell
$env:DD_INSTALL_CPAN_TARGET = '.\Developer-Dashboard-X.XX.tar.gz'
irm https://raw.githubusercontent.com/manif3station/developer-dashboard/refs/heads/master/install.ps1 | iex
```

The Windows bootstrap now keeps test-only dependencies such as `Plack::Test`
and `Test::Pod` out of the packaged install path so blank Windows hosts do not
have to pull the `Test::SharedFork` chain while installing Developer Dashboard.

Repairing an existing installed shell bootstrap
-----------------------------------------------

If an older Debian-family install appended the dashboard-managed bash bootstrap
lines after the standard non-interactive `return` guard in `~/.bashrc`, tmux
status commands can miss `dashboard` even though interactive shells still work.
Use:

```bash
dashboard doctor --fix
```

That now audits both staged helper drift under `~/.developer-dashboard/cli/dd/`
and misplaced dashboard-managed bash bootstrap lines in `~/.bashrc`, then
repairs them in place when the drift is repairable.
