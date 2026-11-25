# macOS ARM64 OpenSSL dependency setup

The Platform Compatibility GitHub Actions job failed while installing project
dependencies on the `macos-26` ARM64 runner. The dependency chain was:

`LWP::Protocol::https` -> `IO::Socket::SSL` -> `Net::SSLeay`

The job log showed that `Net::SSLeay` configured and then failed during its
native build. The nested cpanm build log was not copied into the job log, so
the original run does not expose the underlying compiler or linker diagnostic.
The failure was therefore not evidence that macOS ARM64 is unsupported.

Net::SSLeay 1.96 accepts `OPENSSL_PREFIX` to select an OpenSSL installation.
Its macOS ARM Homebrew autodetection checks `/opt/homebrew/opt/openssl`, not
the versioned `openssl@3` prefix. The workflow previously left that selection
implicit. This is the likely root cause; the original nested build log is not
available to prove which discovery or link step failed. The repository fix
now:

1. Installs `openssl@3` on the macOS ARM64 runner if it is not already present.
2. Resolves the formula prefix with `brew --prefix openssl@3`.
3. Fails visibly if the OpenSSL executable or headers are missing.
4. Reads `lipo -archs` output and requires the exact `arm64` architecture.
5. Exports `OPENSSL_PREFIX` and the formula's `bin` directory to later steps.
6. Builds `Net::SSLeay` separately with cpanm verbose output before installing
   the remaining project dependencies.

This gives the dependency build a deterministic OpenSSL prefix and ensures a
future native build failure includes its configure, compiler, and linker
details in the Actions log. The workflow contract was tested by
the test 229-platform-openssl-workflow inside the development container; that
test was removed on 2026-11-23 together with the GitHub workflow files. The
hosted macOS ARM64 rerun is required to confirm the build itself; the local
Docker test validates the workflow structure, not a macOS native build.

The first hosted attempt with this setup exposed a defect in the architecture
guard itself: Apple's `lipo -verify_arch` parsed the library path as an
architecture argument and exited before Net::SSLeay ran. The guard now reads
`lipo -archs` output and checks for the `arm64` token. The corrected hosted
macOS ARM64 rerun is still required to confirm the OpenSSL setup and native
dependency build; the local Docker test validates the workflow structure, not
a macOS native build.

The original failure is recorded in GitHub Actions run
[41117859690](https://github.com/manif3station/developer-dashboard/actions/runs/41117859690),
job `Perl tests (macOS arm64)`. Its log ended with the failed `Net::SSLeay`
build and did not include the referenced cpanm `build.log` contents.
