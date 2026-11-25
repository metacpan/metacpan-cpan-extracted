# GitHub Release troubleshooting

## Release trigger

The GitHub Release workflow in `.github/workflows/release-github.yml` runs when
a `vX.XX` tag is pushed. Updating `dist.ini` does not create a tag or start a
release. The tag must point to the commit whose distribution metadata has the
same version.

The workflow checks the tag, runs the full test suite and all-metric library
coverage, builds the distribution, and only then creates or updates the GitHub
Release. A failed test or coverage gate therefore leaves the previous
successful GitHub Release as the latest one. Inspect the first failed workflow
step before retrying; provenance is attached after the release is created.

## 2026-10-29 investigation

The reported public latest release was `v4.31`, while `dist.ini` and the
current source commit were at `6.07`. The latest previously pushed tag was
`v5.10`; its release run failed at all-metric coverage before building or
publishing. There was no `v6.07` tag, so the release workflow had not run for
the current source version.

Pushing `v6.07` reproduced the workflow path: the full test suite passed, but
coverage reported 99.9% statement, branch, and subroutine coverage. Its only
uncovered subroutine was the Linux inotify backend's descriptor-close callback
in `Developer::Dashboard::IndicatorStore::Watch`. At that point in the
investigation, CI did not require the optional `FFI::Platypus` module, so the
live native integration could be skipped. The deterministic fake-backend test
created that callback but did not call it.

The regression test now invokes the fake Linux backend's close callback on its
pipe fixture. The next run, `v6.08` at [workflow run
40958667082](https://github.com/manif3station/developer-dashboard/actions/runs/40958667082),
confirmed close coverage but found two further uncovered successful paths in
the same adapter: wrapping a valid descriptor and registering a byte-safe path.
The fake test now exercises all three callbacks without requiring FFI or
changing runtime behaviour. The focused four-metric coverage gate reports
100.0% for `IndicatorStore::Watch.pm`. The failed `v6.07` and `v6.08` tags are
left unchanged; release attempts must use a new, matching version tag.

## XS native backend

The former optional FFI backend has been replaced by the distribution's shared
XS extension for PBKDF2, Linux inotify, and Windows directory notifications.
Platform CI builds the extension before running the full suite; deterministic
watcher tests exercise the API without relying on an FFI installation. macOS
continues to use Mac::FSEvents. A skipped native test is not evidence that the
compiled XS implementation passed: platform jobs must build and load the
extension explicitly.

## Release checklist

1. Confirm `dist.ini` and all library module versions agree.
2. Run the full suite, four-metric coverage gate, security checks, packaging,
   and blank-environment install checks.
3. Build and verify the tarball for that version.
4. Commit and push the verified source commit.
5. Create and push its matching annotated `vX.XX` tag with `git-push-mf`.
6. Confirm the release workflow passes tests, coverage, and build, then verify
   the GitHub Release assets and provenance.

## Evidence

- Previous published release: [v4.31](https://github.com/manif3station/developer-dashboard/releases/tag/v4.31).
- Failed v5.10 workflow: [run 36354660051](https://github.com/manif3station/developer-dashboard/actions/runs/36354660051).
- Investigative v6.07 workflow: [run 40942255350](https://github.com/manif3station/developer-dashboard/actions/runs/40942255350).
