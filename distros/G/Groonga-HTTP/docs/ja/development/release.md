---
title: Release
---

# Requirements

# How to release

## 1.Update change log

```console
$ editor Chnages
```

We write summarized the changes for this release under the "\{\{$NEXT\}\}".

## 2. Check whether we can make packages or not

We confirm below CIs green or not.

* [GitHub Actions][github-actions]

[github-actions]: https://github.com/groonga/Groonga-HTTP/actions

## 3. Upload module to CPAN

```console
$ minil release
```

We need to get the "PAUSE" account to succeed in this procedure.

## 4. Update latest release in document

We update `docs/_config.yml` like https://github.com/groonga/Groonga-HTTP/commit/1c6b9cacb72306f62dce296ed15ddd6a2514b9cf.
