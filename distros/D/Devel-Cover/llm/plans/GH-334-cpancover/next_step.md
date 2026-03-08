# Next Step

## Immediate Action: Test log link changes

The log link resolution rework and template fix are uncommitted.
Test them before committing:

```bash
# Rebuild dev image (code is baked in)
dc -e dev docker-build

# Run test
dc -e dev cpancover-controller-test

# Serve and check HTML
dc -e dev cpancover-serve
# Browse http://localhost:8080/latest/dist/Y.html
#   - YAML-PP should have a ¶ link (Docker-built, has .out.gz)
#   - YAML-Dump should have NO ¶ link (no log file)
#   - Old modules with .out.gz files should have ¶ links
```

## Uncommitted Changes to Commit

```bash
git add lib/Devel/Cover/Collection.pm utils/dc
```

Changes:
- `lib/Devel/Cover/Collection.pm`:
  - Extracted `resolve_log_links` method from `generate_html`
  - Two-pass log resolution: `.out.gz` match first, `.log_ref`
    fallback for dependency modules
  - Conditional `¶` link in template (no link when no log)
- `utils/dc`:
  - `-f` flag for `gzip -d` in `cpancover-uncompress-dir`
  - Delete stale `dist/*.gz` before compression

## After Committing

1. Push to remote
2. Create PR referencing GH-334
3. Consider whether `generate_html` can be run directly on the host
   (without Docker rebuild) for faster iteration on the staging_dev
   data — it only needs Collection.pm, not dc recipes

## Testing Commands

```bash
# Rebuild after fixes
dc -e dev docker-build

# Quick test
dc -e dev cpancover-controller-test

# Serve and inspect
dc -e dev cpancover-serve

# Full compression test (idempotent on second run)
dc cpancover-compress
dc cpancover-compress
```
