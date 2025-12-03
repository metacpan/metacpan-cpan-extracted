# Changelog for Disk::SmartTools

All notable changes to this project will be documented in this file.

## [version/v3.3.15] - 2025-12-02

### 🚀 Features

- *(os)* Add support for FreeBSD and OpenBSD

### 🐛 Bug Fixes

- *(use)* Import missing functions via use

### ⚙️ Miscellaneous Tasks

- *(version)* Bump version patch level

### 🧪 Testing

- *(get_raid_cmd)* Check if RAID cmd is defined

### 📚 Documentation

- *(examples)* Note about crontab and perldoc

## [release/2025/11/30/2334] - 2025-12-01

### 📚 Documentation

- *(changelog)* Update changelog

## [version/v3.3.12] - 2025-12-01

### ⚙️ Miscellaneous Tasks

- *(version)* Bump version patch level

### 📚 Documentation

- *(examples)* Add information about example programs

## [release/2025/11/30/1840] - 2025-11-30

### 📚 Documentation

- *(changelog)* Update changelog

## [version/v3.3.11] - 2025-11-30

### ⚙️ Miscellaneous Tasks

- *(version)* Bump version patch level

### 🚜 Refactor

- *(smart)* Make is_drive_smart handle more cases

### 🧪 Testing

- *(softraidtool)* Skip if softraidtool is not available on system
- *(skip)* Use SKIP blocks for tests unsupported by system

## [release/2025/11/29/1711] - 2025-11-29

### 📚 Documentation

- *(changelog)* Update changelog

## [version/v3.3.8] - 2025-11-29

### 🐛 Bug Fixes

- *(rc file)* Return undef if rc file does not exist
- *(rc file)* Make the name of the rc file consistent

### ⚙️ Miscellaneous Tasks

- *(version)* Bump version patch level

### 🚧 Build

- *(modules)* Increase the required version of Dev::Util

## [release/2025/11/29/1607] - 2025-11-29

### 📚 Documentation

- *(readme)* Update readme and contirbuting docs
- *(changelog)* Update changelog

## [version/v3.3.5] - 2025-11-29

### 🚀 Features

- *(config)* Add local configuration fn and tests

### ⚙️ Miscellaneous Tasks

- Merge branch 'devutil'

* devutil: (28 commits)
  build(manifest): Update manifest and signature file
  test(spell): Add to spelling whitelist
  test(disks): Split tests into separate files
  docs(changelog): Update changelog
  chore(version): Update version to v3.2.16
  build(manifest): Update Manifest
  chore(copyright): Update copyright dates
  test: Add tests for is_drive_smart, get_smart_disks, get_physical_disks
  fix(ipc_run): Update function calls
  fix(use): Add Dev::Util::File
  style(example): Fix typo
  style(readme): Better formatting of document
  build(makefile): Update Prereq_pm with needed modules
  docs: Add Contirbution and Security policies, Install instructions
  docs(markdown): Create markdown documentation for module
  build(makefile): Add Dev::Util to PREREQ_PM
  test(xt): Clean up xt tests. Sync with Dev::Util
  build(support): Create support dir for development tools
  build(git): Ignore examples/archive
  chore(clean): Remove old example files
  ...
- *(version)* Bump version minor level

### 🚜 Refactor

- *(test)* Remove the dependence on yath
- *(yath)* Add option to not use concurrency (--single)
- *(config)* Load host local config from rc file

### 🧪 Testing

- *(disks)* Split tests into separate files
- *(spell)* Add to spelling whitelist
- *(compare)* Remove unnecessary Test2::Tools::Compare

### 📚 Documentation

- *(changelog)* Update changelog
- *(pod)* Clean up and update pod documentation
- *(rc file)* Sample configuration file
- *(pod)* Include pod documentation from example programs

### 🚧 Build

- *(manifest)* Update manifest and signature file
- *(examples)* Move Data::Printer configuration to ~/.dataprinter

## [version/v3.2.16] - 2025-11-14

### 🐛 Bug Fixes

- *(use)* Add Dev::Util::File
- *(ipc_run)* Update function calls

### ⚙️ Miscellaneous Tasks

- *(clean)* Remove old example files
- *(copyright)* Update copyright dates
- *(version)* Update version to v3.2.16

### 🚜 Refactor

- *(modules)* [**breaking**] Convert to using Dev::Util
- *(support)* Update support files. Sync with Dev::Utils versions
- Convert to use Dev::Util

### 🧪 Testing

- *(remove)* Remove test that are now handled by Dev::Util
- *(syntax)* Use Dev::Util::Syntax. Sync with Dev::Util versions
- *(xt)* Modernize xt tests, sync with Dev::Util
- *(xt)* Clean up xt tests. Sync with Dev::Util
- Add tests for is_drive_smart, get_smart_disks, get_physical_disks

### 📚 Documentation

- *(tool)* Install make_docs.sh to make md docs
- *(readme)* Update removing references to deleted submodules
- *(markdown)* Create markdown documentation for module
- Add Contirbution and Security policies, Install instructions

### 🎨 Styling

- *(readme)* Better formatting of document
- *(example)* Fix typo

### 🚧 Build

- *(git)* Ignore examples/archive
- *(support)* Create support dir for development tools
- *(makefile)* Add Dev::Util to PREREQ_PM
- *(makefile)* Update Prereq_pm with needed modules
- *(manifest)* Update Manifest

## [version/v2.1.8] - 2025-11-12

### 🐛 Bug Fixes

- *(shebang)* Standardize shebang line
- *(config)* Update host_config
- *(display_menu)* Change to array_ref from array

### ⚙️ Miscellaneous Tasks

- *(version)* Bump version patch level

### 📚 Documentation

- *(code)* Identify type of code snipit

### 🚧 Build

- *(git)* Update git ignore for new module name

### ◀️  Revert

- *(docs)* Rollback change as the code identification doesn't really help

## [version/v2.1.1] - 2025-10-22

### ⚙️ Miscellaneous Tasks

- *(version)* Bump version patch level

### 📚 Documentation

- *(changelog)* Update changelog
- *(readme)* Convert README to Markdown
- *(readme)* Add module documentation

### 🚧 Build

- *(cliff)* Fix error in default cliff.toml

### Other

- *(other)* Merge branch 'disk'

* disk:
  chore(version): Bump version minor level
  refactor(examples)!: Move bin scripts to examples
  chore(version): Bump version major level
  docs(module): Update manifest
  refactor(module): Convert smart_show.pl
  refactor(module)!: Convert pm modules
  refactor(module)!: Convert lib dir name
  refactor(module)!: Convert example programs
  refactor(module)!: Convert cliff toml
  refactor(module)!: Convert tests
  refactor(module)!: Convert Makefile.PL
  refactor(module)!: Begin conversion to Disk::SmartTools from MERM::SmartTools

## [version/v2.1.0] - 2025-10-21

### ⚙️ Miscellaneous Tasks

- *(version)* Bump version minor level

### 🚜 Refactor

- *(examples)* [**breaking**] Move bin scripts to examples

## [version/v2.0.10] - 2025-10-21

### ⚙️ Miscellaneous Tasks

- *(version)* Bump version major level

### 🚜 Refactor

- *(module)* [**breaking**] Begin conversion to Disk::SmartTools from MERM::SmartTools
- *(module)* [**breaking**] Convert Makefile.PL
- *(module)* [**breaking**] Convert tests
- *(module)* [**breaking**] Convert cliff toml
- *(module)* [**breaking**] Convert example programs
- *(module)* [**breaking**] Convert lib dir name
- *(module)* [**breaking**] Convert pm modules
- *(module)* Convert smart_show.pl

### 📚 Documentation

- *(changelog)* Update changelog
- *(module)* Update manifest

## [version/v1.5.3] - 2025-10-21

### 🚀 Features

- *(use)* Add use version
- *(attributes)* Add SMART atributes

### 🐛 Bug Fixes

- *(vars)* Clear var so previous instance will not interfere

### ⚙️ Miscellaneous Tasks

- *(copyright)* Update copyright year
- *(copyright)* Update the copyright year
- *(version)* Bump version patch level

### 🚜 Refactor

- *(use)* Remove use version, now included in MERM::SmartTools::Syntax

### 📚 Documentation

- *(changelog)* Add changelog generated by git cliff
- *(perldocs)* Refactor pod documentation

### 🚧 Build

- *(signature)* Update signature file

## [version/v1.5.2] - 2025-10-16

### ⚙️ Miscellaneous Tasks

- *(manifest)* Add SIGNATURE
- *(version)* Bump version patch level

### 📚 Documentation

- *(pod)* Add pod to bin files
- *(changelog)* Add changelog generated by git cliff

### 🚧 Build

- *(manifest)* Add scratch files to manifest.skip
- *(manifest)* Update manifest and signature

## [version/v1.5.1] - 2025-10-16

### 🚧 Build

- *(version)* Remake manifest and signature files. Bump patch version.

## [version/v1.5.0] - 2025-10-16

### 🚀 Features

- *(exe)* Move scripts to bin for deployment at install

### ⚙️ Miscellaneous Tasks

- *(version)* Bump version minor level

### 🎨 Styling

- *(tidy)* Clean up code

### 🚧 Build

- *(version)* Add version file
- *(signature)* Signatures for all files in Manifest

## [version/v1.4.4] - 2025-07-05

### 🐛 Bug Fixes

- *(sleeptime)* Increase wait time for long test

### ⚙️ Miscellaneous Tasks

- Add Spacing
- *(version)* Bump version patch level

### 🧪 Testing

- *(kwalitee)* Update kwalitee test

### 📚 Documentation

- *(pod)* Fix format errors via podchecker
- *(pod)* Complete pod coverage of functions

### 🎨 Styling

- *(copyright)* Change the copyright symbol to a single-width char
- *(tidy)* Clean up code formatting

### 🧮 Ops

- *(sd?)* Update dev sd disks

### Other

- *(other)* Fix version
- *(other)* Fix uninitialized value
- *(other)* Add test report-prereqs. Bump version
- *(other)* Update ladros disks
- *(other)* Increase long test wait time
- *(other)* Show first two lines of test history

## [version/v1.4.1] - 2024-06-26

### Other

- *(other)* Only output on actual testing
- *(other)* Update Makefile.PL to include requirements

## [version/v1.4.0] - 2024-06-25

### Other

- *(other)* Update manifest.skip
- *(other)* Remove .yath.rc from manifest
- *(other)* Tweek manifest.skip
- *(other)* Don't include .gitkeep files
- *(other)* Add return for _define_named_constants
- *(other)* Process args, add usage
- *(other)* Diferentiate long tests

for long test skip all disks but the one that matches today's day
- *(other)* Increment version number
- *(other)* Fix dry run
- *(other)* Only perform long tests on the 'correct' day
- *(other)* Update version to v1.4.0

## [release/v1.3.2] - 2024-06-20

### ⚙️ Miscellaneous Tasks

- Explicitly use Test::Perl::Critic::all_critic_ok

### 🧪 Testing

- Testing output of routines

### Other

- *(other)* :SmartTools initial commit
- *(other)* Ignore backup manifest
- *(other)* Add Template Definition
- *(other)* Fix formating
- *(other)* Update MANIFEST
- *(other)* Test module availibility
- *(other)* Add Test::Kwalitee
- *(other)* Test if use feature :5.18 loaded.
- *(other)* Reformat diagnostics
- *(other)* Modernize Kwalitee tests
- *(other)* Fix syntax of use feature
- *(other)* Import utils from MERM::LogArchive
- *(other)* Tidy files
- *(other)* Tests files are tidy
- *(other)* Test if files pass perlcritic
- *(other)* Test Utils module
- *(other)* Revert to simpler functions
- *(other)* Convert to Test2::V0
- *(other)* Convert to IO::Interactive::is_interactive() and EXPORT_OK.
- *(other)* Add banner test
- *(other)* Convert to EXPORT_TAGS
- *(other)* Move Release Tests to xt
- *(other)* Fix need both EXPORT_OK and EXPORT_TAGS
- *(other)* Complete test coverage for Utils
- *(other)* Test via yath and prove
- *(other)* Watch files and run yath
- *(other)* Fix error of wrong module loaded
- *(other)* Add functions display_menu, get_keypress
- *(other)* Yath config. Preload modules
- *(other)* Unpack @_. Use carp instead of warn.
- *(other)* OS module instansiation
- *(other)* Ignore yath temp files
- *(other)* Use carp and croak
- *(other)* Don't log yath runs
- *(other)* OS tests instansiation
- *(other)* Add examples to Synopsis
- *(other)* Implemented OS functions and tests
- *(other)* Don't load Utils (temp)
- *(other)* Add file tests
- *(other)* Add tests for file tests
- *(other)* Implement tests for utils
- *(other)* Refactor and clean code
- *(other)* Generate test coverage report
- *(other)* Utility functions and tests completed
- *(other)* Ignore cover_db in manifest
- *(other)* Don't test for 'use strict' as this is in Syntax
- *(other)* Update manifest
- *(other)* Update pod docs
- *(other)* Ignore temp test files in manifest
- *(other)* Alternate manifest check
- *(other)* Update need modules list
- *(other)* Fix test plan
- *(other)* Pre-Load competed modules
- *(other)* Tests for Disks module
- *(other)* Pass verbose flag
- *(other)* Chomp uname output
- *(other)* Fixed plan and clean up code
- *(other)* Implement disk_prefix & os_disks fns
- *(other)* Perl tidy code
- *(other)* Functions to get cmd paths
- *(other)* Fix linux issues
- *(other)* Further linux fixes
- *(other)* ProhibitExcessMainComplexity increased
- *(other)* Updated expected date
- *(other)* Skip .DS_Store
- *(other)* Update Manifest
- *(other)* Copyright symbol, utf-8 pod encoding
- *(other)* Refactor the test case for stat_date
- *(other)* Sync with ~/.perlcriticrc and Update
- *(other)* Apply new perltidy rules
- *(other)* Add default else clause
- *(other)* Improve test comments
- *(other)* Move POD docs to end of files
- *(other)* Ignore coverage report temp file
- *(other)* Example apps
- *(other)* Tidy code
- *(other)* Ignore coverage temp file
- *(other)* Define named constants
- *(other)* Don't carp on path not found
- *(other)* RAID implementation notes
- *(other)* Scratch get_options and get_raid_flag
- *(other)* Refactored to use SmartTools::Disk et al.
- *(other)* Add get_raid_flag, rename to get_disk_prefix from disk_prefix
- *(other)* Test doesn't work for megaraid
- *(other)* Add get_physical_disks get_smart_disks is_drive_smart
- *(other)* Testing smart_disks
- *(other)* Use smart_disks
- *(other)* Use scalar
- *(other)* Srtip disk_prefix
- *(other)* Fix regex
- *(other)* Add test for is_drive_smart
- *(other)* Turn off debugging
- *(other)* Rename
- *(other)* Change to 'use version' style VERSION
- *(other)* Replacement for smart_run_test_(short|long).sh
- *(other)* Convert to 'use version' style VERSION
- *(other)* Use version->declare
- *(other)* Update for rdisks
- *(other)* Skip test that fail if user is root
- *(other)* Use warn instead of say for debugging
- *(other)* Rename to try_smart_run.pl
- *(other)* Add timeout to run
- *(other)* Try refactoring IPC Cmd
- *(other)* Try transfer ipc_run{l,s} to Disks.pm
- *(other)* Test ipc_run_l,ipc_run_s
- *(other)* Add ipc_run_lipc_run_s
- *(other)* Move ipc_run_l,ipc_run_s to Utils. Add smart_on_for, smart_test_for, selftest_history_for
- *(other)* Consolodate disk and rdisk call loops
- *(other)* Add smart_cmd_for
- *(other)* Clean up cruft
- *(other)* Consolodate disk and rdisk call loops
- *(other)* Pass debug flag
- *(other)* Archive files
- *(other)* Turn off dry run
- *(other)* Update version to v1.3.2

<!-- generated by git-cliff -->
