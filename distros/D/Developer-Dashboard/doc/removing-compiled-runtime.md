# Interpreted CLI runtime

Developer Dashboard commands run through the active Perl interpreter. The
distribution does not compile or cache standalone command binaries. This keeps
`dashboard` and `d2` on one execution path and avoids a secondary compiler,
per-user binary cache, or compiler-specific release workflow.
Legacy files under the generated `pax-output/` directory are excluded from
source distributions so stale compiled binaries are not shipped either.

To verify the installed version in a development container, run:

```sh
perl bin/dashboard version
perl bin/d2 version
```

The internal helper staging mechanism remains in place for lightweight command
helpers; it does not compile the application or alter the interpreter used to
run it.
