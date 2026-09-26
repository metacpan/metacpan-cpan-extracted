# Guide conversion

From this directory, with the distribution installed:

```sh
docbook-convert --pandoc guide.xml > guide.md
```

Inspect guide.md for preserved section IDs, the internal link, and an
`!!! note` block suitable for Material for MkDocs.
