# Embedded Markdown

With the distribution installed, run from this directory:

```sh
markpod --extract-markdown hello.pl
markpod --inplace --nobackup hello.pl
perldoc hello.pl
```

There is intentionally no sidecar. The embedded Markdown is preserved and POD
is regenerated from it. From a checkout, replace `markpod` with
`perl -I../../lib ../../bin/markpod`.
