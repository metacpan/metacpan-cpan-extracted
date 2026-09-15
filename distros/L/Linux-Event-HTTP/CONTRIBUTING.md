# Contributing

Contributions are welcome.

Please open an issue before undertaking substantial API or architectural work
so the change can be discussed against the project's protocol-layer scope.
Small bug fixes, tests, documentation corrections, and benchmark improvements
can be submitted directly as pull requests.

## Development expectations

- Keep the distribution focused on HTTP protocol support rather than web-framework features.
- Preserve Linux::Event ownership of transport, TLS, buffering, backpressure, deadlines, and event dispatch.
- Add or update tests for behavioral changes.
- Keep public API documentation in sync with implementation changes.
- Include benchmarks for performance-sensitive parser or connection-path changes when practical.
- Keep source and documentation ASCII unless a protocol test specifically requires other bytes.

Run the normal distribution checks before submitting a pull request:

```sh
perl Makefile.PL
make
make test
```

## Security issues

Do not report suspected security vulnerabilities in public issues or pull
requests. See `SECURITY.md` for private reporting instructions.

## Attribution

Significant contributors will be credited in distribution metadata and release
notes as appropriate.
