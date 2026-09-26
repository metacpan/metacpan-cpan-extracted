# Sidecar documentation

From this directory, with the distribution installed:

```sh
markpod --dry-run hello.pl
markpod --inplace --nobackup hello.pl
perldoc hello.pl
perl hello.pl
```

Edit `hello.pl.md`, then repeat the merge. A second unchanged merge leaves the
source alone. From a checkout, replace `markpod` with
`perl -I../../lib ../../bin/markpod`.
