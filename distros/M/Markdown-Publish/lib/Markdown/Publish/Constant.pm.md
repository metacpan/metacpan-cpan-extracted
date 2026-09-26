# NAME

Markdown::Publish::Constant - publication defaults

# DESCRIPTION

Defines `MARKDOWN_PUBLISH_MODULE`, `MARKDOWN_PUBLISH_CONFIG_FN`,
`MARKDOWN_PUBLISH_OUTPUT_DN`, `MARKDOWN_PUBLISH_BRANCH`,
`MARKDOWN_PUBLISH_NPM_VERBOSE`, `MARKDOWN_PUBLISH_HOST`, and
`MARKDOWN_PUBLISH_PORT`. Import individual scalar constants or use the default
export set. The default publisher is
`Markdown::Publish::MkDocs`.

An optional `Constant.pm.local` beside the installed module may return a hash
reference of permanent overrides:

```perl
+{
    MARKDOWN_PUBLISH_MODULE    => 'Markdown::Publish::VitePress',
    MARKDOWN_PUBLISH_OUTPUT_DN => 'public'
}
```

Environment variables named after the constants override both the local file
and built-in values. `MARKDOWN_PUBLISH_MODULE` also overrides a module supplied
through the API, `META_MERGE.x_documentation.publish`, or JSON configuration.
Set `MARKDOWN_PUBLISH_NPM_VERBOSE=1` to show npm installation output. Its default
value is `0`; installation start and completion messages are always shown.
Set `MARKDOWN_PUBLISH_HOST` and `MARKDOWN_PUBLISH_PORT` to control where
`publish_serve` listens. Both default to undefined, leaving each engine's
existing address and port in place. Per-engine `host`, `port`, or MkDocs
`address` settings take precedence.

# AUTHOR

Andrew Speer <andrew.speer@isolutions.com.au>

# LICENSE AND COPYRIGHT

This software is copyright (c) 2026 by Andrew Speer. It may be distributed
under the same terms as Perl itself.
