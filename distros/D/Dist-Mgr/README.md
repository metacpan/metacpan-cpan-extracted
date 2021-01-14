## distmgr - Manage a Perl distribution

- [Description](#description)
- [Configuration](#configuration)
- [Limitations](#limitations)
- [Usage](#usage)
- [Commands](#commands)
    - [**create** - Create distribution with repository](#create)
    - [**dist** - Create a distribution](#dist)
    - [**release** - Release a distribution](#release)
    - [**cycle** - Prepare next development cycle](#cycle)
    - [**install** - Install individual features](#install)
    - [**config** - Create a default configuration file](#config)
- [Examples](#examples)
- [Command Process Flows](#command-process-flows)
    - [create](#create-process)
    - [dist](#dist-process)
    - [release](#release-process)
    - [cycle](#cycle-process)
    - [install](#install-process)
    
### Description

The `distmgr` command line application that's installed along with the 
`Dist::Mgr` Perl distribution provides the facility to manage Perl distributions
that you're the author of.

It allows you to create distributions (with or without a Github repository),
release your distributions, automatically prepare your distribution's next
development cycle, and install some or all of the features and files that we
provide.

### Configuration

Some command line arguments can be configured in a configuration file. See the
[config command](#config) section for details.

### Limitations

Due to this software being early in its life, we have some limitations currently

- Github is the only Version Control platform that we support
- You must create an empty Github repository through their site prior to VCS
operations being executed
- You must have `git` installed for VCS functionality to be executed
- Github Actions is the only CI platform we support
- Coveralls.io is the only test coverage platform we support
- Github is the only bugtracker platform we support
- `ExtUtils::MakeMaker` is the only build system we support

### Usage

    distmgr <command> [OPTIONS]

### Commands

#### create

This command creates a new distribution with all features enabled. Before using
this command, you must create an empty Github repository through their site
which we'll clone and insert the distribution's files into. We will include:

- A base distribution skeleton, modelled around one created with
`module-starter` from `Module::Starter`
- `bugtracker` and `repository` information
- CI and test coverage badges
- Pre-populated `.gitignore` file
- Pre-populated `MANIFEST.SKIP` file
- Pre-populated Github Actions CI configuration file

##### Options

    -m | --module   Mandatory: The module name (eg. Test::Module)
    -a | --author   Mandatory: The name of the author (eg. "Steve Bertrand")
    -e | --email    Mandatory: The email address of the author
    -u | --user     Optional:  The Github username (eg. stevieb9)
    -r | --repo     Optional:  The Github repository name (eg. test-module)
    -V | --verbose  Optional:  (Flag) Display verbose output for each process
    -h | --help     Optional:  (Flag) Display help

#### dist

This command is similar to [create](#create), but does not include any VCS or CI
'fluff'. It creates a simple distribution skeleton, nothing more.

##### Options

    -m | --module   Mandatory: The module name (eg. Test::Module)
    -a | --author   Mandatory: The name of the author (eg. "Steve Bertrand")
    -e | --email    Mandatory: The email address of the author
    -h | --help     Optional:  (Flag) Display help
    -V | --verbose  Optional:  (Flag) Display verbose output for each process

#### release

This command performs a release of your distribution. The following actions are
performed (Git/CI operations are only executed if you're in a repository 
directory):

- Set the current date in the `Changes` file
- Run a local `make test`
- Commit and Push to Github, and execute remote CI test and coverage
- Create a distribution tarball
- Git tag the state of the repository with the release version
- Push the new tag
- Upload the distribution tarball to the CPAN

##### Options

    -i | --cpanid   Optional:  Your PAUSE userid
    -p | --cpanpw   Optional:  Your PAUSE userid's password
    -d | --dryrun   Optional:  (Flag) Don't actually upload to the CPAN
    -V | --verbose  Optional:  (Flag) Display verbose output for each process
    -w | --wait     Optional:  (Flag) Wait for CI tests to finish (--nowait to disable)
    -h | --help     Optional:  (Flag) Display help

*Note*: The `--cpanid` and `--cpanpw` can be omitted if you set the 
`CPAN_USERNAME` and `CPAN_PASSWORD` environment variables prior to script run.

#### cycle

This command is run after [release](#release), and prepares your distribution/repository
for your next development cycle. We:

- Bump the version (by `0.01`) in the `Changes` file
- Bump the version in all of your distribution's module files
- Perform Git commit and push actions

##### Options

    -h | --help     Optional:  (Flag) Display help

#### install

This command allows you to install the files and features of this software into
an already-existing distribution that you author.

##### Options

All the options listed below are optional.

    -g | --gitignore    Install .gitignore file
    -c | --ci           Install Github Actions CI configuration file
    -B | --badges       Insert CI/Coverage badges links into the module's POD
    -b | --bugtracker   Insert bugtracker information into Makefile.PL
    -R | --repository   Insert repository information into Makefile.PL
    -h | --help         Display help

    -A | --all          Insert/Install all above options

#### config

Creates an initial, default configuration file.

This file will be named `dist-mgr.json` and will be placed in your `HOME`
directory on Unix systems, and in your `USERPROFILE` directory on Windows.

#### Examples

- Create with repository

```
    distmgr create \
            --module Test::Module \
            --author "Steve Bertrand" \
            --email  steveb@cpan.org \
            --repo   test-module \
            --user   stevieb9
```

- Create without repository

```
    distmgr dist \
            -m Test::Module \
            -a "Steve Bertrand" \
            -e steveb@cpan.org
```
            
- Release an existing distribution

```
    distmgr release \
            --cpanid STEVEB
            --cpanpw password
```
            
- Prepare distribution for next development cycle

```
    distmgr cycle
```
   
- Implement `Dist::Mgr` features into an existing distribution    
                                    
```
    distmgr install \
            --gitignore \
            --ci \
            --badges \
            --bugtracker \
            --repository 
            
    # or
    
    distmgr install --all
```

- Create an initial default configuration file

```
    distmgr config
```

### Command Process Flows

#### create process

- Create the distribution skeleton from an empty repository or new directory.
For Github integration, you must create a new empty repository on Github, then
supply its short name with the `--repo` argument along with the `--user`
argument.

- Remove files that we don't deem necessary for the distribution

- Add a custom `Changes` file, formatted to a standard that is understood to
this software

- Add a `MANIFEST.SKIP` file

- Add a custom `t/manifest.t` test file

- Add a custom `.gitignore` file (requires `--user` and `--repo`)

- Add a default Github Actions Continuous Integration configuration file
(requires `--user` and `--repo`)

- Add bugtracker and repository meta information to `Makefile.PL`, which allows
this information to be presented on the CPAN (requires `--user` and `--repo`)

- Perform a `git add .`, then `git commit` and finally `git push` (requires 
`--user` and `--repo`)

#### dist process

- Create a base distribution skeleton within a directory that is representative
of the module name you've sent in. Other than custom `Changes`, `MANIFEST.SKIP`,
`t/manifest.t` files, the skeleton is pretty well exactly like a distribution
created by `module-starter` from the `Module::Starter` distribution

#### release process

- Enable git interaction if A) `git` is installed, B) `--repo` and `--user` are
sent in

- Set the date in the `Changes` file for the current version we're about to
release

- Updates POD Copyright year, if applicable

- Perform a `make manifest` to update the `MANIFEST` file

- Run a `make test` and halt progress if any test fails

- Run a `git commit` and `git push` if anything has changed and git interaction
is enabled

- Present the user for a prompt while we wait for CI testing to complete. You
must manually check your Github Actions progress while we wait. When CI testing
is complete, you press `CNTRL-C` to inform us of success, or `ENTER` to indicate
CI failure. If you signify failure, we'll halt all further processing. Git must
be enabled for these steps.

- Run a `make dist` to generate the distribution tarball that gets sent to the
CPAN

- Upload the new distribution to the CPAN via `Pause::Uploader`. This process
will not take place unless the `--cpanid` and `--cpanpw` are supplied, or the
`CPAN_USERNAME` and `CPAN_PASSWORD` environment variables are populated

- Run a `make distclean` to clean up the distribution directory

- Perform a `git tag` with the version number of this release (requires Git
to be enabled)

- Perform a `git push --tags` to push the new tag to Github (requires Git
enabled)

#### cycle process

- Enable git interaction if A) `git` is installed, B) `--repo` and `--user` are
sent in

- Increment the version number of all module files found by `0.01`

- Add a new section into the `Changes` file, with the updated version and an
unreleased indicator

- `git commit` and `git push` these changes, if git interaction is enabled

#### install process

- Inserts sections into specific files for new features, or installs files for
updated functionality
