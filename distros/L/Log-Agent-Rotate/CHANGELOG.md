# Change Log

## [1.201] - 2021-04-11
### Changed
- Added Github Actions as a CI/CD pipeline.

## [1.200] - 2015-12-01
### Changed
- Converted build script to Module::Build.
- Refactored to use the constant pragma.

### Fixed
- Metadata files will now be generated dynamically.

## [1.001] - 2015-11-30
### Changed
- Moved change log from changes.pod to CHANGELOG.md.

### Fixed
- Removed dependency on Log::Agent in Makefile.PL.

## [1.000]  - 2013-08-12
### Added
- Added BUILD_REQUIRES dependencies.

### Changed
- Switched to standard X.YYYZZZ versioning. Usage with previous versions will work as expected, but the documentation will be much clearer.
- Replace META.yml with META.json.

### Fixed
- Fixed several tests for Win32 platforms.

## [0.104] - 2002-05-14
### Added
- Allow restriction of file permissions with -file_perm argument to Log::Agent::Rotate->make().

### Changed
- Development and maintenance handed over to [Mark Rogaski](mailto:mrogaski@cpan.org).

## 0.103 - 2001-04-11
### Added
- Mark rotation in the logfile before rotating it, so that any pending "tail -f" gets to know about it. Added a regression test for it.

### Changed
- Now depends on Getargs::Long for argument parsing.

## 0.102 - 2000-11-12
### Changed
- Changed pre-req on Log::Agent: must now use 0.2.1.
- Changed DLSI description to match CPAN's.
- New -single\_host parameter is used to optimize LockFile::Simple:. We don't supply -nfs when -single_host is true, for faster locking procedure.

### Fixed
- Untaint data read or rename() complains under -T.

## 0.101 - 2000-11-06
### Added
- Added is_same() to compare rotation policies.
- Added build_pm_hash() to compute PM value from MANIFEST.

### Changed
- Moved to an array representation for the config object.
- Updated t/badconf.t to new detection logic within Log::Agent.

### Removed
- Removed reference to driver and the ability to specify -max_time in other units than seconds (e.g. "2d").

## 0.100 - 2000-05-05
Initial revision.

[1.201]: https://github.com/mrogaski/Log-Agent-Rotate/compare/v1.200...v1.201
[1.200]: https://github.com/mrogaski/Log-Agent-Rotate/compare/v1.001...v1.200
[1.001]: https://github.com/mrogaski/Log-Agent-Rotate/compare/v1.000...v1.001
[1.000]: https://github.com/mrogaski/Log-Agent-Rotate/compare/rel0_1_4...v1.000
[0.104]: https://github.com/mrogaski/Log-Agent-Rotate/compare/rel0_1_3...rel0_1_4
