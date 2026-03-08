# Change Log

## [2.0.0 - 2026-03-06]

### Added

- People can now have two parents. The module correctly finds the most recent
  common ancestor through either parent's line, taking the shortest path.

### Changed

- The module now uses `Feature::Compat::Class` to provide better compatibility
  across different Perl versions while retaining the modern `class` syntax

### Tests

- Added descriptive labels to all tests in `t/03-cousins.t`

## [1.0.2 - 2025-07-07]

- Added: use v5.38

## [1.0.1 - 2025-07-07]

### Changed

- Removed :reader from the test person classes

## [1.0.0 - 2025-07-03]

### Changed

- Switched to using 'perlclass' instead of Moo
- Use (and document) the field name attributes

## [0.2.0 - 2023-05-24]

### Fixed

- Pod error
- IDs no longer need to be numbers

### Added

- Added `get_relationship_ancestors()` method
- Added `abbr` attribute

## [0.1.2] - 2023-05-23

### Fixed

- Fixed the previous fix

## [0.1.1] - 2023-05-23

### Fixed

- Missing pre-req module (CI is great - but you have to actually use it!)

## [0.1.0] - 2023-05-23

### Added

- We now support arbitrarily distant relationships (by synthesising descriptions)

## [0.0.5] - 2021-01-12

### Added

- Added bugtracker info to metadata

## [0.0.4] - 2020-11-09

### Fixed

- Better tests

- Fixed doc typos

- More consistent indentation

- Thanks to Paul Cochrane for all of the above

## [0.0.3] - 2020-01-10

### Fixed

- Fixed the previous fix

## [0.0.2] - 2020-01-10

### Added

- Added another row and column to the relationship table

## [0.0.1] - 2018-03-31

### Added

- All the things. Release early, release often.
