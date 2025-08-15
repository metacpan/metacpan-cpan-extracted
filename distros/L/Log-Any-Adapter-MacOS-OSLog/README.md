# Log-Any-Adapter-MacOS-OSLog

Log to macOS' unified logging system from Perl.

This adapter bridges [Log::Any][] to
[Apple's structured logging API][Unified Logging] via FFI (foreign
function interface) and a C wrapper.
It supports all standard log levels and lets you choose between public
and private visibility for each message.

It also comes with a simple command line script, `maclog`.

## Why?

macOS uses a modern, structured logging system that’s not directly
accessible from Perl. This module provides a native-feeling solution
without requiring Swift or Objective-C code.

## System requirements

### Runtime

*   macOS Sierra 10.12 or higher
*   Perl v5.18 or higher
*   various Perl modules that will be installed automatically should you
    use a utility like `cpan` or `cpanm`

### Additional building requirements

*   Xcode from the Mac App Store
*   Xcode command line tools, installable via:

    ```shell
    xcode-select --install
    ```

## Installation

```shell
perl Makefile.PL
make
make test
make install
```

## Example usage

```perl
use Log::Any::Adapter ('MacOS::OSLog', subsystem => 'com.example.perl');
use Log::Any qw($log);

$log->info("Hello from Perl!");
```

For more information, consult the full module documentation by running:

```shell
perldoc Log::Any::Adapter::MacOS::OSLog
```

## Status

This is a work in progress. It's currently tested on macOS Sequoia 15.6
and aims to stay compatible with future releases. Feedback and
contributions welcome!

## Learn More

For background, design rationale, and implementation details, see the
full [blog post](https://phoenixtrap.com/2025/08/10/perl-macos-oslog).

## License

See the enclosed LICENSE file.

[Log::Any]:        <https://metacpan.org/pod/Log::Any>
[Unified Logging]: <https://developer.apple.com/documentation/os/logging>
