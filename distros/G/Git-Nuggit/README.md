# Nuggit

Nuggit is a git tool for assisting with submodule based workflows.  It
provides additional logic wrapping native git capabilities to automate
common operations across submodules to achieve a mono-repository like
workflow. 

This is, in part, achieved by encouraging users to conduct all work on
the same branch across all submodules, and taking the appropriate
action when submodules are modified, added, pushed, pulled
etc. without requiring the user to do extra magic just for
submodules.  

All functionality can be access through the 'ngt' or 'nuggit' wrapper
scripts.  Tab auto-completion is optionally available for the 'ngt'
form when using the Bash shell.


For full functionality the nuggit.sh or nuggit.csh shell should be
sourced to add nuggit to your path for bash or csh respectively
(required for auto-completion).  These files can be used as an example
if needed to adopt for other shell environments.  If installed via
cpan, this step is optional, however may be required to enable
shell-specific features.

Full usage information is available via man pages for most scripts, or
from the command-line by specifying '--man' (for detailed usage) or
"--help"  (synopsis only).  For example, "ngt --man" or "ngt
status --man".

## Support

Please report any issues to the [issue
tracker](http://github.com/monacca1/nuggit) or discussions section.


## Installation
Several installation options are documented below for convenience.

Minimum requirements for Nuggit are:
- Command-line Git tools, version 2.24 or later.
- Perl version 5.10 or later

NOTE: The test step for nuggit will fail if git is not installed, or
if you have not defined your git user.name and user.email.  These can
be set with "git config --global user.email my@email.com" and "git
config --global user.name 'J Doe'"

### CPAN (recommended)
Nuggit is now listed in CPAN and can be installed directly with:

   "cpan Git::Nuggit"
   
### CPAN (local, for developers)

Clone this repository and run "cpan ." from within the current folder
to automatically install all dependencies.

This is the recommended installation method for developers, or users
requiring a specific version of Nuggit.

### Makefile.PL

- Install all dependencies (see Makefile.PL for listing)
- perl Makefile.PL
- make
- make test     # Optional
- make install

### Manual
Simply run "source nuggit.sh" (or the equivalent for your platform) to
install nuggit into you rsystem path.

If the requisite dependencies have not already been installed, they
must be installed manually using CPAN, CPANM, or other method.  A list
of dependencies can be found in Makefile.PL

### Optional: CPANM Setup
CPANM is an alternative to CPAN, which is particularly useful if
running on a system where you do not have sudo privileges.

The following commands will install cpanm and all required dependencies locally.  This may take a few minutes if none are already installed.  Running cpanm as root will install packages globally.
- curl -L https://cpanmin.us/ -o cpanm && chmod +x cpanm
- ./cpanm --local-lib=~/perl5 local::lib
- eval $(perl -I ~/perl5/lib/perl5/ -Mlocal::lib)
  - # This command should be added to your .bashrc/.cshrc, or your PERL5LIB path manually updated.
- Clone or download nuggit and cd into it
- ~/cpanm .
  - Note: If you downloaded cpanm to an alternate location, update the
    path accordingly.


## ANSI Color Configuration / Accessibility
The Nuggit scripts utilize ANSI terminal colors to clarify message
output.  Output generally uses custom alias classes of 'error',
'warn', 'info', and 'success'.

Environment variables can be used to disable colored output entirely,
or to customize the color scheme for personal preferences.  See
https://perldoc.perl.org/Term::ANSIColor#ENVIRONMENT for details.


## Command List
The following commands are currently supported.  See their man pages
for details.
-  add
-  branch
-  checkout
-  clone
-  commit
-  diff
-  difftool
-  fetch
-  foreach
-  history
-  init
-  log
-  merge
-  merge-tree
-  mergetool
-  mv 
-  pull
-  push
-  rebase
-  remote
-  reset
-  rm
-  stash save|pop|save|list|show|drop|apply|branch
-  status
-  tag

A 'check' command is also available to verify that all dependnecies,
including minimum git version, are installed.  This command will also
output the current Nuggit version.

## User-defined Command Aliases

Nuggit supports defining custom, project-specific, command aliases.  A
defined alias can be exeuted from anywhere within the nuggit
repository and will operate on paths relative to the root, as with any
native nuggit command.

To define aliases, create a ".nuggit/config.json" file.  For example:

```
{
"aliases: " {
    "foo" : "cat version",
    "build" : { "cmd" : "make",
                "dir" : "app/build",
                "log_file" : "make"
                }
}
```

The above example enables a command "ngt foo", that can be executed
from anywhere within your source tree to view the contents of a
'version' file at the root directory.  

This example also defines a 'ngt build', which will run 'make' from
the directory 'app/build' relative to the repository root.  

The optional 'log_file' parameter will cause the output from this command
to be saved relative tot he specified dir.  In this case, it would
create app/build/makestdout.log and app/build/makestderr.log.  Output
will not appear in the shell if the command exits without error,
however stderr will be displayed if it fails.  In this example, a
failed build would show you the build errors but omit any other
nominal output from the make command.
