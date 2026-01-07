# Changelog for Dev::Util

All notable changes to this project will be documented in this file.

## [version/v2.19.35] - 2026-01-03

### ⚙️ Miscellaneous Tasks

- *(version)* Bump version patch level

### 🧪 Testing

- *(os)* Skip tests that fail under specific OS types

### 🎨 Styling

- *(tidy)* Tidy code

## [release/2025/12/27/1155] - 2025-12-27

### 📚 Documentation

- *(changelog)* Update changelog

## [version/v2.19.33] - 2025-12-27

### 🐛 Bug Fixes

- *(version)* Reduce required version
- *(yath)* Export AUTHOR_TESTING

### ⚙️ Miscellaneous Tasks

- *(version)* Bump version patch level

### 🚜 Refactor

- *(modules)* Convert to Path::Tiny from depreciated FindBin
- *(strict)* Relax StrictWarnings

## [release/2025/12/12/1611] - 2025-12-12

### 📚 Documentation

- *(changelog)* Update changelog

## [version/v2.19.29] - 2025-12-12

### ⚙️ Miscellaneous Tasks

- *(version)* Bump version patch level

### 🚧 Build

- *(makefile)* Update required module versions

## [version/v2.19.28] - 2025-12-12

### ⚙️ Miscellaneous Tasks

- Merge branch 'morext'

* morext:
  build(manifest): Update manifest and signature file
  docs(file): Update documentation
  test(strict): Ensure the use of strict and warnings, or equivalents
  test(tabs): Ensure the use of spaces instead of tabs for indenting
  test(yath): Preload frequently used test modules
  test(versions): Ensure that proper versions
  test(critic): More detailed perlcritic tests for dist
  style(eol): Remove cruft
  test(eol): Ensure proper unix line-endings in all files
  refactor(spell): Augment the spell tests
  test(yath): Run xt/ tests on --author
  docs(pod): Amend note on alternates
  test(critic): Stop using FindBin to specify rc file
  test(yath): Watch examples dir for changes
  test(yath): Remove HARNESS-NO-PRELOAD
- *(version)* Bump version patch level

### 🚜 Refactor

- *(spell)* Augment the spell tests

### 🧪 Testing

- *(file)* Check return values on file ops, skip tests on fail
- *(file)* Add checks for freebsd and openbsd
- *(yath)* Remove HARNESS-NO-PRELOAD
- *(yath)* Watch examples dir for changes
- *(critic)* Stop using FindBin to specify rc file
- *(yath)* Run xt/ tests on --author
- *(eol)* Ensure proper unix line-endings in all files
- *(critic)* More detailed perlcritic tests for dist
- *(versions)* Ensure that proper versions
- *(yath)* Preload frequently used test modules
- *(tabs)* Ensure the use of spaces instead of tabs for indenting
- *(strict)* Ensure the use of strict and warnings, or equivalents

### 📚 Documentation

- *(pod)* Amend note on alternates
- *(file)* Update documentation

### 🎨 Styling

- *(eol)* Remove cruft

### 🚧 Build

- *(manifest)* Update manifest and signature file

## [release/2025/11/25/1032] - 2025-11-25

### 📚 Documentation

- *(changelog)* Update changelog

## [version/v2.19.12] - 2025-11-25

### ⚙️ Miscellaneous Tasks

- *(version)* Bump version patch level

### 🧪 Testing

- *(file)* Change status_for test to avoid timezone issues
- *(file)* Refactor to give each suid,guid,sticky test its own variable

### 📚 Documentation

- *(pod)* Provide links to sub-modules
- *(pod)* Add links to sub-modules. Pod clean-up

### 🚧 Build

- *(manifest)* Skip test.pl so installers wont need yath or prove

## [release/2025/11/20/1858] - 2025-11-20

### 📚 Documentation

- *(changelog)* Update changelog

## [version/v2.19.11] - 2025-11-20

### 🐛 Bug Fixes

- *(query)* Make yes_no_prompt return 1 or 0 as the API specifies

### ⚙️ Miscellaneous Tasks

- *(version)* Bump version patch level

## [release/2025/11/20/1836] - 2025-11-20

### 📚 Documentation

- *(changelog)* Update changelog

## [version/v2.19.10] - 2025-11-20

### 🐛 Bug Fixes

- *(query)* Return value of response, not IO::Prompt::ReturnVal
- *(banner)* Explicitly specify Term::ReadKey::GetTerminalSize()

### ⚙️ Miscellaneous Tasks

- *(version)* Bump version patch level

### 🎨 Styling

- *(spelling)* Fix typo, add to dictionary

## [release/2025/11/20/1406] - 2025-11-20

### 📚 Documentation

- *(changelog)* Update changelog

## [version/v2.19.8] - 2025-11-20

### ⚙️ Miscellaneous Tasks

- *(version)* Bump version patch level

### 🚜 Refactor

- *(manifest)* Cleanup manifest skip file

### 📚 Documentation

- *(pod)* Improve sub-module descritions in Util.pm for CPAN

## [release/2025/11/19/0732] - 2025-11-19

### 📚 Documentation

- *(changelog)* Update changelog

## [version/v2.19.7] - 2025-11-19

### 🐛 Bug Fixes

- *(makefile)* List::Util needs at least version 1.66 for uniq export

### ⚙️ Miscellaneous Tasks

- *(version)* Bump version patch level

## [release/2025/11/18/1744] - 2025-11-18

### 📚 Documentation

- *(changelog)* Update changelog

## [version/v2.19.6] - 2025-11-18

### 🚀 Features

- *(os)* Add fn is_freebsd, and associated tests
- *(os)* Add distro version hashes, is_openbsd sub
- *(os)* Add functions is_freebsd and is_openbsd, with tests, docs

### 🐛 Bug Fixes

- Check for existence of files before deleting
- *(file)* Skip tests if setting setuid/setgid/sticky on test file fails
- *(file)* Skip test (not skip_all) if block/char files is not avail

### ⚙️ Miscellaneous Tasks

- *(version)* Bump version minor level

### 🚜 Refactor

- *(test)* Remove the dependence on yath
- *(tests)* Utilize Test2::Require::Module to ensure test modules are available

### 🧪 Testing

- *(boilerplate)* Add Dev::Util::Sem

## [release/2025/11/15/1336] - 2025-11-15

### 📚 Documentation

- *(changelog)* Update changelog

## [version/v2.18.35] - 2025-11-15

### 🐛 Bug Fixes

- *(test)* Remove the plan because number of tests is variable.
- *(mode)* Change file permissions to allow access to test file
- *(timezone)* Set timezone so all testers use the same one

### ⚙️ Miscellaneous Tasks

- *(version)* Bump version patch level

### 🚜 Refactor

- *(use)* Standarize module loading, remove use lib 'lib'

## [release/2025/11/15/0912] - 2025-11-15

### 📚 Documentation

- *(changelog)* Update changelog

## [version/v2.18.31] - 2025-11-15

### ⚙️ Miscellaneous Tasks

- *(version)* Bump version patch level

### 🚜 Refactor

- *(use)* Standarize module loading, remove use lib 'lib'
- *(yath)* Add option to not use concurrency (--single)

### 🧪 Testing

- *(yath)* Update test configuration and options

### 🚧 Build

- *(git)* Ignore yath temp file lastlog.jsonl

## [release/2025/11/14/0931] - 2025-11-14

### 📚 Documentation

- *(changelog)* Update changelog

## [version/v2.18.26] - 2025-11-14

### ⚙️ Miscellaneous Tasks

- *(version)* Bump version patch level

### 🧪 Testing

- Remove Data::{Dumper,Printer}. Set plan

### 📚 Documentation

- *(pod)* Clarify documentation
- Documentation improvements
- *(readme)* Use Dev::Util::Syntax automatically adds use strict and use warnings

## [release/20251114] - 2025-11-14

### 📚 Documentation

- *(changelog)* Update changelog

### 🚧 Build

- *(manifest)* Update manifest and signature file

### Other

- *(other)* Merge branch 'sem' - Create Sem module

* sem:
  build(manifest): Update manifest and signature file
  docs(changelog): Update changelog
  chore(version): Update version minor level
  docs(pod): Expand the pod documentation
  chore(example): Create simple example of semaphore locking
  fix(diagnostics): Remove diagnostics code used in development
  test(remove): Delete block testing second semaphore wait
  feat(semaphor): Create Sem file locking module and tests
  build(critic): Add _get_locks_dir to ProtectPrivateSubs
  docs(links): Remove links to defunct websites: AnnoCPAN and CPAN Ratings
  docs(contibuting): Document coding style for contributions
  docs(contributing): Create a policy for contibutions to this project
  fix(links): Remove links to defunct websites: AnnoCPAN and CPAN Ratings
  chore(security): Add security policy tool. Create security policy.
  build(support): Create support dir for development tools
  build(makefile): Add IO::Prompt, App::Yath to PREREQ_PM and TEST_REQUIRES respectively
  build(makefile): Add new tests in XT_TEST_REQUIRES
  docs(readme): Add pod description for Dev::Util::Sem
  test: Add xt tests for utf-8 and file name portability
  test(pod): Rename pod.t to pod-syntax.t

## [version/v2.18.19] - 2025-11-14

### 🚀 Features

- *(semaphor)* Create Sem file locking module and tests

### 🐛 Bug Fixes

- *(links)* Remove links to defunct websites: AnnoCPAN and CPAN Ratings
- *(diagnostics)* Remove diagnostics code used in development

### ⚙️ Miscellaneous Tasks

- *(security)* Add security policy tool. Create security policy.
- *(example)* Create simple example of semaphore locking
- *(version)* Update version minor level

### 🧪 Testing

- *(author)* Convert to Author test perl{tidy,critic}
- *(pod)* Rename pod.t to pod-syntax.t
- Add xt tests for utf-8 and file name portability
- *(remove)* Delete block testing second semaphore wait

### 📚 Documentation

- *(readme)* Add pod description for Dev::Util::Sem
- *(contributing)* Create a policy for contibutions to this project
- *(contibuting)* Document coding style for contributions
- *(links)* Remove links to defunct websites: AnnoCPAN and CPAN Ratings
- *(pod)* Expand the pod documentation

### 🚧 Build

- *(makefile)* Add new tests in XT_TEST_REQUIRES
- *(makefile)* Add IO::Prompt, App::Yath to PREREQ_PM and TEST_REQUIRES respectively
- *(support)* Create support dir for development tools
- *(critic)* Add _get_locks_dir to ProtectPrivateSubs

## [release/20251111] - 2025-11-11

### 📚 Documentation

- *(changelog)* Update changelog

## [version/v2.17.17] - 2025-11-11

### ⚙️ Miscellaneous Tasks

- *(version)* Update version to v2.17.17

### 🚜 Refactor

- *(use)* Clean up use statements
- *(use)* Clean up use statements
- *(use)* Remove un-needed modules
- *(makefile)* Add METE_MERGE info. Update PREREQ_PM & TEST_REQUIRES

### 🧪 Testing

- *(spell)* Add to spelling whitelist
- *(boilerplate)* Fix typo for README.md

### 📚 Documentation

- *(pod)* Add function descriptions
- *(readme)* Convert README to Markdown
- *(readme)* Customize README.md for this module and sub-modules
- *(pod)* Updated and corrected pod documentation for modules

### 🎨 Styling

- *(typo)* Fix spelling mistake

### 🚧 Build

- *(makefile)* Update Prereq_pm with needed modules

## [version/v2.17.4] - 2025-11-10

### 🚀 Features

- *(mk_temp_file)* Autoflush temp file, don't unlink it

### ⚙️ Miscellaneous Tasks

- *(version)* Update version to v2.17.4

### 🚜 Refactor

- *(ipc_run)* [**breaking**] Rename functions ipc_run_{l,s} to ipc_run_{c,e}
- *(query)* Code clean up

### 🧪 Testing

- *(const)* Fix test diagnostic messages
- *(spelling)* Add spell check for pod documentation
- *(boilerplate)* Update list of submodules
- *(coverage)* Add tests for better conditional coverage
- *(read_list)* Add tests for read_list
- *(query)* Add tests for query module

### 🎨 Styling

- *(test)* Fix typo in test message
- *(spelling)* Fix mis-spelling of ACKNOWLEDGMENTS

### 🚧 Build

- *(docs)* Add make manifest and make signature

## [version/v2.15.4] - 2025-11-07

### ⚙️ Miscellaneous Tasks

- *(version)* Update version minor level

### 🚜 Refactor

- *(file)* [**breaking**] Move functions to File from Utils
- *(os)* [**breaking**] Move functions to OS from Utils
- *(utils)* [**breaking**] Move Utils to Query

### 🧪 Testing

- Test functions in new module
- *(query)* Convert to Query from Utils

### 📚 Documentation

- *(pod)* Update Pod docs
- *(pod)* Update Pod docs

### Other

- *(other)* Merge branch 'query'

* query:
  docs(pod): Update Pod docs
  test(query): Convert to Query from Utils
  refactor(utils)!: Move Utils to Query

## [version/v2.16.4] - 2025-11-06

### 🚀 Features

- *(docs)* Add script to make docs for modules
- *(read_list)* Add read_list function
- *(mk_tmp_dir)* Add ability to specify temp dir

### 🐛 Bug Fixes

- *(pod)* Fix typo in pod
- *(display_menu)* Use prompt from IO::Prompt, not the local one

### ⚙️ Miscellaneous Tasks

- Merge branch 'utils'

* utils: (26 commits)
  fix(display_menu): Use prompt from IO::Prompt, not the local one
  docs(pod): Update Pod docs
  test(valid): Remove tests for deleted function
  refactor(prompt): Modernize code with IO::Prompt, keeping API
  refactor(display_menu): Modernize code, use IO::Prompt
  feat(mk_tmp_dir): Add ability to specify temp dir
  feat(read_list): Add read_list function
  refactor(yes_no_prompt): Rewrite function using IO::Prompt
  refactor: Remove get_keypress and valid functions, and tests
  docs(markdown): Create markdown docs for modules via make_docs.sh
  feat(docs): Add script to make docs for modules
  build(manifest): Exclude scratch dir from manifest
  fix(pod): Fix typo in pod
  test(load): Include Dev::Util::File in load test
  build(git): Update git ignore file
  test(perlcritic): Update perl critic test
  test(xt): Include xt tests when running yath
  docs(install): Add installation documentation
  refactor(test): Modernize Author tests
  refactor(use): Remove un-needed modules
  ...
- *(version)* Update version to v2.12.4

### 🚜 Refactor

- *(utils)* [**breaking**] Move file and dir functions to new module: Dev::Util::File
- *(use)* Remove un-needed modules
- *(test)* Modernize Author tests
- Remove get_keypress and valid functions, and tests
- *(yes_no_prompt)* Rewrite function using IO::Prompt
- *(display_menu)* Modernize code, use IO::Prompt
- *(prompt)* Modernize code with IO::Prompt, keeping API

### 🧪 Testing

- *(xt)* Include xt tests when running yath
- *(perlcritic)* Update perl critic test
- *(load)* Include Dev::Util::File in load test
- *(valid)* Remove tests for deleted function

### 📚 Documentation

- *(constants)* Define the constants
- *(install)* Add installation documentation
- *(markdown)* Create markdown docs for modules via make_docs.sh
- *(pod)* Update Pod docs

### 🚧 Build

- *(git)* Update git ignore file
- *(manifest)* Exclude scratch dir from manifest

## [version/v2.1.6] - 2025-10-29

### ⚙️ Miscellaneous Tasks

- *(merge)* Merge branch 'devutil'
- *(version)* Bump version minor level

### 🚜 Refactor

- *(utils)* [**breaking**] Move names constants to separate module, Dev::Util::Const

### 🧪 Testing

- *(const)* New tests for Const module
- *(module)* Include new Const module in loading tests

### 📚 Documentation

- *(module)* Update manifest

## [version/v2.0.7] - 2025-10-26

### ⚙️ Miscellaneous Tasks

- *(version)* Bump version major level

### 🚜 Refactor

- *(module)* [**breaking**] Begin conversion to Dev::Util from MERM::Base
- *(module)* [**breaking**] Convert Makefile.PL
- *(module)* [**breaking**] Convert cliff toml
- *(module)* [**breaking**] Convert example programs
- *(module)* [**breaking**] Convert lib dir name
- *(module)* [**breaking**] Convert pm modules
- *(module)* [**breaking**] Convert tests

### 🧪 Testing

- *(prereqs)* Update list of required modules

### 📚 Documentation

- *(changelog)* Update changelog

## [version/v1.1.6] - 2025-10-25

### ⚙️ Miscellaneous Tasks

- *(version)* Bump version patch level
- *(merge)* Merge branch 'backup'

### 🚜 Refactor

- Modernize code, use MERM::Base::Backup
- Modernize code, add pod docs

### 🧪 Testing

- *(load)* Include MERM::Base::Backup in load test
- *(backup)* Add tests for directory backup

### 🎨 Styling

- *(tidy)* Clean up code

## [version/v1.1.3] - 2025-10-23

### 🚀 Features

- *(modules)* Add depentant modules for MERM::Base::Backup
- Add MERM::Base::Backup module
- Add bu script

### ⚙️ Miscellaneous Tasks

- *(manifest)* Add SIGNATURE and VERSION
- *(version)* Bump version patch level
- *(version)* Bump version minor level

### 🧪 Testing

- Add tests for MERM::Base::Backup
- *(kwalitee)* Update kwalitee test

### 📚 Documentation

- *(pod)* Add reference to MERM::Base::Backup
- *(manifest)* Add Backup module and test files
- *(pod)* Fix format errors via podchecker
- *(changelog)* Add changelog generated by git cliff
- *(pod)* Update pod documentation for modules

### 🎨 Styling

- *(tidy)* Clean up code. Use /usr/bin/env perl
- *(tidy)* Clean up code

### 🚧 Build

- *(changelog)* Use git cliff
- *(cliff)* Fix error in default cliff.toml

## [version/v1.0.11] - 2024-09-17

### 🚀 Features

- *(syntax)* Add 'use version', bump version to 1.0.10

### 🐛 Bug Fixes

- *(yes_no_prompt)* Initialize value

### 🎨 Styling

- *(Utils)* Perl Tidy

### Other

- *(other)* Add test report-prereqs. Bump version

## [version/v1.0.8] - 2024-06-26

### Other

- *(other)* Update Makefile.PL to include requirements
- *(other)* Update manifest
- *(other)* Remove duplication

## [version/v1.0.6] - 2024-06-21

### Other

- *(other)* Base modules for perl development. Initial Commit.
- *(other)* Sync dev infrastructure with established codebase

MERM::SmartTools
- *(other)* Use base dev infrastructure for testing

Update to MERM::Base
- *(other)* Merge branch 'testing'

* testing:
  Use base dev infrastructure for testing

module-starter
  --module=MERM::Base
  --module=MERM::Base::Syntax
  --module=MERM::Base::Utils
  --builder=ExtUtils::MakeMaker
  --author='Matt Martini'
  --email=matt@imaginarywave.com
  --ignore=git
  --license=gpl3
  --genlicense
  --minperl=5.018
  --verbose
- *(other)* Tidy tests
- *(other)* Sync code with MERM::SmartTools
- *(other)* Add OS module and tests
- *(other)* Update version

<!-- generated by git-cliff -->
