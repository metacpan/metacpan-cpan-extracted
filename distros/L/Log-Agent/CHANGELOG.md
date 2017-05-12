# Change Log

## [1.001] - 2015-11-29
### Added
- Added .gitignore.

### Changed
- Moved change log to Markdown format.  CHANGELOG.md replaces changes.pod.

### Fixed
- Corrected POD typos. (Florian Schlich)
- Escaped literal left braces in tests. (Petr Pisar)

## [1.000] - 2013-08-13
### Changed
- Switched to standard X.YYYZZZ versioning.
- Replaced ChangeLog with changes.pod.
- Updated 'clean' arguments in Makefile.PL.
- Updated Agent.pm and replaced old README.

## [0.308] - 2013-08-10
### Changed
- Changed license to the Artistic License 2.0.
- Replaced META.yml with META.json.

### Fixed
- Fixed tests for Carp behavior and file permissions.

## [0.307] - 2005-10-02
### Fixed
- Replaced a non-localized modification $^W with "no warnings" so warnings are no disabled globally. (Andreas Vierengel)
- Fixed formatting behavior for strings that contain "%%" without any other formating characters. (David Coppit)
- Fixed a minor undef warning in a major kludge in the Agent::Driver code.

## [0.306] - 2004-02-02
### Fixed
- Stripped line endings in common tests to allow tests to succeed under non-UN*X environments.
- Replaced an unnecessary handle alias with the actual file name in t/file.t. (Jay Lawrence and Terrence Brannon)

## [0.305] - 2003-09-27
### Added
- Added a wrapper for &AutoLoader::AUTOLOAD to save the value of $!, which is often clobbered before the substitution of "%m" by logxxx().
- Added a META.yml file and disabled autogeneration in Makefile.PL.

## [0.304] - 2003-03-08
### Added
- Added support for embedded newlines in messages passed to logcarp() and logxcarp().

### Fixed
- Made the logxxx() calls transparent to all (current) sprintf() formatting patterns. Not all formatting errors will be caught before passed to sprintf(), but the obviously malformed ones will be detected.

## [0.303] - 2002-09-30
### Removed
- Removed the problematic t/mail.t test. The test fails due to problems with redirecting the output of Mail::Mailer in test mode.

## [0.302] - 2002-08-01
### Fixed
- Expanded &Carp::shortmess workaround in Log::Agent::Driver to handle behavior under Perl 5.8.0.

## [0.301_002] - 2002-05-12
### Added
- Added prechecks for sprintf() arguments in Log::Agent::Formatting.
- Added argument for Mail::Mailer options in Log::Agent::Driver::Mail->make().

## [0.301_001] - 2002-04-25
### Added
- Added trial Log::Agent::Driver::Mail for sending log messages via email.

### Changed
- Minor changes to version control.

## [0.301] - 2002-03-18
### Removed
- Removed paranoid argument test from Log::Agent::Driver::Fork::make(), now relying on later failure for invalid argument. Only testing with ref() now.

## 0.300 - 2002-02-23
### Added
- Added Log::Agent::Driver::Fork to allow logconfig() to accept multiple drivers at once.
- Added file permission arguments to Log::Agent::Driver::File and Log::Agent::Channel::File.

### Changed
- Development and maintenance handed over to [Mark Rogaski](mrogaski@cpan.org).

### Fixed
- Corrected "uninitialized value" in Log::Agent::Tag::Caller caused by undefined $subroutine.

## 0.208 - 2001-04-11
### Added
- Added hyperlinks within POD to ease web browsing of manpage.

### Changed
- Routines from Log::Agent::Priorities are now auto-loaded.
- Normalize priority string ("err" -> "error") when logging it, Indeed, Log::Agent::Logger uses those routines but makes strict use of syslog priority names.

## 2001-03-31
### Changed
- Massive renaming Devel::Datum -> Carp::Datum.

### Fixed
- Fixed =over to add explicit indent level, for POD checkers.
- Fixed off-by-one error in prio_from_level(), which caused improper conversion for level 10.

## 2001-03-15
### Changed.
- Updated version number.

## 2001-03-13
### Fixed
- Forgot to handle -prefix in Log::Agent::Channel::Syslog.
- Was wrongly issuing test headers twice when skipping the t/tag_callback.t tests.

## 2001-03-13
### Fixed
- Fixed typo in -priority documentation.

### Removed
- Manual page for Log::Agent::Tag::Priority was irrelevant.

## 2001-03-13
### Added
- Added the -priority and -tags options to logconfig() for including priority string in messages, as well as user-defined tag strings.

### Fixed
- Test the ${line} variable substitution in caller formatting.
- Fixed bug for *BSD systems, which caused the test suite to fail.

### Changed
- Class Log::Agent::Caller disappered, and is now replaced by Log::Agent::Tag::Caller.

## 0.201 - 2000-11-12
### Fixed
- Minor typo fixes.

## 0.200 - 2000-11-06
### Changed
- Modularized the logging channels. They have now their own hierarchy under Log::Agent::Channel.
- Modularized priority, prefixing and timestamping routines, so that they can be re-used by satellite Log::Agent modules.
- Logging from Log::Agent is now subject to pruning depending on the logging level set. By default, it is "notice", so that even logsay() is visible.

## 0.108 - 2000-10-01
### Added
- Added support for Devel::Datum. This module is still under development, but is already used in production system.
- New logcarp, logxcarp and logxcroak interface.

### Fixed
- Fixed carpmess to work around Carp's incorrect offseting and added a test suite for logcarp and logxcarp.

## 0.107 - 2000-07-04
### Fixed
- Forgot to increase version number at last patch.

## 0.106 - 2000-07-04
### Fixed
- Was missing default init check before calling logwrite(), resulting in a call on an undefined referenced in logtrc() and logdbg() when no explicit configuration was otherwise made.

## 0.105 - 2000-06-20
### Added
- Added logcroak(), to die from the perspective of the caller.
- New logwrite() routine for upper-level apps, which unconditionally logs messages to a specified channel.

### Fixed
- Fixed arg processing to avoid dying on 2nd calls to logconfig().
- Fixed typos in debug init and man page.

### Removed
- Removed logtrc() and logdbg() from the driver interface: they are now frozen in Log::Agent, and implemented in terms of logwrite(), which may be redefined as suited.

## 0.104 - 2000-03-30
### Fixed
- Forgot that /(?<\!)/ is a 5.005 feature, fixed Agent/Caller.pm.

## 0.103 - 2000-03-05
### Added
- Added missing 1 for require and fixed typo in pod for Log::Agent::Caller as was reported by many people.
- All .pm files now have an \_\_END__ marker before the pod section anyway, so that the Perl parser stops.
- Added support for logfile rotation via Log::Agent::Rotate.

### Removed
- No longer uses IO::Handle but relies on the new Log::Agent::File hierarch, to support logfile rotation. Native Perl files are now handled via Log::Agent::File::Native.
- Suppressed blurb about the Linux bug since we workaround it by creating a new separate default_exp.t test.

## 0.102 - 1999-12-09
### Fixed
- Wrote two versions of format_args and eval proper one. Indeed, perl-5.005 versions do not support /(?<\!)/ and this is parsed at compile time, hence we need to protect the expression within an eval.

## 0.101 - 1999-12-08
### Fixed
- Forgot that /(?<\!)/ is a 5.005 feature, fixed Agent.pm.
- Mentions that perl 5.005 fails tests on Linux due to a perl or glibc bug. It's only the test code that fails though.

## 0.100
Initial revision.

[1.001]: https://github.com/mrogaski/Log-Agent/compare/v1.000...v1.001
[1.000]: https://github.com/mrogaski/Log-Agent/compare/v0.308...v1.000
[0.308]: https://github.com/mrogaski/Log-Agent/compare/rel_0_3_7...v0.308
[0.307]: https://github.com/mrogaski/Log-Agent/compare/rel_0_3_6...rel_0_3_7
[0.306]: https://github.com/mrogaski/Log-Agent/compare/rel_0_3_5...rel_0_3_6
[0.305]: https://github.com/mrogaski/Log-Agent/compare/rel_0_3_4...rel_0_3_5
[0.304]: https://github.com/mrogaski/Log-Agent/compare/rel_0_3_3...rel_0_3_4
[0.303]: https://github.com/mrogaski/Log-Agent/compare/rel0_3_2...rel_0_3_3
[0.302]: https://github.com/mrogaski/Log-Agent/compare/rel0_3_1_p2...rel0_3_2
[0.301_002]: https://github.com/mrogaski/Log-Agent/compare/rel0_3_1_p1...rel0_3_1_p2
[0.301_001]: https://github.com/mrogaski/Log-Agent/compare/rel0_3_1...rel0_3_1_p1
[0.301]: https://github.com/mrogaski/Log-Agent/compare/rel0_3_0...rel0_3_1
