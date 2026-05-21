# Releasing Masscan::Client

## Build The Distribution

From the project root, generate a fresh release tarball:

```bash
perl Makefile.PL
make manifest
make dist
```

This creates a file like:

```text
Masscan-Client-0.21.tar.gz
```

## Validate The Package

Inspect the tarball contents:

```bash
tar -tzf Masscan-Client-0.21.tar.gz
```

Test-install the release artifact locally:

```bash
cpanm --test-only ./Masscan-Client-0.21.tar.gz
```

## Upload To CPAN

Upload the generated `.tar.gz` to PAUSE using either the web upload page
or a CLI uploader such as:

```bash
cpan-upload Masscan-Client-0.21.tar.gz
```

## Release Notes

If you change runtime dependencies, metadata, or public behavior, bump the
module version before building the new tarball so CPAN clients receive the
new release and corrected metadata.
