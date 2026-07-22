# Google::gRPC

Generic, high-performance gRPC client transport over HTTP/2 for Perl.

This module provides a low-level, high-performance transport client for performing gRPC calls using HTTP/2, built on top of `Net::Curl` and `Protobuf`.

## Installation

```bash
perl Makefile.PL
make
make test
make install
```

## Dependencies

* `Moo`
* `Net::Curl`
* `Protobuf`
* `Log::Any`

## License

Apache License 2.0
