# Convention-based site

From this directory, after installation:

```sh
markdown-publish build
markdown-publish serve
```

The two guide chapters become separate pages. Stop preview with Ctrl-C.
To experiment with publication, copy this example into a disposable Git
repository, make an initial commit, configure an author identity, and run
`markdown-publish gh`. This action creates or updates the local `gh-pages`
branch without contacting a remote.
