# Contributing

## Workflow

1. Make the change with tests in `t/`.
2. Run `prove -lr t`.
3. Run Devel::Cover and keep `lib/` at 100% statement and subroutine coverage.
4. Update documentation in `doc/`, `README.md`, and `lib/Developer/Dashboard.pm` POD when behavior changes.
5. Update `FIXED_BUGS.md` and `Changes`.
6. Rebuild the tarball and keep only the latest `Developer-Dashboard-*.tar.gz`.
7. Run `integration/blank-env/run-host-integration.sh`.

## Release Hygiene

- Do not modify the read-only older reference tree.
- Use `JSON::XS`, `LWP::UserAgent`, and `Capture::Tiny` in active code where those rules apply.
- Keep comments and POD in sync with behavior.

## Security

For private vulnerability reports, use the contact in [`SECURITY.md`](SECURITY.md).
