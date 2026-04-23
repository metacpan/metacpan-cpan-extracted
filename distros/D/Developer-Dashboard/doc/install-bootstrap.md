Install Bootstrap
=================

`install.sh` is the repo-root bootstrap entrypoint for a blank developer
machine. It is a checkout-only helper: the file ships in the repository and
release tarball for explicit operator use, but CPAN and `cpanm` do not install
it into the global command namespace.

Supported platforms
-------------------

- Alpine
- Debian
- Ubuntu
- Fedora
- macOS

Release-gate note
-----------------

Debian-family, Alpine Linux, and Fedora remain the required release gates for
packaged installation checks.
macOS support stays available for manual validation and Homebrew-specific
debugging, but it is not a mandatory release gate.

Basic usage
-----------

Run the installer from a checkout:

```bash
./install.sh
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
   through `brew install`.
6. Verifies that `node`, `npm`, and `npx` are available after those package
   installs, because skill `package.json` dependency handling uses
   `npx --yes npm install`.
7. Bootstraps user-space Perl tooling under `~/perl5` with:

   ```bash
   cpanm --notest --local-lib-contained "$HOME/perl5" local::lib App::cpanminus
   ```

8. Appends exactly one `local::lib` bootstrap line to the active shell startup
   file. Bash users get `~/.bashrc`, zsh users get `~/.zshrc`, and generic POSIX
   `sh` users fall back to `~/.profile`.
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
11. Installs Developer Dashboard into the user account with:

   ```bash
   cpanm --notest Developer::Dashboard
   ```

12. Runs `dashboard init` so the runtime exists immediately after the install.

Useful examples
---------------

Default install:

```bash
./install.sh
```

Force zsh startup-file selection:

```bash
SHELL=/bin/zsh ./install.sh
```

Test the installer against a specific tarball instead of the CPAN package name:

```bash
DD_INSTALL_CPAN_TARGET=./Developer-Dashboard-X.XX.tar.gz ./install.sh
```
