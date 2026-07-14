# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/), and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [3.00] - 2026-07-14

### Added

- XXH3-64 and XXH3-128 single-shot hashing functions (#7)
- Digest-style OO streaming interface for XXH32, XXH64, XXH3-64, and XXH3-128 (#6)
- `xxh3_generate_secret` function for custom secret-based XXH3 hashing
- Secret-based hashing via the OO interface (`secret` parameter)

### Changed

- Updated bundled xxHash submodule from v0.6.0 to v0.8.3 (#5)
- `Math::Int64` is now recommended and not required on 64-bit Perl

### Fixed

- Skip redundant per-call `Math::Int64` load on 64-bit perls (#8)

## [2.04] - 2019-09-05

### Fixed

- Mishandling unsigned 64-bit integers when moving from XS to pure Perl
- Prepend zeros to hex values

## [2.03] - 2016-06-13

### Fixed

- Permissions could cause repeat builds to fail in v2.02

## [2.02] - 2016-06-10

### Changed

- Updated bundled xxHash library to 860118 (June 2nd, 2016)

## [2.01] - 2015-11-09

### Fixed

- Documentation fix

### Changed

- Full support for 64-bit hashes on 32-bit perls built without int64 (basically just DWIM Perl)

## [2.00] - 2015-11-04

### Added

- Include 64-bit hash functions

### Changed

- Brought bundled xxHash library up to date (as of 44a6297b)
- **Breaking:** `xxhash(...)` renamed to `xxhash32(...)`
- **Breaking:** `xxhash_hex(...)` renamed to `xxhash32_hex(...)`

### Removed

- Object-oriented interface

## [1.02] - 2013-12-24

### Fixed

- Minor POD tweak

## [1.01] - 2013-09-24

### Fixed

- U16 redef errors
- POD fixes

## [1.00] - 2013-09-22

### Added

- Object-oriented interface

## [0.99] - 2013-09-21

### Added

- Initial release

[Unreleased]: https://github.com/sanko/digest-xxhash/compare/3.00...HEAD
[3.00]: https://github.com/sanko/digest-xxhash/compare/2.04...3.00
[2.04]: https://github.com/sanko/digest-xxhash/compare/2.03...2.04
[2.03]: https://github.com/sanko/digest-xxhash/compare/2.02...2.03
[2.02]: https://github.com/sanko/digest-xxhash/compare/2.01...2.02
[2.01]: https://github.com/sanko/digest-xxhash/compare/2.00...2.01
[2.00]: https://github.com/sanko/digest-xxhash/compare/1.02...2.00
[1.02]: https://github.com/sanko/digest-xxhash/compare/1.01...1.02
[1.01]: https://github.com/sanko/digest-xxhash/compare/1.00...1.01
[1.00]: https://github.com/sanko/digest-xxhash/compare/0.99...1.00
[0.99]: https://github.com/sanko/digest-xxhash/releases/tag/0.99
