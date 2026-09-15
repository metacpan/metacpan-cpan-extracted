# picohttpparser evaluation

This document records the evaluation of vendored picohttpparser as the native HTTP/1 request-head parser for Linux::Event::HTTP.

## Result

The experiment passed. picohttpparser is suitable as the HTTP/1 request-head parser for this distribution.

The parser is fast enough that the dominant design concern is the Perl representation layered above it, not pico itself. The chosen request representation therefore keeps method, target, and header spans in native state and materializes Perl strings only when requested.

## Upstream

The distribution vendors picohttpparser from:

- project: h2o/picohttpparser
- commit: `f4d94b48b31e0abae029ebeafcfd9ca0680ede58`
- upstream commit date: 2026-04-06

The vendored `picohttpparser.c` and `picohttpparser.h` are unmodified copies of that revision. `vendor/picohttpparser/UPSTREAM` records provenance and `vendor/picohttpparser/LICENSE` retains the upstream license.

The distribution never downloads picohttpparser while configuring, building, testing, installing, or running. `make disttest` verifies that the generated distribution contains the vendored source and can compile and test it self-contained.

## Parser boundary

`Linux::Event::HTTP::_HTTP1` is private. It does not establish a public parser API.

The XS wrapper uses picohttpparser to identify the request method, request target, HTTP/1 minor version, and header name/value spans.

`probe_request` exposes the lowest-overhead parse path for benchmarking and connection-state work. `parse_request_offsets` remains a private benchmark path that exposes offsets as Perl arrays so its allocation cost can be compared directly.

The application-facing path is `parse_request`, which creates a `Linux::Event::HTTP::Request` backed by native state. One C allocation contains the request metadata, header slice table, and a private copy of the parsed request-head bytes. It does not eagerly create a Perl scalar for every parsed field.

`Request` materializes method, target, header names, and header values only when the application asks for them. Header-name lookup is performed directly against the native slices with ASCII case-insensitive comparison before a value is materialized.

The request object owns stable request-head bytes, so later mutation or reuse of the connection input buffer cannot invalidate an application-visible request.

## Public request semantics

The request API intentionally avoids HTTP/1 parser details. Relevant accessors include:

- `method`
- `target`
- `version`
- `header`
- `header_values`
- `header_count`
- `header_name`
- `header_value`

The same application-facing shape can remain useful if later HTTP/2 or HTTP/3 implementations use completely different native wire-protocol state.

Header lookup is ASCII case-insensitive, as required for HTTP field names, but legal field-name characters are not rewritten. For example, `X_Foo` and `X-Foo` remain distinct field names.

## Strict HTTP policy

picohttpparser can report obsolete folded header lines as continuation entries. Linux::Event::HTTP rejects those entries rather than accepting or normalizing `obs-fold`.

The wrapper also imposes an explicit maximum header count. The current hard ceiling is 256, with a default parse limit of 100.

Protocol limits such as maximum request-head bytes and application-facing header limits belong to the Linux::Event HTTP layer rather than to vendored pico source.

## Benchmark

Run after building the distribution:

```sh
perl -Mblib bench/pico-parser.pl
```

The benchmark separates these costs:

- `pico_probe`: pico parsing without constructing parsed Perl structures.
- `pico_offsets`: parsing plus Perl arrays containing offsets and lengths.
- `native_state`: parsing plus the native `Request` representation.
- `native_common_access`: native request creation plus materializing method, target, and one common header.
- `pico_materialize_all`: offset parsing plus materializing method, target, every header name, and every header value as Perl strings.

A GitHub Actions Ubuntu runner using Perl 5.44 and `-O2` produced these representative rates after packing native request state into one allocation:

| headers | pico_probe | native_state | native_common_access | pico_materialize_all |
| ---: | ---: | ---: | ---: | ---: |
| 4 | 4.25M/s | 1.38M/s | 882k/s | 468k/s |
| 16 | 2.36M/s | 1.07M/s | 728k/s | 161k/s |
| 64 | 874k/s | 571k/s | 459k/s | 45.5k/s |

These are microbenchmark results, not server throughput claims. Their purpose is to compare representation costs on the same runner.

The result supports the design: keeping untouched fields native preserves substantially more of pico's parsing performance than eagerly materializing the entire request head into Perl structures.
