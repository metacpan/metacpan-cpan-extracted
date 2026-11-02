# Linux::Event::HTTP 0.005 release notes

This release makes Linux::Event::HTTP easier to learn and use. It is a
documentation-focused maintenance release following the Unblock-based
0.004 rebuild.

## What's improved

- The README begins with complete, runnable HTTP server and client examples.
- The main module, Server and Client POD now describe application usage
  instead of beginning with the internals of the protocol engines.
- The new Getting Started guide covers GET/POST, headers, status codes,
  request routing, HTTPS, HTTP/2 and HTTP/3 setup, streaming and shutdown.
- The Client documentation explains the difference between buffered
  responses and streaming callbacks, especially when on_response runs.
- The docs explain the default 1 MiB buffered-body limit, how to handle
  unknown response sizes, and that compressed response bodies are not
  automatically decompressed.
- Server documentation shows request and response handling, streaming
  uploads and downloads, errors, and graceful shutdown.

## Compatibility

No application API, protocol engine, native bridge, or runtime behavior
has changed. Version 0.005 uses the same dependencies and optional
protocol features as 0.004; no upstream Unblock, Uniform, Net::QUIC,
Linux::Event, or WebSocket release is needed for this update.

Linux and Perl 5.36 or newer are required. Normal HTTP/1 support uses
Linux::Event 0.117, Unblock::HTTP 0.03, Unblock::HTTP1 0.13, and
Uniform::HTTP 0.06. Optional HTTP/2 uses Unblock::HTTP2 0.13.
Optional HTTP/3 uses Unblock::HTTP3 0.14 and Net::QUIC 0.06.

## Release validation

The documentation PR (#42) passed the GitHub CI Perl matrix. The
release commit should also pass CI and the packaged distribution test
before the GitHub tag and CPAN upload are published.

This preparation does not publish a GitHub release or upload to CPAN.
