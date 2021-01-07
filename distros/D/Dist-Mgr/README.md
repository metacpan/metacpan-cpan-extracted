## distmgr - Manage a Perl distribution

- [Description](#description)
- [Limitations](#limitations)
- [Usage](#usage)
- [Commands](#commands)
- [**create** - Create distribution with repository](#create)
- [**dist** - Create a distribution](#dist)
- [**release** - Release a distribution](#release)
- [**cycle** - Prepare next development cycle](#cycle)
- [**install** - Install individual features](#install)
- [Examples](#examples)

### Description

The `distmgr` command line application that's installed along with the 
`Dist::Mgr` Perl distribution provides the facility to manage Perl distributions
that you're the author of.

It allows you to create distributions (with or without a Github repository),
release your distributions, automatically prepare your distribution's next
development cycle, and install some or all of the features and files that we
provide.

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
    -h | --help     Optional:  (Flag) Display help
    -V | --verbose  Optional:  (Flag) Display verbose output for each process

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
    -h | --help     Optional:  (Flag) Display help
    -V | --verbose  Optional:  (Flag) Display verbose output for each process

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
 
