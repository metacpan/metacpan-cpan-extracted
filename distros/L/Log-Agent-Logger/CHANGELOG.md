# Change Log

## [0.200] - 2015-12-01
### Added
- Added CPAN metadata files.

### Changed
- Converted build to Module::Build.
- Converted change log to Markdown.

### Fixed
- Removed Log::Agent dependency in Makefile.PL.

## 0.101 - 2001-04-11
### Added
- New `-caller` argument to customize caller tracing, with the ability to dynamically change settings via `set_caller_info()`.
- New `-priority` argument to customize priority tracing, with the ability to dynamically change settings via `set_priority_info()`.
- New `-tags` argument to add user-defined tags in the logs.
- Must use Log::Agent 0.208 or better, since we rely on a specific feature for priority tracing.
- Now tests proper sprintf semantics in log arguments, i.e. that something like `$log->error("this is message #%d", 5)`	works as advertised.

### Changed
- Now relies on Getargs::Long for argument parsing.

## 0.100 - 2000-11-03
Initial revision.

[0.200]: https://github.com/mrogaski/Log-Agent-Logger/compare/v0.101...v0.200
